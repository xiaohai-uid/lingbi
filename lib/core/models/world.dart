/// 世界模型 — World 顶层容器
///
/// v4.0 替代旧的 Project 成为系统根实体。
/// 一个 World 可包含多个 Work（叙事作品）。
library world;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 世界元数据
///
/// 以 world.json 文件存储在 `Documents/灵笔/Worlds/{id}/` 目录下。
class World {
  World({
    String? id,
    required this.name,
    this.description = '',
    this.genres = const [],
    this.timelineMode = 'linear',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory World.fromJson(Map<String, dynamic> json) => World(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        genres: (json['genres'] as List?)?.cast<String>() ?? [],
        timelineMode: json['timelineMode'] as String? ?? 'linear',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
  final String id;
  String name;
  String description;
  List<String> genres;
  String timelineMode; // linear | branch | tree
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'genres': genres,
        'timelineMode': timelineMode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  World copyWith({
    String? name,
    String? description,
    List<String>? genres,
    String? timelineMode,
  }) =>
      World(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        genres: genres ?? this.genres,
        timelineMode: timelineMode ?? this.timelineMode,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
