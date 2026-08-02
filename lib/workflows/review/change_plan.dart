/// Change plan and propagation models for whole-book review.
library;

class TextRange {
  const TextRange({required this.start, required this.end});
  final int start;
  final int end;
}

/// A proposed text change derived from a review finding.
class ProposedChange {
  const ProposedChange({
    required this.id,
    required this.findingId,
    required this.documentId,
    required this.originalText,
    required this.replacementText,
    required this.range,
  });

  final String id;
  final String findingId;
  final String documentId;
  final String originalText;
  final String replacementText;
  final TextRange range;
}

/// A collection of proposed changes for a project.
class ChangePlan {
  const ChangePlan({required this.projectId, required this.changes});

  final String projectId;
  final List<ProposedChange> changes;
}

/// A canon (story graph) change that may propagate to documents.
class CanonChange {
  const CanonChange({
    required this.entityId,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.sourceChapter,
  });

  final String entityId;
  final String field;
  final String oldValue;
  final String newValue;
  final int sourceChapter;
}

/// A document affected by a canon change.
class AffectedDocument {
  const AffectedDocument({
    required this.documentId,
    required this.mentionCount,
  });

  final String documentId;
  final int mentionCount;
}

/// A single step in an impact plan.
class ImpactStep {
  const ImpactStep({
    required this.documentId,
    required this.description,
    required this.autoApply,
  });

  final String documentId;
  final String description;
  final bool autoApply;
}

/// An ordered impact plan for propagating a canon change.
class ImpactPlan {
  const ImpactPlan({
    required this.steps,
    required this.requiresConfirmation,
  });

  final List<ImpactStep> steps;
  final bool requiresConfirmation;
}
