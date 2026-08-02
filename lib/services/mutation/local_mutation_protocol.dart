/// Local file-based implementation of MutationProtocol.
///
/// Converges all mutations through the journal + canonical store.
/// See ADR-010 for the three-record invariant.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/domain/mutation/mutation_transitions.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

/// Local adapter implementing the full mutation protocol.
final class LocalMutationProtocol implements MutationProtocol {
  LocalMutationProtocol({
    required this.journal,
    required this.store,
  });

  final LocalMutationJournal journal;
  final FileCanonicalStore store;

  @override
  Future<Result<CandidateChange>> propose(ChangeRequest request) async {
    final payloadHash = canonicalTextHash(request.payload);
    final actionHash = _computeActionHash(
      action: request.action,
      target: request.target,
      payloadHash: payloadHash,
      baseRevision: request.baseRevision,
    );

    final candidate = CandidateChange(
      id: _generateId('cand'),
      projectId: request.projectId,
      origin: request.origin,
      action: request.action,
      target: request.target,
      baseRevision: request.baseRevision,
      payloadHash: payloadHash,
      actionHash: actionHash,
      createdAt: DateTime.now().toUtc(),
      state: CandidateState.proposed,
      runId: request.runId,
    );

    // Persist to journal (payload content stored for commit retrieval)
    await journal.append(JournalEvent(
      eventId: 'evt-propose-${candidate.id}',
      eventType: 'candidate_proposed',
      aggregateId: candidate.id,
      payload: {...candidate.toJson(), 'content': request.payload},
      idempotencyKey: request.idempotencyKey,
    ));

    return Result.success(candidate);
  }

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async {
    // Find the candidate in the journal
    final events = await journal.readByAggregate(command.candidateId);
    if (events.isEmpty) {
      return Result.failure(FileError(
        'Candidate not found: ${command.candidateId}',
        code: 'NOT_FOUND',
      ));
    }

    final candidateJson = events.last.payload;
    final candidate = CandidateChange.fromJson(candidateJson);

    // Validate transition
    final transition = transitionCandidate(
      candidate,
      command.approved ? CandidateEvent.approve : CandidateEvent.reject,
    );
    if (!transition.success) {
      return Result.failure(FileError(
        transition.error ?? 'ILLEGAL_TRANSITION',
        code: 'ILLEGAL_TRANSITION',
      ));
    }

    final candidateHash = canonicalJsonHash(candidate.toJson());
    final decision = ApprovalDecision(
      id: _generateId('appr'),
      candidateId: command.candidateId,
      candidateHash: candidateHash,
      actionHash: candidate.actionHash,
      baseRevision: candidate.baseRevision,
      actorId: command.actorId,
      approved: command.approved,
      decidedAt: DateTime.now().toUtc(),
      policy: command.policy,
    );

    await journal.append(JournalEvent(
      eventId: 'evt-decide-${decision.id}',
      eventType: command.approved ? 'candidate_approved' : 'candidate_rejected',
      aggregateId: command.candidateId,
      payload: decision.toJson(),
    ));

    return Result.success(decision);
  }

