/// 项目会话管理器
///
/// 管理 ProjectSessionScope 的创建、切换和销毁。
/// 确保每个项目拥有独立的 CandidateService、WriteLockService、BookStateStore。
/// 不在 ServiceLocator.init() 中注册为全局单例。
library;

import 'package:flutter/foundation.dart';

import '../../modules/pipeline/novel_application_service.dart';
import '../../modules/pipeline/project_session_scope.dart';
import '../../services/ai_service.dart';
import '../../services/canon_service.dart';
import '../../services/document_service.dart';

/// 项目会话管理器
///
/// 由 AppScaffold 或顶层控制器持有。
/// 管理当前活跃项目的会话作用域。
class ProjectSessionManager extends ChangeNotifier {
  ProjectSessionManager({
    required DocumentService documentService,
    required CanonService canonService,
    required AIService aiService,
  })  : _documentService = documentService,
        _canonService = canonService,
        _aiService = aiService;

  final DocumentService _documentService;
  final CanonService _canonService;
  final AIService _aiService;

  /// 当前活跃的项目会话
  ProjectSessionScope? _activeScope;

  /// 已打开的项目会话缓存（projectId → scope）
  final Map<String, ProjectSessionScope> _openScopes = {};

  // ─── Getters ──────────────────────────────────────────────────

  /// 当前活跃会话（可能为 null）
  ProjectSessionScope? get activeScope => _activeScope;

  /// 当前活跃项目 ID
  String? get activeProjectId => _activeScope?.projectId;

  /// 当前活跃的 NovelApplicationService
  NovelApplicationService? get activeNovelService => _activeScope?.novelService;

  /// 是否有活跃项目
  bool get hasActiveProject => _activeScope != null;

  // ─── 项目生命周期 ─────────────────────────────────────────────

  /// 打开项目
  ///
  /// 创建对应 ProjectSessionScope，初始化候选、书籍状态和写锁目录。
  /// 如果项目已打开，直接切换到已有会话。
  ProjectSessionScope openProject({
    required String projectId,
    required String projectDir,
  }) {
    // 如果已打开，直接切换
    final existing = _openScopes[projectId];
    if (existing != null) {
      _activeScope = existing;
      notifyListeners();
      return existing;
    }

    // 创建新会话
    final scope = ProjectSessionScope(
      projectId: projectId,
      projectDir: projectDir,
      documentService: _documentService,
      canonService: _canonService,
      aiService: _aiService,
    );

    _openScopes[projectId] = scope;
    _activeScope = scope;
    notifyListeners();
    return scope;
  }

  /// 切换项目
  ///
  /// - 取消或解绑旧项目正在运行的 UI 任务（由协调器处理）
  /// - 不删除旧项目已落盘候选
  /// - 切换到新项目 Session
  /// - 不复用旧项目 CandidateService
  ProjectSessionScope? switchToProject(String projectId) {
    final scope = _openScopes[projectId];
    if (scope == null) return null;

    // 解绑旧项目章节（不删除候选）
    _activeScope?.unbindChapter();

    _activeScope = scope;
    notifyListeners();
    return scope;
  }

  /// 关闭项目
  ///
  /// - 停止新的生成请求
  /// - 释放监听器和 UI 资源
  /// - 不强制删除候选
  /// - 不因 UI 关闭破坏已经采纳的正文
  void closeProject(String projectId) {
    final scope = _openScopes[projectId];
    if (scope == null) return;

    // 如果关闭的是当前活跃项目，清空活跃状态
    if (_activeScope?.projectId == projectId) {
      _activeScope = null;
    }

    // 释放资源（不删除候选文件）
    scope.dispose();
    _openScopes.remove(projectId);
    notifyListeners();
  }

  /// 关闭所有项目
  void closeAll() {
    for (final scope in _openScopes.values) {
      scope.dispose();
    }
    _openScopes.clear();
    _activeScope = null;
    notifyListeners();
  }

  /// 获取项目的会话（不切换）
  ProjectSessionScope? getScope(String projectId) => _openScopes[projectId];

  /// 检查项目是否已打开
  bool isProjectOpen(String projectId) => _openScopes.containsKey(projectId);

  @override
  void dispose() {
    closeAll();
    super.dispose();
  }
}
