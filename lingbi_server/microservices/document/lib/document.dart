/// Represents a document in the system.
class Document {
  final String id;
  final String projectId;
  final String title;
  final String filePath;
  final int wordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.projectId,
    required this.title,
    required this.filePath,
    required this.wordCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Document from JSON.
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      filePath: json['file_path'] as String,
      wordCount: json['word_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts the Document to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'file_path': filePath,
      'word_count': wordCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this document with updated fields.
  Document copyWith({
    String? id,
    String? projectId,
    String? title,
    String? filePath,
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
