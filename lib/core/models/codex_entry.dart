import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum CodexEntryType { character, location, lore, plotNode }

class CodexEntry {
  final String id;
  final String projectId;
  final CodexEntryType type;
  String name;
  String description;
  Map<String, dynamic> attributes;
  final DateTime createdAt;
  DateTime updatedAt;

  CodexEntry({
    String? id,
    required this.projectId,
    required this.type,
    required this.name,
    this.description = '',
    Map<String, dynamic>? attributes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        attributes = attributes ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'type': type.name,
        'name': name,
        'description': description,
        'attributes': attributes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CodexEntry.fromJson(Map<String, dynamic> json) => CodexEntry(
        id: json['id'] as String?,
        projectId: json['projectId'] as String,
        type: CodexEntryType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CodexEntryType.lore,
        ),
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  CodexEntry copyWith({
    String? name,
    String? description,
    Map<String, dynamic>? attributes,
  }) =>
      CodexEntry(
        id: id,
        projectId: projectId,
        type: type,
        name: name ?? this.name,
        description: description ?? this.description,
        attributes: attributes ?? this.attributes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
