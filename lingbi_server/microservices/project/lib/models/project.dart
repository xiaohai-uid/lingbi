import 'package:sqlite3/sqlite3.dart';

/// Project model representing a Lingbi project.
class Project {
  final int? id;
  final String name;
  final String description;
  final String directoryPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    this.id,
    required this.name,
    required this.description,
    required this.directoryPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a Project from a database row.
  factory Project.fromRow(Row row) {
    return Project(
      id: row.read<int?>('id'),
      name: row.read<String>('name'),
      description: row.read<String>('description'),
      directoryPath: row.read<String>('directory_path'),
      createdAt: DateTime.parse(row.read<String>('created_at')),
      updatedAt: DateTime.parse(row.read<String>('updated_at')),
    );
  }

  /// Convert Project to a map for JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'directoryPath': directoryPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this Project with updated fields.
  Project copyWith({
    int? id,
    String? name,
    String? description,
    String? directoryPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      directoryPath: directoryPath ?? this.directoryPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}