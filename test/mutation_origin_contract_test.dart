/// Contract test: every mutation origin must produce exactly one receipt
/// on success and zero target changes without approval.
///
/// This test validates the origin rules from ADR-010 against the
/// LocalMutationProtocol implementation.
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
  test('includes recovery, external, and legacy migration origins', () {
    expect(ChangeOrigin.values, contains(ChangeOrigin.recovery));
    expect(ChangeOrigin.values, contains(ChangeOrigin.externalMutation));
    expect(ChangeOrigin.values, contains(ChangeOrigin.legacyMigration));
  });

  late Directory tempDir;
  late LocalMutationProtocol protocol;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('origin_contract_');
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

  ChangeRequest requestForOrigin(ChangeOrigin origin) {
    return ChangeRequest(
      projectId: 'proj-contract',
      origin: origin,
      action: ChangeAction.createText,
      target: ChangeTarget(
        projectRelativePath: 'chapters/contract_${origin.name}.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: 'Content from ${origin.name}',
    );
  }

  group('Origin contract: every origin produces receipt on approved success',
      () {
    for (final origin in ChangeOrigin.values) {
      test('${origin.name} origin: propose → approve → commit = 1 receipt',
          () async {
        final request = requestForOrigin(origin);

        // Propose
        final proposeResult = await protocol.propose(request);
        expect(proposeResult, isA<Success<CandidateChange>>());
        final candidate = (proposeResult as Success).value;
        expect(candidate.origin, origin);

        // Approve (policy varies by origin)
        final policy = origin == ChangeOrigin.userUi
            ? 'user_direct_edit'
            : 'explicit_user';
        final approveResult = await protocol.decide(ApprovalCommand(
          candidateId: candidate.id,
          actorId: 'contract-tester',
          approved: true,
          policy: policy,
        ));
        expect(approveResult, isA<Success<ApprovalDecision>>());
        final approval = (approveResult as Success).value;

        // Commit
        final commitResult = await protocol.commit(CommitCommand(
          candidateId: candidate.id,
          approvalId: approval.id,
          idempotencyKey: 'contract-${origin.name}',
        ));
        expect(commitResult, isA<Success<CommitReceipt>>());
        final receipt = (commitResult as Success).value;

        // Exactly one receipt
        expect(receipt.candidateId, candidate.id);
        expect(receipt.approvalId, approval.id);
        expect(receipt.receiptHash, hasLength(64));
      });
    }
  });

  group('Origin contract: zero target changes without approval', () {
    for (final origin in ChangeOrigin.values) {
      test('${origin.name} origin: commit without approval fails', () async {
        final request = requestForOrigin(origin);

        // Propose only
        final proposeResult = await protocol.propose(request);
        final candidate = (proposeResult as Success).value;

        // Attempt commit without approval
        final commitResult = await protocol.commit(CommitCommand(
          candidateId: candidate.id,
          approvalId: 'no-such-approval',
          idempotencyKey: 'no-approval-${origin.name}',
        ));

        // Must fail
        expect(commitResult, isA<Failure>());
      });
    }
  });

  group('Source guard: no forbidden direct writes', () {
    test('autoApprove: true must not exist in production code', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('autoApprove: true'),
          isFalse,
          reason: '${file.path} contains forbidden autoApprove: true',
        );
      }
    });

    test('confirmWrite == null must not authorize writes', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // The old pattern: confirmWrite == null || confirmWrite!(...)
        // This treated missing callback as approval
        final hasNullAsApproval = content.contains('confirmWrite == null ||');
        expect(
          hasNullAsApproval,
          isFalse,
          reason:
              '${file.path} treats null confirmWrite as approval (fail-open)',
        );
      }
    });
  });
}