  @override
  Future<Result<CommitReceipt>> commit(CommitCommand command) async {
    // Find candidate and approval
    final events = await journal.readByAggregate(command.candidateId);
    if (events.isEmpty) {
      return Result.failure(FileError(
        'Candidate not found: ${command.candidateId}',
        code: 'NOT_FOUND',
      ));
    }

    // Find the original proposal event
    final proposalEvents =
        events.where((e) => e.eventType == 'candidate_proposed');
    if (proposalEvents.isEmpty) {
      return Result.failure(FileError(
        'No proposal found for: ${command.candidateId}',
        code: 'NOT_FOUND',
      ));
    }
    final candidate =
        CandidateChange.fromJson(proposalEvents.last.payload);

    // Verify approval exists and matches
    final approvalEvents = events.where(
      (e) =>
          e.eventType == 'candidate_approved' &&
          (e.payload['id'] == command.approvalId),
    );
    if (approvalEvents.isEmpty) {
      return Result.failure(FileError(
        'APPROVAL_REQUIRED: no matching approval for ${command.candidateId}',
        code: 'APPROVAL_REQUIRED',
      ));
    }

    final approval = ApprovalDecision.fromJson(approvalEvents.last.payload);
    final candidateHash = canonicalJsonHash(candidate.toJson());

    // Validate binding
    if (!approval.matchesCandidate(
      candidateHash: candidateHash,
      actionHash: candidate.actionHash,
      baseRevision: candidate.baseRevision,
    )) {
      return Result.failure(FileError(
        'BINDING_MISMATCH: approval no longer valid',
        code: 'BINDING_MISMATCH',
      ));
    }

    // Retrieve payload content from the proposal event
    final proposalPayload = proposalEvents.last.payload;
    final content = proposalPayload['content'] as String?;
    if (content == null) {
      return Result.failure(FileError(
        'PAYLOAD_MISSING: no content in proposal for ${command.candidateId}',
        code: 'PAYLOAD_MISSING',
      ));
    }

    // Verify payload integrity
    if (canonicalTextHash(content) != candidate.payloadHash) {
      return Result.failure(FileError(
        'PAYLOAD_HASH_MISMATCH: content corrupted for ${command.candidateId}',
        code: 'PAYLOAD_HASH_MISMATCH',
      ));
    }

    // Apply to canonical store via prepare/apply
    final plan = CommitPlan(
      transactionId: 'txn-${command.candidateId}',
      targets: [
        CommitTarget(
          relativePath: candidate.target.projectRelativePath,
          newContent: content,
          expectedHash: null,
        ),
      ],
    );

    final Result<PreparedCommit> prepareResult;
    try {
      prepareResult = await store.prepare(plan);
    } catch (e) {
      return Result.failure(FileError(
        'STORE_PREPARE_ERROR: $e',
        code: 'STORE_ERROR',
      ));
    }
    final prepared = prepareResult.getOrNull();
    if (prepared == null) {
      return Result.failure(prepareResult.errorOrNull()!);
    }

    final Result<CommitResult> applyResult;
    try {
      applyResult = await store.apply(prepared);
    } catch (e) {
      return Result.failure(FileError(
        'STORE_APPLY_ERROR: $e',
        code: 'STORE_ERROR',
      ));
    }
    final commitResult = applyResult.getOrNull();
    if (commitResult == null) {
      return Result.failure(applyResult.errorOrNull()!);
    }

    // Canonical write succeeded — now create receipt
    final receipt = CommitReceipt(
      id: _generateId('rcpt'),
      candidateId: command.candidateId,
      approvalId: command.approvalId,
      idempotencyKey: command.idempotencyKey,
      beforeRevision: candidate.baseRevision,
      afterRevision: candidate.baseRevision + 1,
      affectedPaths: commitResult.affectedPaths,
      committedAt: commitResult.committedAt,
      receiptHash: canonicalTextHash(
          '${command.candidateId}:${command.approvalId}:${command.idempotencyKey}'),
    );

    await journal.append(JournalEvent(
      eventId: 'evt-commit-${receipt.id}',
      eventType: 'candidate_committed',
      aggregateId: command.candidateId,
      payload: receipt.toJson(),
      idempotencyKey: command.idempotencyKey,
    ));

    return Result.success(receipt);
  }

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async {
    // Propose
    final proposeResult = await propose(request);
    final candidate = proposeResult.when(
      success: (c) => c,
      failure: (e) => null,
    );
    if (candidate == null) {
      return Result.failure(proposeResult.when(
        success: (_) => FileError('unexpected'),
        failure: (e) => e,
      ));
    }

    // Implicit approval
    final decideResult = await decide(ApprovalCommand(
      candidateId: candidate.id,
      actorId: 'user',
      approved: true,
      policy: 'user_direct_edit',
    ));
    final approval = decideResult.when(
      success: (a) => a,
      failure: (e) => null,
    );
    if (approval == null) {
      return Result.failure(decideResult.when(
        success: (_) => FileError('unexpected'),
        failure: (e) => e,
      ));
    }

    // Commit
    return commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval.id,
      idempotencyKey: request.idempotencyKey ?? _generateId('idem'),
    ));
  }

  @override
  Future<Result<void>> reject(RejectCommand command) async {
    final result = await decide(ApprovalCommand(
      candidateId: command.candidateId,
      actorId: command.actorId,
      approved: false,
      policy: 'explicit_reject',
    ));
    return result.when(
      success: (_) => Result.success(null),
      failure: (e) => Result.failure(e),
    );
  }

  String _computeActionHash({
    required ChangeAction action,
    required ChangeTarget target,
    required String payloadHash,
    required int baseRevision,
  }) {
    final binding =
        '${action.wireName}:${target.projectRelativePath}:$payloadHash:$baseRevision';
    return sha256.convert(utf8.encode(binding)).toString();
  }

  static int _counter = 0;
  String _generateId(String prefix) {
    _counter++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}
