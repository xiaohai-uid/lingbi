/// 势力/组织模型
library faction;

/// 势力类型
enum FactionType {
  sect('sect', '宗门'),
  nation('nation', '国家'),
  clan('clan', '家族'),
  organization('organization', '组织');

  const FactionType(this.value, this.displayName);
  final String value;
  final String displayName;

  static FactionType fromString(String s) =>
      values.firstWhere((t) => t.value == s, orElse: () => organization);
}

/// 势力
class Faction {
  Faction({
    String? id,
    required this.name,
    this.description = '',
    this.type = FactionType.sect,
    this.power = 50,
    this.territory = '',
    this.memberIds = const [],
    this.allyIds = const [],
    this.rivalIds = const [],
    this.resources = const {},
  }) : id = id ?? _generateId(name);

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        type: FactionType.fromString(json['type'] as String? ?? ''),
        power: json['power'] as int? ?? 50,
        territory: json['territory'] as String? ?? '',
        memberIds: (json['memberIds'] as List?)?.cast<String>() ?? [],
        allyIds: (json['allyIds'] as List?)?.cast<String>() ?? [],
        rivalIds: (json['rivalIds'] as List?)?.cast<String>() ?? [],
        resources: (json['resources'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as int),
            ) ??
            {},
      );
  final String id;
  final String name;
  final String description;
  final FactionType type;
  final int power; // 1-100
  final String territory;
  final List<String> memberIds;
  final List<String> allyIds;
  final List<String> rivalIds;
  final Map<String, int> resources;

  static String _generateId(String name) =>
      'fac-${name.hashCode.toRadixString(16)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.value,
        'power': power,
        'territory': territory,
        'memberIds': memberIds,
        'allyIds': allyIds,
        'rivalIds': rivalIds,
        'resources': resources,
      };
}
