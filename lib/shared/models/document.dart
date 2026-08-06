import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Document {

  Document({
    String? id,
    required this.projectId,
    required this.title,
    required this.filePath,
    this.wordCount = 0,
    this.order = 0,
    this.revision = 0,
    this.contentHash = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        projectId: (json['projectId'] ?? json['project_id']) as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String? ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        revision: (json['revision'] as num?)?.toInt() ?? 0,
        contentHash: (json['contentHash'] ?? json['content_hash']) as String? ?? '',
        wordCount: json['wordCount'] as int? ?? 0,
        createdAt: DateTime.parse(
            (json['createdAt'] ?? json['created_at']) as String),
        updatedAt: DateTime.parse(
            (json['updatedAt'] ?? json['updated_at']) as String),
      );
  final String id;
  String projectId;
  String title;
  String filePath;
  int wordCount;
  int order;
  int revision;
  String contentHash;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'filePath': filePath,
        'wordCount': wordCount,
        'order': order,
        'revision': revision,
        'contentHash': contentHash,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
