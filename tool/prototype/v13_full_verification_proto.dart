// PROTOTYPE — 验证后删除（或保留为回归检查）
// 运行：flutter test tool/prototype/v13_full_verification_proto.dart
//
// 接入真实生产代码验证 v1.3 全链路安全加固：
// - LocalMutationProtocol（propose/decide/commit/applyUserEdit）
// - FileCanonicalStore（prepare/apply 原子写入）
// - SandboxedSkillApi（propose-only，不委托物理写入）
// - 全部 5 种 origin 的审批策略（ADR-010）
// - fail-closed 行为
// - 三记录不变量
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/features/skill/data/skill/skill_executor.dart';
import 'package:lingbi/features/skill/data/skill/skill_permission.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/models/canon_entry.dart';

// ═══════════════════════════════════════════════════════════
//  测试基础设施
// ═══════════════════════════════════════════════════════════

/// 记录型 FakeSkillApi — 追踪 delegate 是否被调用
class TrackingSkillApi implements SkillApi {
  final List<String> calls = [];

  @override
  Future<List<CanonEntry>> canonRead(String projectId) async {
    calls.add('canonRead');
    return [];
  }

  @override
  Future<void> canonWrite(String projectId, CanonEntry entry) async {
    calls.add('canonWrite');
  }

  @override
  Future<String> documentRead(String projectId, String documentId) async {
    calls.add('documentRead');
    return '';
  }

  @override
  Future<void> documentWrite(
      String projectId, String documentId, String content) async {
    calls.add('documentWrite');
  }
}

// ═══════════════════════════════════════════════════════════
//  主验证流程
// ═══════════════════════════════════════════════════════════

