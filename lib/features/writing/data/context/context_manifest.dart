/// Explainable context manifest for the ContextCompiler.
///
/// Every entry records its source, reason for inclusion, time point,
/// priority, token cost, and truncation status so the UI inspector
/// can show the author exactly why each piece of context was included.
library;

enum ContextPriority {
  mandatory,
  high,
  medium,
  low;

  int get weight => switch (this) {
        ContextPriority.mandatory => 100,
        ContextPriority.high => 75,
        ContextPriority.medium => 50,
        ContextPriority.low => 25,
      };
}

enum TruncationStatus { full, truncated, omitted }

/// A single context entry submitted to the compiler.
class ContextEntry {
  const ContextEntry({
    required this.id,
    required this.source,
    required this.reason,
    required this.timePoint,
    required this.priority,
    required this.content,
  });

  final String id;
  final String source;
  final String reason;
  final int? timePoint;
  final ContextPriority priority;
  final String content;

  int get rawTokenEstimate => estimateTokens(content);

  static int estimateTokens(String text) {
    // Rough CJK-aware estimate: ~1.5 tokens per CJK char, ~0.25 per ASCII word
    var cjk = 0;
    var ascii = 0;
    for (final code in text.runes) {
      if (code >= 0x4E00 && code <= 0x9FFF ||
          code >= 0x3400 && code <= 0x4DBF ||
          code >= 0xF900 && code <= 0xFAFF) {
        cjk++;
      } else {
        ascii++;
      }
    }
    return (cjk * 1.5 + ascii * 0.25).ceil().clamp(1, 1 << 30);
  }
}

/// A compiled entry with allocation metadata.
class CompiledEntry {
  const CompiledEntry({
    required this.id,
    required this.source,
    required this.reason,
    required this.timePoint,
    required this.priority,
    required this.content,
    required this.allocatedTokens,
    required this.truncationStatus,
  });

  final String id;
  final String source;
  final String reason;
  final int? timePoint;
  final ContextPriority priority;
  final String content;
  final int allocatedTokens;
  final TruncationStatus truncationStatus;
}

/// Records why a source was omitted from the final context.
class ContextOmission {
  const ContextOmission({
    required this.sourceId,
    required this.reason,
    required this.originalTokens,
  });

  final String sourceId;
  final String reason;
  final int originalTokens;
}

/// Manifest entry for the inspector UI.
class ManifestEntry {
  const ManifestEntry({
    required this.source,
    required this.reason,
    required this.tokenCost,
    required this.truncationStatus,
  });

  final String source;
  final String reason;
  final int tokenCost;
  final TruncationStatus truncationStatus;
}

/// The full manifest produced by a compilation pass.
class ContextManifest {
  const ContextManifest({
    required this.entries,
    required this.totalTokens,
    required this.budget,
  });

  final List<ManifestEntry> entries;
  final int totalTokens;
  final int budget;
}
