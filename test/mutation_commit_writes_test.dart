/// P0-1 Regression: commit() must actually write to canonical files.
///
/// These tests verify that LocalMutationProtocol.commit() calls
/// FileCanonicalStore.prepare() and apply(), producing real file changes.
/// Before the fix, commit() only created a receipt without writing.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

void main() {
  late Directory tempDir;
  late LocalMutationProtocol protocol;
  late LocalMutationJournal journal;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('p0_commit_writes_');
    journal = LocalMutationJournal(
      basePath: '${tempDir.path}/.lingbi/mutations',
    );
    final store = FileCanonicalStore(
      projectRoot: tempDir.path,
      atomicStore: AtomicFileStore(),
    );
    protocol = LocalMutationProtocol(journal: journal, store: store);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('P0-1: commit writes real files', () {
    test('propose → approve → commit: target file content equals payload',
        () async {
      const payload = '# 第一章\n\n灵笔初现，夜色中的光芒。';
      const targetPath = 'chapters/ch01.md';

      // Propose
      final proposeResult = await protocol.propose(const ChangeRequest(
        projectId: 'proj-p0',
        origin: ChangeOrigin.agent,
        action: ChangeAction.createText,
        target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
        baseRevision: 0,
        payload: payload,
      ));
      final candidate = (proposeResult as Success<CandidateChange>).value;

      // Approve
      final approveResult = await protocol.decide(ApprovalCommand(
        candidateId: candidate.id,
        actorId: 'user-test',
        approved: true,
        policy: 'explicit_user',
      ));
      final approval = (approveResult as Success<ApprovalDecision>).value;

      // Commit
      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'p0-test-1',
      ));
      expect(commitResult, isA<Success<CommitReceipt>>());

      // THE KEY ASSERTION: file must actually exist with correct content
      final file = File('${tempDir.path}/$targetPath');
      expect(file.existsSync(), isTrue,
          reason: 'commit must create the target file on disk');
      expect(file.readAsStringSync(), payload,
          reason: 'file content must equal the proposed payload');
    });

    test('applyUserEdit: target file content equals payload', () async {
      const payload = '用户直接编辑的内容。';
      const targetPath = 'notes/edit.md';

      final result = await protocol.applyUserEdit(const ChangeRequest(
        projectId: 'proj-p0',
        origin: ChangeOrigin.userUi,
        action: ChangeAction.createText,
        target: ChangeTarget(projectRelativePath: targetPath, kind: 'note'),
        baseRevision: 0,
        payload: payload,
      ));
      expect(result, isA<Success<CommitReceipt>>());

      final file = File('${tempDir.path}/$targetPath');
      expect(file.existsSync(), isTrue,
          reason: 'applyUserEdit must write the file');
      expect(file.readAsStringSync(), payload);
    });

    test('replaceText overwrites existing file with payload', () async {
      const targetPath = 'chapters/ch02.md';
      final file = File('${tempDir.path}/$targetPath');
      file.createSync(recursive: true);
      file.writeAsStringSync('旧版本内容');

      const newPayload = '新版本内容 — 经过 AI 改写。';
      final result = await protocol.applyUserEdit(const ChangeRequest(
        projectId: 'proj-p0',
        origin: ChangeOrigin.userUi,
        action: ChangeAction.replaceText,
        target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
        baseRevision: 1,
        payload: newPayload,
      ));
      expect(result, isA<Success<CommitReceipt>>());
      expect(file.readAsStringSync(), newPayload,
          reason: 'replaceText must overwrite with new payload');
    });
  });

  group('P0-1: commit failure produces no receipt', () {
    test('path escape in target: commit fails, no committed event in journal',
        () async {
      const evilPath = '../escape.md';

      final proposeResult = await protocol.propose(const ChangeRequest(
        projectId: 'proj-p0',
        origin: ChangeOrigin.agent,
        action: ChangeAction.createText,
        target: ChangeTarget(projectRelativePath: evilPath, kind: 'chapter'),
        baseRevision: 0,
        payload: '恶意内容',
      ));
      final candidate = (proposeResult as Success<CandidateChange>).value;

      final approveResult = await protocol.decide(ApprovalCommand(
        candidateId: candidate.id,
        actorId: 'user-test',
        approved: true,
        policy: 'explicit_user',
      ));
      final approval = (approveResult as Success<ApprovalDecision>).value;

      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'p0-escape',
      ));

      // Must fail
      expect(commitResult, isA<Failure>(),
          reason: 'path escape must be rejected by store.prepare()');

      // No committed event in journal
      final events = await journal.readByAggregate(candidate.id);
      final hasCommitted =
          events.any((e) => e.eventType == 'candidate_committed');
      expect(hasCommitted, isFalse,
          reason: 'failed commit must not produce a journal receipt');
    });

    test('unapproved commit does not change target file', () async {
      const targetPath = 'chapters/ch03.md';
      const payload = '不该被写入';

      final proposeResult = await protocol.propose(const ChangeRequest(
        projectId: 'proj-p0',
        origin: ChangeOrigin.agent,
        action: ChangeAction.createText,
        target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
        baseRevision: 0,
        payload: payload,
      ));
      final candidate = (proposeResult as Success<CandidateChange>).value;

      // Commit without approval
      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: 'nonexistent',
        idempotencyKey: 'p0-no-approval',
      ));
      expect(commitResult, isA<Failure>());

      // File must not exist
      final file = File('${tempDir.path}/$targetPath');
      expect(file.existsSync(), isFalse,
          reason: 'unapproved commit must not create the file');
    });
  });

  group('P0-1: revision conflict protection', () {
    test('conflicting expectedHash prevents file change', () async {
      const targetPath = 'chapters/ch04.md';
      final file = File('${tempDir.path}/$targetPath');
      file.createSync(recursive: true);
      file.writeAsStringSync('原始版本');

      // Propose with a baseRevision that implies a specific file state.
      // The store.prepare() with expectedHash will detect the conflict
      // if we pass the wrong hash. Here we test via the store directly
      // since the protocol should delegate to it.
      final store = FileCanonicalStore(
        projectRoot: tempDir.path,
        atomicStore: AtomicFileStore(),
      );

      final plan = CommitPlan(
        transactionId: 'txn-conflict',
        targets: [
          CommitTarget(
            relativePath: targetPath,
            newContent: '覆盖内容',
            expectedHash: 'wrong-hash-does-not-match',
          ),
        ],
      );

      final prepareResult = await store.prepare(plan);
      expect(prepareResult, isA<Failure>());

      // File unchanged
      expect(file.readAsStringSync(), '原始版本');
    });
  });
}
