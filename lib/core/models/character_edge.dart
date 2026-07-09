/// 角色关系模型
library character_edge;

/// 关系类型
enum RelationshipType {
  mentor('mentor', '师徒'),
  rival('rival', '敌对'),
  lover('lover', '恋人'),
  family('family', '家族'),
  servant('servant', '主仆'),
  ally('ally', '盟友'),
  neutral('neutral', '中立');

  const RelationshipType(this.value, this.displayName);
  final String value;
  final String displayName;

  static RelationshipType fromString(String s) =>
      RelationshipType.values.firstWhere(
        (t) => t.value == s,
        orElse: () => RelationshipType.neutral,
      );
}

/// 角色关系边
class CharacterEdge {
  // 关联事件 ID

  const CharacterEdge({
    required this.sourceId,
    required this.targetId,
    required this.type,
    this.strength = 5,
    this.description = '',
    this.events = const [],
  });

  factory CharacterEdge.fromJson(Map<String, dynamic> json) => CharacterEdge(
        sourceId: json['sourceId'] as String,
        targetId: json['targetId'] as String,
        type: RelationshipType.fromString(json['type'] as String? ?? ''),
        strength: json['strength'] as int? ?? 5,
        description: json['description'] as String? ?? '',
        events: (json['events'] as List?)?.cast<String>() ?? [],
      );
  final String sourceId;
  final String targetId;
  final RelationshipType type;
  final int strength; // 1-10
  final String description;
  final List<String> events;

  /// 反转方向
  CharacterEdge reverse() => CharacterEdge(
        sourceId: targetId,
        targetId: sourceId,
        type: type,
        strength: strength,
        description: description,
        events: events,
      );

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'targetId': targetId,
        'type': type.value,
        'strength': strength,
        'description': description,
        'events': events,
      };
}
