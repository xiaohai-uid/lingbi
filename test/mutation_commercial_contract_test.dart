import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

void main() {
  group('commercial mutation origins', () {
    test('uses stable snake_case wire names for every origin', () {
      expect(ChangeOrigin.userUi.wireName, 'user_ui');
      expect(ChangeOrigin.agent.wireName, 'agent');
      expect(ChangeOrigin.batchImport.wireName, 'batch_import');
      expect(ChangeOrigin.skill.wireName, 'skill');
      expect(ChangeOrigin.restore.wireName, 'restore');
      expect(ChangeOrigin.recovery.wireName, 'recovery');
      expect(ChangeOrigin.externalMutation.wireName, 'external_mutation');
      expect(ChangeOrigin.legacyMigration.wireName, 'legacy_migration');

      for (final origin in ChangeOrigin.values) {
        expect(ChangeOrigin.fromWire(origin.wireName), origin);
      }
    });

    test('rejects unknown origin wire names', () {
      expect(
        () => ChangeOrigin.fromWire('future_origin'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('CommitIntent contract', () {
    const intent = CommitIntent(
      id: 'intent-001',
      projectId: 'project-001',
      candidateId: 'candidate-001',
      targetPath: 'chapters/ch01.md',
      baseRevision: 4,
      expectedRevision: 5,
      expectedContentHash:
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      idempotencyKey: 'idem-001',
    );

    test('serializes immutable fields with snake_case keys', () {
      expect(intent.toJson(), {
        'schema_version': 1,
        'id': 'intent-001',
        'project_id': 'project-001',
        'candidate_id': 'candidate-001',
        'target_path': 'chapters/ch01.md',
        'base_revision': 4,
        'expected_revision': 5,
        'expected_content_hash':
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        'idempotency_key': 'idem-001',
        'base_content_hash': '',
      });
    });

    test('round-trips without changing its JSON representation', () {
      final restored = CommitIntent.fromJson(intent.toJson());
      expect(restored.toJson(), intent.toJson());
      expect(restored, intent);
    });

    test('rejects unsupported schema versions', () {
      final json = intent.toJson()..['schema_version'] = 2;
      expect(
        () => CommitIntent.fromJson(json),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });
  });

  group('RecoveryOutcome contract', () {
    final outcome = RecoveryOutcome(
      id: 'outcome-001',
      intentId: 'intent-001',
      projectId: 'project-001',
      targetPath: 'chapters/ch01.md',
      outcome: RecoveryOutcomeType.targetFrozen,
      resolvedAt: DateTime.utc(2026, 8, 3, 12),
      reason: 'target bytes are indeterminate',
    );

    test('round-trips an explicit fail-closed recovery outcome', () {
      final restored = RecoveryOutcome.fromJson(outcome.toJson());
      expect(restored.toJson(), outcome.toJson());
      expect(restored.outcome, RecoveryOutcomeType.targetFrozen);
    });

    test('rejects unsupported schema versions', () {
      final json = outcome.toJson()..['schema_version'] = 99;
      expect(
        () => RecoveryOutcome.fromJson(json),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });
  });

  group('typed mutation error codes', () {
    test('preserve the typed code through Result failure', () {
      final result = Result.failure<void>(
        FileError(
          'target escapes the project root',
          typedCode: MutationErrorCode.pathEscape,
        ),
      );

      expect(result, isA<Failure<void>>());
      final error = (result as Failure<void>).error;
      expect(error.code, MutationErrorCode.pathEscape.wireName);
      expect(error.typedCode, MutationErrorCode.pathEscape);
      expect(
        MutationErrorCode.fromWire(error.code!),
        MutationErrorCode.pathEscape,
      );
    });

    test('defines all fail-closed commercial mutation categories', () {
      expect(
        MutationErrorCode.values.map((code) => code.wireName),
        containsAll(<String>[
          'PROJECT_ROOT_AMBIGUITY',
          'PATH_ESCAPE',
          'REVISION_CONFLICT',
          'UNRESOLVED_RECOVERY',
          'MIGRATION_REQUIRED',
          'PROTOCOL_UNAVAILABLE',
          'STORAGE_FAILURE',
        ]),
      );
    });
  });

  test('every MutationProtocol operation is a typed Result boundary', () {
    final protocol = _ResultBoundaryProbe();
    final request = ChangeRequest(
      projectId: 'project-001',
      origin: ChangeOrigin.userUi,
      action: ChangeAction.createText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: 0,
      payload: 'content',
    );

    final Future<Result<CandidateChange>> proposed = protocol.propose(request);
    final Future<Result<ApprovalDecision>> decided = protocol.decide(
      const ApprovalCommand(
        candidateId: 'candidate-001',
        actorId: 'user-001',
        approved: true,
        policy: 'user_direct_edit',
      ),
    );
    final Future<Result<CommitReceipt>> committed = protocol.commit(
      const CommitCommand(
        candidateId: 'candidate-001',
        approvalId: 'approval-001',
        idempotencyKey: 'idem-001',
      ),
    );
    final Future<Result<CommitReceipt>> applied =
        protocol.applyUserEdit(request);
    final Future<Result<void>> rejected = protocol.reject(
      const RejectCommand(
        candidateId: 'candidate-001',
        actorId: 'user-001',
      ),
    );

    expect(proposed, isA<Future<Result<CandidateChange>>>());
    expect(decided, isA<Future<Result<ApprovalDecision>>>());
    expect(committed, isA<Future<Result<CommitReceipt>>>());
    expect(applied, isA<Future<Result<CommitReceipt>>>());
    expect(rejected, isA<Future<Result<void>>>());
  });
}

final class _ResultBoundaryProbe implements MutationProtocol {
  @override
  Future<Result<CandidateChange>> propose(ChangeRequest request) async =>
      Result.failure<CandidateChange>(FileError('probe'));

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async =>
      Result.failure<ApprovalDecision>(FileError('probe'));

  @override
  Future<Result<CommitReceipt>> commit(CommitCommand command) async =>
      Result.failure<CommitReceipt>(FileError('probe'));

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async =>
      Result.failure<CommitReceipt>(FileError('probe'));

  @override
  Future<Result<void>> reject(RejectCommand command) async =>
      Result.failure<void>(FileError('probe'));

  @override
  Future<Result<List<RecoveryOutcome>>> reconcilePending(String projectId) async =>
      Result.failure<List<RecoveryOutcome>>(FileError('probe'));
}
