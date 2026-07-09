/// Canon（知识体系）模型
///
/// v4.0 替代旧的 CodexEntry。
/// Canon 是世界观知识的统一容器，包含四个子类型。
library canon_entry;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Canon 条目类型
enum CanonType { character, location, lore, worldRule }

/// Canon 条目抽象父类
///
/// 所有世界观知识条目的基类。
/// 子类：Character, Location, Lore, WorldRule
abstract class CanonEntry {
  CanonEntry({
    String? id,
    required this.worldId,
    required this.type,
    required this.name,
    this.description = '',
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  final String id;
  final String worldId;
  String name;
  String description;
  final CanonType type;
  List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson();
}

/// 角色
class Character extends CanonEntry {
  // hero / mentor / ally / villain / etc.

  Character({
    super.id,
    required super.worldId,
    required super.name,
    super.description,
    super.tags,
    this.appearance = '',
    this.personality = '',
    this.background = '',
    this.archetype = '',
    super.createdAt,
    super.updatedAt,
  }) : super(type: CanonType.character);

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: json['id'] as String,
        worldId: json['worldId'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        appearance: json['appearance'] as String? ?? '',
        personality: json['personality'] as String? ?? '',
        background: json['background'] as String? ?? '',
        archetype: json['archetype'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
  String appearance;
  String personality;
  String background;
  String archetype;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'worldId': worldId,
        'type': 'character',
        'name': name,
        'description': description,
        'tags': tags,
        'appearance': appearance,
        'personality': personality,
        'background': background,
        'archetype': archetype,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// 地点
class Location extends CanonEntry {
  Location({
    super.id,
    required super.worldId,
    required super.name,
    super.description,
    super.tags,
    this.atmosphere = '',
    this.associatedEvents = const [],
    super.createdAt,
    super.updatedAt,
  }) : super(type: CanonType.location);

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['id'] as String,
        worldId: json['worldId'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        atmosphere: json['atmosphere'] as String? ?? '',
        associatedEvents:
            (json['associatedEvents'] as List?)?.cast<String>() ?? [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
  String atmosphere;
  List<String> associatedEvents;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'worldId': worldId,
        'type': 'location',
        'name': name,
        'description': description,
        'tags': tags,
        'atmosphere': atmosphere,
        'associatedEvents': associatedEvents,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// 传说/设定
class Lore extends CanonEntry {
  // history / magic / technology / religion / etc.

  Lore({
    super.id,
    required super.worldId,
    required super.name,
    super.description,
    super.tags,
    this.category = '',
    super.createdAt,
    super.updatedAt,
  }) : super(type: CanonType.lore);

  factory Lore.fromJson(Map<String, dynamic> json) => Lore(
        id: json['id'] as String,
        worldId: json['worldId'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        category: json['category'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
  String category;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'worldId': worldId,
        'type': 'lore',
        'name': name,
        'description': description,
        'tags': tags,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// 世界规则
class WorldRule extends CanonEntry {
  // 硬规则(不可打破) vs 软规则

  WorldRule({
    super.id,
    required super.worldId,
    required super.name,
    super.description,
    super.tags,
    this.scope = '',
    this.isHardRule = false,
    super.createdAt,
    super.updatedAt,
  }) : super(type: CanonType.worldRule);

  factory WorldRule.fromJson(Map<String, dynamic> json) => WorldRule(
        id: json['id'] as String,
        worldId: json['worldId'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        scope: json['scope'] as String? ?? '',
        isHardRule: json['isHardRule'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
  String scope; // 适用场景/卷ID, '' 表示全局
  bool isHardRule;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'worldId': worldId,
        'type': 'worldRule',
        'name': name,
        'description': description,
        'tags': tags,
        'scope': scope,
        'isHardRule': isHardRule,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
