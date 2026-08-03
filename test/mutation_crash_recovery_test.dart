/// MP-06: crash-window recovery for the transactional mutation protocol.
///
/// Covers: crash before apply, crash after apply before receipt, base
/// revision conflict, duplicate idempotency replay, hash equality, and
/// indeterminate-target freeze. Uses the projectBound protocol so intents
/// travel in the project-owned journal.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

void main() {
  late Directory tempDir;
  late String projectRoot;
  late _SingleRootResolver resolver;
  late LocalMutationProtocol protocol;
  late LocalMutationJournal journal;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('crash_recovery_test_');
    projectRoot = '${tempDir.path}/project';
    Directory(projectRoot).createSync(recursive: true);
    resolver = _SingleRootResolver('proj-1', projectRoot);
    final journalFactory = ProjectMutationJournalFactory(resolver: resolver);
    protocol = LocalMutationProtocol.projectBound(
      resolver: resolver,
      journalFactory: journalFactory,
      storeForRoot: (root) => FileCanonicalStore.projectOwned(
        root,
        atomicStore: AtomicFileStore(),
      ),
    );
    journal = LocalMutationJournal.projectOwned(
      ResolvedProjectRoot(projectId: 'proj-1', rootPath: projectRoot),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<(CandidateChange, ApprovalDecision)> proposeAndApprove({
    required String payload,
    required String targetPath,
    ChangeAction action = ChangeAction.createText,
    int baseRevision = 0,
  }) async {
    final proposeResult = await protocol.propose(ChangeRequest(
      projectId: 'proj-1',
      origin: ChangeOrigin.agent,
      action: action,
      target: ChangeTarget(projectRelativePath: targetPath, kind: 'chapter'),
      baseRevision: baseRevision,
      payload: payload,
    ));
    final candidate = proposeResult.getOrNull();
    expect(candidate, isNotNull);
    final approveResult = await protocol.decide(ApprovalCommand(
      candidateId: candidate!.id,
      actorId: 'user-test',
      approved: true,
      policy: 'explicit_user',
      projectId: 'proj-1',
    ));
    final approval = approveResult.getOrNull();
    expect(approval, isNotNull);
    return (candidate, approval!);
  }

  CommitIntent makeIntent({
    required String candidateId,
    required String targetPath,
    required String expectedContentHash,
    String baseContentHash = '',
    String idempotencyKey = 'idem-crash',
  }) =>
      CommitIntent(
        id: 'intent-$idempotencyKey',
        projectId: 'proj-1',
        candidateId: candidateId,
        targetPath: targetPath,
        baseRevision: 0,
        expectedRevision: 1,
        expectedContentHash: expectedContentHash,
        idempotencyKey: idempotencyKey,
        baseContentHash: baseContentHash,
      );

  group('commit intent and receipt ordering', () {
    test('commit persists intent before the receipt and before any write',
        () async {
      const payload = '# 第一章\n\n灵笔初现。';
      final (candidate, approval) = await proposeAndApprove(
        payload: payload,
        targetPath: 'chapters/ch01.md',
      );

      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-order',
        projectId: 'proj-1',
      ));
      expect(commitResult, isA<Success<CommitReceipt>>());

      final events = await journal.readByAggregate(candidate.id);
      final types = events.map((e) => e.eventType).toList();
      expect(types, contains('commit_intent'));
      expect(types.indexOf('commit_intent'),
          lessThan(types.indexOf('candidate_committed')));
    });

    test('payload, candidate and receipt hashes are consistent', () async {
      const payload = '同一份规范化正文内容。';
      final (candidate, approval) = await proposeAndApprove(
        payload: payload,
        targetPath: 'chapters/hash.md',
      );

      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-hash',
        projectId: 'proj-1',
      ));
      final receipt = (commitResult as Success<CommitReceipt>).value;

      expect(candidate.payloadHash, canonicalTextHash(payload));
      final file = File('$projectRoot/chapters/hash.md');
      expect(file.existsSync(), isTrue);
      expect(await file.readAsString(), payload);
      expect(
        canonicalTextHash(await file.readAsString()),
        candidate.payloadHash,
      );
      expect(receipt.receiptHash, hasLength(64));
      expect(receipt.afterRevision, 1);
    });
  });

  group('idempotent replay', () {
    test('duplicate idempotency key returns the same receipt without rewrite',
        () async {
      const payload = '只写一次。';
      final (candidate, approval) = await proposeAndApprove(
        payload: payload,
        targetPath: 'chapters/idem.md',
      );

      final first = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-duplicate',
        projectId: 'proj-1',
      ));
      final firstReceipt = (first as Success<CommitReceipt>).value;

      final second = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-duplicate',
        projectId: 'proj-1',
      ));
      final secondReceipt = (second as Success<CommitReceipt>).value;

      expect(secondReceipt.id, firstReceipt.id);
      expect(await File('$projectRoot/chapters/idem.md').readAsString(),
          payload);

      final committed = await journal.readAll();
      final receipts = committed
          .where((e) => e.eventType == 'candidate_committed')
          .toList();
      expect(receipts, hasLength(1));
    });
  });

  group('base revision conflict', () {
    test('external edit between propose and commit fails with REVISION_CONFLICT',
        () async {
      final targetPath = 'chapters/conflict.md';
      final file = File('$projectRoot/$targetPath')
        ..createSync(recursive: true)
        ..writeAsStringSync('V1');
      final (candidate, approval) = await proposeAndApprove(
        payload: 'V2',
        targetPath: targetPath,
        action: ChangeAction.replaceText,
        baseRevision: 0,
      );

      // External change after proposal.
      file.writeAsStringSync('V1.5');

      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-conflict',
        projectId: 'proj-1',
      ));
      expect(commitResult, isA<Failure>());
      final error = (commitResult as Failure).error;
      expect(error.typedCode, MutationErrorCode.revisionConflict);
      expect(await file.readAsString(), 'V1.5');

      final events = await journal.readAll();
      expect(
        events.where((e) => e.eventType == 'candidate_committed'),
        isEmpty,
      );
      expect(
        events.where((e) => e.eventType == 'commit_intent'),
        isEmpty,
        reason: 'conflict is detected before any intent is persisted',
      );
    });

    test('commit succeeds when the file is unchanged since propose', () async {
      final targetPath = 'chapters/ok.md';
      File('$projectRoot/$targetPath')
        ..createSync(recursive: true)
        ..writeAsStringSync('V1');
      final (candidate, approval) = await proposeAndApprove(
        payload: 'V2',
        targetPath: targetPath,
        action: ChangeAction.replaceText,
        baseRevision: 0,
      );

      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-ok',
        projectId: 'proj-1',
      ));
      expect(commitResult, isA<Success<CommitReceipt>>());
      expect(await File('$projectRoot/$targetPath').readAsString(), 'V2');
    });
  });

  group('crash-window recovery', () {
    test('crash before apply: untouched target abandons the intent', () async {
      final (candidate, _) = await proposeAndApprove(
        payload: '期望内容',
        targetPath: 'chapters/before.md',
      );
      final intent = makeIntent(
        candidateId: candidate.id,
        targetPath: 'chapters/before.md',
        expectedContentHash: canonicalTextHash('期望内容'),
        idempotencyKey: 'idem-before',
      );
      await journal.appendCommitIntent(intent);

      final outcomes = await protocol.reconcilePending('proj-1');
      expect(outcomes, isA<Success<List<RecoveryOutcome>>>());
      final list = (outcomes as Success<List<RecoveryOutcome>>).value;
      expect(list.single.outcome, RecoveryOutcomeType.intentAbandoned);

      expect(File('$projectRoot/chapters/before.md').existsSync(), isFalse);
      final events = await journal.readAll();
      final allEvents = await journal.readAll();
      expect(
        allEvents.where((e) => e.eventType == 'recovery_outcome'),
        hasLength(1),
      );
    });

    test('crash after apply before receipt: matching target completes receipt',
        () async {
      const payload = '已落盘但未写回执。';
      final (candidate, approval) = await proposeAndApprove(
        payload: payload,
        targetPath: 'chapters/after.md',
      );
      final intent = makeIntent(
        candidateId: candidate.id,
        targetPath: 'chapters/after.md',
        expectedContentHash: canonicalTextHash(payload),
        idempotencyKey: 'idem-after',
      );
      await journal.appendCommitIntent(intent);
      // The atomic apply already happened before the crash.
      File('$projectRoot/chapters/after.md')
        ..createSync(recursive: true)
        ..writeAsStringSync(payload);

      final outcomes = await protocol.reconcilePending('proj-1');
      final list =
          (outcomes as Success<List<RecoveryOutcome>>).value;
      expect(list.single.outcome, RecoveryOutcomeType.receiptCompleted);

      expect(await File('$projectRoot/chapters/after.md').readAsString(),
          payload);
      final events = await journal.readByAggregate(candidate.id);
      expect(
        events.where((e) => e.eventType == 'candidate_committed'),
        hasLength(1),
      );
      final allEvents = await journal.readAll();
      expect(
        allEvents.where((e) => e.eventType == 'recovery_outcome'),
        hasLength(1),
      );
    });

    test('indeterminate target freezes and preserves the current bytes',
        () async {
      const payload = '期望内容';
      final (candidate, _) = await proposeAndApprove(
        payload: payload,
        targetPath: 'chapters/frozen.md',
      );
      final intent = makeIntent(
        candidateId: candidate.id,
        targetPath: 'chapters/frozen.md',
        expectedContentHash: canonicalTextHash(payload),
        baseContentHash: canonicalTextHash('基线内容'),
        idempotencyKey: 'idem-frozen',
      );
      await journal.appendCommitIntent(intent);
      // Neither base nor expected content: indeterminate.
      File('$projectRoot/chapters/frozen.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('第三种内容');

      final outcomes = await protocol.reconcilePending('proj-1');
      final list =
          (outcomes as Success<List<RecoveryOutcome>>).value;
      expect(list.single.outcome, RecoveryOutcomeType.targetFrozen);

      expect(await File('$projectRoot/chapters/frozen.md').readAsString(),
          '第三种内容');
      final events = await journal.readAll();
      expect(
        events.where((e) => e.eventType == 'candidate_committed'),
        isEmpty,
      );
      expect(
        events.where((e) => e.eventType == 'recovery_outcome'),
        hasLength(1),
      );
    });
  });
}

class _SingleRootResolver implements ProjectRootResolver {
  _SingleRootResolver(this.projectId, this.rootPath);

  final String projectId;
  final String rootPath;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String id) async {
    if (id != projectId) {
      return Result.failure(FileError(
        'no root for $id',
        typedCode: MutationErrorCode.projectRootAmbiguity,
      ));
    }
    return Result.success(
      ResolvedProjectRoot(projectId: id, rootPath: rootPath),
    );
  }
}
