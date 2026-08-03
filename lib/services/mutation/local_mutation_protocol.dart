/// Local file-based implementation of MutationProtocol.
///
/// Converges all mutations through the journal + canonical store.
/// See ADR-010 for the three-record invariant and crash consistency.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/domain/mutation/mutation_transitions.dart';
import 'package:lingbi/services/mutation/commit_reconciler.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

/// Creates a canonical store bound to one resolved project root.
typedef StoreForResolvedRoot = FileCanonicalStore Function(
    ResolvedProjectRoot root);

/// Local adapter implementing the full mutation protocol.
///
/// Two constructions exist:
/// - [LocalMutationProtocol.projectBound]: resolves the current project root
///   for every operation and uses the project-owned journal and a per-root
///   store (ADR-012). This is the production seam.
/// - the default constructor: a journal and store bound once at construction
///   time, used by legacy callers and test doubles. The journal remains the
///   project-owned layout when the caller binds it to a project root.
final class LocalMutationProtocol implements MutationProtocol {
  LocalMutationProtocol({
    required this.journal,
    required this.store,
  })  : resolver = null,
        journalFactory = null,
        storeForRoot = null;

  LocalMutationProtocol.projectBound({
    required this.resolver,
    required this.journalFactory,
    required this.storeForRoot,
  })  : journal = null,
        store = null;

  /// Legacy single journal; non-null only in the default constructor.
  final LocalMutationJournal? journal;
  final FileCanonicalStore? store;

  final ProjectRootResolver? resolver;
  final ProjectMutationJournalFactory? journalFactory;
  final StoreForResolvedRoot? storeForRoot;

  Future<Result<(LocalMutationJournal, FileCanonicalStore)>> _boundFor(
      String projectId) async {
    final rootResolver = resolver;
    if (rootResolver != null) {
      final resolution = await rootResolver.resolve(projectId);
      final root = resolution.getOrNull();
      if (root == null) {
        return Result.failure(resolution.errorOrNull()!);
      }
      final journal = await journalFactory!.forProject(projectId);
      final boundJournal = journal.getOrNull();
      if (boundJournal == null) {
        return Result.failure(journal.errorOrNull()!);
      }
      return Result.success(
          (boundJournal, storeForRoot!(root)));
    }
    return Result.success((journal!, store!));
  }

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

    final bound = await _boundFor(request.projectId);
    final pair = bound.getOrNull();
    if (pair == null) {
      return Result.failure(bound.errorOrNull()!);
    }
    final journal = pair.$1;
    final store = pair.$2;

    // Snapshot the current target bytes so commit can detect drift between
    // propose and commit (the journal event payload is not schema-locked).
    final snapshot = await store.read(request.target.projectRelativePath);
    final baseHash = snapshot.getOrNull()?.hash;

    await journal.append(JournalEvent(
      eventId: 'evt-propose-${candidate.id}',
      eventType: 'candidate_proposed',
      aggregateId: candidate.id,
      payload: {
        ...candidate.toJson(),
        'content': request.payload,
        if (baseHash != null) 'base_hash': baseHash,
      },
      idempotencyKey: request.idempotencyKey,
    ));

