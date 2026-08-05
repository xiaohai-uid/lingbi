/// Journal-driven crash reconciliation for unresolved commit intents.
///
/// ADR-010 crash consistency: a `commit_intent` event is durable before the
/// target write. After a crash the target bytes decide the outcome:
///   - target matches the intent's expected hash → the apply happened; the
///     receipt is completed (receiptCompleted)
///   - target matches the intent's base hash (or a create target is still
///     absent) → the apply never ran; the intent is abandoned explicitly
///   - otherwise the bytes are indeterminate → the target is frozen and the
///     current bytes are preserved; no automatic overwrite or rollback
///
/// Every resolution is recorded as a `recovery_outcome` journal event; the
/// intent is never silently deleted.
library;

import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/shared/errors/result.dart';

/// Resolves every unresolved intent of one project against current bytes.
final class CommitReconciler {
  CommitReconciler({
    required this.journal,
    required FileCanonicalStore store,
  }) : _store = store;

  final LocalMutationJournal journal;
  final FileCanonicalStore _store;

  /// Reconcile all unresolved intents and return the recorded outcomes.
  Future<Result<List<RecoveryOutcome>>> reconcileAll() async {
    final intents = await journal.readUnresolvedIntents();
    final outcomes = <RecoveryOutcome>[];

    for (final intent in intents) {
      final outcome = await _reconcileOne(intent);
      if (outcome == null) continue;
      await journal.appendRecoveryOutcome(outcome);
      outcomes.add(outcome);
    }

    return Result.success(outcomes);
  }

  Future<RecoveryOutcome?> _reconcileOne(CommitIntent intent) async {
    final snapshot = await _store.read(intent.targetPath);
    final targetHash = snapshot.getOrNull()?.hash;

    if (targetHash != null && targetHash == intent.expectedContentHash) {
      // The apply already reached the target; complete the receipt.
      await _completeReceipt(intent);
      return _outcome(intent, RecoveryOutcomeType.receiptCompleted);
    }

    final targetMissing = snapshot.errorOrNull() != null;
    final atBase = targetMissing
        ? intent.baseContentHash.isEmpty
        : targetHash == intent.baseContentHash &&
            intent.baseContentHash.isNotEmpty;
    if (atBase) {
      return _outcome(intent, RecoveryOutcomeType.intentAbandoned);
    }

    return _outcome(intent, RecoveryOutcomeType.targetFrozen);
  }

  /// Complete the receipt for an apply that already landed, mirroring the
  /// normal commit receipt.
  Future<void> _completeReceipt(CommitIntent intent) async {
    final events = await journal.readByAggregate(intent.candidateId);
    final approval = events
        .where((e) => e.eventType == 'candidate_approved')
        .map((e) => ApprovalDecision.fromJson(e.payload))
        .lastOrNull;

    final receipt = CommitReceipt(
      id: _generateId('rcpt'),
      candidateId: intent.candidateId,
      approvalId: approval?.id ?? 'reconciled',
      idempotencyKey: intent.idempotencyKey,
      beforeRevision: intent.baseRevision,
      afterRevision: intent.expectedRevision,
      afterContentHash: intent.expectedContentHash,
      affectedPaths: [intent.targetPath],
      committedAt: DateTime.now().toUtc(),
      receiptHash: canonicalTextHash(
        '${intent.candidateId}:${approval?.id ?? 'reconciled'}:${intent.idempotencyKey}',
      ),
    );

    await journal.append(JournalEvent(
      eventId: 'evt-commit-${receipt.id}',
      eventType: LocalMutationJournal.receiptEventType,
      aggregateId: intent.candidateId,
      payload: receipt.toJson(),
      idempotencyKey: intent.idempotencyKey,
    ));
  }

  RecoveryOutcome _outcome(
    CommitIntent intent,
    RecoveryOutcomeType outcome,
  ) =>
      RecoveryOutcome(
        id: _generateId('outcome'),
        intentId: intent.id,
        projectId: intent.projectId,
        targetPath: intent.targetPath,
        outcome: outcome,
        resolvedAt: DateTime.now().toUtc(),
        reason: switch (outcome) {
          RecoveryOutcomeType.receiptCompleted =>
            'target matched expected content; receipt completed',
          RecoveryOutcomeType.intentAbandoned =>
            'target untouched at base; intent abandoned',
          RecoveryOutcomeType.targetFrozen =>
            'target bytes indeterminate; frozen pending user decision',
        },
      );

  static int _counter = 0;
  String _generateId(String prefix) {
    _counter++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}

extension _LastOrNull<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
