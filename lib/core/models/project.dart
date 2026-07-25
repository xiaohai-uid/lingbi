import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Project {

  Project({
    String? id,
    required this.name,
    this.description = '',
    required this.directoryPath,
    this.targetPlatform = '',
    this.genre = '',
    this.audience = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        directoryPath: json['directoryPath'] as String,
        targetPlatform: json['targetPlatform'] as String? ?? '',
        genre: json['genre'] as String? ?? '',
        audience: json['audience'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
  final String id;
  String name;
  String description;
  String directoryPath;

  /// 目标发布平台（起点中文网/番茄小说/七猫等）
  String targetPlatform;

  /// 题材（玄幻/都市/悬疑/言情等）
  String genre;

  /// 目标读者画像（如 "18-25岁男性"）
  String audience;

  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'directoryPath': directoryPath,
        'targetPlatform': targetPlatform,
        'genre': genre,
        'audience': audience,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
