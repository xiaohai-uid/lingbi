/// Whole-book review workflow with evidence-linked findings,
/// selective diff application, conflict detection, and undo.
library;

import 'change_plan.dart';

export 'change_plan.dart';

enum ReviewMode { developmental, line, dialogue, copy, custom }

enum FindingSeverity { critical, high, medium, low }

/// A single review finding with evidence and source location.
class ReviewFinding {
  const ReviewFinding({
    required this.id,
    required this.mode,
    required this.severity,
    required this.description,
    required this.evidence,
    required this.sourceDocumentId,
    required this.sourceRange,
    required this.suggestedAction,
  });

  final String id;
  final ReviewMode mode;
  final FindingSeverity severity;
  final String description;
  final String evidence;
  final String sourceDocumentId;
  final TextRange sourceRange;
  final String suggestedAction;
}

/// Summary statistics for a review report.
class ReviewSummary {
  const ReviewSummary({
    required this.totalFindings,
    required this.bySeverity,
    required this.byMode,
  });

  final int totalFindings;
  final Map<FindingSeverity, int> bySeverity;
  final Map<ReviewMode, int> byMode;
}

/// A complete review report.
class ReviewReport {
  const ReviewReport({
    required this.projectId,
    required this.findings,
    required this.summary,
  });

  final String projectId;
  final List<ReviewFinding> findings;
  final ReviewSummary summary;
}

/// Result of applying changes to a document.
class ApplyResult {
  const ApplyResult({
    required this.text,
    required this.appliedIds,
    required this.skippedIds,
    required this.conflicts,
    required this.originalText,
  });

  final String text;
  final List<String> appliedIds;
  final List<String> skippedIds;
  final List<String> conflicts;
  final String originalText;
}

class BookReviewWorkflow {
  BookReviewWorkflow({required this.storageDir});

  final String storageDir;

  /// Builds a review report from findings.
  ReviewReport buildReport({
    required String projectId,
    required List<ReviewFinding> findings,
  }) {
    final bySeverity = <FindingSeverity, int>{};
    final byMode = <ReviewMode, int>{};
    for (final f in findings) {
      bySeverity[f.severity] = (bySeverity[f.severity] ?? 0) + 1;
      byMode[f.mode] = (byMode[f.mode] ?? 0) + 1;
    }

    return ReviewReport(
      projectId: projectId,
      findings: findings,
      summary: ReviewSummary(
        totalFindings: findings.length,
        bySeverity: bySeverity,
        byMode: byMode,
      ),
    );
  }

  /// Applies selected changes to original text with conflict detection.
  ApplyResult applyChanges({
    required String originalText,
    required ChangePlan plan,
    required Set<String> selectedChangeIds,
  }) {
    final selected = plan.changes
        .where((c) => selectedChangeIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.range.start.compareTo(b.range.start));

    final appliedIds = <String>[];
    final skippedIds = <String>[];
    final conflicts = <String>[];

    // Detect overlapping ranges
    final nonOverlapping = <ProposedChange>[];
    var lastEnd = -1;
    for (final change in selected) {
      if (change.range.start < lastEnd) {
        conflicts.add(change.id);
      } else {
        nonOverlapping.add(change);
        lastEnd = change.range.end;
      }
    }

    // Skipped = selected but not in plan
    for (final c in plan.changes) {
      if (!selectedChangeIds.contains(c.id)) {
        skippedIds.add(c.id);
      }
    }

    // Apply non-overlapping changes from end to start to preserve offsets
    var result = originalText;
    for (final change in nonOverlapping.reversed) {
      result = result.substring(0, change.range.start) +
          change.replacementText +
          result.substring(change.range.end);
      appliedIds.add(change.id);
    }
    appliedIds.sort();

    return ApplyResult(
      text: result,
      appliedIds: appliedIds,
      skippedIds: skippedIds,
      conflicts: conflicts,
      originalText: originalText,
    );
  }

  /// Reverts applied changes to the original text.
  String undoChanges(ApplyResult result) => result.originalText;

  /// Builds an ordered impact plan for propagating a canon change.
  ImpactPlan buildImpactPlan({
    required CanonChange canonChange,
    required List<AffectedDocument> affectedDocuments,
  }) {
    // Sort by document ID (which encodes chapter order)
    final sorted = List<AffectedDocument>.from(affectedDocuments)
      ..sort((a, b) => a.documentId.compareTo(b.documentId));

    final steps = sorted.map((doc) {
      return ImpactStep(
        documentId: doc.documentId,
        description:
            'Update ${doc.mentionCount} mention(s) of ${canonChange.entityId} '
            '(${canonChange.field}: "${canonChange.oldValue}" -> "${canonChange.newValue}")',
        autoApply: false,
      );
    }).toList();

    return ImpactPlan(
      steps: steps,
      requiresConfirmation: true,
    );
  }
}
