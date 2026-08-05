import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/domain/mutation/mutation_transitions.dart';

void main() {
  // Helper to create a valid CandidateChange for testing.
  CandidateChange makeCandidate({
    CandidateState state = CandidateState.proposed,
    String payloadHash = 'aaaa',
    String actionHash = 'bbbb',
    int baseRevision = 1,
  }) {
    return CandidateChange(
      id: 'cand-001',
      projectId: 'proj-001',
      origin: ChangeOrigin.agent,
      action: ChangeAction.createText,
      target: const ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      ),
      baseRevision: baseRevision,
      payloadHash: payloadHash,
      actionHash: actionHash,
      createdAt: DateTime.utc(2026, 8, 1),
      state: state,
    );
  }

  group('CandidateChange immutability and serialization', () {
    test('all fields are final and accessible', () {
      final candidate = makeCandidate();
      expect(candidate.id, 'cand-001');
      expect(candidate.projectId, 'proj-001');
      expect(candidate.origin, ChangeOrigin.agent);
      expect(candidate.action, ChangeAction.createText);
      expect(candidate.target.projectRelativePath, 'chapters/ch01.md');
      expect(candidate.target.kind, 'chapter');
      expect(candidate.baseRevision, 1);
      expect(candidate.payloadHash, 'aaaa');
      expect(candidate.actionHash, 'bbbb');
      expect(candidate.state, CandidateState.proposed);
      expect(candidate.runId, isNull);
    });

    test('toJson uses snake_case keys and schema_version 1', () {
      final candidate = makeCandidate();
      final json = candidate.toJson();
      expect(json['schema_version'], 1);
      expect(json['id'], 'cand-001');
      expect(json['project_id'], 'proj-001');
      expect(json['origin'], 'agent');
      expect(json['action'], 'create_text');
      expect(json['target'], isA<Map<String, dynamic>>());
      expect(json['base_revision'], 1);
      expect(json['payload_hash'], 'aaaa');
      expect(json['action_hash'], 'bbbb');
      expect(json['state'], 'proposed');
      // Ensure no camelCase keys leak
      expect(json.containsKey('projectId'), isFalse);
      expect(json.containsKey('baseRevision'), isFalse);
      expect(json.containsKey('payloadHash'), isFalse);
    });

    test('fromJson round-trips correctly', () {
      final original = makeCandidate();
      final json = original.toJson();
      final restored = CandidateChange.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.projectId, original.projectId);
      expect(restored.origin, original.origin);
      expect(restored.action, original.action);
      expect(restored.target.projectRelativePath,
          original.target.projectRelativePath);
      expect(restored.baseRevision, original.baseRevision);
      expect(restored.payloadHash, original.payloadHash);
      expect(restored.actionHash, original.actionHash);
      expect(restored.state, original.state);
    });

    test('fromJson rejects unknown future schema_version', () {
      final json = makeCandidate().toJson();
      json['schema_version'] = 99;
      expect(
        () => CandidateChange.fromJson(json),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });

    test('fromJson rejects missing schema_version', () {
      final json = makeCandidate().toJson();
      json.remove('schema_version');
      expect(
        () => CandidateChange.fromJson(json),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });
  });

  group('ApprovalDecision serialization', () {
    test('toJson uses snake_case and schema_version 1', () {
      final decision = ApprovalDecision(
        id: 'appr-001',
        candidateId: 'cand-001',
        candidateHash: 'hash-c',
        actionHash: 'hash-a',
        baseRevision: 1,
        actorId: 'user-001',
        approved: true,
        decidedAt: DateTime.utc(2026, 8, 1, 12),
        policy: 'explicit_user',
      );
      final json = decision.toJson();
      expect(json['schema_version'], 1);
      expect(json['candidate_id'], 'cand-001');
      expect(json['candidate_hash'], 'hash-c');
      expect(json['action_hash'], 'hash-a');
      expect(json['base_revision'], 1);
      expect(json['actor_id'], 'user-001');
      expect(json['approved'], true);
      expect(json['policy'], 'explicit_user');
      expect(json.containsKey('candidateId'), isFalse);
    });

    test('fromJson rejects future schema_version', () {
      final decision = ApprovalDecision(
        id: 'appr-001',
        candidateId: 'cand-001',
        candidateHash: 'hash-c',
        actionHash: 'hash-a',
        baseRevision: 1,
        actorId: 'user-001',
        approved: true,
        decidedAt: DateTime.utc(2026, 8, 1),
        policy: 'explicit_user',
      );
      final json = decision.toJson();
      json['schema_version'] = 42;
      expect(
        () => ApprovalDecision.fromJson(json),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });
  });

  group('CommitReceipt serialization', () {
    test('toJson uses snake_case and schema_version 1', () {
      final receipt = CommitReceipt(
        id: 'rcpt-001',
        candidateId: 'cand-001',
        approvalId: 'appr-001',
        idempotencyKey: 'idem-001',
        beforeRevision: 1,
        afterRevision: 2,
        affectedPaths: ['chapters/ch01.md'],
        committedAt: DateTime.utc(2026, 8, 1, 13),
        receiptHash: 'hash-r',
      );
      final json = receipt.toJson();
      expect(json['schema_version'], 1);
      expect(json['candidate_id'], 'cand-001');
      expect(json['approval_id'], 'appr-001');
      expect(json['idempotency_key'], 'idem-001');
      expect(json['before_revision'], 1);
      expect(json['after_revision'], 2);
      expect(json['affected_paths'], ['chapters/ch01.md']);
      expect(json['receipt_hash'], 'hash-r');
      expect(json['after_content_hash'], '');
      expect(json.containsKey('beforeRevision'), isFalse);
    });

    test('fromJson rejects future schema_version', () {
      final receipt = CommitReceipt(
        id: 'rcpt-001',
        candidateId: 'cand-001',
        approvalId: 'appr-001',
        idempotencyKey: 'idem-001',
        beforeRevision: 1,
        afterRevision: 2,
        affectedPaths: ['chapters/ch01.md'],
        committedAt: DateTime.utc(2026, 8, 1),
        receiptHash: 'hash-r',
      );
      final json = receipt.toJson();
      json['schema_version'] = 7;
      expect(
        () => CommitReceipt.fromJson(json),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });
  });

  group('transitionCandidate legal transitions', () {
    test('proposed → approved', () {
      final candidate = makeCandidate(state: CandidateState.proposed);
      final result = transitionCandidate(candidate, CandidateEvent.approve);
      expect(result.success, isTrue);
      expect(result.candidate!.state, CandidateState.approved);
    });

    test('proposed → rejected', () {
      final candidate = makeCandidate(state: CandidateState.proposed);
      final result = transitionCandidate(candidate, CandidateEvent.reject);
      expect(result.success, isTrue);
      expect(result.candidate!.state, CandidateState.rejected);
    });

    test('approved → committed', () {
      final candidate = makeCandidate(state: CandidateState.approved);
      final result = transitionCandidate(candidate, CandidateEvent.commit);
      expect(result.success, isTrue);
      expect(result.candidate!.state, CandidateState.committed);
    });

    test('proposed → superseded', () {
      final candidate = makeCandidate(state: CandidateState.proposed);
      final result = transitionCandidate(candidate, CandidateEvent.supersede);
      expect(result.success, isTrue);
      expect(result.candidate!.state, CandidateState.superseded);
    });

    test('approved → superseded', () {
      final candidate = makeCandidate(state: CandidateState.approved);
      final result = transitionCandidate(candidate, CandidateEvent.supersede);
      expect(result.success, isTrue);
      expect(result.candidate!.state, CandidateState.superseded);
    });
  });

  group('transitionCandidate rejected transitions', () {
    test('proposed → committed is illegal (must approve first)', () {
      final candidate = makeCandidate(state: CandidateState.proposed);
      final result = transitionCandidate(candidate, CandidateEvent.commit);
      expect(result.success, isFalse);
      expect(result.error, contains('ILLEGAL_TRANSITION'));
    });

    test('rejected → approved is illegal (terminal)', () {
      final candidate = makeCandidate(state: CandidateState.rejected);
      final result = transitionCandidate(candidate, CandidateEvent.approve);
      expect(result.success, isFalse);
      expect(result.error, contains('ILLEGAL_TRANSITION'));
    });

    test('rejected → committed is illegal (terminal)', () {
      final candidate = makeCandidate(state: CandidateState.rejected);
      final result = transitionCandidate(candidate, CandidateEvent.commit);
      expect(result.success, isFalse);
    });

    test('committed → approved is illegal (terminal)', () {
      final candidate = makeCandidate(state: CandidateState.committed);
      final result = transitionCandidate(candidate, CandidateEvent.approve);
      expect(result.success, isFalse);
    });

    test('committed → superseded is illegal (terminal)', () {
      final candidate = makeCandidate(state: CandidateState.committed);
      final result = transitionCandidate(candidate, CandidateEvent.supersede);
      expect(result.success, isFalse);
    });

    test('superseded → approved is illegal (terminal)', () {
      final candidate = makeCandidate(state: CandidateState.superseded);
      final result = transitionCandidate(candidate, CandidateEvent.approve);
      expect(result.success, isFalse);
    });

    test('superseded → committed is illegal (terminal)', () {
      final candidate = makeCandidate(state: CandidateState.superseded);
      final result = transitionCandidate(candidate, CandidateEvent.commit);
      expect(result.success, isFalse);
    });

    test('approved → approved is illegal (no self-transition)', () {
      final candidate = makeCandidate(state: CandidateState.approved);
      final result = transitionCandidate(candidate, CandidateEvent.approve);
      expect(result.success, isFalse);
    });

    test('approved → rejected is illegal', () {
      final candidate = makeCandidate(state: CandidateState.approved);
      final result = transitionCandidate(candidate, CandidateEvent.reject);
      expect(result.success, isFalse);
    });
  });

  group('transitionCandidate produces new immutable record', () {
    test('original candidate is unchanged after transition', () {
      final original = makeCandidate(state: CandidateState.proposed);
      final result = transitionCandidate(original, CandidateEvent.approve);
      expect(result.candidate!.state, CandidateState.approved);
      expect(original.state, CandidateState.proposed);
    });

    test('transitioned record preserves identity fields', () {
      final original = makeCandidate(state: CandidateState.proposed);
      final result = transitionCandidate(original, CandidateEvent.approve);
      final next = result.candidate!;
      expect(next.id, original.id);
      expect(next.projectId, original.projectId);
      expect(next.origin, original.origin);
      expect(next.action, original.action);
      expect(
          next.target.projectRelativePath, original.target.projectRelativePath);
      expect(next.baseRevision, original.baseRevision);
      expect(next.payloadHash, original.payloadHash);
      expect(next.actionHash, original.actionHash);
    });
  });

  group('ApprovalDecision binding validation', () {
    ApprovalDecision makeApproval({
      String candidateHash = 'hash-c',
      String actionHash = 'bbbb',
      int baseRevision = 1,
    }) {
      return ApprovalDecision(
        id: 'appr-001',
        candidateId: 'cand-001',
        candidateHash: candidateHash,
        actionHash: actionHash,
        baseRevision: baseRevision,
        actorId: 'user-001',
        approved: true,
        decidedAt: DateTime.utc(2026, 8, 1),
        policy: 'explicit_user',
      );
    }

    test('valid approval matches candidate bindings', () {
      final candidate = makeCandidate();
      final approval = makeApproval();
      expect(
        approval.matchesCandidate(
          candidateHash: 'hash-c',
          actionHash: candidate.actionHash,
          baseRevision: candidate.baseRevision,
        ),
        isTrue,
      );
    });

    test('approval invalid if candidateHash differs', () {
      final approval = makeApproval();
      expect(
        approval.matchesCandidate(
          candidateHash: 'different-hash',
          actionHash: 'bbbb',
          baseRevision: 1,
        ),
        isFalse,
      );
    });

    test('approval invalid if actionHash differs', () {
      final approval = makeApproval();
      expect(
        approval.matchesCandidate(
          candidateHash: 'hash-c',
          actionHash: 'changed-action',
          baseRevision: 1,
        ),
        isFalse,
      );
    });

    test('approval invalid if baseRevision differs', () {
      final approval = makeApproval();
      expect(
        approval.matchesCandidate(
          candidateHash: 'hash-c',
          actionHash: 'bbbb',
          baseRevision: 99,
        ),
        isFalse,
      );
    });
  });

  group('ChangeTarget serialization', () {
    test('toJson uses snake_case', () {
      const target = ChangeTarget(
        projectRelativePath: 'chapters/ch01.md',
        kind: 'chapter',
      );
      final json = target.toJson();
      expect(json['project_relative_path'], 'chapters/ch01.md');
      expect(json['kind'], 'chapter');
    });

    test('fromJson round-trips', () {
      const target = ChangeTarget(
        projectRelativePath: 'assets/world.json',
        kind: 'canon',
      );
      final restored = ChangeTarget.fromJson(target.toJson());
      expect(restored.projectRelativePath, 'assets/world.json');
      expect(restored.kind, 'canon');
    });
  });

  group('Enum coverage', () {
    test('ChangeOrigin has all eight values', () {
      expect(ChangeOrigin.values.length, 8);
      expect(ChangeOrigin.values, contains(ChangeOrigin.userUi));
      expect(ChangeOrigin.values, contains(ChangeOrigin.agent));
      expect(ChangeOrigin.values, contains(ChangeOrigin.batchImport));
      expect(ChangeOrigin.values, contains(ChangeOrigin.skill));
      expect(ChangeOrigin.values, contains(ChangeOrigin.restore));
      expect(ChangeOrigin.values, contains(ChangeOrigin.recovery));
      expect(ChangeOrigin.values, contains(ChangeOrigin.externalMutation));
      expect(ChangeOrigin.values, contains(ChangeOrigin.legacyMigration));
    });

    test('ChangeAction has all four values', () {
      expect(ChangeAction.values.length, 4);
      expect(ChangeAction.values, contains(ChangeAction.createText));
      expect(ChangeAction.values, contains(ChangeAction.replaceText));
      expect(ChangeAction.values, contains(ChangeAction.replaceAsset));
      expect(ChangeAction.values, contains(ChangeAction.restoreSnapshot));
    });

    test('CandidateState has all five values', () {
      expect(CandidateState.values.length, 5);
      expect(CandidateState.values, contains(CandidateState.proposed));
      expect(CandidateState.values, contains(CandidateState.approved));
      expect(CandidateState.values, contains(CandidateState.rejected));
      expect(CandidateState.values, contains(CandidateState.committed));
      expect(CandidateState.values, contains(CandidateState.superseded));
    });
  });
}
