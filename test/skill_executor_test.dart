// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/features/skill/data/skill/skill_executor.dart';
import 'package:lingbi/features/skill/data/skill/skill_manifest.dart';
import 'package:lingbi/features/skill/data/skill/skill_permission.dart';
import 'package:lingbi/features/skill/data/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';

// ==================== Fake 服务 ====================

/// 内存级 Fake SkillApi，记录所有调用
class FakeSkillApi implements SkillApi {
  final List<CanonEntry> _canonEntries = [];
  final Map<String, String> _documents = {};

  // 调用追踪
  final List<String> callLog = [];

  /// 预置正典数据
  void seedCanon(List<CanonEntry> entries) {
    _canonEntries.addAll(entries);
  }

  /// 预置文档数据
  void seedDocument(String documentId, String content) {
    _documents[documentId] = content;
  }

  @override
  Future<List<CanonEntry>> canonRead(String projectId) async {
    callLog.add('canonRead:$projectId');
    return List.unmodifiable(_canonEntries);
  }

  @override
  Future<void> canonWrite(String projectId, CanonEntry entry) async {
    callLog.add('canonWrite:$projectId');
    _canonEntries.add(entry);
  }

  @override
  Future<String> documentRead(String projectId, String documentId) async {
    callLog.add('documentRead:$projectId:$documentId');
    return _documents[documentId] ?? '';
  }

  @override
  Future<void> documentWrite(
      String projectId, String documentId, String content) async {
    callLog.add('documentWrite:$projectId:$documentId');
    _documents[documentId] = content;
  }
}

// ==================== 测试 ====================

