// PROTOTYPE — 一次性验证脚本，验证后删除。
// 问题：LocalMutationProtocol.commit() 是否真正把内容写入了目标文件？
//
// 运行方式（项目根目录）：
//   dart run tool/prototype/mutation_commit_proto.dart
//
// 你会看到 5 个场景逐个执行，每个场景打印：
//   - 做了什么
//   - 目标文件的真实内容（或"文件不存在"）
//   - PASS / FAIL 判定
//
// 当前代码预期：场景 1、5 会 FAIL（因为 commit 没有真正写文件）。
// 修复后预期：全部 PASS。

import 'dart:io';

import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

// ─── 工具函数 ───────────────────────────────────────────────

void printHeader(String title) {
  print('\n${'═' * 60}');
  print('  $title');
  print('${'═' * 60}');
}

void printStep(String msg) => print('  → $msg');

void printVerdict(bool pass, String detail) {
  final icon = pass ? '✅ PASS' : '❌ FAIL';
  print('  $icon — $detail');
}

String? readFileOrNull(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  return f.readAsStringSync();
}

// ─── 主流程 ─────────────────────────────────────────────────

Future<void> main() async {
  printHeader('MutationProtocol Commit 原型验证');
  print('  本原型直接调用真实 LocalMutationProtocol + FileCanonicalStore');
  print('  目标：验证 commit() 是否真正把 payload 写入磁盘文件\n');

  final tempDir = Directory.systemTemp.createTempSync('mutation_proto_');
  final projectRoot = '${tempDir.path}/project';
  Directory(projectRoot).createSync(recursive: true);

  final journal = LocalMutationJournal(
    basePath: '${tempDir.path}/.lingbi/mutations',
  );
  final store = FileCanonicalStore(
    projectRoot: projectRoot,
    atomicStore: AtomicFileStore(),
  );
  final protocol = LocalMutationProtocol(journal: journal, store: store);

  var passCount = 0;
  var failCount = 0;

  // ─── 场景 1：propose → approve → commit → 文件内容 == payload ───
  {
    printHeader('场景 1：正常流程 — commit 后文件应等于 payload');
    const payload = '# 第一章 灵笔初现\n\n夜色中，一道光芒划破长空。';
    const targetPath = 'chapters/ch01.md';
    final fullPath = '$projectRoot/$targetPath';

    printStep('propose: payload = "${payload.substring(0, 20)}..."');
    final proposeResult = await protocol.propose(const ChangeRequest(
      projectId: 'proto-proj',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
      baseRevision: 0,
      payload: payload,
    ));
    final candidate = (proposeResult as Success<CandidateChange>).value;
    printStep('candidate.id = ${candidate.id}');

    printStep('approve: 用户批准');
    final approveResult = await protocol.decide(ApprovalCommand(
      candidateId: candidate.id,
      actorId: 'user-proto',
      approved: true,
      policy: 'explicit_user',
    ));
    final approval = (approveResult as Success<ApprovalDecision>).value;
    printStep('approval.id = ${approval.id}');

    printStep('commit: 提交到 canonical store');
    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval.id,
      idempotencyKey: 'proto-scenario-1',
    ));

    final isCommitSuccess = commitResult is Success<CommitReceipt>;
    printStep('commit 返回: ${isCommitSuccess ? "Success" : "Failure"}');

    final fileContent = readFileOrNull(fullPath);
    printStep('目标文件 $targetPath 内容: ${fileContent == null ? "⚠️ 文件不存在!" : '"$fileContent"'}');

    final pass = isCommitSuccess && fileContent == payload;
    printVerdict(pass, pass
        ? '文件内容 == payload，commit 真正写入了磁盘'
        : 'commit 声称成功但文件${fileContent == null ? "不存在" : "内容不匹配"}（P0-1 bug）');
    pass ? passCount++ : failCount++;
  }

  // ─── 场景 2：未批准就 commit → 文件不变 ───
  {
    printHeader('场景 2：未批准 commit — 文件不应被改变');
    const targetPath = 'chapters/ch02.md';
    final fullPath = '$projectRoot/$targetPath';

    printStep('propose: 提议创建 ch02');
    final proposeResult = await protocol.propose(const ChangeRequest(
      projectId: 'proto-proj',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
      baseRevision: 0,
      payload: '不该被写入的内容',
    ));
    final candidate = (proposeResult as Success<CandidateChange>).value;

    printStep('commit: 跳过 approve，直接 commit（用假 approvalId）');
    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: 'fake-approval-id',
      idempotencyKey: 'proto-scenario-2',
    ));

    final isFailure = commitResult is Failure;
    final fileContent = readFileOrNull(fullPath);
    printStep('commit 返回: ${isFailure ? "Failure (正确拒绝)" : "Success (不该!)"}');
    final fileDesc2 = fileContent == null ? '不存在 (正确)' : '存在! 内容=$fileContent (不该!)';
    printStep('目标文件: $fileDesc2');

    final pass = isFailure && fileContent == null;
    printVerdict(pass, pass ? '无批准 → 拒绝写入，fail-closed 正常' : '安全漏洞：无批准也能写文件!');
    pass ? passCount++ : failCount++;
  }

  // ─── 场景 3：applyUserEdit 便捷路径 → 文件写入 ───
  {
    printHeader('场景 3：applyUserEdit — 用户直接编辑应写入文件');
    const payload = '用户亲手写的段落。';
    const targetPath = 'notes/user_note.md';
    final fullPath = '$projectRoot/$targetPath';

    printStep('applyUserEdit: 一步完成 propose+approve+commit');
    final result = await protocol.applyUserEdit(const ChangeRequest(
      projectId: 'proto-proj',
      origin: ChangeOrigin.userUi,
      action: ChangeAction.createText,
      target: ChangeTarget(projectRelativePath: targetPath, kind: 'note'),
      baseRevision: 0,
      payload: payload,
    ));

    final isSuccess = result is Success<CommitReceipt>;
    final fileContent = readFileOrNull(fullPath);
    printStep('返回: ${isSuccess ? "Success" : "Failure"}');
    printStep('目标文件: ${fileContent == null ? "⚠️ 不存在!" : '"$fileContent"'}');

    final pass = isSuccess && fileContent == payload;
    printVerdict(pass, pass
        ? '用户编辑成功落盘'
        : 'applyUserEdit 也没有真正写文件（P0-1 bug 影响所有写入路径）');
    pass ? passCount++ : failCount++;
  }

  // ─── 场景 4：revision conflict → 文件不变 ───
  {
    printHeader('场景 4：Revision Conflict — 文件已被他人修改');
    const targetPath = 'chapters/ch04.md';
    final fullPath = '$projectRoot/$targetPath';

    // 先创建文件（模拟已有内容）
    File(fullPath).createSync(recursive: true);
    File(fullPath).writeAsStringSync('原始版本 v1');
    printStep('预置文件内容: "原始版本 v1"');

    // 使用 FileCanonicalStore 直接测试 revision conflict
    printStep('store.prepare: expectedHash 不匹配（模拟冲突）');
    final plan = CommitPlan(
      transactionId: 'txn-conflict-test',
      targets: [
        CommitTarget(
          relativePath: targetPath,
          newContent: '恶意覆盖内容',
          expectedHash: 'wrong-hash-that-does-not-match',
        ),
      ],
    );
    final prepareResult = await store.prepare(plan);
    final isConflict = prepareResult is Failure;
    printStep('prepare 返回: ${isConflict ? "Failure(REVISION_CONFLICT)" : "Success"}');

    final fileContent = readFileOrNull(fullPath);
    printStep('文件内容: "$fileContent"');

    final pass = isConflict && fileContent == '原始版本 v1';
    printVerdict(pass, pass ? '冲突检测正常，文件未被篡改' : 'revision conflict 保护失败!');
    pass ? passCount++ : failCount++;
  }

  // ─── 场景 5：commit 失败时不应有 receipt ───
  {
    printHeader('场景 5：apply 失败 → journal 中不应有 committed 记录');
    const targetPath = '../escape_attempt.md'; // 路径逃逸
    printStep('propose: 目标路径 = "$targetPath"（路径逃逸攻击）');

    final proposeResult = await protocol.propose(const ChangeRequest(
      projectId: 'proto-proj',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
      baseRevision: 0,
      payload: '恶意内容',
    ));
    final candidate = (proposeResult as Success<CandidateChange>).value;

    final approveResult = await protocol.decide(ApprovalCommand(
      candidateId: candidate.id,
      actorId: 'user-proto',
      approved: true,
      policy: 'explicit_user',
    ));
    final approval = (approveResult as Success<ApprovalDecision>).value;

    printStep('commit: 尝试提交路径逃逸的候选');
    final commitResult = await protocol.commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval.id,
      idempotencyKey: 'proto-scenario-5',
    ));

    // 检查 journal 中是否有 committed 记录
    final events = await journal.readByAggregate(candidate.id);
    final hasCommittedEvent =
        events.any((e) => e.eventType == 'candidate_committed');

    final isFailure = commitResult is Failure;
    printStep('commit 返回: ${isFailure ? "Failure (正确)" : "Success (不该!)"}');
    printStep('journal 有 committed 记录: ${hasCommittedEvent ? "是 (不该!)" : "否 (正确)"}');

    // 当前代码：commit 不经过 store，所以路径检查不会触发 → 会返回 Success
    // 修复后：store.prepare 会拒绝路径逃逸 → Failure + 无 receipt
    final pass = isFailure && !hasCommittedEvent;
    printVerdict(pass, pass
        ? '路径逃逸被拦截，无虚假 receipt'
        : '路径逃逸未被拦截或产生了虚假 receipt（P0-1 bug：commit 绕过了 store 安全检查）');
    pass ? passCount++ : failCount++;
  }

  // ─── 总结 ───
  printHeader('验证结果汇总');
  print('  通过: $passCount / ${passCount + failCount}');
  print('  失败: $failCount / ${passCount + failCount}');
  if (failCount > 0) {
    print('\n  ⚠️  存在失败场景 — 证实 P0-1 bug：commit() 没有真正写入 canonical 文件');
    print('  修复目标：让全部 5 个场景 PASS');
  } else {
    print('\n  🎉 全部通过 — commit() 已正确写入 canonical 文件');
  }

  // 清理
  tempDir.deleteSync(recursive: true);
  print('\n  临时目录已清理。原型结束。');
}
