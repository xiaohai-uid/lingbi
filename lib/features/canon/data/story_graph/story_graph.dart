enum StoryEntityType {
  character,
  location,
  lore,
  plotNode,
  faction,
  object,
  event,
  custom,
}

enum ConfirmationStatus { pending, confirmed, rejected }

final class SourceRange {
  const SourceRange({required this.start, required this.end})
      : assert(start >= 0),
        assert(end >= start);

  factory SourceRange.fromJson(Map<String, dynamic> json) => SourceRange(
        start: json['start'] as int? ?? 0,
        end: json['end'] as int? ?? 0,
      );

  final int start;
  final int end;

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  @override
  bool operator ==(Object other) =>
      other is SourceRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

final class StoryEntity {
  const StoryEntity({
    required this.id,
    required this.type,
    required this.canonicalName,
    this.aliases = const [],
    this.attributes = const {},
  });

  factory StoryEntity.fromJson(Map<String, dynamic> json) => StoryEntity(
        id: json['id'] as String,
        type: StoryEntityType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => StoryEntityType.custom,
        ),
        canonicalName: json['canonicalName'] as String,
        aliases: (json['aliases'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        attributes:
            Map<String, dynamic>.from(json['attributes'] as Map? ?? const {}),
      );

  final String id;
  final StoryEntityType type;
  final String canonicalName;
  final List<String> aliases;
  final Map<String, dynamic> attributes;

  Iterable<String> get names => {canonicalName, ...aliases};

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'canonicalName': canonicalName,
        'aliases': aliases,
        'attributes': attributes,
      };
}

final class StoryFact {
  const StoryFact({
    required this.id,
    required this.entityId,
    required this.predicate,
    required this.value,
    required this.validFromChapter,
    this.validToChapter,
    required this.sourceDocumentId,
    required this.sourceRange,
    required this.confidence,
    this.confirmation = ConfirmationStatus.pending,
    this.isRetracted = false,
  })  : assert(validFromChapter >= 0),
        assert(validToChapter == null || validToChapter >= validFromChapter),
        assert(confidence >= 0 && confidence <= 1);

  factory StoryFact.fromJson(Map<String, dynamic> json) => StoryFact(
        id: json['id'] as String,
        entityId: json['entityId'] as String,
        predicate: json['predicate'] as String,
        value: json['value'] as String,
        validFromChapter: json['validFromChapter'] as int? ?? 0,
        validToChapter: json['validToChapter'] as int?,
        sourceDocumentId: json['sourceDocumentId'] as String? ?? '',
        sourceRange: SourceRange.fromJson(
          Map<String, dynamic>.from(
            json['sourceRange'] as Map? ?? const {'start': 0, 'end': 0},
          ),
        ),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
        confirmation: _confirmationFromJson(json['confirmation']),
        isRetracted: json['isRetracted'] as bool? ?? false,
      );

  final String id;
  final String entityId;
  final String predicate;
  final String value;
  final int validFromChapter;
  final int? validToChapter;
  final String sourceDocumentId;
  final SourceRange sourceRange;
  final double confidence;
  final ConfirmationStatus confirmation;
  final bool isRetracted;

  bool isActiveAt(int chapter) =>
      !isRetracted &&
      confirmation == ConfirmationStatus.confirmed &&
      chapter >= validFromChapter &&
      (validToChapter == null || chapter <= validToChapter!);

  StoryFact copyWith({
    ConfirmationStatus? confirmation,
    bool? isRetracted,
  }) =>
      StoryFact(
        id: id,
        entityId: entityId,
        predicate: predicate,
        value: value,
        validFromChapter: validFromChapter,
        validToChapter: validToChapter,
        sourceDocumentId: sourceDocumentId,
        sourceRange: sourceRange,
        confidence: confidence,
        confirmation: confirmation ?? this.confirmation,
        isRetracted: isRetracted ?? this.isRetracted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityId': entityId,
        'predicate': predicate,
        'value': value,
        'validFromChapter': validFromChapter,
        'validToChapter': validToChapter,
        'sourceDocumentId': sourceDocumentId,
        'sourceRange': sourceRange.toJson(),
        'confidence': confidence,
        'confirmation': confirmation.name,
        'isRetracted': isRetracted,
      };
}

final class StoryRelation {
  const StoryRelation({
    required this.id,
    required this.fromEntityId,
    required this.toEntityId,
    required this.predicate,
    required this.validFromChapter,
    this.validToChapter,
    required this.sourceDocumentId,
    required this.sourceRange,
    required this.confidence,
    this.confirmation = ConfirmationStatus.pending,
    this.isRetracted = false,
  })  : assert(validFromChapter >= 0),
        assert(validToChapter == null || validToChapter >= validFromChapter),
        assert(confidence >= 0 && confidence <= 1);

