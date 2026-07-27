/// Continuity gates for long-form fiction generation.
///
/// Pre-generation: emits hard constraints from confirmed story graph facts.
/// Post-generation: detects contradictions, distinguishes inventions from
/// contradictions, and blocks adoption of high-risk conflicts without
/// explicit author override.
library;

enum ContinuitySeverity { critical, high, medium, low }

enum ContinuityAction { blockAdoption, requireConfirmation, warn }

/// A confirmed or unconfirmed fact from the story graph.
class ContinuityFact {
  const ContinuityFact({
    required this.id,
    required this.entityId,
    required this.claim,
    required this.validFromChapter,
    required this.validToChapter,
    required this.confirmed,
    required this.severity,
  });

  final String id;
  final String entityId;
  final String claim;
  final int validFromChapter;
  final int? validToChapter;
  final bool confirmed;
  final ContinuitySeverity severity;

  bool isValidAt(int chapter) =>
      chapter >= validFromChapter &&
      (validToChapter == null || chapter <= validToChapter!);
}

/// An entity mention in generated text.
class EntityMention {
  const EntityMention({
    required this.entityId,
    required this.start,
    required this.end,
  });

  final String entityId;
  final int start;
  final int end;
}

/// A pre-generation constraint derived from a confirmed fact.
class ContinuityConstraint {
  const ContinuityConstraint({
    required this.factId,
    required this.entityId,
    required this.claim,
    required this.blocking,
  });

  final String factId;
  final String entityId;
  final String claim;
  final bool blocking;
}

/// A post-generation continuity issue.
class ContinuityIssue {
  const ContinuityIssue({
    required this.factId,
    required this.entityId,
    required this.description,
    required this.evidence,
    required this.severity,
    required this.proposedAction,
    required this.requiresOverride,
  });

  final String factId;
  final String entityId;
  final String description;
  final String evidence;
  final ContinuitySeverity severity;
  final ContinuityAction proposedAction;
  final bool requiresOverride;
}

/// The adoption decision after continuity analysis.
class AdoptionDecision {
  const AdoptionDecision({
    required this.canAdopt,
    required this.blockingIssues,
    required this.warnings,
  });

  final bool canAdopt;
  final List<ContinuityIssue> blockingIssues;
  final List<ContinuityIssue> warnings;
}

/// Contradiction patterns: keyword pairs that indicate violation of a fact.
const _contradictionPatterns = <String, List<String>>{
  'lost her left arm': ['左手', '伸出左臂', '左手接', '左手握', '左手拿'],
  'lost his left arm': ['左手', '伸出左臂'],
  'is dead': ['复活', '站起来', '走回来'],
  'destroyed': ['重建', '完好无损'],
};

/// Consistency patterns: text that acknowledges the fact correctly.
const _consistencyPatterns = <String, List<String>>{
  'lost her left arm': ['空荡的左袖', '断臂', '失去左臂', '右手握剑'],
  'lost his left arm': ['空荡的左袖', '断臂'],
  'is dead': ['遗体', '墓碑', '祭奠'],
  'destroyed': ['废墟', '残垣断壁'],
};

class ContinuityGate {
  const ContinuityGate();

  /// Produces hard constraints for the generation prompt.
  List<ContinuityConstraint> preGenerationConstraints({
    required List<ContinuityFact> facts,
    required int targetChapter,
  }) {
    return facts
        .where((f) => f.confirmed && f.isValidAt(targetChapter))
        .map((f) => ContinuityConstraint(
              factId: f.id,
              entityId: f.entityId,
              claim: f.claim,
              blocking: f.severity == ContinuitySeverity.critical ||
                  f.severity == ContinuitySeverity.high,
            ))
        .toList();
  }

  /// Detects continuity issues in generated text against known facts.
  List<ContinuityIssue> detectIssues({
    required String generatedText,
    required List<ContinuityFact> facts,
    required int chapter,
    required List<EntityMention> entityMentions,
  }) {
    final issues = <ContinuityIssue>[];
    final mentionedEntities = entityMentions.map((m) => m.entityId).toSet();

    for (final fact in facts) {
      if (!fact.confirmed || !fact.isValidAt(chapter)) continue;
      if (!mentionedEntities.contains(fact.entityId)) continue;

      // Check if text is consistent (acknowledges the fact)
      final consistencyKeys = _consistencyPatterns.keys.where(
        (k) => fact.claim.toLowerCase().contains(k),
      );
      var isConsistent = false;
      for (final key in consistencyKeys) {
        for (final pattern in _consistencyPatterns[key]!) {
          if (generatedText.contains(pattern)) {
            isConsistent = true;
            break;
          }
        }
        if (isConsistent) break;
      }
      if (isConsistent) continue;

      // Check for contradiction patterns
      final contradictionKeys = _contradictionPatterns.keys.where(
        (k) => fact.claim.toLowerCase().contains(k),
      );
      for (final key in contradictionKeys) {
        for (final pattern in _contradictionPatterns[key]!) {
          if (generatedText.contains(pattern)) {
            issues.add(ContinuityIssue(
              factId: fact.id,
              entityId: fact.entityId,
              description:
                  'Generated text contradicts: ${fact.claim}',
              evidence: pattern,
              severity: fact.severity,
              proposedAction: fact.severity == ContinuitySeverity.critical
                  ? ContinuityAction.blockAdoption
                  : ContinuityAction.requireConfirmation,
              requiresOverride:
                  fact.severity == ContinuitySeverity.critical ||
                      fact.severity == ContinuitySeverity.high,
            ));
            break;
          }
        }
      }
    }

    return issues;
  }

  /// Makes an adoption decision based on detected issues.
  AdoptionDecision adoptionDecision(
    List<ContinuityIssue> issues, {
    Set<String> overriddenFactIds = const {},
  }) {
    final blocking = issues
        .where((i) =>
            i.proposedAction == ContinuityAction.blockAdoption &&
            !overriddenFactIds.contains(i.factId))
        .toList();
    final warnings = issues
        .where((i) => i.proposedAction == ContinuityAction.warn)
        .toList();

    return AdoptionDecision(
      canAdopt: blocking.isEmpty,
      blockingIssues: blocking,
      warnings: warnings,
    );
  }
}