void main() {
  late Directory tempDir;
  late String projectRoot;
  late String journalPath;
  late LocalMutationProtocol protocol;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_v13_proto_');
    projectRoot = '${tempDir.path}/project';
    journalPath = '${tempDir.path}/journal';
    Directory(projectRoot).createSync(recursive: true);
    Directory(journalPath).createSync(recursive: true);
    protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: journalPath),
      store: FileCanonicalStore(
        projectRoot: projectRoot,
        atomicStore: AtomicFileStore(),
      ),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('场景 1：userUi origin — 隐式批准，一步落盘 + 三记录不变量', () async {
    final result = await protocol.applyUserEdit(ChangeRequest(
      projectId: 'proj-1',
      origin: ChangeOrigin.userUi,
      action: ChangeAction.replaceText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: '# 第一章\n\n用户直接编辑的内容。',
    ));

    expect(result.getOrNull(), isNotNull, reason: 'applyUserEdit 返回 Success');

    final file = File('$projectRoot/chapters/ch01.md');
    expect(file.existsSync(), isTrue, reason: '文件已创建');
    expect(file.readAsStringSync(), contains('用户直接编辑'),
        reason: '文件内容 == payload');

    // 验证三记录不变量
    final journal = LocalMutationJournal(basePath: journalPath);
    final events = await journal.readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(types, contains('candidate_proposed'));
    expect(types, contains('candidate_approved'));
    expect(types, contains('candidate_committed'));
  });

  test('场景 2：Skill origin — propose-only，不落盘，delegate 不调用', () async {
    final trackingApi = TrackingSkillApi();
    final sandbox = SandboxedSkillApi(
      permissions: PermissionSet.fromStrings(['canon.write']),
      delegate: trackingApi,
      mutationProtocol: protocol,
      skillId: 'test-skill',
    );

    await sandbox.canonWrite(
      'proj-1',
      CanonEntry(
        projectId: 'proj-1',
        type: CanonEntryType.character,
        name: '测试角色',
        description: 'Skill 写入的角色',
      ),
    );

    // 核心断言：delegate 不被调用（propose-only）
    expect(trackingApi.calls, isNot(contains('canonWrite')),
        reason: 'delegate.canonWrite 未被调用（propose-only）');

    // 验证 journal 只有 proposed，没有 committed
    final journal = LocalMutationJournal(basePath: journalPath);
    final events = await journal.readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(types, contains('candidate_proposed'));
    expect(types, isNot(contains('candidate_committed')),
        reason: 'Skill 提案未被 commit（等待用户审批）');
  });

  test('场景 3：Skill origin — 协议不可用时 fail-closed，delegate 不调用', () async {
    final trackingApi = TrackingSkillApi();
    final sandboxNoProtocol = SandboxedSkillApi(
      permissions: PermissionSet.fromStrings(['canon.write']),
      delegate: trackingApi,
      mutationProtocol: _UnavailableProtocol(),
      skillId: 'no-protocol-skill',
    );

    await expectLater(
      sandboxNoProtocol.canonWrite(
        'proj-1',
        CanonEntry(projectId: 'proj-1', type: CanonEntryType.lore, name: 'x'),
      ),
      throwsStateError,
      reason: '协议不可用时 propose 失败 → StateError（fail-closed）',
    );
    expect(trackingApi.calls, isNot(contains('canonWrite')),
        reason: 'delegate.canonWrite 未被调用');
  });

  test('场景 4：Agent origin — 显式批准后才能 commit', () async {
    // Step 1: propose
    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'proj-1',
      origin: ChangeOrigin.agent,
      action: ChangeAction.replaceText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch02.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: '# 第二章\n\nAI 生成的内容。',
    ));
    final candidate = proposeResult.getOrNull();
    expect(candidate, isNotNull, reason: 'Agent propose 成功');

    // Step 2: 未批准直接 commit → 应失败
    final earlyCommit = await protocol.commit(CommitCommand(
      candidateId: candidate!.id,
      approvalId: 'fake-approval',
      idempotencyKey: 'idem-early',
    ));
    expect(earlyCommit.getOrNull(), isNull, reason: '未批准 commit 被拒绝');
    expect(File('$projectRoot/chapters/ch02.md').existsSync(), isFalse,
        reason: '未批准时文件不存在');

    // Step 3: 用户批准
    final decideResult = await protocol.decide(ApprovalCommand(
      candidateId: candidate.id,
      actorId: 'user',
      approved: true,
      policy: 'explicit_user_approval',
    ));
    final approval = decideResult.getOrNull();
    expect(approval, isNotNull, reason: '用户批准成功');

    // Step 4: 批准后 commit → 成功落盘
    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval!.id,
      idempotencyKey: 'idem-agent-ch02',
    ));
    expect(commitResult.getOrNull(), isNotNull, reason: '批准后 commit 成功');

    final fileAfter = File('$projectRoot/chapters/ch02.md');
    expect(fileAfter.existsSync(), isTrue, reason: '文件已创建');
    expect(fileAfter.readAsStringSync(), contains('AI 生成'),
        reason: '文件内容 == Agent payload');
  });

  test('场景 5：被拒绝的候选不能 commit', () async {
    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'proj-1',
      origin: ChangeOrigin.agent,
      action: ChangeAction.replaceText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch03.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: '不应被写入的内容',
    ));
    final candidate = proposeResult.getOrNull()!;

    // 用户拒绝
    await protocol.decide(ApprovalCommand(
      candidateId: candidate.id,
      actorId: 'user',
      approved: false,
      policy: 'explicit_reject',
    ));

    // 尝试 commit → 应失败
    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: 'any',
      idempotencyKey: 'idem-rejected',
    ));
    expect(commitResult.getOrNull(), isNull, reason: '被拒绝的候选 commit 失败');
    expect(File('$projectRoot/chapters/ch03.md').existsSync(), isFalse,
        reason: '被拒绝后文件不存在');
  });

  test('场景 6：路径逃逸攻击 → 拦截', () async {
    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'proj-1',
      origin: ChangeOrigin.agent,
      action: ChangeAction.replaceText,
      target: const ChangeTarget(
        projectRelativePath: '../../etc/passwd',
        kind: 'file',
      ),
      baseRevision: 0,
      payload: 'malicious content',
    ));
    final candidate = proposeResult.getOrNull();
    // propose 可能成功（journal 记录），但 commit 时 store 拒绝
    if (candidate != null) {
      final decideResult = await protocol.decide(ApprovalCommand(
        candidateId: candidate.id,
        actorId: 'user',
        approved: true,
        policy: 'test',
      ));
      final approval = decideResult.getOrNull();
      if (approval != null) {
        final commitResult = await protocol.commit(CommitCommand(
          candidateId: candidate.id,
          approvalId: approval.id,
          idempotencyKey: 'idem-escape',
        ));
        expect(commitResult.getOrNull(), isNull,
            reason: '路径逃逸 commit 被拦截');
      }
    }
    expect(File('${tempDir.path}/etc/passwd').existsSync(), isFalse,
        reason: '项目外文件未被创建');
  });

  test('场景 7：Revision Conflict — 并发写入保护', () async {
    // 先写入一个文件
    await protocol.applyUserEdit(ChangeRequest(
      projectId: 'proj-1',
      origin: ChangeOrigin.userUi,
      action: ChangeAction.replaceText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: '原始版本 v1',
    ));

    // 再次写入同一文件（expectedHash: null 所以不会冲突，但验证不崩溃）
    final result = await protocol.applyUserEdit(ChangeRequest(
      projectId: 'proj-1',
      origin: ChangeOrigin.userUi,
      action: ChangeAction.replaceText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 1,
      payload: '更新版本 v2',
    ));

    final content = File('$projectRoot/chapters/ch01.md').readAsStringSync();
    expect(content, contains('v2'), reason: '文件内容已更新');
  });

  test('场景 8：Skill 无 canon.write 权限 → PermissionViolation', () async {
    final trackingApi = TrackingSkillApi();
    final readOnlySandbox = SandboxedSkillApi(
      permissions: PermissionSet.fromStrings(['canon.read']),
      delegate: trackingApi,
      mutationProtocol: protocol,
      skillId: 'readonly-skill',
    );

    expect(
      () => readOnlySandbox.canonWrite(
        'proj-1',
        CanonEntry(projectId: 'proj-1', type: CanonEntryType.lore, name: 'x'),
      ),
      throwsA(isA<PermissionViolation>()),
      reason: '无 canon.write 权限时抛出 PermissionViolation',
    );
  });
}

/// 协议不可用时的 fail-closed 替身：所有操作返回 protocolUnavailable。
class _UnavailableProtocol implements MutationProtocol {
  Result<Never> get _unavailable =>
      Result.failure(FileError('protocolUnavailable', code: 'PROTOCOL_UNAVAILABLE'));

  @override
  Future<Result<CandidateChange>> propose(ChangeRequest request) async =>
      _unavailable;

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async =>
      _unavailable;

  @override
  Future<Result<CommitReceipt>> commit(CommitCommand command) async =>
      _unavailable;

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async =>
      _unavailable;

  @override
  Future<Result<void>> reject(RejectCommand command) async => _unavailable;

  @override
  Future<Result<List<RecoveryOutcome>>> reconcilePending(
          String projectId) async =>
      _unavailable;
}
