import 'dart:convert';

/// Project model representing a Lingbi project.
class Project {
  final String id;
  String name;
  String description;
  DateTime createdAt;
  DateTime updatedAt;
  int documentCount;
  Map<String, List<String>> treeStructure; // folderId -> [docId]

  Project({
    required this.id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.documentCount = 0,
    Map<String, List<String>>? treeStructure,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        treeStructure = treeStructure ?? {};

  /// Create a Project from a JSON map.
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      documentCount: json['document_count'] as int? ?? 0,
      treeStructure: (json['tree_structure'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, List<String>.from(v as List))) ??
          {},
    );
  }

  /// Convert Project to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'document_count': documentCount,
      'tree_structure': treeStructure.map((k, v) => MapEntry(k, v)),
    };
  }

  /// Create a copy of this Project with updated fields.
  Project copyWith({
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? documentCount,
    Map<String, List<String>>? treeStructure,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentCount: documentCount ?? this.documentCount,
      treeStructure: treeStructure ?? Map.from(this.treeStructure),
    );
  }

  @override
  String toString() => 'Project(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Project && id == other.id;

  @override
  int get hashCode => id.hashCode;
}