void main() {
  group('SandboxedSkillApi 权限守卫', () {
    late FakeSkillApi fakeApi;

    setUp(() {
      fakeApi = FakeSkillApi();
    });

    test('有 canonRead 权限时读取成功', () async {
      final permissions = PermissionSet.fromStrings(['canon.read']);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      final result = await sandbox.canonRead('proj-1');
      expect(result, isA<List<CanonEntry>>());
      expect(fakeApi.callLog, contains('canonRead:proj-1'));
    });

    test('无 canonRead 权限时抛出 PermissionViolation', () async {
      final permissions = PermissionSet.fromStrings([]);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      expect(
        () => sandbox.canonRead('proj-1'),
        throwsA(isA<PermissionViolation>()),
      );
    });

    test('有 canonWrite 权限时写入成功（propose-only，不委托物理写入）', () async {
      final temp = Directory.systemTemp.createTempSync('lingbi_skill_perm_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final protocol = LocalMutationProtocol(
        journal: LocalMutationJournal(basePath: '${temp.path}/journal'),
        store: FileCanonicalStore(
          projectRoot: temp.path,
          atomicStore: AtomicFileStore(),
        ),
      );
      final permissions = PermissionSet.fromStrings(['canon.write']);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: protocol,
      );

      await sandbox.canonWrite(
        'proj-1',
        CanonEntry(projectId: 'proj-1', type: CanonEntryType.character, name: '角色A'),
      );
      // T01: Skill origin is propose-only — delegate NOT called
      expect(fakeApi.callLog, isNot(contains('canonWrite:proj-1')));
    });

    test('无 canonWrite 权限时（仅有 canonRead）抛出 PermissionViolation',
        () async {
      final permissions = PermissionSet.fromStrings(['canon.read']);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      expect(
        () => sandbox.canonWrite(
          'proj-1',
          CanonEntry(projectId: 'proj-1', type: CanonEntryType.character, name: 'x'),
        ),
        throwsA(isA<PermissionViolation>()),
      );
    });

    test('有 documentRead 权限时读取成功', () async {
      final permissions = PermissionSet.fromStrings(['document.read']);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      await sandbox.documentRead('proj-1', 'doc-1');
      expect(fakeApi.callLog, contains('documentRead:proj-1:doc-1'));
    });

    test('无 documentRead 权限时抛出 PermissionViolation', () async {
      final permissions = PermissionSet.fromStrings([]);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      expect(
        () => sandbox.documentRead('proj-1', 'doc-1'),
        throwsA(isA<PermissionViolation>()),
      );
    });

    test('有 documentWrite 权限时写入成功', () async {
      final permissions = PermissionSet.fromStrings(['document.write']);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      await sandbox.documentWrite('proj-1', 'doc-1', '新内容');
      expect(fakeApi.callLog, contains('documentWrite:proj-1:doc-1'));
    });

    test('无 documentWrite 权限时（仅有 documentRead）抛出 PermissionViolation',
        () async {
      final permissions = PermissionSet.fromStrings(['document.read']);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      expect(
        () => sandbox.documentWrite('proj-1', 'doc-1', '新内容'),
        throwsA(isA<PermissionViolation>()),
      );
    });

    test('PermissionViolation 消息包含缺失权限名', () async {
      final permissions = PermissionSet.fromStrings([]);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );

      try {
        await sandbox.canonRead('proj-1');
        fail('应抛出异常');
      } on PermissionViolation catch (e) {
        expect(e.toString(), contains('canon.read'));
      }
    });
  });

  group('SkillExecutor 路由测试', () {
    late FakeSkillApi fakeApi;
    late SkillExecutor executor;

    setUp(() {
      fakeApi = FakeSkillApi();
      executor = SkillExecutor();
    });

    DynamicPromptSkill makeSkill({
      SkillType type = SkillType.lightweight,
      List<String> permissionStrings = const [],
      String? category,
    }) {
      final manifest = SkillManifest(
        id: 'test-skill',
        name: '测试技能',
        description: '用于路由测试',
        promptTemplate: '请分析以下文本：{input}',
        type: type,
        category: category,
      );
      return DynamicPromptSkill(
        manifest: manifest,
        permissions: permissionStrings.isEmpty
            ? null
            : PermissionSet.fromStrings(permissionStrings),
      );
    }

    test('轻量 Skill 走 prompt 路径，结果含 promptForAI', () async {
      final skill = makeSkill();
      final api = SandboxedSkillApi(
        permissions: PermissionSet.defaultLightweight(),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(
        selectedText: '测试文本',
        projectId: 'proj-1',
      );

      final result = await executor.execute(
        skill: skill,
        context: context,
        api: api,
      );

      expect(result.success, isTrue);
      expect(result.promptForAI, contains('测试文本'));
      // 轻量 Skill 不调用任何沙箱 API
      expect(fakeApi.callLog, isEmpty);
    });

    test('轻量 Skill 输入文本不足时返回错误', () async {
      final skill = _SkillWithMinInput(minInputLength: 10);
      final api = SandboxedSkillApi(
        permissions: PermissionSet.defaultLightweight(),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(selectedText: '短');

      final result = await executor.execute(
        skill: skill,
        context: context,
        api: api,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('至少需要 10 字'));
    });

    test('轻量 Skill 缺少必填参数时返回错误', () async {
      final skill = _SkillWithRequiredParams();
      final api = SandboxedSkillApi(
        permissions: PermissionSet.defaultLightweight(),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(selectedText: '测试文本');

      // 不传 params，触发缺少参数错误
      final result = await executor.execute(
        skill: skill,
        context: context,
        api: api,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('缺少必填参数'));
      expect(result.error, contains('写作风格'));
    });

    test('轻量 Skill 提供必填参数时正常执行', () async {
      final skill = _SkillWithRequiredParams();
      final api = SandboxedSkillApi(
        permissions: PermissionSet.defaultLightweight(),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(selectedText: '测试文本');

      final result = await executor.execute(
        skill: skill,
        context: context,
        api: api,
        params: {'style': '武侠'},
      );

      expect(result.success, isTrue);
      expect(result.promptForAI, contains('测试文本'));
    });

    test('manifest.type 路由：同一 Skill 轻量和重量走完全不同的路径', () async {
      fakeApi.seedCanon([
        CanonEntry(projectId: 'proj-1', type: CanonEntryType.character, name: '角色A'),
      ]);
      fakeApi.seedDocument('doc-1', '章节正文');

      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(['canon.read', 'document.read']),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(
        selectedText: '测试文本',
        projectId: 'proj-1',
        chapterId: 'doc-1',
      );

      // 轻量 Skill → prompt 路径
      final lightweightSkill = makeSkill();
      final lightweightResult = await executor.execute(
        skill: lightweightSkill,
        context: context,
        api: api,
      );
      expect(lightweightResult.promptForAI, contains('测试文本'));
      expect(lightweightResult.canonEntries, isEmpty);
      expect(fakeApi.callLog, isEmpty); // 未调用任何 API

      // 重量 Skill → API 路径
      fakeApi.callLog.clear();
      final heavyweightSkill = makeSkill(
        type: SkillType.heavyweight,
        permissionStrings: ['canon.read', 'document.read'],
      );
      final heavyweightResult = await executor.execute(
        skill: heavyweightSkill,
        context: context,
        api: api,
      );
      expect(heavyweightResult.promptForAI, isEmpty);
      expect(heavyweightResult.canonEntries, hasLength(1));
      expect(heavyweightResult.canonEntries[0].name, equals('角色A'));
      expect(heavyweightResult.output, equals('章节正文'));
      expect(fakeApi.callLog, containsAll(['canonRead:proj-1', 'documentRead:proj-1:doc-1']));
    });

    test('重量 Skill 走 API 路径，结果不含 promptForAI', () async {
      fakeApi.seedCanon([
        CanonEntry(projectId: 'proj-1', type: CanonEntryType.character, name: '角色A'),
        CanonEntry(projectId: 'proj-1', type: CanonEntryType.location, name: '地点B'),
      ]);
      fakeApi.seedDocument('doc-1', '章节正文内容');
      final skill = makeSkill(
        type: SkillType.heavyweight,
        permissionStrings: ['canon.read', 'canon.write', 'document.read'],
      );
      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(['canon.read', 'canon.write', 'document.read']),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(
        selectedText: '重量级测试',
        projectId: 'proj-1',
        chapterId: 'doc-1',
      );

      final result = await executor.execute(
        skill: skill,
        context: context,
        api: api,
      );

      expect(result.success, isTrue);
      // canonEntries 和 document 内容同时返回
      expect(result.canonEntries, hasLength(2));
      expect(result.canonEntries[0].name, equals('角色A'));
      expect(result.canonEntries[1].name, equals('地点B'));
      expect(result.output, equals('章节正文内容'));
      expect(result.promptForAI, isEmpty);
      // 两个 API 都被并行调用
      expect(fakeApi.callLog, contains('canonRead:proj-1'));
      expect(fakeApi.callLog, contains('documentRead:proj-1:doc-1'));
    });

    test('重量 Skill 无 document.read 权限时 PermissionViolation 向上传播', () async {
      fakeApi.seedCanon([
        CanonEntry(projectId: 'proj-1', type: CanonEntryType.character, name: '角色A'),
      ]);
      final skill = makeSkill(
        type: SkillType.heavyweight,
        permissionStrings: ['canon.read'], // 有 canonRead 但无 documentRead
      );
      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(['canon.read']),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(projectId: 'proj-1', chapterId: 'doc-1');

      expect(
        () => executor.execute(skill: skill, context: context, api: api),
        throwsA(isA<PermissionViolation>()),
      );
    });

    test('重量 Skill 无 canon.read 权限时 PermissionViolation 向上传播', () async {
      final skill = makeSkill(
        type: SkillType.heavyweight,
        permissionStrings: ['document.read'], // 有 documentRead 但无 canonRead
      );
      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(['document.read']),
        delegate: fakeApi,
        mutationProtocol: _NoopProtocol(),
      );
      const context = SkillContext(projectId: 'proj-1', chapterId: 'doc-1');

      expect(
        () => executor.execute(skill: skill, context: context, api: api),
        throwsA(isA<PermissionViolation>()),
      );
    });
  });

  group('SandboxedSkillApi MutationProtocol 集成', () {
    test('canonWrite 经 MutationProtocol 创建 journal 记录', () async {
      final temp = Directory.systemTemp.createTempSync('lingbi_skill_mutation_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final journalDir = Directory('${temp.path}/journal')..createSync();
      final protocol = LocalMutationProtocol(
        journal: LocalMutationJournal(basePath: journalDir.path),
        store: FileCanonicalStore(
          projectRoot: temp.path,
          atomicStore: AtomicFileStore(),
        ),
      );
      final fakeApi = FakeSkillApi();
      final permissions = PermissionSet.fromStrings(['canon.write']);
      final sandbox = SandboxedSkillApi(
        permissions: permissions,
        delegate: fakeApi,
        mutationProtocol: protocol,
      );

      final entry = CanonEntry(
        id: 'entry-1',
        projectId: 'proj-1',
        name: '人物',
        type: CanonEntryType.character,
        description: '主角：李明',
      );
      await sandbox.canonWrite('proj-1', entry);

      // T01: Skill origin is propose-only — delegate NOT called
      expect(fakeApi.callLog, isNot(contains('canonWrite:proj-1')));

      // T01: Skill origin uses propose-only (explicit approval required)
      // Journal has proposed event but NOT approved/committed
      final journal = LocalMutationJournal(basePath: journalDir.path);
      final events = await journal.readAll();
      final types = events.map((e) => e.eventType).toList();
      expect(types, contains('candidate_proposed'));
      expect(types, isNot(contains('candidate_committed')));
    });
  });
}

/// 辅助类：用于测试轻量 Skill 输入长度验证
class _SkillWithMinInput extends DynamicPromptSkill {

  _SkillWithMinInput({required this.minInputLength})
      : super(
          manifest: const SkillManifest(
            id: 'min-input-skill',
            name: '最小输入测试',
            description: '用于测试输入长度验证',
            promptTemplate: '请分析：{input}',
          ),
        );
  final int minInputLength;

  @override
  ContextRequirements get contextRequirements => ContextRequirements(
        minInputLength: minInputLength,
      );
}

/// 辅助类：用于测试轻量 Skill 必填参数验证
class _SkillWithRequiredParams extends DynamicPromptSkill {
  _SkillWithRequiredParams()
      : super(
          manifest: const SkillManifest(
            id: 'required-params-skill',
            name: '必填参数测试',
            description: '用于测试必填参数验证',
            promptTemplate: '请以{style}风格分析：{input}',
          ),
        );

  @override
  List<SkillParameter> get requiredParameters => [
        const SkillParameter(
          name: 'style',
          label: '写作风格',
          required: true,
        ),
      ];
}


class _NoopProtocol implements MutationProtocol {
  @override
  Future<Result<CandidateChange>> propose(ChangeRequest request) async =>
      Result.success(CandidateChange(
        id: 'noop-cand',
        projectId: request.projectId,
        origin: request.origin,
        action: request.action,
        target: request.target,
        baseRevision: request.baseRevision,
        payloadHash: 'noop',
        actionHash: 'noop',
        createdAt: DateTime.now().toUtc(),
        state: CandidateState.proposed,
      ));

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async =>
      Result.success(ApprovalDecision(
        id: 'noop-appr',
        candidateId: command.candidateId,
        candidateHash: 'noop',
        actionHash: 'noop',
        baseRevision: 0,
        actorId: command.actorId,
        approved: command.approved,
        decidedAt: DateTime.now().toUtc(),
        policy: command.policy,
      ));

  @override
  Future<Result<CommitReceipt>> commit(CommitCommand command) async =>
      Result.success(CommitReceipt(
        id: 'noop-rcpt',
        candidateId: command.candidateId,
        approvalId: command.approvalId,
        idempotencyKey: command.idempotencyKey,
        beforeRevision: 0,
        afterRevision: 1,
        affectedPaths: const [],
        committedAt: DateTime.now().toUtc(),
        receiptHash: 'noop',
      ));

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async =>
      commit(CommitCommand(
        candidateId: 'noop-cand',
        approvalId: 'noop-appr',
        idempotencyKey: request.idempotencyKey ?? 'noop-idem',
      ));

  @override
  Future<Result<void>> reject(RejectCommand command) async =>
      Result.success(null);

  @override
  Future<Result<List<RecoveryOutcome>>> reconcilePending(String projectId) async =>
      Result.success(const []);
}
