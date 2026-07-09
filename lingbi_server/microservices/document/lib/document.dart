/// Represents a document in the system.
class Document {
  final String id;
  final String projectId;
  String title;
  String content;
  int wordCount;
  DateTime createdAt;
  DateTime updatedAt;

  Document({
    required this.id,
    required this.projectId,
    required this.title,
    required this.content,
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
      content: json['content'] as String? ?? '',
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
      'content': content,
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
    String? content,
    int? wordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculates word count from content.
  /// A word is a sequence of non-whitespace characters (handles both CJK and Latin text).
  static int calculateWordCount(String content) {
    if (content.isEmpty) return 0;

    // For Chinese/Japanese text, count each character as one word.
    // For Latin text, split on whitespace.
    // Use a regex that matches CJK characters individually or Latin "words".
    final cjkChars = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]');
    int count = 0;

    // Count CJK characters
    for (final match in cjkChars.allMatches(content)) {
      count++;
    }

    // Remove CJK characters and count Latin words
    final latinOnly = content.replaceAll(cjkChars, ' ');
    final words = latinOnly.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    count += words.length;

    return count;
  }
}
