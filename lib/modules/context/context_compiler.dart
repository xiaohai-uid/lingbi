/// Explainable context compiler with deterministic budget allocation.
///
/// Replaces the opaque token-budget trimming in ContextAssembler with a
/// transparent, priority-weighted allocation that records every decision.
library;

import 'context_manifest.dart';

export 'context_manifest.dart';

class CompilerConfig {
  const CompilerConfig({
    this.tokenBudget = 8000,
    this.mandatoryReserveRatio = 0.15,
  });

  final int tokenBudget;
  final double mandatoryReserveRatio;
}

/// The result of a compilation pass.
class CompiledContext {
  const CompiledContext({
    required this.text,
    required this.entries,
    required this.tokenEstimate,
    required this.omissions,
    required this.manifest,
  });

  final String text;
  final List<CompiledEntry> entries;
  final int tokenEstimate;
  final List<ContextOmission> omissions;
  final ContextManifest manifest;
}

class ContextCompiler {
  const ContextCompiler({required this.config});

  final CompilerConfig config;

  CompiledContext compile(List<ContextEntry> entries, {int? currentChapter}) {
    if (entries.isEmpty) {
      return const CompiledContext(
        text: '',
        entries: [],
        tokenEstimate: 0,
        omissions: [],
        manifest: ContextManifest(entries: [], totalTokens: 0, budget: 0),
      );
    }

    final budget = config.tokenBudget;

    // Score each entry: priority weight + recency bonus
    final scored = entries.map((e) {
      final recencyBonus = _recencyScore(e.timePoint, currentChapter);
      return _ScoredEntry(
        entry: e,
        score: e.priority.weight + recencyBonus,
        rawTokens: e.rawTokenEstimate,
      );
    }).toList();

    // Sort by score descending, then by id for determinism
    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.entry.id.compareTo(b.entry.id);
    });

    // Phase 1: mandatory entries get first access to the available budget.
    var remaining = budget;
    final allocations = <String, int>{};
    final statuses = <String, TruncationStatus>{};

    for (final s in scored) {
      if (s.entry.priority == ContextPriority.mandatory) {
        final alloc = s.rawTokens.clamp(0, remaining);
        allocations[s.entry.id] = alloc;
        statuses[s.entry.id] =
            alloc >= s.rawTokens ? TruncationStatus.full : TruncationStatus.truncated;
        remaining -= alloc;
      }
    }

    // Phase 2: distribute remaining budget proportionally by score
    final nonMandatory = scored
        .where((s) => s.entry.priority != ContextPriority.mandatory)
        .toList();
    final totalScore = nonMandatory.fold<double>(0, (sum, s) => sum + s.score);

    for (final s in nonMandatory) {
      if (remaining <= 0) {
        allocations[s.entry.id] = 0;
        statuses[s.entry.id] = TruncationStatus.omitted;
        continue;
      }
      final share = totalScore > 0
          ? (remaining * s.score / totalScore).ceil()
          : 0;
      final alloc = share.clamp(0, s.rawTokens).clamp(0, remaining);
      allocations[s.entry.id] = alloc;
      statuses[s.entry.id] = alloc >= s.rawTokens
          ? TruncationStatus.full
          : alloc > 0
              ? TruncationStatus.truncated
              : TruncationStatus.omitted;
      remaining -= alloc;
    }

    // Build compiled entries in original order
    final compiledEntries = <CompiledEntry>[];
    final omissions = <ContextOmission>[];
    final manifestEntries = <ManifestEntry>[];
    final textParts = <String>[];
    var totalAllocated = 0;

    for (final entry in entries) {
      final alloc = allocations[entry.id] ?? 0;
      final status = statuses[entry.id] ?? TruncationStatus.omitted;
      final content = _truncateToTokens(entry.content, alloc);

      compiledEntries.add(CompiledEntry(
        id: entry.id,
        source: entry.source,
        reason: entry.reason,
        timePoint: entry.timePoint,
        priority: entry.priority,
        content: content,
        allocatedTokens: alloc,
        truncationStatus: status,
      ));

      manifestEntries.add(ManifestEntry(
        source: entry.source,
        reason: entry.reason,
        tokenCost: alloc,
        truncationStatus: status,
      ));

      if (status == TruncationStatus.omitted) {
        omissions.add(ContextOmission(
          sourceId: entry.source,
          reason: 'Budget exhausted; priority score too low for allocation',
          originalTokens: entry.rawTokenEstimate,
        ));
      } else if (status == TruncationStatus.truncated) {
        omissions.add(ContextOmission(
          sourceId: entry.source,
          reason:
              'Truncated from ${entry.rawTokenEstimate} to $alloc tokens by budget',
          originalTokens: entry.rawTokenEstimate - alloc,
        ));
      }
      if (content.isNotEmpty) {
        textParts.add(content);
        totalAllocated += alloc;
      }
    }

    return CompiledContext(
      text: textParts.join('\n\n'),
      entries: compiledEntries,
      tokenEstimate: totalAllocated,
      omissions: omissions,
      manifest: ContextManifest(
        entries: manifestEntries,
        totalTokens: totalAllocated,
        budget: budget,
      ),
    );
  }

  double _recencyScore(int? timePoint, int? currentChapter) {
    if (timePoint == null || currentChapter == null) return 0;
    final distance = (currentChapter - timePoint).abs();
    // Closer chapters get higher recency bonus (max 20)
    return (20.0 / (1 + distance * 0.1)).clamp(0, 20);
  }

  String _truncateToTokens(String content, int maxTokens) {
    if (maxTokens <= 0) return '';
    final estimated = ContextEntry.estimateTokens(content);
    if (estimated <= maxTokens) return content;
    // Approximate character cut: ratio of maxTokens to estimated
    final ratio = maxTokens / estimated;
    final cutChars = (content.length * ratio).floor();
    return '${content.substring(0, cutChars.clamp(0, content.length))}...';
  }
}

class _ScoredEntry {
  const _ScoredEntry({
    required this.entry,
    required this.score,
    required this.rawTokens,
  });

  final ContextEntry entry;
  final double score;
  final int rawTokens;
}
