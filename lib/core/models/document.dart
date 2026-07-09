import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Document {
  Document({
    String? id,
    required this.projectId,
    required this.title,
    required this.filePath,
    this.wordCount = 0,
    this.currentSceneId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String,
        wordCount: json['wordCount'] as int? ?? 0,
        currentSceneId: json['currentSceneId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
  final String id;
  String projectId;
  String title;
  String filePath;
  int wordCount;
  String? currentSceneId;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'filePath': filePath,
        'wordCount': wordCount,
        'currentSceneId': currentSceneId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
