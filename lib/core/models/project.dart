import 'package:uuid/uuid.dart';

const _uuid = Uuid();

@Deprecated(
    'Use World from core/models/world.dart instead. Project is replaced by World + Work in v4.0')
class Project {
  @Deprecated('Use World from core/models/world.dart instead')
  Project({
    String? id,
    required this.name,
    this.description = '',
    required this.directoryPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @Deprecated('Use World.fromJson instead')
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        directoryPath: json['directoryPath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
  final String id;
  String name;
  String description;
  String directoryPath;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'directoryPath': directoryPath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
