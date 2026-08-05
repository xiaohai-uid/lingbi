/// Experience outcome recorded by the routing journal.
enum ExperienceOutcome { completed, miss, failed }

/// A reusable routing experience entry.
class ExperienceEntry {
  const ExperienceEntry({
    required this.id,
    required this.scene,
    required this.userMessage,
    required this.outcome,
    this.summary = '',
    this.nodeChain = const [],
    this.outputGateResult,
    this.createdAt,
  });

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) {
    return ExperienceEntry(
      id: json['id'] as String,
      scene: json['scene'] as String,
      userMessage: json['userMessage'] as String,
      outcome: ExperienceOutcome.values.firstWhere(
        (e) => e.name == json['outcome'],
      ),
      summary: json['summary'] as String? ?? '',
      nodeChain: (json['nodeChain'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      outputGateResult: json['outputGateResult'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  final String id;
  final String scene;
  final String userMessage;
  final ExperienceOutcome outcome;
  final String summary;
  final List<String> nodeChain;
  final String? outputGateResult;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'scene': scene,
        'userMessage': userMessage,
        'outcome': outcome.name,
        'summary': summary,
        'nodeChain': nodeChain,
        if (outputGateResult != null) 'outputGateResult': outputGateResult,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
