import 'package:lingbi/modules/story_graph/story_graph.dart';

final class EntityMention {
  const EntityMention({
    required this.entityId,
    required this.canonicalName,
    required this.matchedText,
    required this.range,
    required this.confidence,
  });

  final String entityId;
  final String canonicalName;
  final String matchedText;
  final SourceRange range;
  final double confidence;
}

/// Deterministic local linker: longest known name wins at overlapping ranges.
final class TextEntityLinker {
  const TextEntityLinker();

  List<EntityMention> link(String text, Iterable<StoryEntity> entities) {
    final candidates = <EntityMention>[];
    for (final entity in entities) {
      final names = <String>{entity.canonicalName, ...entity.aliases};
      for (final name in names) {
        final normalized = name.trim();
        if (normalized.length < 2) continue;
        var start = text.indexOf(normalized);
        while (start >= 0) {
          candidates.add(
            EntityMention(
              entityId: entity.id,
              canonicalName: entity.canonicalName,
              matchedText: normalized,
              range: SourceRange(start: start, end: start + normalized.length),
              confidence: normalized == entity.canonicalName ? 1 : 0.98,
            ),
          );
          start = text.indexOf(normalized, start + normalized.length);
        }
      }
    }

    candidates.sort((left, right) {
      final byLength = (right.range.end - right.range.start)
          .compareTo(left.range.end - left.range.start);
      if (byLength != 0) return byLength;
      final byStart = left.range.start.compareTo(right.range.start);
      if (byStart != 0) return byStart;
      return left.entityId.compareTo(right.entityId);
    });

    final selected = <EntityMention>[];
    for (final candidate in candidates) {
      final overlaps = selected.any(
        (mention) =>
            candidate.range.start < mention.range.end &&
            mention.range.start < candidate.range.end,
      );
      if (!overlaps) selected.add(candidate);
    }
    selected
        .sort((left, right) => left.range.start.compareTo(right.range.start));
    return List.unmodifiable(selected);
  }
}
