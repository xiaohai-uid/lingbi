/// A suggestion generated after repeated route misses in one scene.
final class SkillSuggestion {
  const SkillSuggestion({
    required this.scene,
    required this.count,
    required this.suggestedSkillId,
    this.exampleUserMessage,
  });

  final String scene;
  final int count;
  final String suggestedSkillId;
  final String? exampleUserMessage;
}

/// Aggregates route misses and emits skill suggestions after a threshold.
class RouteMissAggregator {
  RouteMissAggregator({this.threshold = 3});

  final int threshold;
  final Map<String, _MissBucket> _buckets = {};

  int countFor(String scene) => _buckets[scene]?.count ?? 0;

  void recordMiss({required String scene, String userMessage = ''}) {
    final bucket = _buckets.putIfAbsent(
      scene,
      () => _MissBucket(scene: scene),
    );
    bucket.count += 1;
    if (userMessage.isNotEmpty && bucket.exampleUserMessage == null) {
      bucket.exampleUserMessage = userMessage;
    }
  }

  List<SkillSuggestion> suggestions({String? scene}) {
    final buckets = _buckets.values
        .where((b) => scene == null || b.scene == scene)
        .where((b) => b.count >= threshold);
    return buckets
        .map(
          (b) => SkillSuggestion(
            scene: b.scene,
            count: b.count,
            suggestedSkillId: 'skill:${b.scene}',
            exampleUserMessage: b.exampleUserMessage,
          ),
        )
        .toList();
  }

  void reset({String? scene}) {
    if (scene == null) {
      _buckets.clear();
    } else {
      _buckets.remove(scene);
    }
  }
}

final class _MissBucket {
  _MissBucket({required this.scene});

  final String scene;
  int count = 0;
  String? exampleUserMessage;
}
