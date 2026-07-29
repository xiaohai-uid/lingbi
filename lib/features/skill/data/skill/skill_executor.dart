/// SkillExecutor — 声明式执行沙箱
///
/// 提供受权限约束的灵笔 API 访问，根据 manifest 声明路由到对应 API。
/// SandboxedSkillApi 在真实服务代理之上叠加权限守卫，
/// SkillExecutor 统一入口，将轻量/重量 Skill 路由到正确执行路径。
library;

import 'dart:io';

import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/features/skill/data/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/features/skill/data/skill/skill_audit_log.dart';
import 'package:lingbi/features/skill/data/skill/skill_manifest.dart';
import 'package:lingbi/features/skill/data/skill/skill_permission.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';
import 'package:path/path.dart' as path;

/// 权限违反异常
class PermissionViolation implements Exception {
  PermissionViolation(this.message);

  final String message;

  @override
  String toString() => 'PermissionViolation: $message';
}

/// 灵笔内置 API 门面 — 供 Skill 调用的受限接口
abstract class SkillApi {
  /// 读取正典条目列表
  Future<List<CanonEntry>> canonRead(String projectId);

  /// 写入正典条目
  Future<void> canonWrite(String projectId, CanonEntry entry);

  /// 读取文档内容
  Future<String> documentRead(String projectId, String documentId);

  /// 写入文档内容
  Future<void> documentWrite(
      String projectId, String documentId, String content);
}

/// External resources are injected at the sandbox seam so a denied request
/// never reaches the network or secure storage adapter.
abstract class SkillExternalAccess {
  Future<String> networkGet(Uri uri);

  Future<String?> readSecret(String projectId, String key);
}

/// 受权限约束的 API 实现
///
/// 每次调用前先校验 permissions 是否包含所需权限，
/// 无权限则抛出 [PermissionViolation]，有权限则委托给 delegate。
class SandboxedSkillApi implements SkillApi {
  SandboxedSkillApi({
    required this.permissions,
    required SkillApi delegate,
    this.projectId,
    this.skillId = 'unknown-skill',
    Set<String> capabilities = const {},
    this.projectRoot,
    SkillExternalAccess? externalAccess,
    this.auditLog,
  })  : capabilities = Set.unmodifiable(capabilities),
        _delegate = delegate,
        _externalAccess = externalAccess;

  /// 当前 Skill 声明的权限集
  final PermissionSet permissions;

  /// Project this runtime instance is allowed to access. Legacy callers that
  /// omit it are locked to the first project they touch.
  final String? projectId;
  final String skillId;
  final Set<String> capabilities;
  final String? projectRoot;
  final SkillAuditLog? auditLog;

  /// 真实服务代理（生产环境注入 CanonService/DocumentService 适配器）
  final SkillApi _delegate;
  final SkillExternalAccess? _externalAccess;
  String? _boundProjectId;

  void _checkPermission(SkillPermission required) {
    if (!permissions.can(required)) {
      throw PermissionViolation(
        'Skill 未声明权限: ${required.value}',
      );
    }
  }

  void _checkProject(String requestedProjectId) {
    final allowed = projectId ?? _boundProjectId;
    if (allowed == null) {
      _boundProjectId = requestedProjectId;
      return;
    }
    if (requestedProjectId != allowed) {
      throw PermissionViolation(
        'Skill $skillId cannot access project $requestedProjectId',
      );
    }
  }

  @override
  Future<List<CanonEntry>> canonRead(String projectId) {
    _checkProject(projectId);
    _checkPermission(SkillPermission.canonRead);
    return _delegate.canonRead(projectId);
  }

  @override
  Future<void> canonWrite(String projectId, CanonEntry entry) {
    _checkProject(projectId);
    _checkPermission(SkillPermission.canonWrite);
    return _delegate.canonWrite(projectId, entry);
  }

  @override
  Future<String> documentRead(String projectId, String documentId) {
    _checkProject(projectId);
    _checkPermission(SkillPermission.documentRead);
    return _delegate.documentRead(projectId, documentId);
  }

  @override
  Future<void> documentWrite(
      String projectId, String documentId, String content) {
    _checkProject(projectId);
    _checkPermission(SkillPermission.documentWrite);
    return _delegate.documentWrite(projectId, documentId, content);
  }

  Future<String> networkGet(Uri uri) async {
    final capability = 'network:${uri.host.toLowerCase()}';
    if (!capabilities.contains('network') && !capabilities.contains(capability)) {
      await _recordDenied('network.get', {'host': uri.host});
      throw PermissionViolation('Skill $skillId did not declare $capability');
    }
    final external = _externalAccess;
    if (external == null) {
      throw PermissionViolation('Network access adapter is unavailable');
    }
    return external.networkGet(uri);
  }

  Future<String?> readSecret(String requestedProjectId, String key) async {
    try {
      _checkProject(requestedProjectId);
    } on PermissionViolation {
      await _recordDenied('secret.read', {'key': key});
      rethrow;
    }
    final capability = 'secret.read:$key';
    if (!capabilities.contains(capability)) {
      await _recordDenied('secret.read', {'key': key});
      throw PermissionViolation('Skill $skillId did not declare $capability');
    }
    final external = _externalAccess;
    if (external == null) {
      throw PermissionViolation('Secret access adapter is unavailable');
    }
    return external.readSecret(requestedProjectId, key);
  }