  factory StoryRelation.fromJson(Map<String, dynamic> json) => StoryRelation(
        id: json['id'] as String,
        fromEntityId: json['fromEntityId'] as String,
        toEntityId: json['toEntityId'] as String,
        predicate: json['predicate'] as String,
        validFromChapter: json['validFromChapter'] as int? ?? 0,
        validToChapter: json['validToChapter'] as int?,
        sourceDocumentId: json['sourceDocumentId'] as String? ?? '',
        sourceRange: SourceRange.fromJson(
          Map<String, dynamic>.from(
            json['sourceRange'] as Map? ?? const {'start': 0, 'end': 0},
          ),
        ),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1,
        confirmation: _confirmationFromJson(json['confirmation']),
        isRetracted: json['isRetracted'] as bool? ?? false,
      );

  final String id;
  final String fromEntityId;
  final String toEntityId;
  final String predicate;
  final int validFromChapter;
  final int? validToChapter;
  final String sourceDocumentId;
  final SourceRange sourceRange;
  final double confidence;
  final ConfirmationStatus confirmation;
  final bool isRetracted;

  bool isActiveAt(int chapter) =>
      !isRetracted &&
      confirmation == ConfirmationStatus.confirmed &&
      chapter >= validFromChapter &&
      (validToChapter == null || chapter <= validToChapter!);

  StoryRelation copyWith({
    ConfirmationStatus? confirmation,
    bool? isRetracted,
  }) =>
      StoryRelation(
        id: id,
        fromEntityId: fromEntityId,
        toEntityId: toEntityId,
        predicate: predicate,
        validFromChapter: validFromChapter,
        validToChapter: validToChapter,
        sourceDocumentId: sourceDocumentId,
        sourceRange: sourceRange,
        confidence: confidence,
        confirmation: confirmation ?? this.confirmation,
        isRetracted: isRetracted ?? this.isRetracted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromEntityId': fromEntityId,
        'toEntityId': toEntityId,
        'predicate': predicate,
        'validFromChapter': validFromChapter,
        'validToChapter': validToChapter,
        'sourceDocumentId': sourceDocumentId,
        'sourceRange': sourceRange.toJson(),
        'confidence': confidence,
        'confirmation': confirmation.name,
        'isRetracted': isRetracted,
      };
}

final class StoryGraph {
  const StoryGraph({
    required this.projectId,
    this.schemaVersion = currentStoryGraphSchemaVersion,
    this.revision = 0,
    this.entities = const [],
    this.facts = const [],
    this.relations = const [],
  });

  factory StoryGraph.empty(String projectId) =>
      StoryGraph(projectId: projectId);

  factory StoryGraph.fromJson(Map<String, dynamic> json) => StoryGraph(
        projectId: json['projectId'] as String,
        schemaVersion:
            json['schemaVersion'] as int? ?? currentStoryGraphSchemaVersion,
        revision: json['revision'] as int? ?? 0,
        entities: (json['entities'] as List<dynamic>? ?? const [])
            .map((entry) =>
                StoryEntity.fromJson(Map<String, dynamic>.from(entry as Map)))
            .toList(growable: false),
        facts: (json['facts'] as List<dynamic>? ?? const [])
            .map((entry) =>
                StoryFact.fromJson(Map<String, dynamic>.from(entry as Map)))
            .toList(growable: false),
        relations: (json['relations'] as List<dynamic>? ?? const [])
            .map((entry) =>
                StoryRelation.fromJson(Map<String, dynamic>.from(entry as Map)))
            .toList(growable: false),
      );