    return Result.success(candidate);
  }

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async {
    // The candidate aggregate lives in the journal of the project it was
    // proposed into; resolve that project's current root (ADR-012).
    final bound = await _boundFor(command.projectId);
    final pair = bound.getOrNull();
    if (pair == null) {
      return Result.failure(bound.errorOrNull()!);
    }
    final journal = pair.$1;

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
    final bound = await _boundFor(command.projectId);
    final pair = bound.getOrNull();
    if (pair == null) {
      return Result.failure(bound.errorOrNull()!);
    }
    final journal = pair.$1;
    final store = pair.$2;

    // Idempotent replay: a receipt with the same idempotency key is the same
    // commit, returned without rewriting anything.
    final existingReceipt = await _findReceiptByKey(journal, command.idempotencyKey);
    if (existingReceipt != null) {
      return Result.success(existingReceipt);
    }

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

    // A previously persisted intent for the same idempotency key means a
    // crash interrupted this commit: reconcile against current bytes.
    final unresolved =
        await journal.readUnresolvedIntents();
    final staleIntent = unresolved
        .where((i) => i.idempotencyKey == command.idempotencyKey)
        .firstOrNull;
    if (staleIntent != null) {
      return _reconcileStaleIntent(journal, store, command, candidate, staleIntent);
    }

    final baseHash =
        proposalPayload['base_hash'] as String?;

    // Drift check: the target must still match the base observed at propose.
    final snapshot = await store.read(candidate.target.projectRelativePath);
    final currentHash = snapshot.getOrNull()?.hash;
    final currentRevision = snapshot.getOrNull()?.revision;
    final currentMissing = snapshot.errorOrNull() != null;
    if ((currentMissing && baseHash != null) ||
        (!currentMissing && baseHash == null) ||
        (!currentMissing && baseHash != null && currentHash != baseHash)) {
      return Result.failure(FileError(
        'REVISION_CONFLICT: ${candidate.target.projectRelativePath} '
        'drifted since proposal (base=$baseHash current=$currentHash)',
        typedCode: MutationErrorCode.revisionConflict,
      ));
    }

    final intent = CommitIntent(
      id: _generateId('intent'),
      projectId: candidate.projectId,
      candidateId: candidate.id,
      targetPath: candidate.target.projectRelativePath,
      baseRevision: candidate.baseRevision,
      expectedRevision: candidate.baseRevision + 1,
      expectedContentHash: candidate.payloadHash,
      idempotencyKey: command.idempotencyKey,
      baseContentHash: baseHash ?? '',
    );
    await journal.appendCommitIntent(intent);

    final plan = CommitPlan(
      transactionId: 'txn-${command.candidateId}',
      targets: [
        CommitTarget(
          relativePath: candidate.target.projectRelativePath,
          newContent: content,
          expectedHash: baseHash,
          // Revision is envelope authority only for verified canonical JSON;
          // legacy/non-envelope JSON is migrated by MP-08 and keeps raw-text
          // hash authority until then.
          expectedRevision: currentRevision != null ? candidate.baseRevision : null,
        ),
      ],
    );

    final prepareResult = await store.prepare(plan);
    final prepared = prepareResult.getOrNull();
    if (prepared == null) {
      await journal.appendRecoveryOutcome(RecoveryOutcome(
        id: _generateId('outcome'),
        intentId: intent.id,
        projectId: candidate.projectId,
        targetPath: intent.targetPath,
        outcome: RecoveryOutcomeType.intentAbandoned,
        resolvedAt: DateTime.now().toUtc(),
        reason: 'prepare failed: ${prepareResult.errorOrNull()}',
      ));
      return Result.failure(prepareResult.errorOrNull()!);
    }

    final applyResult = await store.apply(prepared);
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
      afterRevision: commitResult.afterRevisions[intent.targetPath] ??
          candidate.baseRevision + 1,
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

  Future<Result<CommitReceipt>> _reconcileStaleIntent(
    LocalMutationJournal journal,
    FileCanonicalStore store,
    CommitCommand command,
    CandidateChange candidate,
    CommitIntent intent,
  ) async {
    final snapshot = await store.read(intent.targetPath);
    final currentHash = snapshot.getOrNull()?.hash;

    if (currentHash != null && currentHash == intent.expectedContentHash) {
      // Apply already landed; complete the receipt.
      final receipt = CommitReceipt(
        id: _generateId('rcpt'),
        candidateId: command.candidateId,
        approvalId: command.approvalId,
        idempotencyKey: command.idempotencyKey,
        beforeRevision: intent.baseRevision,
        afterRevision: intent.expectedRevision,
        affectedPaths: [intent.targetPath],
        committedAt: DateTime.now().toUtc(),
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
      await journal.appendRecoveryOutcome(RecoveryOutcome(
        id: _generateId('outcome'),
        intentId: intent.id,
        projectId: intent.projectId,
        targetPath: intent.targetPath,
        outcome: RecoveryOutcomeType.receiptCompleted,
        resolvedAt: DateTime.now().toUtc(),
        reason: 'stale intent completed on retry',
      ));
      return Result.success(receipt);
    }

    final missing = snapshot.errorOrNull() != null;
    final atBase = missing
        ? intent.baseContentHash.isEmpty
        : intent.baseContentHash.isNotEmpty &&
            currentHash == intent.baseContentHash;
    if (atBase) {
      // Untouched base: abandon the stale intent explicitly and retry the
      // commit from scratch is handled by returning a typed unresolved error;
      // the caller can retry after reconciliation.
      await journal.appendRecoveryOutcome(RecoveryOutcome(
        id: _generateId('outcome'),
        intentId: intent.id,
        projectId: intent.projectId,
        targetPath: intent.targetPath,
        outcome: RecoveryOutcomeType.intentAbandoned,
        resolvedAt: DateTime.now().toUtc(),
        reason: 'stale intent abandoned at base on retry',
      ));
      return Result.failure(FileError(
        'UNRESOLVED_RECOVERY: intent ${intent.id} abandoned at base; retry commit',
        typedCode: MutationErrorCode.unresolvedRecovery,
      ));
    }

    // Indeterminate bytes: freeze; never auto-overwrite or roll back.
    await journal.appendRecoveryOutcome(RecoveryOutcome(
      id: _generateId('outcome'),
      intentId: intent.id,
      projectId: intent.projectId,
      targetPath: intent.targetPath,
      outcome: RecoveryOutcomeType.targetFrozen,
      resolvedAt: DateTime.now().toUtc(),
      reason: 'indeterminate target frozen on retry',
    ));
    return Result.failure(FileError(
      'UNRESOLVED_RECOVERY: target ${intent.targetPath} is indeterminate '
      'and frozen; user decision required',
      typedCode: MutationErrorCode.unresolvedRecovery,
    ));
  }

  Future<CommitReceipt?> _findReceiptByKey(
    LocalMutationJournal journal,
    String idempotencyKey,
  ) async {
    final events = await journal.readAll();
    for (final event in events) {
      if (event.eventType == 'candidate_committed') {
        final payloadKey = event.payload['idempotency_key'] as String?;
        if (payloadKey == idempotencyKey) {
          return CommitReceipt.fromJson(event.payload);
        }
      }
    }
    return null;
  }

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async {
    // Propose
    final proposeResult = await propose(request);
    final candidate = proposeResult.getOrNull();
    if (candidate == null) {
      return Result.failure(proposeResult.errorOrNull()!);
    }

    // Implicit approval
    final decideResult = await decide(ApprovalCommand(
      candidateId: candidate.id,
      actorId: 'user',
      approved: true,
      policy: 'user_direct_edit',
      projectId: request.projectId,
    ));
    final approval = decideResult.getOrNull();
    if (approval == null) {
      return Result.failure(decideResult.errorOrNull()!);
    }

    // Commit
    return commit(CommitCommand(
      candidateId: candidate.id,
      approvalId: approval.id,
      idempotencyKey: request.idempotencyKey ?? _generateId('idem'),
      projectId: request.projectId,
    ));
  }

  @override
  Future<Result<void>> reject(RejectCommand command) async {
    final result = await decide(ApprovalCommand(
      candidateId: command.candidateId,
      actorId: command.actorId,
      approved: false,
      policy: 'explicit_reject',
      projectId: command.projectId,
    ));
    return result.when(
      success: (_) => Result.success(null),
      failure: (e) => Result.failure(e),
    );
  }

  @override
  Future<Result<List<RecoveryOutcome>>> reconcilePending(
      String projectId) async {
    final bound = await _boundFor(projectId);
    final pair = bound.getOrNull();
    if (pair == null) {
      return Result.failure(bound.errorOrNull()!);
    }
    return CommitReconciler(journal: pair.$1, store: pair.$2).reconcileAll();
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