  Future<String> readProjectFile(
    String requestedProjectId,
    String relativePath,
  ) async {
    _checkProject(requestedProjectId);
    if (!capabilities.contains('project.file.read')) {
      await _recordDenied('project.file.read', {'path': relativePath});
      throw PermissionViolation(
        'Skill $skillId did not declare project.file.read',
      );
    }
    final root = projectRoot;
    if (root == null || !_isSafeRelativePath(relativePath)) {
      await _recordDenied('project.file.read', {'path': relativePath});
      throw PermissionViolation('Project path escapes the configured root');
    }
    final absoluteRoot = path.normalize(path.absolute(root));
    final target = path.normalize(path.join(absoluteRoot, relativePath));
    if (!path.isWithin(absoluteRoot, target)) {
      await _recordDenied('project.file.read', {'path': relativePath});
      throw PermissionViolation('Project path escapes the configured root');
    }
    return File(target).readAsString();
  }

  bool _isSafeRelativePath(String value) {
    if (value.isEmpty || path.isAbsolute(value)) return false;
    return !value
        .replaceAll(r'\', '/')
        .split('/')
        .any((segment) => segment == '..' || segment.isEmpty);
  }

  Future<void> _recordDenied(
    String operation,
    Map<String, String> details,
  ) async {
    final log = auditLog;
    if (log == null) return;
    await log.append(
      skillId: skillId,
      projectId: projectId ?? _boundProjectId ?? '',
      operation: operation,
      outcome: SkillAuditOutcome.denied,
      details: details,
    );
  }
}

/// 声明式执行引擎
///
/// 统一入口：将 Skill 的执行请求路由到正确路径。
/// - 轻量 Skill（lightweight）→ 传统 prompt 路径
/// - 重量 Skill（heavyweight）→ 声明式 API 路径（直接调用沙箱 API，返回结构化结果）
class SkillExecutor {
  SkillExecutor();

  /// 执行技能
  ///
  /// [skill]    — 待执行的 DynamicPromptSkill
  /// [context]  — 执行上下文（选中文本、项目信息等）
  /// [api]      — 受沙箱保护的 API 实例
  /// [params]   — 额外参数
  Future<SkillResult> execute({
    required DynamicPromptSkill skill,
    required SkillContext context,
    required SandboxedSkillApi api,
    Map<String, String> params = const {},
  }) async {
    // 轻量 Skill：直接在 executor 内完成验证 + prompt 构建
    if (skill.manifest.type == SkillType.lightweight) {
      return _executeLightweight(
        skill: skill,
        context: context,
        params: params,
      );
    }

    // 重量 Skill 走声明式 API 路径
    return _executeHeavyweight(
      skill: skill,
      context: context,
      api: api,
      params: params,
    );
  }

  /// 轻量 Skill：验证输入 + 检查参数 + 构建 prompt，不调用任何沙箱 API
  SkillResult _executeLightweight({
    required DynamicPromptSkill skill,
    required SkillContext context,
    required Map<String, String> params,
  }) {
    // 验证输入长度
    final input = context.effectiveInput(skill.inputScope);
    final minLength = skill.contextRequirements.minInputLength;
    if (minLength > 0 && input.length < minLength) {
      return SkillResult(
        success: false,
        error: '输入文本不足（至少需要 $minLength 字）',
      );
    }

    // 检查必填参数
    if (!skill.areParametersSatisfied(params)) {
      final missing = skill.getMissingParameters(params);
      final names = missing.map((p) => p.label).join(', ');
      return SkillResult(
        success: false,
        error: '缺少必填参数: $names',
      );
    }

    // 构建 prompt
    final prompt = skill.buildPrompt(context: context, params: params);
    return SkillResult(
      success: true,
      promptForAI: prompt,
    );
  }

  /// 重量 Skill 声明式执行：并行读取 Canon + Document，组装结果
  Future<SkillResult> _executeHeavyweight({
    required DynamicPromptSkill skill,
    required SkillContext context,
    required SandboxedSkillApi api,
    required Map<String, String> params,
  }) async {
    final projectId = context.projectId;
    final documentId = params['documentId'] ?? context.chapterId;

    try {
      // 并行读取，失败则直接抛出（权限不足 / 服务异常）
      final results = await Future.wait([
        api.canonRead(projectId),
        api.documentRead(projectId, documentId),
      ]);

      final canonEntries = results[0] as List<CanonEntry>;
      final documentContent = results[1] as String;

      return SkillResult(
        success: true,
        canonEntries: canonEntries,
        output: documentContent,
      );
    } on PermissionViolation {
      // 权限异常直接向上传播，不吞掉
      rethrow;
    } catch (e) {
      return SkillResult(
        success: false,
        error: '执行失败: $e',
      );
    }
  }
}
