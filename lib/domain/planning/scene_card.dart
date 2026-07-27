/// Scene card domain model for the planning matrix.
library;

import 'dart:convert';

class SceneCard {
  const SceneCard({
    required this.id,
    required this.projectId,
    required this.title,
    required this.chapterIndex,
    required this.revision,
    this.povCharacter,
    this.location,
    this.subplot,
    this.summary,
    this.beats = const [],
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final int chapterIndex;
  final int revision;
  final String? povCharacter;
  final String? location;
  final String? subplot;
  final String? summary;
  final List<String> beats;
  final DateTime? updatedAt;

  SceneCard copyWith({
    String? title,
    int? chapterIndex,
    int? revision,
    String? povCharacter,
    String? location,
    String? subplot,
    String? summary,
    List<String>? beats,
    DateTime? updatedAt,
  }) {
    return SceneCard(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      revision: revision ?? this.revision,
      povCharacter: povCharacter ?? this.povCharacter,
      location: location ?? this.location,
      subplot: subplot ?? this.subplot,
      summary: summary ?? this.summary,
      beats: beats ?? this.beats,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'chapter_index': chapterIndex,
        'revision': revision,
        'pov_character': povCharacter,
        'location': location,
        'subplot': subplot,
        'summary': summary,
        'beats': beats,
        'updated_at': updatedAt?.toUtc().toIso8601String(),
      };

  factory SceneCard.fromJson(Map<String, dynamic> json) => SceneCard(
        id: json['id'] as String,
        projectId: json['project_id'] as String,
        title: json['title'] as String,
        chapterIndex: json['chapter_index'] as int,
        revision: json['revision'] as int,
        povCharacter: json['pov_character'] as String?,
        location: json['location'] as String?,
        subplot: json['subplot'] as String?,
        summary: json['summary'] as String?,
        beats: (json['beats'] as List? ?? const []).cast<String>(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  String serialize() => jsonEncode(toJson());

  factory SceneCard.deserialize(String raw) =>
      SceneCard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class RevisionConflictException implements Exception {
  const RevisionConflictException(this.message);
  final String message;
  @override
  String toString() => 'RevisionConflictException: $message';
}
