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
    this.templateId = '',
    this.targetLength,
    this.premise = '',
    this.briefRevision = 0,
    this.provenance,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Project.fromJson(Map<String, dynamic> json) {
    final brief = json['projectBrief'] is Map<String, dynamic>
        ? json['projectBrief'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return Project(
      id: json['id'] as String,
      name: (brief['title'] ?? json['name']) as String,
      description: json['description'] as String? ?? '',
      directoryPath: json['directoryPath'] as String,
      targetPlatform:
          (brief['targetPlatform'] ?? json['targetPlatform']) as String? ?? '',
      genre: (brief['genreId'] ?? json['genre']) as String? ?? '',
      audience: (brief['audience'] ?? json['audience']) as String? ?? '',
      templateId: brief['templateId'] as String? ?? '',
      targetLength: brief['targetLength'] as int?,
      premise:
          brief['premise'] as String? ?? json['description'] as String? ?? '',
      briefRevision: brief['revision'] as int? ?? 0,
      provenance: json['provenance'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  final String id;
  String name;
  String description;
  String directoryPath;

  /// 独立副本来源标记，如 `copy-of:<原项目id>`。null = 原创项目。
  String? provenance;

  /// 目标发布平台（起点中文网/番茄小说/七猫等）
  String targetPlatform;

  /// 题材（玄幻/都市/悬疑/言情等）
  String genre;

  /// 目标读者画像（如 "18-25岁男性"）
  String audience;

  String templateId;
  int? targetLength;
  String premise;
  int briefRevision;

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
        'templateId': templateId,
        if (targetLength != null) 'targetLength': targetLength,
        'premise': premise,
        'briefRevision': briefRevision,
        if (provenance != null) 'provenance': provenance,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
