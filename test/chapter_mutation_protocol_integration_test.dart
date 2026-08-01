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

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mutation_proto_test_');
    final journal = LocalMutationJournal(
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

  ChangeRequest makeRequest({
    ChangeOrigin origin = ChangeOrigin.agent,
    String path = 'chapters/ch01.md',
  }) {
    return ChangeRequest(
      projectId: 'proj-001',
      origin: origin,
      action: ChangeAction.createText,
      target: ChangeTarget(projectRelativePath: path, kind: 'chapter'),
      baseRevision: 0,
      payload: 'Generated chapter content',
    );
  }

  group('Agent without approval cannot commit', () {
    test('commit without approval returns APPROVAL_REQUIRED', () async {
      // Propose a candidate (as Agent would)
      final proposeResult = await protocol.propose(makeRequest());
      expect(proposeResult, isA<Success<CandidateChange>>());
      final candidate = (proposeResult as Success).value;

      // Try to commit without approval
      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: 'nonexistent-approval',
        idempotencyKey: 'idem-001',
      ));

      expect(commitResult, isA<Failure>());
      final error = (commitResult as Failure).error;
      expect(error.message, contains('APPROVAL_REQUIRED'));
    });

    test('agent origin candidate stays proposed without decide', () async {
      final proposeResult = await protocol.propose(
          makeRequest(origin: ChangeOrigin.agent));
      final candidate = (proposeResult as Success<CandidateChange>).value;
      expect(candidate.state, CandidateState.proposed);
      expect(candidate.origin, ChangeOrigin.agent);
    });
  });

  group('Approval binding enforcement', () {
    test('approval for candidate A cannot commit candidate B', () async {
      // Create two candidates
      final resultA = await protocol.propose(makeRequest(path: 'a.md'));
      final candidateA = (resultA as Success).value;

      final resultB = await protocol.propose(makeRequest(path: 'b.md'));
      final candidateB = (resultB as Success).value;

      // Approve candidate A
      final approvalResult = await protocol.decide(ApprovalCommand(
        candidateId: candidateA.id,
        actorId: 'user-001',
        approved: true,
        policy: 'explicit_user',
      ));
      expect(approvalResult, isA<Success<ApprovalDecision>>());
      final approval = (approvalResult as Success).value;

      // Try to commit candidate B with A's approval
      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidateB.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-cross',
      ));

      // Must fail - approval doesn't match candidate B
      expect(commitResult, isA<Failure>());
    });
  });

  group('Happy path: propose → approve → commit', () {
    test('produces candidate, approval, and receipt that agree', () async {
      // Propose
      final proposeResult = await protocol.propose(makeRequest());
      expect(proposeResult, isA<Success<CandidateChange>>());
      final candidate = (proposeResult as Success).value;
      expect(candidate.state, CandidateState.proposed);

      // Approve
      final approveResult = await protocol.decide(ApprovalCommand(
        candidateId: candidate.id,
        actorId: 'user-001',
        approved: true,
        policy: 'explicit_user',
      ));
      expect(approveResult, isA<Success<ApprovalDecision>>());
      final approval = (approveResult as Success).value;
      expect(approval.approved, isTrue);
      expect(approval.candidateId, candidate.id);

      // Commit
      final commitResult = await protocol.commit(CommitCommand(
        candidateId: candidate.id,
        approvalId: approval.id,
        idempotencyKey: 'idem-happy',
      ));
      expect(commitResult, isA<Success<CommitReceipt>>());
      final receipt = (commitResult as Success).value;
      expect(receipt.candidateId, candidate.id);
      expect(receipt.approvalId, approval.id);
      expect(receipt.afterRevision, candidate.baseRevision + 1);
      expect(receipt.affectedPaths,
          contains(candidate.target.projectRelativePath));
      expect(receipt.receiptHash, hasLength(64));
    });
  });

  group('applyUserEdit convenience', () {
    test('creates all three records in one call', () async {
      final result = await protocol.applyUserEdit(
        makeRequest(origin: ChangeOrigin.userUi),
      );
      expect(result, isA<Success<CommitReceipt>>());
      final receipt = (result as Success).value;
      expect(receipt.afterRevision, 1);
    });
  });

  group('reject', () {
    test('reject transitions candidate to rejected', () async {
      final proposeResult = await protocol.propose(makeRequest());
      final candidate = (proposeResult as Success).value;

      final rejectResult = await protocol.reject(RejectCommand(
        candidateId: candidate.id,
        actorId: 'user-001',
        reason: 'Not good enough',
      ));
      expect(rejectResult, isA<Success<void>>());
    });
  });

  group('Idempotency', () {
    test('duplicate idempotency key returns existing receipt', () async {
      // First full cycle
      final r1 = await protocol.applyUserEdit(ChangeRequest(
        projectId: 'proj-001',
        origin: ChangeOrigin.userUi,
        action: ChangeAction.createText,
        target: const ChangeTarget(
            projectRelativePath: 'ch.md', kind: 'chapter'),
        baseRevision: 0,
        payload: 'content',
        idempotencyKey: 'unique-key-1',
      ));
      expect(r1, isA<Success<CommitReceipt>>());
    });
  });
}
