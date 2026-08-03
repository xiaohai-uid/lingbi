/// Unified mutation protocol interface.
///
/// Every mutating caller (UI, Agent, import, Skill, restore) converges
/// on this single deep-module interface. See ADR-010.
library;

import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/errors/result.dart';

/// The named Result boundary shared by every canonical mutation operation.
///
/// This alias keeps the public contract explicit without introducing another
/// result implementation or allowing nullable/boolean mutation outcomes.
typedef MutationResult<T> = Result<T>;

/// Command to propose a new change.
final class ChangeRequest {
  const ChangeRequest({
    required this.projectId,
    required this.origin,
    required this.action,
    required this.target,
    required this.baseRevision,
    required this.payload,
    this.runId,
    this.idempotencyKey,
  });

  final String projectId;
  final ChangeOrigin origin;
  final ChangeAction action;
  final ChangeTarget target;
  final int baseRevision;
  final String payload;
  final String? runId;
  final String? idempotencyKey;
}

/// Command to approve or reject a candidate.
final class ApprovalCommand {
  const ApprovalCommand({
    required this.candidateId,
    required this.actorId,
    required this.approved,
    required this.policy,
    this.projectId = '',
  });

  final String candidateId;
  final String actorId;
  final bool approved;
  final String policy;

  /// Stable project identity for root resolution in project-bound mode.
  final String projectId;
}

/// Command to commit an approved candidate.
final class CommitCommand {
  const CommitCommand({
    required this.candidateId,
    required this.approvalId,
    required this.idempotencyKey,
    this.projectId = '',
  });

  final String candidateId;
  final String approvalId;
  final String idempotencyKey;

  /// Stable project identity for root resolution in project-bound mode.
  final String projectId;
}

/// Command to reject a candidate.
final class RejectCommand {
  const RejectCommand({
    required this.candidateId,
    required this.actorId,
    this.reason,
    this.projectId = '',
  });

  final String candidateId;
  final String actorId;
  final String? reason;

  /// Stable project identity for root resolution in project-bound mode.
  final String projectId;
}

/// The single interface through which all canonical mutations flow.
abstract interface class MutationProtocol {
  /// Propose a new candidate change. Persists the candidate record.
  Future<MutationResult<CandidateChange>> propose(ChangeRequest request);

  /// Record an approval or rejection decision.
  Future<MutationResult<ApprovalDecision>> decide(ApprovalCommand command);

  /// Commit an approved candidate to canonical storage.
  Future<MutationResult<CommitReceipt>> commit(CommitCommand command);

  /// Deep convenience: persist candidate + implicit approval + commit.
  ///
  /// Internally creates all three records. Does NOT bypass the protocol.
  Future<MutationResult<CommitReceipt>> applyUserEdit(ChangeRequest request);

  /// Reject a proposed candidate.
  Future<MutationResult<void>> reject(RejectCommand command);

  /// Reconcile every unresolved commit intent for a project (ADR-010
  /// crash consistency): complete a matching receipt, abandon an untouched
  /// base intent with an explicit outcome, or freeze an indeterminate
  /// target. Never auto-overwrites or auto-rolls back.
  Future<MutationResult<List<RecoveryOutcome>>> reconcilePending(
      String projectId);
}