  final String projectId;
  final int schemaVersion;
  final int revision;
  final List<StoryEntity> entities;
  final List<StoryFact> facts;
  final List<StoryRelation> relations;

  StoryEntity? findEntity(String nameOrAlias) {
    final query = nameOrAlias.trim();
    for (final entity in entities) {
      if (entity.names.any((name) => name == query)) return entity;
    }
    return null;
  }

  List<StoryFact> factsAt(
    int chapter, {
    String? entityId,
    String? predicate,
  }) =>
      facts
          .where((fact) =>
              fact.isActiveAt(chapter) &&
              (entityId == null || fact.entityId == entityId) &&
              (predicate == null || fact.predicate == predicate))
          .toList(growable: false);

  List<StoryRelation> relationsAt(int chapter, {String? entityId}) => relations
      .where((relation) =>
          relation.isActiveAt(chapter) &&
          (entityId == null ||
              relation.fromEntityId == entityId ||
              relation.toEntityId == entityId))
      .toList(growable: false);

  StoryGraph withEntity(StoryEntity entity) => copyWith(
        entities: _replaceById(
          entities,
          entity,
          (candidate) => candidate.id,
        ),
      );

  StoryGraph withFact(StoryFact fact) => copyWith(
        facts: _replaceById(facts, fact, (candidate) => candidate.id),
      );

  StoryGraph withRelation(StoryRelation relation) => copyWith(
        relations:
            _replaceById(relations, relation, (candidate) => candidate.id),
      );

  StoryGraph confirm(String assertionId) => _updateAssertion(
        assertionId,
        ConfirmationStatus.confirmed,
        false,
      );

  StoryGraph reject(String assertionId) => _updateAssertion(
        assertionId,
        ConfirmationStatus.rejected,
        false,
      );

  StoryGraph undo(String assertionId) => _updateAssertion(
        assertionId,
        null,
        true,
      );

  StoryGraph _updateAssertion(
    String assertionId,
    ConfirmationStatus? status,
    bool retract,
  ) {
    final hasFact = facts.any((fact) => fact.id == assertionId);
    final hasRelation = relations.any((relation) => relation.id == assertionId);
    if (!hasFact && !hasRelation) {
      throw StateError('Story assertion not found: $assertionId');
    }
    return copyWith(
      facts: facts
          .map((fact) => fact.id == assertionId
              ? fact.copyWith(
                  confirmation: status,
                  isRetracted: retract ? true : null,
                )
              : fact)
          .toList(growable: false),
      relations: relations
          .map((relation) => relation.id == assertionId
              ? relation.copyWith(
                  confirmation: status,
                  isRetracted: retract ? true : null,
                )
              : relation)
          .toList(growable: false),
    );
  }

  StoryGraph copyWith({
    int? revision,
    List<StoryEntity>? entities,
    List<StoryFact>? facts,
    List<StoryRelation>? relations,
  }) =>
      StoryGraph(
        projectId: projectId,
        schemaVersion: schemaVersion,
        revision: revision ?? this.revision,
        entities: entities ?? this.entities,
        facts: facts ?? this.facts,
        relations: relations ?? this.relations,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'projectId': projectId,
        'revision': revision,
        'entities': entities.map((entity) => entity.toJson()).toList(),
        'facts': facts.map((fact) => fact.toJson()).toList(),
        'relations': relations.map((relation) => relation.toJson()).toList(),
      };
}

const currentStoryGraphSchemaVersion = 1;

ConfirmationStatus _confirmationFromJson(Object? value) =>
    ConfirmationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ConfirmationStatus.pending,
    );

List<T> _replaceById<T>(
  List<T> items,
  T replacement,
  String Function(T item) idOf,
) {
  final replacementId = idOf(replacement);
  final result = <T>[];
  var replaced = false;
  for (final item in items) {
    if (idOf(item) == replacementId) {
      if (!replaced) result.add(replacement);
      replaced = true;
    } else {
      result.add(item);
    }
  }
  if (!replaced) result.add(replacement);
  return List.unmodifiable(result);
}
