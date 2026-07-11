// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_database.dart';

// ignore_for_file: type=lint
class $CharactersTable extends Characters
    with TableInfo<$CharactersTable, Character> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharactersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _personalityMeta =
      const VerificationMeta('personality');
  @override
  late final GeneratedColumn<String> personality = GeneratedColumn<String>(
      'personality', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backstoryMeta =
      const VerificationMeta('backstory');
  @override
  late final GeneratedColumn<String> backstory = GeneratedColumn<String>(
      'backstory', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _motivationMeta =
      const VerificationMeta('motivation');
  @override
  late final GeneratedColumn<String> motivation = GeneratedColumn<String>(
      'motivation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _arcMeta = const VerificationMeta('arc');
  @override
  late final GeneratedColumn<String> arc = GeneratedColumn<String>(
      'arc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseWeightMeta =
      const VerificationMeta('baseWeight');
  @override
  late final GeneratedColumn<int> baseWeight = GeneratedColumn<int>(
      'base_weight', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tempWeightMeta =
      const VerificationMeta('tempWeight');
  @override
  late final GeneratedColumn<int> tempWeight = GeneratedColumn<int>(
      'temp_weight', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentStatusMeta =
      const VerificationMeta('currentStatus');
  @override
  late final GeneratedColumn<String> currentStatus = GeneratedColumn<String>(
      'current_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentLocationIdMeta =
      const VerificationMeta('currentLocationId');
  @override
  late final GeneratedColumn<String> currentLocationId =
      GeneratedColumn<String>('current_location_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        worldId,
        name,
        description,
        role,
        personality,
        backstory,
        motivation,
        arc,
        baseWeight,
        tempWeight,
        currentStatus,
        currentLocationId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'characters';
  @override
  VerificationContext validateIntegrity(Insertable<Character> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('personality')) {
      context.handle(
          _personalityMeta,
          personality.isAcceptableOrUnknown(
              data['personality']!, _personalityMeta));
    } else if (isInserting) {
      context.missing(_personalityMeta);
    }
    if (data.containsKey('backstory')) {
      context.handle(_backstoryMeta,
          backstory.isAcceptableOrUnknown(data['backstory']!, _backstoryMeta));
    } else if (isInserting) {
      context.missing(_backstoryMeta);
    }
    if (data.containsKey('motivation')) {
      context.handle(
          _motivationMeta,
          motivation.isAcceptableOrUnknown(
              data['motivation']!, _motivationMeta));
    } else if (isInserting) {
      context.missing(_motivationMeta);
    }
    if (data.containsKey('arc')) {
      context.handle(
          _arcMeta, arc.isAcceptableOrUnknown(data['arc']!, _arcMeta));
    } else if (isInserting) {
      context.missing(_arcMeta);
    }
    if (data.containsKey('base_weight')) {
      context.handle(
          _baseWeightMeta,
          baseWeight.isAcceptableOrUnknown(
              data['base_weight']!, _baseWeightMeta));
    } else if (isInserting) {
      context.missing(_baseWeightMeta);
    }
    if (data.containsKey('temp_weight')) {
      context.handle(
          _tempWeightMeta,
          tempWeight.isAcceptableOrUnknown(
              data['temp_weight']!, _tempWeightMeta));
    } else if (isInserting) {
      context.missing(_tempWeightMeta);
    }
    if (data.containsKey('current_status')) {
      context.handle(
          _currentStatusMeta,
          currentStatus.isAcceptableOrUnknown(
              data['current_status']!, _currentStatusMeta));
    } else if (isInserting) {
      context.missing(_currentStatusMeta);
    }
    if (data.containsKey('current_location_id')) {
      context.handle(
          _currentLocationIdMeta,
          currentLocationId.isAcceptableOrUnknown(
              data['current_location_id']!, _currentLocationIdMeta));
    } else if (isInserting) {
      context.missing(_currentLocationIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Character map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Character(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      personality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}personality'])!,
      backstory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backstory'])!,
      motivation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motivation'])!,
      arc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}arc'])!,
      baseWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_weight'])!,
      tempWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}temp_weight'])!,
      currentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}current_status'])!,
      currentLocationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_location_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CharactersTable createAlias(String alias) {
    return $CharactersTable(attachedDatabase, alias);
  }
}

class Character extends DataClass implements Insertable<Character> {
  String id;
  String worldId;
  String name;
  String description;
  String role;
  String personality;
  String backstory;
  String motivation;
  String arc;
  int baseWeight;
  int tempWeight;
  String currentStatus;
  String currentLocationId;
  DateTime createdAt;
  DateTime updatedAt;
  Character(
      {required this.id,
      required this.worldId,
      required this.name,
      required this.description,
      required this.role,
      required this.personality,
      required this.backstory,
      required this.motivation,
      required this.arc,
      required this.baseWeight,
      required this.tempWeight,
      required this.currentStatus,
      required this.currentLocationId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['role'] = Variable<String>(role);
    map['personality'] = Variable<String>(personality);
    map['backstory'] = Variable<String>(backstory);
    map['motivation'] = Variable<String>(motivation);
    map['arc'] = Variable<String>(arc);
    map['base_weight'] = Variable<int>(baseWeight);
    map['temp_weight'] = Variable<int>(tempWeight);
    map['current_status'] = Variable<String>(currentStatus);
    map['current_location_id'] = Variable<String>(currentLocationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CharactersCompanion toCompanion(bool nullToAbsent) {
    return CharactersCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      description: Value(description),
      role: Value(role),
      personality: Value(personality),
      backstory: Value(backstory),
      motivation: Value(motivation),
      arc: Value(arc),
      baseWeight: Value(baseWeight),
      tempWeight: Value(tempWeight),
      currentStatus: Value(currentStatus),
      currentLocationId: Value(currentLocationId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Character.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Character(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      role: serializer.fromJson<String>(json['role']),
      personality: serializer.fromJson<String>(json['personality']),
      backstory: serializer.fromJson<String>(json['backstory']),
      motivation: serializer.fromJson<String>(json['motivation']),
      arc: serializer.fromJson<String>(json['arc']),
      baseWeight: serializer.fromJson<int>(json['baseWeight']),
      tempWeight: serializer.fromJson<int>(json['tempWeight']),
      currentStatus: serializer.fromJson<String>(json['currentStatus']),
      currentLocationId: serializer.fromJson<String>(json['currentLocationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'role': serializer.toJson<String>(role),
      'personality': serializer.toJson<String>(personality),
      'backstory': serializer.toJson<String>(backstory),
      'motivation': serializer.toJson<String>(motivation),
      'arc': serializer.toJson<String>(arc),
      'baseWeight': serializer.toJson<int>(baseWeight),
      'tempWeight': serializer.toJson<int>(tempWeight),
      'currentStatus': serializer.toJson<String>(currentStatus),
      'currentLocationId': serializer.toJson<String>(currentLocationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Character copyWith(
          {String? id,
          String? worldId,
          String? name,
          String? description,
          String? role,
          String? personality,
          String? backstory,
          String? motivation,
          String? arc,
          int? baseWeight,
          int? tempWeight,
          String? currentStatus,
          String? currentLocationId,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Character(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        name: name ?? this.name,
        description: description ?? this.description,
        role: role ?? this.role,
        personality: personality ?? this.personality,
        backstory: backstory ?? this.backstory,
        motivation: motivation ?? this.motivation,
        arc: arc ?? this.arc,
        baseWeight: baseWeight ?? this.baseWeight,
        tempWeight: tempWeight ?? this.tempWeight,
        currentStatus: currentStatus ?? this.currentStatus,
        currentLocationId: currentLocationId ?? this.currentLocationId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Character copyWithCompanion(CharactersCompanion data) {
    return Character(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      role: data.role.present ? data.role.value : this.role,
      personality:
          data.personality.present ? data.personality.value : this.personality,
      backstory: data.backstory.present ? data.backstory.value : this.backstory,
      motivation:
          data.motivation.present ? data.motivation.value : this.motivation,
      arc: data.arc.present ? data.arc.value : this.arc,
      baseWeight:
          data.baseWeight.present ? data.baseWeight.value : this.baseWeight,
      tempWeight:
          data.tempWeight.present ? data.tempWeight.value : this.tempWeight,
      currentStatus: data.currentStatus.present
          ? data.currentStatus.value
          : this.currentStatus,
      currentLocationId: data.currentLocationId.present
          ? data.currentLocationId.value
          : this.currentLocationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Character(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('role: $role, ')
          ..write('personality: $personality, ')
          ..write('backstory: $backstory, ')
          ..write('motivation: $motivation, ')
          ..write('arc: $arc, ')
          ..write('baseWeight: $baseWeight, ')
          ..write('tempWeight: $tempWeight, ')
          ..write('currentStatus: $currentStatus, ')
          ..write('currentLocationId: $currentLocationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      worldId,
      name,
      description,
      role,
      personality,
      backstory,
      motivation,
      arc,
      baseWeight,
      tempWeight,
      currentStatus,
      currentLocationId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Character &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.description == this.description &&
          other.role == this.role &&
          other.personality == this.personality &&
          other.backstory == this.backstory &&
          other.motivation == this.motivation &&
          other.arc == this.arc &&
          other.baseWeight == this.baseWeight &&
          other.tempWeight == this.tempWeight &&
          other.currentStatus == this.currentStatus &&
          other.currentLocationId == this.currentLocationId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CharactersCompanion extends UpdateCompanion<Character> {
  Value<String> id;
  Value<String> worldId;
  Value<String> name;
  Value<String> description;
  Value<String> role;
  Value<String> personality;
  Value<String> backstory;
  Value<String> motivation;
  Value<String> arc;
  Value<int> baseWeight;
  Value<int> tempWeight;
  Value<String> currentStatus;
  Value<String> currentLocationId;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  CharactersCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.role = const Value.absent(),
    this.personality = const Value.absent(),
    this.backstory = const Value.absent(),
    this.motivation = const Value.absent(),
    this.arc = const Value.absent(),
    this.baseWeight = const Value.absent(),
    this.tempWeight = const Value.absent(),
    this.currentStatus = const Value.absent(),
    this.currentLocationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharactersCompanion.insert({
    required String id,
    required String worldId,
    required String name,
    required String description,
    required String role,
    required String personality,
    required String backstory,
    required String motivation,
    required String arc,
    required int baseWeight,
    required int tempWeight,
    required String currentStatus,
    required String currentLocationId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        name = Value(name),
        description = Value(description),
        role = Value(role),
        personality = Value(personality),
        backstory = Value(backstory),
        motivation = Value(motivation),
        arc = Value(arc),
        baseWeight = Value(baseWeight),
        tempWeight = Value(tempWeight),
        currentStatus = Value(currentStatus),
        currentLocationId = Value(currentLocationId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Character> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? role,
    Expression<String>? personality,
    Expression<String>? backstory,
    Expression<String>? motivation,
    Expression<String>? arc,
    Expression<int>? baseWeight,
    Expression<int>? tempWeight,
    Expression<String>? currentStatus,
    Expression<String>? currentLocationId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (role != null) 'role': role,
      if (personality != null) 'personality': personality,
      if (backstory != null) 'backstory': backstory,
      if (motivation != null) 'motivation': motivation,
      if (arc != null) 'arc': arc,
      if (baseWeight != null) 'base_weight': baseWeight,
      if (tempWeight != null) 'temp_weight': tempWeight,
      if (currentStatus != null) 'current_status': currentStatus,
      if (currentLocationId != null) 'current_location_id': currentLocationId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharactersCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? role,
      Value<String>? personality,
      Value<String>? backstory,
      Value<String>? motivation,
      Value<String>? arc,
      Value<int>? baseWeight,
      Value<int>? tempWeight,
      Value<String>? currentStatus,
      Value<String>? currentLocationId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CharactersCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      personality: personality ?? this.personality,
      backstory: backstory ?? this.backstory,
      motivation: motivation ?? this.motivation,
      arc: arc ?? this.arc,
      baseWeight: baseWeight ?? this.baseWeight,
      tempWeight: tempWeight ?? this.tempWeight,
      currentStatus: currentStatus ?? this.currentStatus,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (personality.present) {
      map['personality'] = Variable<String>(personality.value);
    }
    if (backstory.present) {
      map['backstory'] = Variable<String>(backstory.value);
    }
    if (motivation.present) {
      map['motivation'] = Variable<String>(motivation.value);
    }
    if (arc.present) {
      map['arc'] = Variable<String>(arc.value);
    }
    if (baseWeight.present) {
      map['base_weight'] = Variable<int>(baseWeight.value);
    }
    if (tempWeight.present) {
      map['temp_weight'] = Variable<int>(tempWeight.value);
    }
    if (currentStatus.present) {
      map['current_status'] = Variable<String>(currentStatus.value);
    }
    if (currentLocationId.present) {
      map['current_location_id'] = Variable<String>(currentLocationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharactersCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('role: $role, ')
          ..write('personality: $personality, ')
          ..write('backstory: $backstory, ')
          ..write('motivation: $motivation, ')
          ..write('arc: $arc, ')
          ..write('baseWeight: $baseWeight, ')
          ..write('tempWeight: $tempWeight, ')
          ..write('currentStatus: $currentStatus, ')
          ..write('currentLocationId: $currentLocationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdentitiesTable extends Identities
    with TableInfo<$IdentitiesTable, Identity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdentitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
      'character_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<int> weight = GeneratedColumn<int>(
      'weight', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _autoDetectedMeta =
      const VerificationMeta('autoDetected');
  @override
  late final GeneratedColumn<bool> autoDetected = GeneratedColumn<bool>(
      'auto_detected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_detected" IN (0, 1))'));
  static const VerificationMeta _organizationIdMeta =
      const VerificationMeta('organizationId');
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
      'organization_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _establishedAfterEventIdMeta =
      const VerificationMeta('establishedAfterEventId');
  @override
  late final GeneratedColumn<String> establishedAfterEventId =
      GeneratedColumn<String>('established_after_event_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAfterEventIdMeta =
      const VerificationMeta('expiresAfterEventId');
  @override
  late final GeneratedColumn<String> expiresAfterEventId =
      GeneratedColumn<String>('expires_after_event_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        characterId,
        name,
        description,
        weight,
        autoDetected,
        organizationId,
        establishedAfterEventId,
        expiresAfterEventId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'identities';
  @override
  VerificationContext validateIntegrity(Insertable<Identity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('auto_detected')) {
      context.handle(
          _autoDetectedMeta,
          autoDetected.isAcceptableOrUnknown(
              data['auto_detected']!, _autoDetectedMeta));
    } else if (isInserting) {
      context.missing(_autoDetectedMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
          _organizationIdMeta,
          organizationId.isAcceptableOrUnknown(
              data['organization_id']!, _organizationIdMeta));
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('established_after_event_id')) {
      context.handle(
          _establishedAfterEventIdMeta,
          establishedAfterEventId.isAcceptableOrUnknown(
              data['established_after_event_id']!,
              _establishedAfterEventIdMeta));
    } else if (isInserting) {
      context.missing(_establishedAfterEventIdMeta);
    }
    if (data.containsKey('expires_after_event_id')) {
      context.handle(
          _expiresAfterEventIdMeta,
          expiresAfterEventId.isAcceptableOrUnknown(
              data['expires_after_event_id']!, _expiresAfterEventIdMeta));
    } else if (isInserting) {
      context.missing(_expiresAfterEventIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Identity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Identity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weight'])!,
      autoDetected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_detected'])!,
      organizationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}organization_id'])!,
      establishedAfterEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}established_after_event_id'])!,
      expiresAfterEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}expires_after_event_id'])!,
    );
  }

  @override
  $IdentitiesTable createAlias(String alias) {
    return $IdentitiesTable(attachedDatabase, alias);
  }
}

class Identity extends DataClass implements Insertable<Identity> {
  String id;
  String characterId;
  String name;
  String description;
  int weight;
  bool autoDetected;
  String organizationId;
  String establishedAfterEventId;
  String expiresAfterEventId;
  Identity(
      {required this.id,
      required this.characterId,
      required this.name,
      required this.description,
      required this.weight,
      required this.autoDetected,
      required this.organizationId,
      required this.establishedAfterEventId,
      required this.expiresAfterEventId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['weight'] = Variable<int>(weight);
    map['auto_detected'] = Variable<bool>(autoDetected);
    map['organization_id'] = Variable<String>(organizationId);
    map['established_after_event_id'] =
        Variable<String>(establishedAfterEventId);
    map['expires_after_event_id'] = Variable<String>(expiresAfterEventId);
    return map;
  }

  IdentitiesCompanion toCompanion(bool nullToAbsent) {
    return IdentitiesCompanion(
      id: Value(id),
      characterId: Value(characterId),
      name: Value(name),
      description: Value(description),
      weight: Value(weight),
      autoDetected: Value(autoDetected),
      organizationId: Value(organizationId),
      establishedAfterEventId: Value(establishedAfterEventId),
      expiresAfterEventId: Value(expiresAfterEventId),
    );
  }

  factory Identity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Identity(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      weight: serializer.fromJson<int>(json['weight']),
      autoDetected: serializer.fromJson<bool>(json['autoDetected']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      establishedAfterEventId:
          serializer.fromJson<String>(json['establishedAfterEventId']),
      expiresAfterEventId:
          serializer.fromJson<String>(json['expiresAfterEventId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'weight': serializer.toJson<int>(weight),
      'autoDetected': serializer.toJson<bool>(autoDetected),
      'organizationId': serializer.toJson<String>(organizationId),
      'establishedAfterEventId':
          serializer.toJson<String>(establishedAfterEventId),
      'expiresAfterEventId': serializer.toJson<String>(expiresAfterEventId),
    };
  }

  Identity copyWith(
          {String? id,
          String? characterId,
          String? name,
          String? description,
          int? weight,
          bool? autoDetected,
          String? organizationId,
          String? establishedAfterEventId,
          String? expiresAfterEventId}) =>
      Identity(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        name: name ?? this.name,
        description: description ?? this.description,
        weight: weight ?? this.weight,
        autoDetected: autoDetected ?? this.autoDetected,
        organizationId: organizationId ?? this.organizationId,
        establishedAfterEventId:
            establishedAfterEventId ?? this.establishedAfterEventId,
        expiresAfterEventId: expiresAfterEventId ?? this.expiresAfterEventId,
      );
  Identity copyWithCompanion(IdentitiesCompanion data) {
    return Identity(
      id: data.id.present ? data.id.value : this.id,
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      weight: data.weight.present ? data.weight.value : this.weight,
      autoDetected: data.autoDetected.present
          ? data.autoDetected.value
          : this.autoDetected,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      establishedAfterEventId: data.establishedAfterEventId.present
          ? data.establishedAfterEventId.value
          : this.establishedAfterEventId,
      expiresAfterEventId: data.expiresAfterEventId.present
          ? data.expiresAfterEventId.value
          : this.expiresAfterEventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Identity(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('weight: $weight, ')
          ..write('autoDetected: $autoDetected, ')
          ..write('organizationId: $organizationId, ')
          ..write('establishedAfterEventId: $establishedAfterEventId, ')
          ..write('expiresAfterEventId: $expiresAfterEventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      characterId,
      name,
      description,
      weight,
      autoDetected,
      organizationId,
      establishedAfterEventId,
      expiresAfterEventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Identity &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.name == this.name &&
          other.description == this.description &&
          other.weight == this.weight &&
          other.autoDetected == this.autoDetected &&
          other.organizationId == this.organizationId &&
          other.establishedAfterEventId == this.establishedAfterEventId &&
          other.expiresAfterEventId == this.expiresAfterEventId);
}

class IdentitiesCompanion extends UpdateCompanion<Identity> {
  Value<String> id;
  Value<String> characterId;
  Value<String> name;
  Value<String> description;
  Value<int> weight;
  Value<bool> autoDetected;
  Value<String> organizationId;
  Value<String> establishedAfterEventId;
  Value<String> expiresAfterEventId;
  Value<int> rowid;
  IdentitiesCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.weight = const Value.absent(),
    this.autoDetected = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.establishedAfterEventId = const Value.absent(),
    this.expiresAfterEventId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdentitiesCompanion.insert({
    required String id,
    required String characterId,
    required String name,
    required String description,
    required int weight,
    required bool autoDetected,
    required String organizationId,
    required String establishedAfterEventId,
    required String expiresAfterEventId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        characterId = Value(characterId),
        name = Value(name),
        description = Value(description),
        weight = Value(weight),
        autoDetected = Value(autoDetected),
        organizationId = Value(organizationId),
        establishedAfterEventId = Value(establishedAfterEventId),
        expiresAfterEventId = Value(expiresAfterEventId);
  static Insertable<Identity> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? weight,
    Expression<bool>? autoDetected,
    Expression<String>? organizationId,
    Expression<String>? establishedAfterEventId,
    Expression<String>? expiresAfterEventId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (weight != null) 'weight': weight,
      if (autoDetected != null) 'auto_detected': autoDetected,
      if (organizationId != null) 'organization_id': organizationId,
      if (establishedAfterEventId != null)
        'established_after_event_id': establishedAfterEventId,
      if (expiresAfterEventId != null)
        'expires_after_event_id': expiresAfterEventId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdentitiesCompanion copyWith(
      {Value<String>? id,
      Value<String>? characterId,
      Value<String>? name,
      Value<String>? description,
      Value<int>? weight,
      Value<bool>? autoDetected,
      Value<String>? organizationId,
      Value<String>? establishedAfterEventId,
      Value<String>? expiresAfterEventId,
      Value<int>? rowid}) {
    return IdentitiesCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      name: name ?? this.name,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      autoDetected: autoDetected ?? this.autoDetected,
      organizationId: organizationId ?? this.organizationId,
      establishedAfterEventId:
          establishedAfterEventId ?? this.establishedAfterEventId,
      expiresAfterEventId: expiresAfterEventId ?? this.expiresAfterEventId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (weight.present) {
      map['weight'] = Variable<int>(weight.value);
    }
    if (autoDetected.present) {
      map['auto_detected'] = Variable<bool>(autoDetected.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (establishedAfterEventId.present) {
      map['established_after_event_id'] =
          Variable<String>(establishedAfterEventId.value);
    }
    if (expiresAfterEventId.present) {
      map['expires_after_event_id'] =
          Variable<String>(expiresAfterEventId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdentitiesCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('weight: $weight, ')
          ..write('autoDetected: $autoDetected, ')
          ..write('organizationId: $organizationId, ')
          ..write('establishedAfterEventId: $establishedAfterEventId, ')
          ..write('expiresAfterEventId: $expiresAfterEventId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightSpecsTable extends WeightSpecs
    with TableInfo<$WeightSpecsTable, WeightSpec> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightSpecsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
      'character_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _volumeIdMeta =
      const VerificationMeta('volumeId');
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
      'volume_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weightDeltaMeta =
      const VerificationMeta('weightDelta');
  @override
  late final GeneratedColumn<int> weightDelta = GeneratedColumn<int>(
      'weight_delta', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _promoteToMainMeta =
      const VerificationMeta('promoteToMain');
  @override
  late final GeneratedColumn<bool> promoteToMain = GeneratedColumn<bool>(
      'promote_to_main', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("promote_to_main" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        characterId,
        description,
        volumeId,
        eventId,
        chapterId,
        weightDelta,
        promoteToMain
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_specs';
  @override
  VerificationContext validateIntegrity(Insertable<WeightSpec> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(_volumeIdMeta,
          volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta));
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('weight_delta')) {
      context.handle(
          _weightDeltaMeta,
          weightDelta.isAcceptableOrUnknown(
              data['weight_delta']!, _weightDeltaMeta));
    } else if (isInserting) {
      context.missing(_weightDeltaMeta);
    }
    if (data.containsKey('promote_to_main')) {
      context.handle(
          _promoteToMainMeta,
          promoteToMain.isAcceptableOrUnknown(
              data['promote_to_main']!, _promoteToMainMeta));
    } else if (isInserting) {
      context.missing(_promoteToMainMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightSpec map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightSpec(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character_id'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      volumeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}volume_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_id'])!,
      weightDelta: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weight_delta'])!,
      promoteToMain: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}promote_to_main'])!,
    );
  }

  @override
  $WeightSpecsTable createAlias(String alias) {
    return $WeightSpecsTable(attachedDatabase, alias);
  }
}

class WeightSpec extends DataClass implements Insertable<WeightSpec> {
  String id;
  String characterId;
  String description;
  String volumeId;
  String eventId;
  String chapterId;
  int weightDelta;
  bool promoteToMain;
  WeightSpec(
      {required this.id,
      required this.characterId,
      required this.description,
      required this.volumeId,
      required this.eventId,
      required this.chapterId,
      required this.weightDelta,
      required this.promoteToMain});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['description'] = Variable<String>(description);
    map['volume_id'] = Variable<String>(volumeId);
    map['event_id'] = Variable<String>(eventId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['weight_delta'] = Variable<int>(weightDelta);
    map['promote_to_main'] = Variable<bool>(promoteToMain);
    return map;
  }

  WeightSpecsCompanion toCompanion(bool nullToAbsent) {
    return WeightSpecsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      description: Value(description),
      volumeId: Value(volumeId),
      eventId: Value(eventId),
      chapterId: Value(chapterId),
      weightDelta: Value(weightDelta),
      promoteToMain: Value(promoteToMain),
    );
  }

  factory WeightSpec.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightSpec(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      description: serializer.fromJson<String>(json['description']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      weightDelta: serializer.fromJson<int>(json['weightDelta']),
      promoteToMain: serializer.fromJson<bool>(json['promoteToMain']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'description': serializer.toJson<String>(description),
      'volumeId': serializer.toJson<String>(volumeId),
      'eventId': serializer.toJson<String>(eventId),
      'chapterId': serializer.toJson<String>(chapterId),
      'weightDelta': serializer.toJson<int>(weightDelta),
      'promoteToMain': serializer.toJson<bool>(promoteToMain),
    };
  }

  WeightSpec copyWith(
          {String? id,
          String? characterId,
          String? description,
          String? volumeId,
          String? eventId,
          String? chapterId,
          int? weightDelta,
          bool? promoteToMain}) =>
      WeightSpec(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        description: description ?? this.description,
        volumeId: volumeId ?? this.volumeId,
        eventId: eventId ?? this.eventId,
        chapterId: chapterId ?? this.chapterId,
        weightDelta: weightDelta ?? this.weightDelta,
        promoteToMain: promoteToMain ?? this.promoteToMain,
      );
  WeightSpec copyWithCompanion(WeightSpecsCompanion data) {
    return WeightSpec(
      id: data.id.present ? data.id.value : this.id,
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
      description:
          data.description.present ? data.description.value : this.description,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      weightDelta:
          data.weightDelta.present ? data.weightDelta.value : this.weightDelta,
      promoteToMain: data.promoteToMain.present
          ? data.promoteToMain.value
          : this.promoteToMain,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightSpec(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('description: $description, ')
          ..write('volumeId: $volumeId, ')
          ..write('eventId: $eventId, ')
          ..write('chapterId: $chapterId, ')
          ..write('weightDelta: $weightDelta, ')
          ..write('promoteToMain: $promoteToMain')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, characterId, description, volumeId,
      eventId, chapterId, weightDelta, promoteToMain);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightSpec &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.description == this.description &&
          other.volumeId == this.volumeId &&
          other.eventId == this.eventId &&
          other.chapterId == this.chapterId &&
          other.weightDelta == this.weightDelta &&
          other.promoteToMain == this.promoteToMain);
}

class WeightSpecsCompanion extends UpdateCompanion<WeightSpec> {
  Value<String> id;
  Value<String> characterId;
  Value<String> description;
  Value<String> volumeId;
  Value<String> eventId;
  Value<String> chapterId;
  Value<int> weightDelta;
  Value<bool> promoteToMain;
  Value<int> rowid;
  WeightSpecsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.description = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.weightDelta = const Value.absent(),
    this.promoteToMain = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightSpecsCompanion.insert({
    required String id,
    required String characterId,
    required String description,
    required String volumeId,
    required String eventId,
    required String chapterId,
    required int weightDelta,
    required bool promoteToMain,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        characterId = Value(characterId),
        description = Value(description),
        volumeId = Value(volumeId),
        eventId = Value(eventId),
        chapterId = Value(chapterId),
        weightDelta = Value(weightDelta),
        promoteToMain = Value(promoteToMain);
  static Insertable<WeightSpec> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? description,
    Expression<String>? volumeId,
    Expression<String>? eventId,
    Expression<String>? chapterId,
    Expression<int>? weightDelta,
    Expression<bool>? promoteToMain,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (description != null) 'description': description,
      if (volumeId != null) 'volume_id': volumeId,
      if (eventId != null) 'event_id': eventId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (weightDelta != null) 'weight_delta': weightDelta,
      if (promoteToMain != null) 'promote_to_main': promoteToMain,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightSpecsCompanion copyWith(
      {Value<String>? id,
      Value<String>? characterId,
      Value<String>? description,
      Value<String>? volumeId,
      Value<String>? eventId,
      Value<String>? chapterId,
      Value<int>? weightDelta,
      Value<bool>? promoteToMain,
      Value<int>? rowid}) {
    return WeightSpecsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      description: description ?? this.description,
      volumeId: volumeId ?? this.volumeId,
      eventId: eventId ?? this.eventId,
      chapterId: chapterId ?? this.chapterId,
      weightDelta: weightDelta ?? this.weightDelta,
      promoteToMain: promoteToMain ?? this.promoteToMain,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (weightDelta.present) {
      map['weight_delta'] = Variable<int>(weightDelta.value);
    }
    if (promoteToMain.present) {
      map['promote_to_main'] = Variable<bool>(promoteToMain.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightSpecsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('description: $description, ')
          ..write('volumeId: $volumeId, ')
          ..write('eventId: $eventId, ')
          ..write('chapterId: $chapterId, ')
          ..write('weightDelta: $weightDelta, ')
          ..write('promoteToMain: $promoteToMain, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterRelationsTable extends CharacterRelations
    with TableInfo<$CharacterRelationsTable, CharacterRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
      'character_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relatedCharacterIdMeta =
      const VerificationMeta('relatedCharacterId');
  @override
  late final GeneratedColumn<String> relatedCharacterId =
      GeneratedColumn<String>('related_character_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relationTypeMeta =
      const VerificationMeta('relationType');
  @override
  late final GeneratedColumn<String> relationType = GeneratedColumn<String>(
      'relation_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intimacyMeta =
      const VerificationMeta('intimacy');
  @override
  late final GeneratedColumn<int> intimacy = GeneratedColumn<int>(
      'intimacy', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        characterId,
        relatedCharacterId,
        relationType,
        intimacy,
        description
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_relations';
  @override
  VerificationContext validateIntegrity(Insertable<CharacterRelation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('related_character_id')) {
      context.handle(
          _relatedCharacterIdMeta,
          relatedCharacterId.isAcceptableOrUnknown(
              data['related_character_id']!, _relatedCharacterIdMeta));
    } else if (isInserting) {
      context.missing(_relatedCharacterIdMeta);
    }
    if (data.containsKey('relation_type')) {
      context.handle(
          _relationTypeMeta,
          relationType.isAcceptableOrUnknown(
              data['relation_type']!, _relationTypeMeta));
    } else if (isInserting) {
      context.missing(_relationTypeMeta);
    }
    if (data.containsKey('intimacy')) {
      context.handle(_intimacyMeta,
          intimacy.isAcceptableOrUnknown(data['intimacy']!, _intimacyMeta));
    } else if (isInserting) {
      context.missing(_intimacyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterRelation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character_id'])!,
      relatedCharacterId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}related_character_id'])!,
      relationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relation_type'])!,
      intimacy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}intimacy'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
    );
  }

  @override
  $CharacterRelationsTable createAlias(String alias) {
    return $CharacterRelationsTable(attachedDatabase, alias);
  }
}

class CharacterRelation extends DataClass
    implements Insertable<CharacterRelation> {
  String id;
  String characterId;
  String relatedCharacterId;
  String relationType;
  int intimacy;
  String description;
  CharacterRelation(
      {required this.id,
      required this.characterId,
      required this.relatedCharacterId,
      required this.relationType,
      required this.intimacy,
      required this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character_id'] = Variable<String>(characterId);
    map['related_character_id'] = Variable<String>(relatedCharacterId);
    map['relation_type'] = Variable<String>(relationType);
    map['intimacy'] = Variable<int>(intimacy);
    map['description'] = Variable<String>(description);
    return map;
  }

  CharacterRelationsCompanion toCompanion(bool nullToAbsent) {
    return CharacterRelationsCompanion(
      id: Value(id),
      characterId: Value(characterId),
      relatedCharacterId: Value(relatedCharacterId),
      relationType: Value(relationType),
      intimacy: Value(intimacy),
      description: Value(description),
    );
  }

  factory CharacterRelation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterRelation(
      id: serializer.fromJson<String>(json['id']),
      characterId: serializer.fromJson<String>(json['characterId']),
      relatedCharacterId:
          serializer.fromJson<String>(json['relatedCharacterId']),
      relationType: serializer.fromJson<String>(json['relationType']),
      intimacy: serializer.fromJson<int>(json['intimacy']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'characterId': serializer.toJson<String>(characterId),
      'relatedCharacterId': serializer.toJson<String>(relatedCharacterId),
      'relationType': serializer.toJson<String>(relationType),
      'intimacy': serializer.toJson<int>(intimacy),
      'description': serializer.toJson<String>(description),
    };
  }

  CharacterRelation copyWith(
          {String? id,
          String? characterId,
          String? relatedCharacterId,
          String? relationType,
          int? intimacy,
          String? description}) =>
      CharacterRelation(
        id: id ?? this.id,
        characterId: characterId ?? this.characterId,
        relatedCharacterId: relatedCharacterId ?? this.relatedCharacterId,
        relationType: relationType ?? this.relationType,
        intimacy: intimacy ?? this.intimacy,
        description: description ?? this.description,
      );
  CharacterRelation copyWithCompanion(CharacterRelationsCompanion data) {
    return CharacterRelation(
      id: data.id.present ? data.id.value : this.id,
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
      relatedCharacterId: data.relatedCharacterId.present
          ? data.relatedCharacterId.value
          : this.relatedCharacterId,
      relationType: data.relationType.present
          ? data.relationType.value
          : this.relationType,
      intimacy: data.intimacy.present ? data.intimacy.value : this.intimacy,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRelation(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('relatedCharacterId: $relatedCharacterId, ')
          ..write('relationType: $relationType, ')
          ..write('intimacy: $intimacy, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, characterId, relatedCharacterId, relationType, intimacy, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterRelation &&
          other.id == this.id &&
          other.characterId == this.characterId &&
          other.relatedCharacterId == this.relatedCharacterId &&
          other.relationType == this.relationType &&
          other.intimacy == this.intimacy &&
          other.description == this.description);
}

class CharacterRelationsCompanion extends UpdateCompanion<CharacterRelation> {
  Value<String> id;
  Value<String> characterId;
  Value<String> relatedCharacterId;
  Value<String> relationType;
  Value<int> intimacy;
  Value<String> description;
  Value<int> rowid;
  CharacterRelationsCompanion({
    this.id = const Value.absent(),
    this.characterId = const Value.absent(),
    this.relatedCharacterId = const Value.absent(),
    this.relationType = const Value.absent(),
    this.intimacy = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterRelationsCompanion.insert({
    required String id,
    required String characterId,
    required String relatedCharacterId,
    required String relationType,
    required int intimacy,
    required String description,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        characterId = Value(characterId),
        relatedCharacterId = Value(relatedCharacterId),
        relationType = Value(relationType),
        intimacy = Value(intimacy),
        description = Value(description);
  static Insertable<CharacterRelation> custom({
    Expression<String>? id,
    Expression<String>? characterId,
    Expression<String>? relatedCharacterId,
    Expression<String>? relationType,
    Expression<int>? intimacy,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (characterId != null) 'character_id': characterId,
      if (relatedCharacterId != null)
        'related_character_id': relatedCharacterId,
      if (relationType != null) 'relation_type': relationType,
      if (intimacy != null) 'intimacy': intimacy,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterRelationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? characterId,
      Value<String>? relatedCharacterId,
      Value<String>? relationType,
      Value<int>? intimacy,
      Value<String>? description,
      Value<int>? rowid}) {
    return CharacterRelationsCompanion(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      relatedCharacterId: relatedCharacterId ?? this.relatedCharacterId,
      relationType: relationType ?? this.relationType,
      intimacy: intimacy ?? this.intimacy,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (relatedCharacterId.present) {
      map['related_character_id'] = Variable<String>(relatedCharacterId.value);
    }
    if (relationType.present) {
      map['relation_type'] = Variable<String>(relationType.value);
    }
    if (intimacy.present) {
      map['intimacy'] = Variable<int>(intimacy.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterRelationsCompanion(')
          ..write('id: $id, ')
          ..write('characterId: $characterId, ')
          ..write('relatedCharacterId: $relatedCharacterId, ')
          ..write('relationType: $relationType, ')
          ..write('intimacy: $intimacy, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelationStagesTable extends RelationStages
    with TableInfo<$RelationStagesTable, RelationStage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationStagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relationIdMeta =
      const VerificationMeta('relationId');
  @override
  late final GeneratedColumn<String> relationId = GeneratedColumn<String>(
      'relation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _atIntimacyMeta =
      const VerificationMeta('atIntimacy');
  @override
  late final GeneratedColumn<int> atIntimacy = GeneratedColumn<int>(
      'at_intimacy', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stageNameMeta =
      const VerificationMeta('stageName');
  @override
  late final GeneratedColumn<String> stageName = GeneratedColumn<String>(
      'stage_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reachedAtMeta =
      const VerificationMeta('reachedAt');
  @override
  late final GeneratedColumn<DateTime> reachedAt = GeneratedColumn<DateTime>(
      'reached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _triggerEventIdMeta =
      const VerificationMeta('triggerEventId');
  @override
  late final GeneratedColumn<String> triggerEventId = GeneratedColumn<String>(
      'trigger_event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confirmedMeta =
      const VerificationMeta('confirmed');
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
      'confirmed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("confirmed" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        relationId,
        atIntimacy,
        stageName,
        reachedAt,
        triggerEventId,
        confirmed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relation_stages';
  @override
  VerificationContext validateIntegrity(Insertable<RelationStage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('relation_id')) {
      context.handle(
          _relationIdMeta,
          relationId.isAcceptableOrUnknown(
              data['relation_id']!, _relationIdMeta));
    } else if (isInserting) {
      context.missing(_relationIdMeta);
    }
    if (data.containsKey('at_intimacy')) {
      context.handle(
          _atIntimacyMeta,
          atIntimacy.isAcceptableOrUnknown(
              data['at_intimacy']!, _atIntimacyMeta));
    } else if (isInserting) {
      context.missing(_atIntimacyMeta);
    }
    if (data.containsKey('stage_name')) {
      context.handle(_stageNameMeta,
          stageName.isAcceptableOrUnknown(data['stage_name']!, _stageNameMeta));
    } else if (isInserting) {
      context.missing(_stageNameMeta);
    }
    if (data.containsKey('reached_at')) {
      context.handle(_reachedAtMeta,
          reachedAt.isAcceptableOrUnknown(data['reached_at']!, _reachedAtMeta));
    } else if (isInserting) {
      context.missing(_reachedAtMeta);
    }
    if (data.containsKey('trigger_event_id')) {
      context.handle(
          _triggerEventIdMeta,
          triggerEventId.isAcceptableOrUnknown(
              data['trigger_event_id']!, _triggerEventIdMeta));
    } else if (isInserting) {
      context.missing(_triggerEventIdMeta);
    }
    if (data.containsKey('confirmed')) {
      context.handle(_confirmedMeta,
          confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta));
    } else if (isInserting) {
      context.missing(_confirmedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RelationStage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RelationStage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      relationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relation_id'])!,
      atIntimacy: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}at_intimacy'])!,
      stageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stage_name'])!,
      reachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reached_at'])!,
      triggerEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}trigger_event_id'])!,
      confirmed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}confirmed'])!,
    );
  }

  @override
  $RelationStagesTable createAlias(String alias) {
    return $RelationStagesTable(attachedDatabase, alias);
  }
}

class RelationStage extends DataClass implements Insertable<RelationStage> {
  String id;
  String relationId;
  int atIntimacy;
  String stageName;
  DateTime reachedAt;
  String triggerEventId;
  bool confirmed;
  RelationStage(
      {required this.id,
      required this.relationId,
      required this.atIntimacy,
      required this.stageName,
      required this.reachedAt,
      required this.triggerEventId,
      required this.confirmed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['relation_id'] = Variable<String>(relationId);
    map['at_intimacy'] = Variable<int>(atIntimacy);
    map['stage_name'] = Variable<String>(stageName);
    map['reached_at'] = Variable<DateTime>(reachedAt);
    map['trigger_event_id'] = Variable<String>(triggerEventId);
    map['confirmed'] = Variable<bool>(confirmed);
    return map;
  }

  RelationStagesCompanion toCompanion(bool nullToAbsent) {
    return RelationStagesCompanion(
      id: Value(id),
      relationId: Value(relationId),
      atIntimacy: Value(atIntimacy),
      stageName: Value(stageName),
      reachedAt: Value(reachedAt),
      triggerEventId: Value(triggerEventId),
      confirmed: Value(confirmed),
    );
  }

  factory RelationStage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RelationStage(
      id: serializer.fromJson<String>(json['id']),
      relationId: serializer.fromJson<String>(json['relationId']),
      atIntimacy: serializer.fromJson<int>(json['atIntimacy']),
      stageName: serializer.fromJson<String>(json['stageName']),
      reachedAt: serializer.fromJson<DateTime>(json['reachedAt']),
      triggerEventId: serializer.fromJson<String>(json['triggerEventId']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'relationId': serializer.toJson<String>(relationId),
      'atIntimacy': serializer.toJson<int>(atIntimacy),
      'stageName': serializer.toJson<String>(stageName),
      'reachedAt': serializer.toJson<DateTime>(reachedAt),
      'triggerEventId': serializer.toJson<String>(triggerEventId),
      'confirmed': serializer.toJson<bool>(confirmed),
    };
  }

  RelationStage copyWith(
          {String? id,
          String? relationId,
          int? atIntimacy,
          String? stageName,
          DateTime? reachedAt,
          String? triggerEventId,
          bool? confirmed}) =>
      RelationStage(
        id: id ?? this.id,
        relationId: relationId ?? this.relationId,
        atIntimacy: atIntimacy ?? this.atIntimacy,
        stageName: stageName ?? this.stageName,
        reachedAt: reachedAt ?? this.reachedAt,
        triggerEventId: triggerEventId ?? this.triggerEventId,
        confirmed: confirmed ?? this.confirmed,
      );
  RelationStage copyWithCompanion(RelationStagesCompanion data) {
    return RelationStage(
      id: data.id.present ? data.id.value : this.id,
      relationId:
          data.relationId.present ? data.relationId.value : this.relationId,
      atIntimacy:
          data.atIntimacy.present ? data.atIntimacy.value : this.atIntimacy,
      stageName: data.stageName.present ? data.stageName.value : this.stageName,
      reachedAt: data.reachedAt.present ? data.reachedAt.value : this.reachedAt,
      triggerEventId: data.triggerEventId.present
          ? data.triggerEventId.value
          : this.triggerEventId,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RelationStage(')
          ..write('id: $id, ')
          ..write('relationId: $relationId, ')
          ..write('atIntimacy: $atIntimacy, ')
          ..write('stageName: $stageName, ')
          ..write('reachedAt: $reachedAt, ')
          ..write('triggerEventId: $triggerEventId, ')
          ..write('confirmed: $confirmed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, relationId, atIntimacy, stageName,
      reachedAt, triggerEventId, confirmed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelationStage &&
          other.id == this.id &&
          other.relationId == this.relationId &&
          other.atIntimacy == this.atIntimacy &&
          other.stageName == this.stageName &&
          other.reachedAt == this.reachedAt &&
          other.triggerEventId == this.triggerEventId &&
          other.confirmed == this.confirmed);
}

class RelationStagesCompanion extends UpdateCompanion<RelationStage> {
  Value<String> id;
  Value<String> relationId;
  Value<int> atIntimacy;
  Value<String> stageName;
  Value<DateTime> reachedAt;
  Value<String> triggerEventId;
  Value<bool> confirmed;
  Value<int> rowid;
  RelationStagesCompanion({
    this.id = const Value.absent(),
    this.relationId = const Value.absent(),
    this.atIntimacy = const Value.absent(),
    this.stageName = const Value.absent(),
    this.reachedAt = const Value.absent(),
    this.triggerEventId = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelationStagesCompanion.insert({
    required String id,
    required String relationId,
    required int atIntimacy,
    required String stageName,
    required DateTime reachedAt,
    required String triggerEventId,
    required bool confirmed,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        relationId = Value(relationId),
        atIntimacy = Value(atIntimacy),
        stageName = Value(stageName),
        reachedAt = Value(reachedAt),
        triggerEventId = Value(triggerEventId),
        confirmed = Value(confirmed);
  static Insertable<RelationStage> custom({
    Expression<String>? id,
    Expression<String>? relationId,
    Expression<int>? atIntimacy,
    Expression<String>? stageName,
    Expression<DateTime>? reachedAt,
    Expression<String>? triggerEventId,
    Expression<bool>? confirmed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (relationId != null) 'relation_id': relationId,
      if (atIntimacy != null) 'at_intimacy': atIntimacy,
      if (stageName != null) 'stage_name': stageName,
      if (reachedAt != null) 'reached_at': reachedAt,
      if (triggerEventId != null) 'trigger_event_id': triggerEventId,
      if (confirmed != null) 'confirmed': confirmed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelationStagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? relationId,
      Value<int>? atIntimacy,
      Value<String>? stageName,
      Value<DateTime>? reachedAt,
      Value<String>? triggerEventId,
      Value<bool>? confirmed,
      Value<int>? rowid}) {
    return RelationStagesCompanion(
      id: id ?? this.id,
      relationId: relationId ?? this.relationId,
      atIntimacy: atIntimacy ?? this.atIntimacy,
      stageName: stageName ?? this.stageName,
      reachedAt: reachedAt ?? this.reachedAt,
      triggerEventId: triggerEventId ?? this.triggerEventId,
      confirmed: confirmed ?? this.confirmed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (relationId.present) {
      map['relation_id'] = Variable<String>(relationId.value);
    }
    if (atIntimacy.present) {
      map['at_intimacy'] = Variable<int>(atIntimacy.value);
    }
    if (stageName.present) {
      map['stage_name'] = Variable<String>(stageName.value);
    }
    if (reachedAt.present) {
      map['reached_at'] = Variable<DateTime>(reachedAt.value);
    }
    if (triggerEventId.present) {
      map['trigger_event_id'] = Variable<String>(triggerEventId.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationStagesCompanion(')
          ..write('id: $id, ')
          ..write('relationId: $relationId, ')
          ..write('atIntimacy: $atIntimacy, ')
          ..write('stageName: $stageName, ')
          ..write('reachedAt: $reachedAt, ')
          ..write('triggerEventId: $triggerEventId, ')
          ..write('confirmed: $confirmed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocationsTable extends Locations
    with TableInfo<$LocationsTable, Location> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, worldId, name, description, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations';
  @override
  VerificationContext validateIntegrity(Insertable<Location> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Location map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Location(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocationsTable createAlias(String alias) {
    return $LocationsTable(attachedDatabase, alias);
  }
}

class Location extends DataClass implements Insertable<Location> {
  String id;
  String worldId;
  String name;
  String description;
  DateTime createdAt;
  DateTime updatedAt;
  Location(
      {required this.id,
      required this.worldId,
      required this.name,
      required this.description,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocationsCompanion toCompanion(bool nullToAbsent) {
    return LocationsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Location.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Location(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Location copyWith(
          {String? id,
          String? worldId,
          String? name,
          String? description,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Location(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Location copyWithCompanion(LocationsCompanion data) {
    return Location(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Location(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, worldId, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Location &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocationsCompanion extends UpdateCompanion<Location> {
  Value<String> id;
  Value<String> worldId;
  Value<String> name;
  Value<String> description;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  LocationsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocationsCompanion.insert({
    required String id,
    required String worldId,
    required String name,
    required String description,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        name = Value(name),
        description = Value(description),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Location> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? name,
      Value<String>? description,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocationsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoresTable extends Lores with TableInfo<$LoresTable, Lore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _triggerKeywordsMeta =
      const VerificationMeta('triggerKeywords');
  @override
  late final GeneratedColumn<String> triggerKeywords = GeneratedColumn<String>(
      'trigger_keywords', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        worldId,
        name,
        type,
        description,
        triggerKeywords,
        enabled,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lores';
  @override
  VerificationContext validateIntegrity(Insertable<Lore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('trigger_keywords')) {
      context.handle(
          _triggerKeywordsMeta,
          triggerKeywords.isAcceptableOrUnknown(
              data['trigger_keywords']!, _triggerKeywordsMeta));
    } else if (isInserting) {
      context.missing(_triggerKeywordsMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lore(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      triggerKeywords: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}trigger_keywords'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LoresTable createAlias(String alias) {
    return $LoresTable(attachedDatabase, alias);
  }
}

class Lore extends DataClass implements Insertable<Lore> {
  String id;
  String worldId;
  String name;
  String type;
  String description;
  String triggerKeywords;
  bool enabled;
  DateTime createdAt;
  DateTime updatedAt;
  Lore(
      {required this.id,
      required this.worldId,
      required this.name,
      required this.type,
      required this.description,
      required this.triggerKeywords,
      required this.enabled,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['description'] = Variable<String>(description);
    map['trigger_keywords'] = Variable<String>(triggerKeywords);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LoresCompanion toCompanion(bool nullToAbsent) {
    return LoresCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      type: Value(type),
      description: Value(description),
      triggerKeywords: Value(triggerKeywords),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Lore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lore(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String>(json['description']),
      triggerKeywords: serializer.fromJson<String>(json['triggerKeywords']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String>(description),
      'triggerKeywords': serializer.toJson<String>(triggerKeywords),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Lore copyWith(
          {String? id,
          String? worldId,
          String? name,
          String? type,
          String? description,
          String? triggerKeywords,
          bool? enabled,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Lore(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        name: name ?? this.name,
        type: type ?? this.type,
        description: description ?? this.description,
        triggerKeywords: triggerKeywords ?? this.triggerKeywords,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Lore copyWithCompanion(LoresCompanion data) {
    return Lore(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      description:
          data.description.present ? data.description.value : this.description,
      triggerKeywords: data.triggerKeywords.present
          ? data.triggerKeywords.value
          : this.triggerKeywords,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lore(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('triggerKeywords: $triggerKeywords, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, worldId, name, type, description,
      triggerKeywords, enabled, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lore &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.type == this.type &&
          other.description == this.description &&
          other.triggerKeywords == this.triggerKeywords &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LoresCompanion extends UpdateCompanion<Lore> {
  Value<String> id;
  Value<String> worldId;
  Value<String> name;
  Value<String> type;
  Value<String> description;
  Value<String> triggerKeywords;
  Value<bool> enabled;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  LoresCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.triggerKeywords = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoresCompanion.insert({
    required String id,
    required String worldId,
    required String name,
    required String type,
    required String description,
    required String triggerKeywords,
    required bool enabled,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        name = Value(name),
        type = Value(type),
        description = Value(description),
        triggerKeywords = Value(triggerKeywords),
        enabled = Value(enabled),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Lore> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? description,
    Expression<String>? triggerKeywords,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (triggerKeywords != null) 'trigger_keywords': triggerKeywords,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoresCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? name,
      Value<String>? type,
      Value<String>? description,
      Value<String>? triggerKeywords,
      Value<bool>? enabled,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LoresCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      triggerKeywords: triggerKeywords ?? this.triggerKeywords,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (triggerKeywords.present) {
      map['trigger_keywords'] = Variable<String>(triggerKeywords.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoresCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('triggerKeywords: $triggerKeywords, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorldRulesTable extends WorldRules
    with TableInfo<$WorldRulesTable, WorldRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorldRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
      'scope', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, worldId, name, description, scope, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'world_rules';
  @override
  VerificationContext validateIntegrity(Insertable<WorldRule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
          _scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorldRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorldRule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      scope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorldRulesTable createAlias(String alias) {
    return $WorldRulesTable(attachedDatabase, alias);
  }
}

class WorldRule extends DataClass implements Insertable<WorldRule> {
  String id;
  String worldId;
  String name;
  String description;
  String scope;
  DateTime createdAt;
  DateTime updatedAt;
  WorldRule(
      {required this.id,
      required this.worldId,
      required this.name,
      required this.description,
      required this.scope,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['scope'] = Variable<String>(scope);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorldRulesCompanion toCompanion(bool nullToAbsent) {
    return WorldRulesCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      description: Value(description),
      scope: Value(scope),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorldRule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorldRule(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      scope: serializer.fromJson<String>(json['scope']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'scope': serializer.toJson<String>(scope),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorldRule copyWith(
          {String? id,
          String? worldId,
          String? name,
          String? description,
          String? scope,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      WorldRule(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        name: name ?? this.name,
        description: description ?? this.description,
        scope: scope ?? this.scope,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WorldRule copyWithCompanion(WorldRulesCompanion data) {
    return WorldRule(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      scope: data.scope.present ? data.scope.value : this.scope,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorldRule(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('scope: $scope, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, worldId, name, description, scope, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorldRule &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.description == this.description &&
          other.scope == this.scope &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorldRulesCompanion extends UpdateCompanion<WorldRule> {
  Value<String> id;
  Value<String> worldId;
  Value<String> name;
  Value<String> description;
  Value<String> scope;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  WorldRulesCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.scope = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorldRulesCompanion.insert({
    required String id,
    required String worldId,
    required String name,
    required String description,
    required String scope,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        name = Value(name),
        description = Value(description),
        scope = Value(scope),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<WorldRule> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? scope,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (scope != null) 'scope': scope,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorldRulesCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? scope,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return WorldRulesCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      description: description ?? this.description,
      scope: scope ?? this.scope,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorldRulesCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('scope: $scope, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimelineEventsTable extends TimelineEvents
    with TableInfo<$TimelineEventsTable, TimelineEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderKeyMeta =
      const VerificationMeta('orderKey');
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
      'order_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inStoryDateMeta =
      const VerificationMeta('inStoryDate');
  @override
  late final GeneratedColumn<String> inStoryDate = GeneratedColumn<String>(
      'in_story_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inStoryDayMeta =
      const VerificationMeta('inStoryDay');
  @override
  late final GeneratedColumn<int> inStoryDay = GeneratedColumn<int>(
      'in_story_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<String> duration = GeneratedColumn<String>(
      'duration', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterAnchorMeta =
      const VerificationMeta('chapterAnchor');
  @override
  late final GeneratedColumn<String> chapterAnchor = GeneratedColumn<String>(
      'chapter_anchor', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentEventIdMeta =
      const VerificationMeta('parentEventId');
  @override
  late final GeneratedColumn<String> parentEventId = GeneratedColumn<String>(
      'parent_event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        worldId,
        title,
        description,
        orderKey,
        inStoryDate,
        inStoryDay,
        duration,
        chapterAnchor,
        branchId,
        parentEventId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_events';
  @override
  VerificationContext validateIntegrity(Insertable<TimelineEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('order_key')) {
      context.handle(_orderKeyMeta,
          orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta));
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('in_story_date')) {
      context.handle(
          _inStoryDateMeta,
          inStoryDate.isAcceptableOrUnknown(
              data['in_story_date']!, _inStoryDateMeta));
    } else if (isInserting) {
      context.missing(_inStoryDateMeta);
    }
    if (data.containsKey('in_story_day')) {
      context.handle(
          _inStoryDayMeta,
          inStoryDay.isAcceptableOrUnknown(
              data['in_story_day']!, _inStoryDayMeta));
    } else if (isInserting) {
      context.missing(_inStoryDayMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('chapter_anchor')) {
      context.handle(
          _chapterAnchorMeta,
          chapterAnchor.isAcceptableOrUnknown(
              data['chapter_anchor']!, _chapterAnchorMeta));
    } else if (isInserting) {
      context.missing(_chapterAnchorMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('parent_event_id')) {
      context.handle(
          _parentEventIdMeta,
          parentEventId.isAcceptableOrUnknown(
              data['parent_event_id']!, _parentEventIdMeta));
    } else if (isInserting) {
      context.missing(_parentEventIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimelineEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      orderKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_key'])!,
      inStoryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}in_story_date'])!,
      inStoryDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}in_story_day'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}duration'])!,
      chapterAnchor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_anchor'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      parentEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}parent_event_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TimelineEventsTable createAlias(String alias) {
    return $TimelineEventsTable(attachedDatabase, alias);
  }
}

class TimelineEvent extends DataClass implements Insertable<TimelineEvent> {
  String id;
  String worldId;
  String title;
  String description;
  String orderKey;
  String inStoryDate;
  int inStoryDay;
  String duration;
  String chapterAnchor;
  String branchId;
  String parentEventId;
  DateTime createdAt;
  TimelineEvent(
      {required this.id,
      required this.worldId,
      required this.title,
      required this.description,
      required this.orderKey,
      required this.inStoryDate,
      required this.inStoryDay,
      required this.duration,
      required this.chapterAnchor,
      required this.branchId,
      required this.parentEventId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['order_key'] = Variable<String>(orderKey);
    map['in_story_date'] = Variable<String>(inStoryDate);
    map['in_story_day'] = Variable<int>(inStoryDay);
    map['duration'] = Variable<String>(duration);
    map['chapter_anchor'] = Variable<String>(chapterAnchor);
    map['branch_id'] = Variable<String>(branchId);
    map['parent_event_id'] = Variable<String>(parentEventId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TimelineEventsCompanion toCompanion(bool nullToAbsent) {
    return TimelineEventsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      title: Value(title),
      description: Value(description),
      orderKey: Value(orderKey),
      inStoryDate: Value(inStoryDate),
      inStoryDay: Value(inStoryDay),
      duration: Value(duration),
      chapterAnchor: Value(chapterAnchor),
      branchId: Value(branchId),
      parentEventId: Value(parentEventId),
      createdAt: Value(createdAt),
    );
  }

  factory TimelineEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineEvent(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
      inStoryDate: serializer.fromJson<String>(json['inStoryDate']),
      inStoryDay: serializer.fromJson<int>(json['inStoryDay']),
      duration: serializer.fromJson<String>(json['duration']),
      chapterAnchor: serializer.fromJson<String>(json['chapterAnchor']),
      branchId: serializer.fromJson<String>(json['branchId']),
      parentEventId: serializer.fromJson<String>(json['parentEventId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'orderKey': serializer.toJson<String>(orderKey),
      'inStoryDate': serializer.toJson<String>(inStoryDate),
      'inStoryDay': serializer.toJson<int>(inStoryDay),
      'duration': serializer.toJson<String>(duration),
      'chapterAnchor': serializer.toJson<String>(chapterAnchor),
      'branchId': serializer.toJson<String>(branchId),
      'parentEventId': serializer.toJson<String>(parentEventId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TimelineEvent copyWith(
          {String? id,
          String? worldId,
          String? title,
          String? description,
          String? orderKey,
          String? inStoryDate,
          int? inStoryDay,
          String? duration,
          String? chapterAnchor,
          String? branchId,
          String? parentEventId,
          DateTime? createdAt}) =>
      TimelineEvent(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        title: title ?? this.title,
        description: description ?? this.description,
        orderKey: orderKey ?? this.orderKey,
        inStoryDate: inStoryDate ?? this.inStoryDate,
        inStoryDay: inStoryDay ?? this.inStoryDay,
        duration: duration ?? this.duration,
        chapterAnchor: chapterAnchor ?? this.chapterAnchor,
        branchId: branchId ?? this.branchId,
        parentEventId: parentEventId ?? this.parentEventId,
        createdAt: createdAt ?? this.createdAt,
      );
  TimelineEvent copyWithCompanion(TimelineEventsCompanion data) {
    return TimelineEvent(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      inStoryDate:
          data.inStoryDate.present ? data.inStoryDate.value : this.inStoryDate,
      inStoryDay:
          data.inStoryDay.present ? data.inStoryDay.value : this.inStoryDay,
      duration: data.duration.present ? data.duration.value : this.duration,
      chapterAnchor: data.chapterAnchor.present
          ? data.chapterAnchor.value
          : this.chapterAnchor,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      parentEventId: data.parentEventId.present
          ? data.parentEventId.value
          : this.parentEventId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEvent(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('orderKey: $orderKey, ')
          ..write('inStoryDate: $inStoryDate, ')
          ..write('inStoryDay: $inStoryDay, ')
          ..write('duration: $duration, ')
          ..write('chapterAnchor: $chapterAnchor, ')
          ..write('branchId: $branchId, ')
          ..write('parentEventId: $parentEventId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      worldId,
      title,
      description,
      orderKey,
      inStoryDate,
      inStoryDay,
      duration,
      chapterAnchor,
      branchId,
      parentEventId,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineEvent &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.title == this.title &&
          other.description == this.description &&
          other.orderKey == this.orderKey &&
          other.inStoryDate == this.inStoryDate &&
          other.inStoryDay == this.inStoryDay &&
          other.duration == this.duration &&
          other.chapterAnchor == this.chapterAnchor &&
          other.branchId == this.branchId &&
          other.parentEventId == this.parentEventId &&
          other.createdAt == this.createdAt);
}

class TimelineEventsCompanion extends UpdateCompanion<TimelineEvent> {
  Value<String> id;
  Value<String> worldId;
  Value<String> title;
  Value<String> description;
  Value<String> orderKey;
  Value<String> inStoryDate;
  Value<int> inStoryDay;
  Value<String> duration;
  Value<String> chapterAnchor;
  Value<String> branchId;
  Value<String> parentEventId;
  Value<DateTime> createdAt;
  Value<int> rowid;
  TimelineEventsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.inStoryDate = const Value.absent(),
    this.inStoryDay = const Value.absent(),
    this.duration = const Value.absent(),
    this.chapterAnchor = const Value.absent(),
    this.branchId = const Value.absent(),
    this.parentEventId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimelineEventsCompanion.insert({
    required String id,
    required String worldId,
    required String title,
    required String description,
    required String orderKey,
    required String inStoryDate,
    required int inStoryDay,
    required String duration,
    required String chapterAnchor,
    required String branchId,
    required String parentEventId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        title = Value(title),
        description = Value(description),
        orderKey = Value(orderKey),
        inStoryDate = Value(inStoryDate),
        inStoryDay = Value(inStoryDay),
        duration = Value(duration),
        chapterAnchor = Value(chapterAnchor),
        branchId = Value(branchId),
        parentEventId = Value(parentEventId),
        createdAt = Value(createdAt);
  static Insertable<TimelineEvent> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? orderKey,
    Expression<String>? inStoryDate,
    Expression<int>? inStoryDay,
    Expression<String>? duration,
    Expression<String>? chapterAnchor,
    Expression<String>? branchId,
    Expression<String>? parentEventId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (orderKey != null) 'order_key': orderKey,
      if (inStoryDate != null) 'in_story_date': inStoryDate,
      if (inStoryDay != null) 'in_story_day': inStoryDay,
      if (duration != null) 'duration': duration,
      if (chapterAnchor != null) 'chapter_anchor': chapterAnchor,
      if (branchId != null) 'branch_id': branchId,
      if (parentEventId != null) 'parent_event_id': parentEventId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimelineEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? title,
      Value<String>? description,
      Value<String>? orderKey,
      Value<String>? inStoryDate,
      Value<int>? inStoryDay,
      Value<String>? duration,
      Value<String>? chapterAnchor,
      Value<String>? branchId,
      Value<String>? parentEventId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TimelineEventsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderKey: orderKey ?? this.orderKey,
      inStoryDate: inStoryDate ?? this.inStoryDate,
      inStoryDay: inStoryDay ?? this.inStoryDay,
      duration: duration ?? this.duration,
      chapterAnchor: chapterAnchor ?? this.chapterAnchor,
      branchId: branchId ?? this.branchId,
      parentEventId: parentEventId ?? this.parentEventId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (inStoryDate.present) {
      map['in_story_date'] = Variable<String>(inStoryDate.value);
    }
    if (inStoryDay.present) {
      map['in_story_day'] = Variable<int>(inStoryDay.value);
    }
    if (duration.present) {
      map['duration'] = Variable<String>(duration.value);
    }
    if (chapterAnchor.present) {
      map['chapter_anchor'] = Variable<String>(chapterAnchor.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (parentEventId.present) {
      map['parent_event_id'] = Variable<String>(parentEventId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEventsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('orderKey: $orderKey, ')
          ..write('inStoryDate: $inStoryDate, ')
          ..write('inStoryDay: $inStoryDay, ')
          ..write('duration: $duration, ')
          ..write('chapterAnchor: $chapterAnchor, ')
          ..write('branchId: $branchId, ')
          ..write('parentEventId: $parentEventId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FactionsTable extends Factions with TableInfo<$FactionsTable, Faction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _powerMeta = const VerificationMeta('power');
  @override
  late final GeneratedColumn<int> power = GeneratedColumn<int>(
      'power', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _territoryMeta =
      const VerificationMeta('territory');
  @override
  late final GeneratedColumn<String> territory = GeneratedColumn<String>(
      'territory', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        worldId,
        name,
        description,
        type,
        power,
        territory,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'factions';
  @override
  VerificationContext validateIntegrity(Insertable<Faction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('power')) {
      context.handle(
          _powerMeta, power.isAcceptableOrUnknown(data['power']!, _powerMeta));
    } else if (isInserting) {
      context.missing(_powerMeta);
    }
    if (data.containsKey('territory')) {
      context.handle(_territoryMeta,
          territory.isAcceptableOrUnknown(data['territory']!, _territoryMeta));
    } else if (isInserting) {
      context.missing(_territoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Faction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Faction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      power: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}power'])!,
      territory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}territory'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FactionsTable createAlias(String alias) {
    return $FactionsTable(attachedDatabase, alias);
  }
}

class Faction extends DataClass implements Insertable<Faction> {
  String id;
  String worldId;
  String name;
  String description;
  String type;
  int power;
  String territory;
  DateTime createdAt;
  DateTime updatedAt;
  Faction(
      {required this.id,
      required this.worldId,
      required this.name,
      required this.description,
      required this.type,
      required this.power,
      required this.territory,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    map['power'] = Variable<int>(power);
    map['territory'] = Variable<String>(territory);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FactionsCompanion toCompanion(bool nullToAbsent) {
    return FactionsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      power: Value(power),
      territory: Value(territory),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Faction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Faction(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      power: serializer.fromJson<int>(json['power']),
      territory: serializer.fromJson<String>(json['territory']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'power': serializer.toJson<int>(power),
      'territory': serializer.toJson<String>(territory),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Faction copyWith(
          {String? id,
          String? worldId,
          String? name,
          String? description,
          String? type,
          int? power,
          String? territory,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Faction(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        power: power ?? this.power,
        territory: territory ?? this.territory,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Faction copyWithCompanion(FactionsCompanion data) {
    return Faction(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      power: data.power.present ? data.power.value : this.power,
      territory: data.territory.present ? data.territory.value : this.territory,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Faction(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('power: $power, ')
          ..write('territory: $territory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, worldId, name, description, type, power,
      territory, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Faction &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.power == this.power &&
          other.territory == this.territory &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FactionsCompanion extends UpdateCompanion<Faction> {
  Value<String> id;
  Value<String> worldId;
  Value<String> name;
  Value<String> description;
  Value<String> type;
  Value<int> power;
  Value<String> territory;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  FactionsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.power = const Value.absent(),
    this.territory = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FactionsCompanion.insert({
    required String id,
    required String worldId,
    required String name,
    required String description,
    required String type,
    required int power,
    required String territory,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        name = Value(name),
        description = Value(description),
        type = Value(type),
        power = Value(power),
        territory = Value(territory),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Faction> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<int>? power,
    Expression<String>? territory,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (power != null) 'power': power,
      if (territory != null) 'territory': territory,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? type,
      Value<int>? power,
      Value<String>? territory,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return FactionsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      power: power ?? this.power,
      territory: territory ?? this.territory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (power.present) {
      map['power'] = Variable<int>(power.value);
    }
    if (territory.present) {
      map['territory'] = Variable<String>(territory.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FactionsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('power: $power, ')
          ..write('territory: $territory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ForeshadowingsTable extends Foreshadowings
    with TableInfo<$ForeshadowingsTable, Foreshadowing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ForeshadowingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plantedEventIdMeta =
      const VerificationMeta('plantedEventId');
  @override
  late final GeneratedColumn<String> plantedEventId = GeneratedColumn<String>(
      'planted_event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _harvestedEventIdMeta =
      const VerificationMeta('harvestedEventId');
  @override
  late final GeneratedColumn<String> harvestedEventId = GeneratedColumn<String>(
      'harvested_event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subtletyMeta =
      const VerificationMeta('subtlety');
  @override
  late final GeneratedColumn<int> subtlety = GeneratedColumn<int>(
      'subtlety', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        worldId,
        plantedEventId,
        harvestedEventId,
        status,
        subtlety,
        description,
        note,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foreshadowings';
  @override
  VerificationContext validateIntegrity(Insertable<Foreshadowing> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('planted_event_id')) {
      context.handle(
          _plantedEventIdMeta,
          plantedEventId.isAcceptableOrUnknown(
              data['planted_event_id']!, _plantedEventIdMeta));
    } else if (isInserting) {
      context.missing(_plantedEventIdMeta);
    }
    if (data.containsKey('harvested_event_id')) {
      context.handle(
          _harvestedEventIdMeta,
          harvestedEventId.isAcceptableOrUnknown(
              data['harvested_event_id']!, _harvestedEventIdMeta));
    } else if (isInserting) {
      context.missing(_harvestedEventIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('subtlety')) {
      context.handle(_subtletyMeta,
          subtlety.isAcceptableOrUnknown(data['subtlety']!, _subtletyMeta));
    } else if (isInserting) {
      context.missing(_subtletyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Foreshadowing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Foreshadowing(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      plantedEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}planted_event_id'])!,
      harvestedEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}harvested_event_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      subtlety: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}subtlety'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ForeshadowingsTable createAlias(String alias) {
    return $ForeshadowingsTable(attachedDatabase, alias);
  }
}

class Foreshadowing extends DataClass implements Insertable<Foreshadowing> {
  String id;
  String worldId;
  String plantedEventId;
  String harvestedEventId;
  String status;
  int subtlety;
  String description;
  String note;
  DateTime createdAt;
  DateTime updatedAt;
  Foreshadowing(
      {required this.id,
      required this.worldId,
      required this.plantedEventId,
      required this.harvestedEventId,
      required this.status,
      required this.subtlety,
      required this.description,
      required this.note,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['planted_event_id'] = Variable<String>(plantedEventId);
    map['harvested_event_id'] = Variable<String>(harvestedEventId);
    map['status'] = Variable<String>(status);
    map['subtlety'] = Variable<int>(subtlety);
    map['description'] = Variable<String>(description);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ForeshadowingsCompanion toCompanion(bool nullToAbsent) {
    return ForeshadowingsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      plantedEventId: Value(plantedEventId),
      harvestedEventId: Value(harvestedEventId),
      status: Value(status),
      subtlety: Value(subtlety),
      description: Value(description),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Foreshadowing.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Foreshadowing(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      plantedEventId: serializer.fromJson<String>(json['plantedEventId']),
      harvestedEventId: serializer.fromJson<String>(json['harvestedEventId']),
      status: serializer.fromJson<String>(json['status']),
      subtlety: serializer.fromJson<int>(json['subtlety']),
      description: serializer.fromJson<String>(json['description']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'plantedEventId': serializer.toJson<String>(plantedEventId),
      'harvestedEventId': serializer.toJson<String>(harvestedEventId),
      'status': serializer.toJson<String>(status),
      'subtlety': serializer.toJson<int>(subtlety),
      'description': serializer.toJson<String>(description),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Foreshadowing copyWith(
          {String? id,
          String? worldId,
          String? plantedEventId,
          String? harvestedEventId,
          String? status,
          int? subtlety,
          String? description,
          String? note,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Foreshadowing(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        plantedEventId: plantedEventId ?? this.plantedEventId,
        harvestedEventId: harvestedEventId ?? this.harvestedEventId,
        status: status ?? this.status,
        subtlety: subtlety ?? this.subtlety,
        description: description ?? this.description,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Foreshadowing copyWithCompanion(ForeshadowingsCompanion data) {
    return Foreshadowing(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      plantedEventId: data.plantedEventId.present
          ? data.plantedEventId.value
          : this.plantedEventId,
      harvestedEventId: data.harvestedEventId.present
          ? data.harvestedEventId.value
          : this.harvestedEventId,
      status: data.status.present ? data.status.value : this.status,
      subtlety: data.subtlety.present ? data.subtlety.value : this.subtlety,
      description:
          data.description.present ? data.description.value : this.description,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Foreshadowing(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('plantedEventId: $plantedEventId, ')
          ..write('harvestedEventId: $harvestedEventId, ')
          ..write('status: $status, ')
          ..write('subtlety: $subtlety, ')
          ..write('description: $description, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, worldId, plantedEventId, harvestedEventId,
      status, subtlety, description, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Foreshadowing &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.plantedEventId == this.plantedEventId &&
          other.harvestedEventId == this.harvestedEventId &&
          other.status == this.status &&
          other.subtlety == this.subtlety &&
          other.description == this.description &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ForeshadowingsCompanion extends UpdateCompanion<Foreshadowing> {
  Value<String> id;
  Value<String> worldId;
  Value<String> plantedEventId;
  Value<String> harvestedEventId;
  Value<String> status;
  Value<int> subtlety;
  Value<String> description;
  Value<String> note;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  ForeshadowingsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.plantedEventId = const Value.absent(),
    this.harvestedEventId = const Value.absent(),
    this.status = const Value.absent(),
    this.subtlety = const Value.absent(),
    this.description = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ForeshadowingsCompanion.insert({
    required String id,
    required String worldId,
    required String plantedEventId,
    required String harvestedEventId,
    required String status,
    required int subtlety,
    required String description,
    required String note,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        plantedEventId = Value(plantedEventId),
        harvestedEventId = Value(harvestedEventId),
        status = Value(status),
        subtlety = Value(subtlety),
        description = Value(description),
        note = Value(note),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Foreshadowing> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? plantedEventId,
    Expression<String>? harvestedEventId,
    Expression<String>? status,
    Expression<int>? subtlety,
    Expression<String>? description,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (plantedEventId != null) 'planted_event_id': plantedEventId,
      if (harvestedEventId != null) 'harvested_event_id': harvestedEventId,
      if (status != null) 'status': status,
      if (subtlety != null) 'subtlety': subtlety,
      if (description != null) 'description': description,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ForeshadowingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? plantedEventId,
      Value<String>? harvestedEventId,
      Value<String>? status,
      Value<int>? subtlety,
      Value<String>? description,
      Value<String>? note,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ForeshadowingsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      plantedEventId: plantedEventId ?? this.plantedEventId,
      harvestedEventId: harvestedEventId ?? this.harvestedEventId,
      status: status ?? this.status,
      subtlety: subtlety ?? this.subtlety,
      description: description ?? this.description,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (plantedEventId.present) {
      map['planted_event_id'] = Variable<String>(plantedEventId.value);
    }
    if (harvestedEventId.present) {
      map['harvested_event_id'] = Variable<String>(harvestedEventId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (subtlety.present) {
      map['subtlety'] = Variable<int>(subtlety.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ForeshadowingsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('plantedEventId: $plantedEventId, ')
          ..write('harvestedEventId: $harvestedEventId, ')
          ..write('status: $status, ')
          ..write('subtlety: $subtlety, ')
          ..write('description: $description, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ButterflyAnalysesTable extends ButterflyAnalyses
    with TableInfo<$ButterflyAnalysesTable, ButterflyAnalysis> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ButterflyAnalysesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _analysisTextMeta =
      const VerificationMeta('analysisText');
  @override
  late final GeneratedColumn<String> analysisText = GeneratedColumn<String>(
      'analysis_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _predictedDirectionMeta =
      const VerificationMeta('predictedDirection');
  @override
  late final GeneratedColumn<String> predictedDirection =
      GeneratedColumn<String>('predicted_direction', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tokenCostMeta =
      const VerificationMeta('tokenCost');
  @override
  late final GeneratedColumn<int> tokenCost = GeneratedColumn<int>(
      'token_cost', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _estimatedCostMeta =
      const VerificationMeta('estimatedCost');
  @override
  late final GeneratedColumn<double> estimatedCost = GeneratedColumn<double>(
      'estimated_cost', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        worldId,
        eventId,
        analysisText,
        predictedDirection,
        tokenCost,
        estimatedCost,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'butterfly_analyses';
  @override
  VerificationContext validateIntegrity(Insertable<ButterflyAnalysis> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('analysis_text')) {
      context.handle(
          _analysisTextMeta,
          analysisText.isAcceptableOrUnknown(
              data['analysis_text']!, _analysisTextMeta));
    } else if (isInserting) {
      context.missing(_analysisTextMeta);
    }
    if (data.containsKey('predicted_direction')) {
      context.handle(
          _predictedDirectionMeta,
          predictedDirection.isAcceptableOrUnknown(
              data['predicted_direction']!, _predictedDirectionMeta));
    } else if (isInserting) {
      context.missing(_predictedDirectionMeta);
    }
    if (data.containsKey('token_cost')) {
      context.handle(_tokenCostMeta,
          tokenCost.isAcceptableOrUnknown(data['token_cost']!, _tokenCostMeta));
    } else if (isInserting) {
      context.missing(_tokenCostMeta);
    }
    if (data.containsKey('estimated_cost')) {
      context.handle(
          _estimatedCostMeta,
          estimatedCost.isAcceptableOrUnknown(
              data['estimated_cost']!, _estimatedCostMeta));
    } else if (isInserting) {
      context.missing(_estimatedCostMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ButterflyAnalysis map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ButterflyAnalysis(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      analysisText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis_text'])!,
      predictedDirection: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}predicted_direction'])!,
      tokenCost: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}token_cost'])!,
      estimatedCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}estimated_cost'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ButterflyAnalysesTable createAlias(String alias) {
    return $ButterflyAnalysesTable(attachedDatabase, alias);
  }
}

class ButterflyAnalysis extends DataClass
    implements Insertable<ButterflyAnalysis> {
  String id;
  String worldId;
  String eventId;
  String analysisText;
  String predictedDirection;
  int tokenCost;
  double estimatedCost;
  DateTime createdAt;
  ButterflyAnalysis(
      {required this.id,
      required this.worldId,
      required this.eventId,
      required this.analysisText,
      required this.predictedDirection,
      required this.tokenCost,
      required this.estimatedCost,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['event_id'] = Variable<String>(eventId);
    map['analysis_text'] = Variable<String>(analysisText);
    map['predicted_direction'] = Variable<String>(predictedDirection);
    map['token_cost'] = Variable<int>(tokenCost);
    map['estimated_cost'] = Variable<double>(estimatedCost);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ButterflyAnalysesCompanion toCompanion(bool nullToAbsent) {
    return ButterflyAnalysesCompanion(
      id: Value(id),
      worldId: Value(worldId),
      eventId: Value(eventId),
      analysisText: Value(analysisText),
      predictedDirection: Value(predictedDirection),
      tokenCost: Value(tokenCost),
      estimatedCost: Value(estimatedCost),
      createdAt: Value(createdAt),
    );
  }

  factory ButterflyAnalysis.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ButterflyAnalysis(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      analysisText: serializer.fromJson<String>(json['analysisText']),
      predictedDirection:
          serializer.fromJson<String>(json['predictedDirection']),
      tokenCost: serializer.fromJson<int>(json['tokenCost']),
      estimatedCost: serializer.fromJson<double>(json['estimatedCost']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'eventId': serializer.toJson<String>(eventId),
      'analysisText': serializer.toJson<String>(analysisText),
      'predictedDirection': serializer.toJson<String>(predictedDirection),
      'tokenCost': serializer.toJson<int>(tokenCost),
      'estimatedCost': serializer.toJson<double>(estimatedCost),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ButterflyAnalysis copyWith(
          {String? id,
          String? worldId,
          String? eventId,
          String? analysisText,
          String? predictedDirection,
          int? tokenCost,
          double? estimatedCost,
          DateTime? createdAt}) =>
      ButterflyAnalysis(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        eventId: eventId ?? this.eventId,
        analysisText: analysisText ?? this.analysisText,
        predictedDirection: predictedDirection ?? this.predictedDirection,
        tokenCost: tokenCost ?? this.tokenCost,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        createdAt: createdAt ?? this.createdAt,
      );
  ButterflyAnalysis copyWithCompanion(ButterflyAnalysesCompanion data) {
    return ButterflyAnalysis(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      analysisText: data.analysisText.present
          ? data.analysisText.value
          : this.analysisText,
      predictedDirection: data.predictedDirection.present
          ? data.predictedDirection.value
          : this.predictedDirection,
      tokenCost: data.tokenCost.present ? data.tokenCost.value : this.tokenCost,
      estimatedCost: data.estimatedCost.present
          ? data.estimatedCost.value
          : this.estimatedCost,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ButterflyAnalysis(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('eventId: $eventId, ')
          ..write('analysisText: $analysisText, ')
          ..write('predictedDirection: $predictedDirection, ')
          ..write('tokenCost: $tokenCost, ')
          ..write('estimatedCost: $estimatedCost, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, worldId, eventId, analysisText,
      predictedDirection, tokenCost, estimatedCost, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ButterflyAnalysis &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.eventId == this.eventId &&
          other.analysisText == this.analysisText &&
          other.predictedDirection == this.predictedDirection &&
          other.tokenCost == this.tokenCost &&
          other.estimatedCost == this.estimatedCost &&
          other.createdAt == this.createdAt);
}

class ButterflyAnalysesCompanion extends UpdateCompanion<ButterflyAnalysis> {
  Value<String> id;
  Value<String> worldId;
  Value<String> eventId;
  Value<String> analysisText;
  Value<String> predictedDirection;
  Value<int> tokenCost;
  Value<double> estimatedCost;
  Value<DateTime> createdAt;
  Value<int> rowid;
  ButterflyAnalysesCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.analysisText = const Value.absent(),
    this.predictedDirection = const Value.absent(),
    this.tokenCost = const Value.absent(),
    this.estimatedCost = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ButterflyAnalysesCompanion.insert({
    required String id,
    required String worldId,
    required String eventId,
    required String analysisText,
    required String predictedDirection,
    required int tokenCost,
    required double estimatedCost,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        eventId = Value(eventId),
        analysisText = Value(analysisText),
        predictedDirection = Value(predictedDirection),
        tokenCost = Value(tokenCost),
        estimatedCost = Value(estimatedCost),
        createdAt = Value(createdAt);
  static Insertable<ButterflyAnalysis> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? eventId,
    Expression<String>? analysisText,
    Expression<String>? predictedDirection,
    Expression<int>? tokenCost,
    Expression<double>? estimatedCost,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (eventId != null) 'event_id': eventId,
      if (analysisText != null) 'analysis_text': analysisText,
      if (predictedDirection != null) 'predicted_direction': predictedDirection,
      if (tokenCost != null) 'token_cost': tokenCost,
      if (estimatedCost != null) 'estimated_cost': estimatedCost,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ButterflyAnalysesCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? eventId,
      Value<String>? analysisText,
      Value<String>? predictedDirection,
      Value<int>? tokenCost,
      Value<double>? estimatedCost,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ButterflyAnalysesCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      eventId: eventId ?? this.eventId,
      analysisText: analysisText ?? this.analysisText,
      predictedDirection: predictedDirection ?? this.predictedDirection,
      tokenCost: tokenCost ?? this.tokenCost,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (analysisText.present) {
      map['analysis_text'] = Variable<String>(analysisText.value);
    }
    if (predictedDirection.present) {
      map['predicted_direction'] = Variable<String>(predictedDirection.value);
    }
    if (tokenCost.present) {
      map['token_cost'] = Variable<int>(tokenCost.value);
    }
    if (estimatedCost.present) {
      map['estimated_cost'] = Variable<double>(estimatedCost.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ButterflyAnalysesCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('eventId: $eventId, ')
          ..write('analysisText: $analysisText, ')
          ..write('predictedDirection: $predictedDirection, ')
          ..write('tokenCost: $tokenCost, ')
          ..write('estimatedCost: $estimatedCost, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SceneSummariesTable extends SceneSummaries
    with TableInfo<$SceneSummariesTable, SceneSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SceneSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sceneIdMeta =
      const VerificationMeta('sceneId');
  @override
  late final GeneratedColumn<String> sceneId = GeneratedColumn<String>(
      'scene_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keywordsMeta =
      const VerificationMeta('keywords');
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
      'keywords', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _charactersMeta =
      const VerificationMeta('characters');
  @override
  late final GeneratedColumn<String> characters = GeneratedColumn<String>(
      'characters', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inStoryDayMeta =
      const VerificationMeta('inStoryDay');
  @override
  late final GeneratedColumn<String> inStoryDay = GeneratedColumn<String>(
      'in_story_day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _causeEventMeta =
      const VerificationMeta('causeEvent');
  @override
  late final GeneratedColumn<String> causeEvent = GeneratedColumn<String>(
      'cause_event', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _effectEventMeta =
      const VerificationMeta('effectEvent');
  @override
  late final GeneratedColumn<String> effectEvent = GeneratedColumn<String>(
      'effect_event', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _characterEmotionsMeta =
      const VerificationMeta('characterEmotions');
  @override
  late final GeneratedColumn<String> characterEmotions =
      GeneratedColumn<String>('character_emotions', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conflictTypeMeta =
      const VerificationMeta('conflictType');
  @override
  late final GeneratedColumn<String> conflictType = GeneratedColumn<String>(
      'conflict_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _suspenseTagsMeta =
      const VerificationMeta('suspenseTags');
  @override
  late final GeneratedColumn<String> suspenseTags = GeneratedColumn<String>(
      'suspense_tags', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyDialoguesMeta =
      const VerificationMeta('keyDialogues');
  @override
  late final GeneratedColumn<String> keyDialogues = GeneratedColumn<String>(
      'key_dialogues', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _signatureMomentsMeta =
      const VerificationMeta('signatureMoments');
  @override
  late final GeneratedColumn<String> signatureMoments = GeneratedColumn<String>(
      'signature_moments', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _foreshadowingIdsMeta =
      const VerificationMeta('foreshadowingIds');
  @override
  late final GeneratedColumn<String> foreshadowingIds = GeneratedColumn<String>(
      'foreshadowing_ids', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordCountMeta =
      const VerificationMeta('wordCount');
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
      'word_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sceneOrderMeta =
      const VerificationMeta('sceneOrder');
  @override
  late final GeneratedColumn<int> sceneOrder = GeneratedColumn<int>(
      'scene_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sceneId,
        chapterId,
        worldId,
        summary,
        keywords,
        characters,
        location,
        mood,
        inStoryDay,
        causeEvent,
        effectEvent,
        characterEmotions,
        conflictType,
        suspenseTags,
        keyDialogues,
        signatureMoments,
        foreshadowingIds,
        wordCount,
        sceneOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scene_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<SceneSummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scene_id')) {
      context.handle(_sceneIdMeta,
          sceneId.isAcceptableOrUnknown(data['scene_id']!, _sceneIdMeta));
    } else if (isInserting) {
      context.missing(_sceneIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('keywords')) {
      context.handle(_keywordsMeta,
          keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta));
    } else if (isInserting) {
      context.missing(_keywordsMeta);
    }
    if (data.containsKey('characters')) {
      context.handle(
          _charactersMeta,
          characters.isAcceptableOrUnknown(
              data['characters']!, _charactersMeta));
    } else if (isInserting) {
      context.missing(_charactersMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('in_story_day')) {
      context.handle(
          _inStoryDayMeta,
          inStoryDay.isAcceptableOrUnknown(
              data['in_story_day']!, _inStoryDayMeta));
    } else if (isInserting) {
      context.missing(_inStoryDayMeta);
    }
    if (data.containsKey('cause_event')) {
      context.handle(
          _causeEventMeta,
          causeEvent.isAcceptableOrUnknown(
              data['cause_event']!, _causeEventMeta));
    } else if (isInserting) {
      context.missing(_causeEventMeta);
    }
    if (data.containsKey('effect_event')) {
      context.handle(
          _effectEventMeta,
          effectEvent.isAcceptableOrUnknown(
              data['effect_event']!, _effectEventMeta));
    } else if (isInserting) {
      context.missing(_effectEventMeta);
    }
    if (data.containsKey('character_emotions')) {
      context.handle(
          _characterEmotionsMeta,
          characterEmotions.isAcceptableOrUnknown(
              data['character_emotions']!, _characterEmotionsMeta));
    } else if (isInserting) {
      context.missing(_characterEmotionsMeta);
    }
    if (data.containsKey('conflict_type')) {
      context.handle(
          _conflictTypeMeta,
          conflictType.isAcceptableOrUnknown(
              data['conflict_type']!, _conflictTypeMeta));
    } else if (isInserting) {
      context.missing(_conflictTypeMeta);
    }
    if (data.containsKey('suspense_tags')) {
      context.handle(
          _suspenseTagsMeta,
          suspenseTags.isAcceptableOrUnknown(
              data['suspense_tags']!, _suspenseTagsMeta));
    } else if (isInserting) {
      context.missing(_suspenseTagsMeta);
    }
    if (data.containsKey('key_dialogues')) {
      context.handle(
          _keyDialoguesMeta,
          keyDialogues.isAcceptableOrUnknown(
              data['key_dialogues']!, _keyDialoguesMeta));
    } else if (isInserting) {
      context.missing(_keyDialoguesMeta);
    }
    if (data.containsKey('signature_moments')) {
      context.handle(
          _signatureMomentsMeta,
          signatureMoments.isAcceptableOrUnknown(
              data['signature_moments']!, _signatureMomentsMeta));
    } else if (isInserting) {
      context.missing(_signatureMomentsMeta);
    }
    if (data.containsKey('foreshadowing_ids')) {
      context.handle(
          _foreshadowingIdsMeta,
          foreshadowingIds.isAcceptableOrUnknown(
              data['foreshadowing_ids']!, _foreshadowingIdsMeta));
    } else if (isInserting) {
      context.missing(_foreshadowingIdsMeta);
    }
    if (data.containsKey('word_count')) {
      context.handle(_wordCountMeta,
          wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta));
    } else if (isInserting) {
      context.missing(_wordCountMeta);
    }
    if (data.containsKey('scene_order')) {
      context.handle(
          _sceneOrderMeta,
          sceneOrder.isAcceptableOrUnknown(
              data['scene_order']!, _sceneOrderMeta));
    } else if (isInserting) {
      context.missing(_sceneOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SceneSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SceneSummary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sceneId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scene_id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      keywords: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}keywords'])!,
      characters: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}characters'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood'])!,
      inStoryDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}in_story_day'])!,
      causeEvent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cause_event'])!,
      effectEvent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effect_event'])!,
      characterEmotions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}character_emotions'])!,
      conflictType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conflict_type'])!,
      suspenseTags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}suspense_tags'])!,
      keyDialogues: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_dialogues'])!,
      signatureMoments: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}signature_moments'])!,
      foreshadowingIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}foreshadowing_ids'])!,
      wordCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_count'])!,
      sceneOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scene_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SceneSummariesTable createAlias(String alias) {
    return $SceneSummariesTable(attachedDatabase, alias);
  }
}

class SceneSummary extends DataClass implements Insertable<SceneSummary> {
  String id;
  String sceneId;
  String chapterId;
  String worldId;
  String summary;
  String keywords;
  String characters;
  String location;
  String mood;
  String inStoryDay;
  String causeEvent;
  String effectEvent;
  String characterEmotions;
  String conflictType;
  String suspenseTags;
  String keyDialogues;
  String signatureMoments;
  String foreshadowingIds;
  int wordCount;
  int sceneOrder;
  DateTime createdAt;
  DateTime updatedAt;
  SceneSummary(
      {required this.id,
      required this.sceneId,
      required this.chapterId,
      required this.worldId,
      required this.summary,
      required this.keywords,
      required this.characters,
      required this.location,
      required this.mood,
      required this.inStoryDay,
      required this.causeEvent,
      required this.effectEvent,
      required this.characterEmotions,
      required this.conflictType,
      required this.suspenseTags,
      required this.keyDialogues,
      required this.signatureMoments,
      required this.foreshadowingIds,
      required this.wordCount,
      required this.sceneOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scene_id'] = Variable<String>(sceneId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['world_id'] = Variable<String>(worldId);
    map['summary'] = Variable<String>(summary);
    map['keywords'] = Variable<String>(keywords);
    map['characters'] = Variable<String>(characters);
    map['location'] = Variable<String>(location);
    map['mood'] = Variable<String>(mood);
    map['in_story_day'] = Variable<String>(inStoryDay);
    map['cause_event'] = Variable<String>(causeEvent);
    map['effect_event'] = Variable<String>(effectEvent);
    map['character_emotions'] = Variable<String>(characterEmotions);
    map['conflict_type'] = Variable<String>(conflictType);
    map['suspense_tags'] = Variable<String>(suspenseTags);
    map['key_dialogues'] = Variable<String>(keyDialogues);
    map['signature_moments'] = Variable<String>(signatureMoments);
    map['foreshadowing_ids'] = Variable<String>(foreshadowingIds);
    map['word_count'] = Variable<int>(wordCount);
    map['scene_order'] = Variable<int>(sceneOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SceneSummariesCompanion toCompanion(bool nullToAbsent) {
    return SceneSummariesCompanion(
      id: Value(id),
      sceneId: Value(sceneId),
      chapterId: Value(chapterId),
      worldId: Value(worldId),
      summary: Value(summary),
      keywords: Value(keywords),
      characters: Value(characters),
      location: Value(location),
      mood: Value(mood),
      inStoryDay: Value(inStoryDay),
      causeEvent: Value(causeEvent),
      effectEvent: Value(effectEvent),
      characterEmotions: Value(characterEmotions),
      conflictType: Value(conflictType),
      suspenseTags: Value(suspenseTags),
      keyDialogues: Value(keyDialogues),
      signatureMoments: Value(signatureMoments),
      foreshadowingIds: Value(foreshadowingIds),
      wordCount: Value(wordCount),
      sceneOrder: Value(sceneOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SceneSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SceneSummary(
      id: serializer.fromJson<String>(json['id']),
      sceneId: serializer.fromJson<String>(json['sceneId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      summary: serializer.fromJson<String>(json['summary']),
      keywords: serializer.fromJson<String>(json['keywords']),
      characters: serializer.fromJson<String>(json['characters']),
      location: serializer.fromJson<String>(json['location']),
      mood: serializer.fromJson<String>(json['mood']),
      inStoryDay: serializer.fromJson<String>(json['inStoryDay']),
      causeEvent: serializer.fromJson<String>(json['causeEvent']),
      effectEvent: serializer.fromJson<String>(json['effectEvent']),
      characterEmotions: serializer.fromJson<String>(json['characterEmotions']),
      conflictType: serializer.fromJson<String>(json['conflictType']),
      suspenseTags: serializer.fromJson<String>(json['suspenseTags']),
      keyDialogues: serializer.fromJson<String>(json['keyDialogues']),
      signatureMoments: serializer.fromJson<String>(json['signatureMoments']),
      foreshadowingIds: serializer.fromJson<String>(json['foreshadowingIds']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      sceneOrder: serializer.fromJson<int>(json['sceneOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sceneId': serializer.toJson<String>(sceneId),
      'chapterId': serializer.toJson<String>(chapterId),
      'worldId': serializer.toJson<String>(worldId),
      'summary': serializer.toJson<String>(summary),
      'keywords': serializer.toJson<String>(keywords),
      'characters': serializer.toJson<String>(characters),
      'location': serializer.toJson<String>(location),
      'mood': serializer.toJson<String>(mood),
      'inStoryDay': serializer.toJson<String>(inStoryDay),
      'causeEvent': serializer.toJson<String>(causeEvent),
      'effectEvent': serializer.toJson<String>(effectEvent),
      'characterEmotions': serializer.toJson<String>(characterEmotions),
      'conflictType': serializer.toJson<String>(conflictType),
      'suspenseTags': serializer.toJson<String>(suspenseTags),
      'keyDialogues': serializer.toJson<String>(keyDialogues),
      'signatureMoments': serializer.toJson<String>(signatureMoments),
      'foreshadowingIds': serializer.toJson<String>(foreshadowingIds),
      'wordCount': serializer.toJson<int>(wordCount),
      'sceneOrder': serializer.toJson<int>(sceneOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SceneSummary copyWith(
          {String? id,
          String? sceneId,
          String? chapterId,
          String? worldId,
          String? summary,
          String? keywords,
          String? characters,
          String? location,
          String? mood,
          String? inStoryDay,
          String? causeEvent,
          String? effectEvent,
          String? characterEmotions,
          String? conflictType,
          String? suspenseTags,
          String? keyDialogues,
          String? signatureMoments,
          String? foreshadowingIds,
          int? wordCount,
          int? sceneOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SceneSummary(
        id: id ?? this.id,
        sceneId: sceneId ?? this.sceneId,
        chapterId: chapterId ?? this.chapterId,
        worldId: worldId ?? this.worldId,
        summary: summary ?? this.summary,
        keywords: keywords ?? this.keywords,
        characters: characters ?? this.characters,
        location: location ?? this.location,
        mood: mood ?? this.mood,
        inStoryDay: inStoryDay ?? this.inStoryDay,
        causeEvent: causeEvent ?? this.causeEvent,
        effectEvent: effectEvent ?? this.effectEvent,
        characterEmotions: characterEmotions ?? this.characterEmotions,
        conflictType: conflictType ?? this.conflictType,
        suspenseTags: suspenseTags ?? this.suspenseTags,
        keyDialogues: keyDialogues ?? this.keyDialogues,
        signatureMoments: signatureMoments ?? this.signatureMoments,
        foreshadowingIds: foreshadowingIds ?? this.foreshadowingIds,
        wordCount: wordCount ?? this.wordCount,
        sceneOrder: sceneOrder ?? this.sceneOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SceneSummary copyWithCompanion(SceneSummariesCompanion data) {
    return SceneSummary(
      id: data.id.present ? data.id.value : this.id,
      sceneId: data.sceneId.present ? data.sceneId.value : this.sceneId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      summary: data.summary.present ? data.summary.value : this.summary,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
      characters:
          data.characters.present ? data.characters.value : this.characters,
      location: data.location.present ? data.location.value : this.location,
      mood: data.mood.present ? data.mood.value : this.mood,
      inStoryDay:
          data.inStoryDay.present ? data.inStoryDay.value : this.inStoryDay,
      causeEvent:
          data.causeEvent.present ? data.causeEvent.value : this.causeEvent,
      effectEvent:
          data.effectEvent.present ? data.effectEvent.value : this.effectEvent,
      characterEmotions: data.characterEmotions.present
          ? data.characterEmotions.value
          : this.characterEmotions,
      conflictType: data.conflictType.present
          ? data.conflictType.value
          : this.conflictType,
      suspenseTags: data.suspenseTags.present
          ? data.suspenseTags.value
          : this.suspenseTags,
      keyDialogues: data.keyDialogues.present
          ? data.keyDialogues.value
          : this.keyDialogues,
      signatureMoments: data.signatureMoments.present
          ? data.signatureMoments.value
          : this.signatureMoments,
      foreshadowingIds: data.foreshadowingIds.present
          ? data.foreshadowingIds.value
          : this.foreshadowingIds,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      sceneOrder:
          data.sceneOrder.present ? data.sceneOrder.value : this.sceneOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SceneSummary(')
          ..write('id: $id, ')
          ..write('sceneId: $sceneId, ')
          ..write('chapterId: $chapterId, ')
          ..write('worldId: $worldId, ')
          ..write('summary: $summary, ')
          ..write('keywords: $keywords, ')
          ..write('characters: $characters, ')
          ..write('location: $location, ')
          ..write('mood: $mood, ')
          ..write('inStoryDay: $inStoryDay, ')
          ..write('causeEvent: $causeEvent, ')
          ..write('effectEvent: $effectEvent, ')
          ..write('characterEmotions: $characterEmotions, ')
          ..write('conflictType: $conflictType, ')
          ..write('suspenseTags: $suspenseTags, ')
          ..write('keyDialogues: $keyDialogues, ')
          ..write('signatureMoments: $signatureMoments, ')
          ..write('foreshadowingIds: $foreshadowingIds, ')
          ..write('wordCount: $wordCount, ')
          ..write('sceneOrder: $sceneOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        sceneId,
        chapterId,
        worldId,
        summary,
        keywords,
        characters,
        location,
        mood,
        inStoryDay,
        causeEvent,
        effectEvent,
        characterEmotions,
        conflictType,
        suspenseTags,
        keyDialogues,
        signatureMoments,
        foreshadowingIds,
        wordCount,
        sceneOrder,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SceneSummary &&
          other.id == this.id &&
          other.sceneId == this.sceneId &&
          other.chapterId == this.chapterId &&
          other.worldId == this.worldId &&
          other.summary == this.summary &&
          other.keywords == this.keywords &&
          other.characters == this.characters &&
          other.location == this.location &&
          other.mood == this.mood &&
          other.inStoryDay == this.inStoryDay &&
          other.causeEvent == this.causeEvent &&
          other.effectEvent == this.effectEvent &&
          other.characterEmotions == this.characterEmotions &&
          other.conflictType == this.conflictType &&
          other.suspenseTags == this.suspenseTags &&
          other.keyDialogues == this.keyDialogues &&
          other.signatureMoments == this.signatureMoments &&
          other.foreshadowingIds == this.foreshadowingIds &&
          other.wordCount == this.wordCount &&
          other.sceneOrder == this.sceneOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SceneSummariesCompanion extends UpdateCompanion<SceneSummary> {
  Value<String> id;
  Value<String> sceneId;
  Value<String> chapterId;
  Value<String> worldId;
  Value<String> summary;
  Value<String> keywords;
  Value<String> characters;
  Value<String> location;
  Value<String> mood;
  Value<String> inStoryDay;
  Value<String> causeEvent;
  Value<String> effectEvent;
  Value<String> characterEmotions;
  Value<String> conflictType;
  Value<String> suspenseTags;
  Value<String> keyDialogues;
  Value<String> signatureMoments;
  Value<String> foreshadowingIds;
  Value<int> wordCount;
  Value<int> sceneOrder;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  SceneSummariesCompanion({
    this.id = const Value.absent(),
    this.sceneId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.summary = const Value.absent(),
    this.keywords = const Value.absent(),
    this.characters = const Value.absent(),
    this.location = const Value.absent(),
    this.mood = const Value.absent(),
    this.inStoryDay = const Value.absent(),
    this.causeEvent = const Value.absent(),
    this.effectEvent = const Value.absent(),
    this.characterEmotions = const Value.absent(),
    this.conflictType = const Value.absent(),
    this.suspenseTags = const Value.absent(),
    this.keyDialogues = const Value.absent(),
    this.signatureMoments = const Value.absent(),
    this.foreshadowingIds = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.sceneOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SceneSummariesCompanion.insert({
    required String id,
    required String sceneId,
    required String chapterId,
    required String worldId,
    required String summary,
    required String keywords,
    required String characters,
    required String location,
    required String mood,
    required String inStoryDay,
    required String causeEvent,
    required String effectEvent,
    required String characterEmotions,
    required String conflictType,
    required String suspenseTags,
    required String keyDialogues,
    required String signatureMoments,
    required String foreshadowingIds,
    required int wordCount,
    required int sceneOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sceneId = Value(sceneId),
        chapterId = Value(chapterId),
        worldId = Value(worldId),
        summary = Value(summary),
        keywords = Value(keywords),
        characters = Value(characters),
        location = Value(location),
        mood = Value(mood),
        inStoryDay = Value(inStoryDay),
        causeEvent = Value(causeEvent),
        effectEvent = Value(effectEvent),
        characterEmotions = Value(characterEmotions),
        conflictType = Value(conflictType),
        suspenseTags = Value(suspenseTags),
        keyDialogues = Value(keyDialogues),
        signatureMoments = Value(signatureMoments),
        foreshadowingIds = Value(foreshadowingIds),
        wordCount = Value(wordCount),
        sceneOrder = Value(sceneOrder),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SceneSummary> custom({
    Expression<String>? id,
    Expression<String>? sceneId,
    Expression<String>? chapterId,
    Expression<String>? worldId,
    Expression<String>? summary,
    Expression<String>? keywords,
    Expression<String>? characters,
    Expression<String>? location,
    Expression<String>? mood,
    Expression<String>? inStoryDay,
    Expression<String>? causeEvent,
    Expression<String>? effectEvent,
    Expression<String>? characterEmotions,
    Expression<String>? conflictType,
    Expression<String>? suspenseTags,
    Expression<String>? keyDialogues,
    Expression<String>? signatureMoments,
    Expression<String>? foreshadowingIds,
    Expression<int>? wordCount,
    Expression<int>? sceneOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sceneId != null) 'scene_id': sceneId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (worldId != null) 'world_id': worldId,
      if (summary != null) 'summary': summary,
      if (keywords != null) 'keywords': keywords,
      if (characters != null) 'characters': characters,
      if (location != null) 'location': location,
      if (mood != null) 'mood': mood,
      if (inStoryDay != null) 'in_story_day': inStoryDay,
      if (causeEvent != null) 'cause_event': causeEvent,
      if (effectEvent != null) 'effect_event': effectEvent,
      if (characterEmotions != null) 'character_emotions': characterEmotions,
      if (conflictType != null) 'conflict_type': conflictType,
      if (suspenseTags != null) 'suspense_tags': suspenseTags,
      if (keyDialogues != null) 'key_dialogues': keyDialogues,
      if (signatureMoments != null) 'signature_moments': signatureMoments,
      if (foreshadowingIds != null) 'foreshadowing_ids': foreshadowingIds,
      if (wordCount != null) 'word_count': wordCount,
      if (sceneOrder != null) 'scene_order': sceneOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SceneSummariesCompanion copyWith(
      {Value<String>? id,
      Value<String>? sceneId,
      Value<String>? chapterId,
      Value<String>? worldId,
      Value<String>? summary,
      Value<String>? keywords,
      Value<String>? characters,
      Value<String>? location,
      Value<String>? mood,
      Value<String>? inStoryDay,
      Value<String>? causeEvent,
      Value<String>? effectEvent,
      Value<String>? characterEmotions,
      Value<String>? conflictType,
      Value<String>? suspenseTags,
      Value<String>? keyDialogues,
      Value<String>? signatureMoments,
      Value<String>? foreshadowingIds,
      Value<int>? wordCount,
      Value<int>? sceneOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SceneSummariesCompanion(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,
      chapterId: chapterId ?? this.chapterId,
      worldId: worldId ?? this.worldId,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      characters: characters ?? this.characters,
      location: location ?? this.location,
      mood: mood ?? this.mood,
      inStoryDay: inStoryDay ?? this.inStoryDay,
      causeEvent: causeEvent ?? this.causeEvent,
      effectEvent: effectEvent ?? this.effectEvent,
      characterEmotions: characterEmotions ?? this.characterEmotions,
      conflictType: conflictType ?? this.conflictType,
      suspenseTags: suspenseTags ?? this.suspenseTags,
      keyDialogues: keyDialogues ?? this.keyDialogues,
      signatureMoments: signatureMoments ?? this.signatureMoments,
      foreshadowingIds: foreshadowingIds ?? this.foreshadowingIds,
      wordCount: wordCount ?? this.wordCount,
      sceneOrder: sceneOrder ?? this.sceneOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sceneId.present) {
      map['scene_id'] = Variable<String>(sceneId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    if (characters.present) {
      map['characters'] = Variable<String>(characters.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (inStoryDay.present) {
      map['in_story_day'] = Variable<String>(inStoryDay.value);
    }
    if (causeEvent.present) {
      map['cause_event'] = Variable<String>(causeEvent.value);
    }
    if (effectEvent.present) {
      map['effect_event'] = Variable<String>(effectEvent.value);
    }
    if (characterEmotions.present) {
      map['character_emotions'] = Variable<String>(characterEmotions.value);
    }
    if (conflictType.present) {
      map['conflict_type'] = Variable<String>(conflictType.value);
    }
    if (suspenseTags.present) {
      map['suspense_tags'] = Variable<String>(suspenseTags.value);
    }
    if (keyDialogues.present) {
      map['key_dialogues'] = Variable<String>(keyDialogues.value);
    }
    if (signatureMoments.present) {
      map['signature_moments'] = Variable<String>(signatureMoments.value);
    }
    if (foreshadowingIds.present) {
      map['foreshadowing_ids'] = Variable<String>(foreshadowingIds.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (sceneOrder.present) {
      map['scene_order'] = Variable<int>(sceneOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SceneSummariesCompanion(')
          ..write('id: $id, ')
          ..write('sceneId: $sceneId, ')
          ..write('chapterId: $chapterId, ')
          ..write('worldId: $worldId, ')
          ..write('summary: $summary, ')
          ..write('keywords: $keywords, ')
          ..write('characters: $characters, ')
          ..write('location: $location, ')
          ..write('mood: $mood, ')
          ..write('inStoryDay: $inStoryDay, ')
          ..write('causeEvent: $causeEvent, ')
          ..write('effectEvent: $effectEvent, ')
          ..write('characterEmotions: $characterEmotions, ')
          ..write('conflictType: $conflictType, ')
          ..write('suspenseTags: $suspenseTags, ')
          ..write('keyDialogues: $keyDialogues, ')
          ..write('signatureMoments: $signatureMoments, ')
          ..write('foreshadowingIds: $foreshadowingIds, ')
          ..write('wordCount: $wordCount, ')
          ..write('sceneOrder: $sceneOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChapterSummariesTable extends ChapterSummaries
    with TableInfo<$ChapterSummariesTable, ChapterSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _volumeIdMeta =
      const VerificationMeta('volumeId');
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
      'volume_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hookMeta = const VerificationMeta('hook');
  @override
  late final GeneratedColumn<String> hook = GeneratedColumn<String>(
      'hook', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _majorEventsMeta =
      const VerificationMeta('majorEvents');
  @override
  late final GeneratedColumn<String> majorEvents = GeneratedColumn<String>(
      'major_events', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _characterArcsMeta =
      const VerificationMeta('characterArcs');
  @override
  late final GeneratedColumn<String> characterArcs = GeneratedColumn<String>(
      'character_arcs', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conflictResolutionMeta =
      const VerificationMeta('conflictResolution');
  @override
  late final GeneratedColumn<String> conflictResolution =
      GeneratedColumn<String>('conflict_resolution', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emotionalClimaxMeta =
      const VerificationMeta('emotionalClimax');
  @override
  late final GeneratedColumn<String> emotionalClimax = GeneratedColumn<String>(
      'emotional_climax', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unansweredQuestionsMeta =
      const VerificationMeta('unansweredQuestions');
  @override
  late final GeneratedColumn<String> unansweredQuestions =
      GeneratedColumn<String>('unanswered_questions', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sceneCountMeta =
      const VerificationMeta('sceneCount');
  @override
  late final GeneratedColumn<int> sceneCount = GeneratedColumn<int>(
      'scene_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        chapterId,
        volumeId,
        worldId,
        summary,
        hook,
        majorEvents,
        characterArcs,
        conflictResolution,
        emotionalClimax,
        unansweredQuestions,
        sceneCount,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<ChapterSummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(_volumeIdMeta,
          volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta));
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('hook')) {
      context.handle(
          _hookMeta, hook.isAcceptableOrUnknown(data['hook']!, _hookMeta));
    } else if (isInserting) {
      context.missing(_hookMeta);
    }
    if (data.containsKey('major_events')) {
      context.handle(
          _majorEventsMeta,
          majorEvents.isAcceptableOrUnknown(
              data['major_events']!, _majorEventsMeta));
    } else if (isInserting) {
      context.missing(_majorEventsMeta);
    }
    if (data.containsKey('character_arcs')) {
      context.handle(
          _characterArcsMeta,
          characterArcs.isAcceptableOrUnknown(
              data['character_arcs']!, _characterArcsMeta));
    } else if (isInserting) {
      context.missing(_characterArcsMeta);
    }
    if (data.containsKey('conflict_resolution')) {
      context.handle(
          _conflictResolutionMeta,
          conflictResolution.isAcceptableOrUnknown(
              data['conflict_resolution']!, _conflictResolutionMeta));
    } else if (isInserting) {
      context.missing(_conflictResolutionMeta);
    }
    if (data.containsKey('emotional_climax')) {
      context.handle(
          _emotionalClimaxMeta,
          emotionalClimax.isAcceptableOrUnknown(
              data['emotional_climax']!, _emotionalClimaxMeta));
    } else if (isInserting) {
      context.missing(_emotionalClimaxMeta);
    }
    if (data.containsKey('unanswered_questions')) {
      context.handle(
          _unansweredQuestionsMeta,
          unansweredQuestions.isAcceptableOrUnknown(
              data['unanswered_questions']!, _unansweredQuestionsMeta));
    } else if (isInserting) {
      context.missing(_unansweredQuestionsMeta);
    }
    if (data.containsKey('scene_count')) {
      context.handle(
          _sceneCountMeta,
          sceneCount.isAcceptableOrUnknown(
              data['scene_count']!, _sceneCountMeta));
    } else if (isInserting) {
      context.missing(_sceneCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChapterSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterSummary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_id'])!,
      volumeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}volume_id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      hook: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hook'])!,
      majorEvents: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}major_events'])!,
      characterArcs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character_arcs'])!,
      conflictResolution: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conflict_resolution'])!,
      emotionalClimax: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}emotional_climax'])!,
      unansweredQuestions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}unanswered_questions'])!,
      sceneCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scene_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChapterSummariesTable createAlias(String alias) {
    return $ChapterSummariesTable(attachedDatabase, alias);
  }
}

class ChapterSummary extends DataClass implements Insertable<ChapterSummary> {
  String id;
  String chapterId;
  String volumeId;
  String worldId;
  String summary;
  String hook;
  String majorEvents;
  String characterArcs;
  String conflictResolution;
  String emotionalClimax;
  String unansweredQuestions;
  int sceneCount;
  DateTime createdAt;
  DateTime updatedAt;
  ChapterSummary(
      {required this.id,
      required this.chapterId,
      required this.volumeId,
      required this.worldId,
      required this.summary,
      required this.hook,
      required this.majorEvents,
      required this.characterArcs,
      required this.conflictResolution,
      required this.emotionalClimax,
      required this.unansweredQuestions,
      required this.sceneCount,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chapter_id'] = Variable<String>(chapterId);
    map['volume_id'] = Variable<String>(volumeId);
    map['world_id'] = Variable<String>(worldId);
    map['summary'] = Variable<String>(summary);
    map['hook'] = Variable<String>(hook);
    map['major_events'] = Variable<String>(majorEvents);
    map['character_arcs'] = Variable<String>(characterArcs);
    map['conflict_resolution'] = Variable<String>(conflictResolution);
    map['emotional_climax'] = Variable<String>(emotionalClimax);
    map['unanswered_questions'] = Variable<String>(unansweredQuestions);
    map['scene_count'] = Variable<int>(sceneCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChapterSummariesCompanion toCompanion(bool nullToAbsent) {
    return ChapterSummariesCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      volumeId: Value(volumeId),
      worldId: Value(worldId),
      summary: Value(summary),
      hook: Value(hook),
      majorEvents: Value(majorEvents),
      characterArcs: Value(characterArcs),
      conflictResolution: Value(conflictResolution),
      emotionalClimax: Value(emotionalClimax),
      unansweredQuestions: Value(unansweredQuestions),
      sceneCount: Value(sceneCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChapterSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterSummary(
      id: serializer.fromJson<String>(json['id']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      summary: serializer.fromJson<String>(json['summary']),
      hook: serializer.fromJson<String>(json['hook']),
      majorEvents: serializer.fromJson<String>(json['majorEvents']),
      characterArcs: serializer.fromJson<String>(json['characterArcs']),
      conflictResolution:
          serializer.fromJson<String>(json['conflictResolution']),
      emotionalClimax: serializer.fromJson<String>(json['emotionalClimax']),
      unansweredQuestions:
          serializer.fromJson<String>(json['unansweredQuestions']),
      sceneCount: serializer.fromJson<int>(json['sceneCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chapterId': serializer.toJson<String>(chapterId),
      'volumeId': serializer.toJson<String>(volumeId),
      'worldId': serializer.toJson<String>(worldId),
      'summary': serializer.toJson<String>(summary),
      'hook': serializer.toJson<String>(hook),
      'majorEvents': serializer.toJson<String>(majorEvents),
      'characterArcs': serializer.toJson<String>(characterArcs),
      'conflictResolution': serializer.toJson<String>(conflictResolution),
      'emotionalClimax': serializer.toJson<String>(emotionalClimax),
      'unansweredQuestions': serializer.toJson<String>(unansweredQuestions),
      'sceneCount': serializer.toJson<int>(sceneCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChapterSummary copyWith(
          {String? id,
          String? chapterId,
          String? volumeId,
          String? worldId,
          String? summary,
          String? hook,
          String? majorEvents,
          String? characterArcs,
          String? conflictResolution,
          String? emotionalClimax,
          String? unansweredQuestions,
          int? sceneCount,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ChapterSummary(
        id: id ?? this.id,
        chapterId: chapterId ?? this.chapterId,
        volumeId: volumeId ?? this.volumeId,
        worldId: worldId ?? this.worldId,
        summary: summary ?? this.summary,
        hook: hook ?? this.hook,
        majorEvents: majorEvents ?? this.majorEvents,
        characterArcs: characterArcs ?? this.characterArcs,
        conflictResolution: conflictResolution ?? this.conflictResolution,
        emotionalClimax: emotionalClimax ?? this.emotionalClimax,
        unansweredQuestions: unansweredQuestions ?? this.unansweredQuestions,
        sceneCount: sceneCount ?? this.sceneCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChapterSummary copyWithCompanion(ChapterSummariesCompanion data) {
    return ChapterSummary(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      summary: data.summary.present ? data.summary.value : this.summary,
      hook: data.hook.present ? data.hook.value : this.hook,
      majorEvents:
          data.majorEvents.present ? data.majorEvents.value : this.majorEvents,
      characterArcs: data.characterArcs.present
          ? data.characterArcs.value
          : this.characterArcs,
      conflictResolution: data.conflictResolution.present
          ? data.conflictResolution.value
          : this.conflictResolution,
      emotionalClimax: data.emotionalClimax.present
          ? data.emotionalClimax.value
          : this.emotionalClimax,
      unansweredQuestions: data.unansweredQuestions.present
          ? data.unansweredQuestions.value
          : this.unansweredQuestions,
      sceneCount:
          data.sceneCount.present ? data.sceneCount.value : this.sceneCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterSummary(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('volumeId: $volumeId, ')
          ..write('worldId: $worldId, ')
          ..write('summary: $summary, ')
          ..write('hook: $hook, ')
          ..write('majorEvents: $majorEvents, ')
          ..write('characterArcs: $characterArcs, ')
          ..write('conflictResolution: $conflictResolution, ')
          ..write('emotionalClimax: $emotionalClimax, ')
          ..write('unansweredQuestions: $unansweredQuestions, ')
          ..write('sceneCount: $sceneCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      chapterId,
      volumeId,
      worldId,
      summary,
      hook,
      majorEvents,
      characterArcs,
      conflictResolution,
      emotionalClimax,
      unansweredQuestions,
      sceneCount,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterSummary &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.volumeId == this.volumeId &&
          other.worldId == this.worldId &&
          other.summary == this.summary &&
          other.hook == this.hook &&
          other.majorEvents == this.majorEvents &&
          other.characterArcs == this.characterArcs &&
          other.conflictResolution == this.conflictResolution &&
          other.emotionalClimax == this.emotionalClimax &&
          other.unansweredQuestions == this.unansweredQuestions &&
          other.sceneCount == this.sceneCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChapterSummariesCompanion extends UpdateCompanion<ChapterSummary> {
  Value<String> id;
  Value<String> chapterId;
  Value<String> volumeId;
  Value<String> worldId;
  Value<String> summary;
  Value<String> hook;
  Value<String> majorEvents;
  Value<String> characterArcs;
  Value<String> conflictResolution;
  Value<String> emotionalClimax;
  Value<String> unansweredQuestions;
  Value<int> sceneCount;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  ChapterSummariesCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.summary = const Value.absent(),
    this.hook = const Value.absent(),
    this.majorEvents = const Value.absent(),
    this.characterArcs = const Value.absent(),
    this.conflictResolution = const Value.absent(),
    this.emotionalClimax = const Value.absent(),
    this.unansweredQuestions = const Value.absent(),
    this.sceneCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChapterSummariesCompanion.insert({
    required String id,
    required String chapterId,
    required String volumeId,
    required String worldId,
    required String summary,
    required String hook,
    required String majorEvents,
    required String characterArcs,
    required String conflictResolution,
    required String emotionalClimax,
    required String unansweredQuestions,
    required int sceneCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        chapterId = Value(chapterId),
        volumeId = Value(volumeId),
        worldId = Value(worldId),
        summary = Value(summary),
        hook = Value(hook),
        majorEvents = Value(majorEvents),
        characterArcs = Value(characterArcs),
        conflictResolution = Value(conflictResolution),
        emotionalClimax = Value(emotionalClimax),
        unansweredQuestions = Value(unansweredQuestions),
        sceneCount = Value(sceneCount),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ChapterSummary> custom({
    Expression<String>? id,
    Expression<String>? chapterId,
    Expression<String>? volumeId,
    Expression<String>? worldId,
    Expression<String>? summary,
    Expression<String>? hook,
    Expression<String>? majorEvents,
    Expression<String>? characterArcs,
    Expression<String>? conflictResolution,
    Expression<String>? emotionalClimax,
    Expression<String>? unansweredQuestions,
    Expression<int>? sceneCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (volumeId != null) 'volume_id': volumeId,
      if (worldId != null) 'world_id': worldId,
      if (summary != null) 'summary': summary,
      if (hook != null) 'hook': hook,
      if (majorEvents != null) 'major_events': majorEvents,
      if (characterArcs != null) 'character_arcs': characterArcs,
      if (conflictResolution != null) 'conflict_resolution': conflictResolution,
      if (emotionalClimax != null) 'emotional_climax': emotionalClimax,
      if (unansweredQuestions != null)
        'unanswered_questions': unansweredQuestions,
      if (sceneCount != null) 'scene_count': sceneCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChapterSummariesCompanion copyWith(
      {Value<String>? id,
      Value<String>? chapterId,
      Value<String>? volumeId,
      Value<String>? worldId,
      Value<String>? summary,
      Value<String>? hook,
      Value<String>? majorEvents,
      Value<String>? characterArcs,
      Value<String>? conflictResolution,
      Value<String>? emotionalClimax,
      Value<String>? unansweredQuestions,
      Value<int>? sceneCount,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ChapterSummariesCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      volumeId: volumeId ?? this.volumeId,
      worldId: worldId ?? this.worldId,
      summary: summary ?? this.summary,
      hook: hook ?? this.hook,
      majorEvents: majorEvents ?? this.majorEvents,
      characterArcs: characterArcs ?? this.characterArcs,
      conflictResolution: conflictResolution ?? this.conflictResolution,
      emotionalClimax: emotionalClimax ?? this.emotionalClimax,
      unansweredQuestions: unansweredQuestions ?? this.unansweredQuestions,
      sceneCount: sceneCount ?? this.sceneCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (hook.present) {
      map['hook'] = Variable<String>(hook.value);
    }
    if (majorEvents.present) {
      map['major_events'] = Variable<String>(majorEvents.value);
    }
    if (characterArcs.present) {
      map['character_arcs'] = Variable<String>(characterArcs.value);
    }
    if (conflictResolution.present) {
      map['conflict_resolution'] = Variable<String>(conflictResolution.value);
    }
    if (emotionalClimax.present) {
      map['emotional_climax'] = Variable<String>(emotionalClimax.value);
    }
    if (unansweredQuestions.present) {
      map['unanswered_questions'] = Variable<String>(unansweredQuestions.value);
    }
    if (sceneCount.present) {
      map['scene_count'] = Variable<int>(sceneCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterSummariesCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('volumeId: $volumeId, ')
          ..write('worldId: $worldId, ')
          ..write('summary: $summary, ')
          ..write('hook: $hook, ')
          ..write('majorEvents: $majorEvents, ')
          ..write('characterArcs: $characterArcs, ')
          ..write('conflictResolution: $conflictResolution, ')
          ..write('emotionalClimax: $emotionalClimax, ')
          ..write('unansweredQuestions: $unansweredQuestions, ')
          ..write('sceneCount: $sceneCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VolumeSummariesTable extends VolumeSummaries
    with TableInfo<$VolumeSummariesTable, VolumeSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VolumeSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _volumeIdMeta =
      const VerificationMeta('volumeId');
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
      'volume_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mainCharactersMeta =
      const VerificationMeta('mainCharacters');
  @override
  late final GeneratedColumn<String> mainCharacters = GeneratedColumn<String>(
      'main_characters', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storyArcMeta =
      const VerificationMeta('storyArc');
  @override
  late final GeneratedColumn<String> storyArc = GeneratedColumn<String>(
      'story_arc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _majorPlotPointsMeta =
      const VerificationMeta('majorPlotPoints');
  @override
  late final GeneratedColumn<String> majorPlotPoints = GeneratedColumn<String>(
      'major_plot_points', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unresolvedThreadsMeta =
      const VerificationMeta('unresolvedThreads');
  @override
  late final GeneratedColumn<String> unresolvedThreads =
      GeneratedColumn<String>('unresolved_threads', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterCountMeta =
      const VerificationMeta('chapterCount');
  @override
  late final GeneratedColumn<int> chapterCount = GeneratedColumn<int>(
      'chapter_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        volumeId,
        worldId,
        summary,
        status,
        mainCharacters,
        storyArc,
        majorPlotPoints,
        unresolvedThreads,
        chapterCount,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'volume_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<VolumeSummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(_volumeIdMeta,
          volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta));
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('main_characters')) {
      context.handle(
          _mainCharactersMeta,
          mainCharacters.isAcceptableOrUnknown(
              data['main_characters']!, _mainCharactersMeta));
    } else if (isInserting) {
      context.missing(_mainCharactersMeta);
    }
    if (data.containsKey('story_arc')) {
      context.handle(_storyArcMeta,
          storyArc.isAcceptableOrUnknown(data['story_arc']!, _storyArcMeta));
    } else if (isInserting) {
      context.missing(_storyArcMeta);
    }
    if (data.containsKey('major_plot_points')) {
      context.handle(
          _majorPlotPointsMeta,
          majorPlotPoints.isAcceptableOrUnknown(
              data['major_plot_points']!, _majorPlotPointsMeta));
    } else if (isInserting) {
      context.missing(_majorPlotPointsMeta);
    }
    if (data.containsKey('unresolved_threads')) {
      context.handle(
          _unresolvedThreadsMeta,
          unresolvedThreads.isAcceptableOrUnknown(
              data['unresolved_threads']!, _unresolvedThreadsMeta));
    } else if (isInserting) {
      context.missing(_unresolvedThreadsMeta);
    }
    if (data.containsKey('chapter_count')) {
      context.handle(
          _chapterCountMeta,
          chapterCount.isAcceptableOrUnknown(
              data['chapter_count']!, _chapterCountMeta));
    } else if (isInserting) {
      context.missing(_chapterCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VolumeSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VolumeSummary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      volumeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}volume_id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      mainCharacters: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}main_characters'])!,
      storyArc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}story_arc'])!,
      majorPlotPoints: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}major_plot_points'])!,
      unresolvedThreads: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}unresolved_threads'])!,
      chapterCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VolumeSummariesTable createAlias(String alias) {
    return $VolumeSummariesTable(attachedDatabase, alias);
  }
}

class VolumeSummary extends DataClass implements Insertable<VolumeSummary> {
  String id;
  String volumeId;
  String worldId;
  String summary;
  String status;
  String mainCharacters;
  String storyArc;
  String majorPlotPoints;
  String unresolvedThreads;
  int chapterCount;
  DateTime createdAt;
  DateTime updatedAt;
  VolumeSummary(
      {required this.id,
      required this.volumeId,
      required this.worldId,
      required this.summary,
      required this.status,
      required this.mainCharacters,
      required this.storyArc,
      required this.majorPlotPoints,
      required this.unresolvedThreads,
      required this.chapterCount,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['volume_id'] = Variable<String>(volumeId);
    map['world_id'] = Variable<String>(worldId);
    map['summary'] = Variable<String>(summary);
    map['status'] = Variable<String>(status);
    map['main_characters'] = Variable<String>(mainCharacters);
    map['story_arc'] = Variable<String>(storyArc);
    map['major_plot_points'] = Variable<String>(majorPlotPoints);
    map['unresolved_threads'] = Variable<String>(unresolvedThreads);
    map['chapter_count'] = Variable<int>(chapterCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VolumeSummariesCompanion toCompanion(bool nullToAbsent) {
    return VolumeSummariesCompanion(
      id: Value(id),
      volumeId: Value(volumeId),
      worldId: Value(worldId),
      summary: Value(summary),
      status: Value(status),
      mainCharacters: Value(mainCharacters),
      storyArc: Value(storyArc),
      majorPlotPoints: Value(majorPlotPoints),
      unresolvedThreads: Value(unresolvedThreads),
      chapterCount: Value(chapterCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VolumeSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VolumeSummary(
      id: serializer.fromJson<String>(json['id']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      summary: serializer.fromJson<String>(json['summary']),
      status: serializer.fromJson<String>(json['status']),
      mainCharacters: serializer.fromJson<String>(json['mainCharacters']),
      storyArc: serializer.fromJson<String>(json['storyArc']),
      majorPlotPoints: serializer.fromJson<String>(json['majorPlotPoints']),
      unresolvedThreads: serializer.fromJson<String>(json['unresolvedThreads']),
      chapterCount: serializer.fromJson<int>(json['chapterCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'volumeId': serializer.toJson<String>(volumeId),
      'worldId': serializer.toJson<String>(worldId),
      'summary': serializer.toJson<String>(summary),
      'status': serializer.toJson<String>(status),
      'mainCharacters': serializer.toJson<String>(mainCharacters),
      'storyArc': serializer.toJson<String>(storyArc),
      'majorPlotPoints': serializer.toJson<String>(majorPlotPoints),
      'unresolvedThreads': serializer.toJson<String>(unresolvedThreads),
      'chapterCount': serializer.toJson<int>(chapterCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VolumeSummary copyWith(
          {String? id,
          String? volumeId,
          String? worldId,
          String? summary,
          String? status,
          String? mainCharacters,
          String? storyArc,
          String? majorPlotPoints,
          String? unresolvedThreads,
          int? chapterCount,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      VolumeSummary(
        id: id ?? this.id,
        volumeId: volumeId ?? this.volumeId,
        worldId: worldId ?? this.worldId,
        summary: summary ?? this.summary,
        status: status ?? this.status,
        mainCharacters: mainCharacters ?? this.mainCharacters,
        storyArc: storyArc ?? this.storyArc,
        majorPlotPoints: majorPlotPoints ?? this.majorPlotPoints,
        unresolvedThreads: unresolvedThreads ?? this.unresolvedThreads,
        chapterCount: chapterCount ?? this.chapterCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  VolumeSummary copyWithCompanion(VolumeSummariesCompanion data) {
    return VolumeSummary(
      id: data.id.present ? data.id.value : this.id,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      summary: data.summary.present ? data.summary.value : this.summary,
      status: data.status.present ? data.status.value : this.status,
      mainCharacters: data.mainCharacters.present
          ? data.mainCharacters.value
          : this.mainCharacters,
      storyArc: data.storyArc.present ? data.storyArc.value : this.storyArc,
      majorPlotPoints: data.majorPlotPoints.present
          ? data.majorPlotPoints.value
          : this.majorPlotPoints,
      unresolvedThreads: data.unresolvedThreads.present
          ? data.unresolvedThreads.value
          : this.unresolvedThreads,
      chapterCount: data.chapterCount.present
          ? data.chapterCount.value
          : this.chapterCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VolumeSummary(')
          ..write('id: $id, ')
          ..write('volumeId: $volumeId, ')
          ..write('worldId: $worldId, ')
          ..write('summary: $summary, ')
          ..write('status: $status, ')
          ..write('mainCharacters: $mainCharacters, ')
          ..write('storyArc: $storyArc, ')
          ..write('majorPlotPoints: $majorPlotPoints, ')
          ..write('unresolvedThreads: $unresolvedThreads, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      volumeId,
      worldId,
      summary,
      status,
      mainCharacters,
      storyArc,
      majorPlotPoints,
      unresolvedThreads,
      chapterCount,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VolumeSummary &&
          other.id == this.id &&
          other.volumeId == this.volumeId &&
          other.worldId == this.worldId &&
          other.summary == this.summary &&
          other.status == this.status &&
          other.mainCharacters == this.mainCharacters &&
          other.storyArc == this.storyArc &&
          other.majorPlotPoints == this.majorPlotPoints &&
          other.unresolvedThreads == this.unresolvedThreads &&
          other.chapterCount == this.chapterCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VolumeSummariesCompanion extends UpdateCompanion<VolumeSummary> {
  Value<String> id;
  Value<String> volumeId;
  Value<String> worldId;
  Value<String> summary;
  Value<String> status;
  Value<String> mainCharacters;
  Value<String> storyArc;
  Value<String> majorPlotPoints;
  Value<String> unresolvedThreads;
  Value<int> chapterCount;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  VolumeSummariesCompanion({
    this.id = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.summary = const Value.absent(),
    this.status = const Value.absent(),
    this.mainCharacters = const Value.absent(),
    this.storyArc = const Value.absent(),
    this.majorPlotPoints = const Value.absent(),
    this.unresolvedThreads = const Value.absent(),
    this.chapterCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VolumeSummariesCompanion.insert({
    required String id,
    required String volumeId,
    required String worldId,
    required String summary,
    required String status,
    required String mainCharacters,
    required String storyArc,
    required String majorPlotPoints,
    required String unresolvedThreads,
    required int chapterCount,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        volumeId = Value(volumeId),
        worldId = Value(worldId),
        summary = Value(summary),
        status = Value(status),
        mainCharacters = Value(mainCharacters),
        storyArc = Value(storyArc),
        majorPlotPoints = Value(majorPlotPoints),
        unresolvedThreads = Value(unresolvedThreads),
        chapterCount = Value(chapterCount),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<VolumeSummary> custom({
    Expression<String>? id,
    Expression<String>? volumeId,
    Expression<String>? worldId,
    Expression<String>? summary,
    Expression<String>? status,
    Expression<String>? mainCharacters,
    Expression<String>? storyArc,
    Expression<String>? majorPlotPoints,
    Expression<String>? unresolvedThreads,
    Expression<int>? chapterCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (volumeId != null) 'volume_id': volumeId,
      if (worldId != null) 'world_id': worldId,
      if (summary != null) 'summary': summary,
      if (status != null) 'status': status,
      if (mainCharacters != null) 'main_characters': mainCharacters,
      if (storyArc != null) 'story_arc': storyArc,
      if (majorPlotPoints != null) 'major_plot_points': majorPlotPoints,
      if (unresolvedThreads != null) 'unresolved_threads': unresolvedThreads,
      if (chapterCount != null) 'chapter_count': chapterCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VolumeSummariesCompanion copyWith(
      {Value<String>? id,
      Value<String>? volumeId,
      Value<String>? worldId,
      Value<String>? summary,
      Value<String>? status,
      Value<String>? mainCharacters,
      Value<String>? storyArc,
      Value<String>? majorPlotPoints,
      Value<String>? unresolvedThreads,
      Value<int>? chapterCount,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return VolumeSummariesCompanion(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      worldId: worldId ?? this.worldId,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      mainCharacters: mainCharacters ?? this.mainCharacters,
      storyArc: storyArc ?? this.storyArc,
      majorPlotPoints: majorPlotPoints ?? this.majorPlotPoints,
      unresolvedThreads: unresolvedThreads ?? this.unresolvedThreads,
      chapterCount: chapterCount ?? this.chapterCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (mainCharacters.present) {
      map['main_characters'] = Variable<String>(mainCharacters.value);
    }
    if (storyArc.present) {
      map['story_arc'] = Variable<String>(storyArc.value);
    }
    if (majorPlotPoints.present) {
      map['major_plot_points'] = Variable<String>(majorPlotPoints.value);
    }
    if (unresolvedThreads.present) {
      map['unresolved_threads'] = Variable<String>(unresolvedThreads.value);
    }
    if (chapterCount.present) {
      map['chapter_count'] = Variable<int>(chapterCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VolumeSummariesCompanion(')
          ..write('id: $id, ')
          ..write('volumeId: $volumeId, ')
          ..write('worldId: $worldId, ')
          ..write('summary: $summary, ')
          ..write('status: $status, ')
          ..write('mainCharacters: $mainCharacters, ')
          ..write('storyArc: $storyArc, ')
          ..write('majorPlotPoints: $majorPlotPoints, ')
          ..write('unresolvedThreads: $unresolvedThreads, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorksTable extends Works with TableInfo<$WorksTable, Work> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, worldId, title, description, type, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'works';
  @override
  VerificationContext validateIntegrity(Insertable<Work> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Work map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Work(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WorksTable createAlias(String alias) {
    return $WorksTable(attachedDatabase, alias);
  }
}

class Work extends DataClass implements Insertable<Work> {
  String id;
  String worldId;
  String title;
  String description;
  String type;
  DateTime createdAt;
  DateTime updatedAt;
  Work(
      {required this.id,
      required this.worldId,
      required this.title,
      required this.description,
      required this.type,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorksCompanion toCompanion(bool nullToAbsent) {
    return WorksCompanion(
      id: Value(id),
      worldId: Value(worldId),
      title: Value(title),
      description: Value(description),
      type: Value(type),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Work.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Work(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Work copyWith(
          {String? id,
          String? worldId,
          String? title,
          String? description,
          String? type,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Work(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Work copyWithCompanion(WorksCompanion data) {
    return Work(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Work(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, worldId, title, description, type, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Work &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorksCompanion extends UpdateCompanion<Work> {
  Value<String> id;
  Value<String> worldId;
  Value<String> title;
  Value<String> description;
  Value<String> type;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  WorksCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorksCompanion.insert({
    required String id,
    required String worldId,
    required String title,
    required String description,
    required String type,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        title = Value(title),
        description = Value(description),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Work> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorksCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? title,
      Value<String>? description,
      Value<String>? type,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return WorksCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorksCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VolumesTable extends Volumes with TableInfo<$VolumesTable, Volume> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VolumesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
      'work_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _volumeNumberMeta =
      const VerificationMeta('volumeNumber');
  @override
  late final GeneratedColumn<int> volumeNumber = GeneratedColumn<int>(
      'volume_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _synopsisMeta =
      const VerificationMeta('synopsis');
  @override
  late final GeneratedColumn<String> synopsis = GeneratedColumn<String>(
      'synopsis', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, workId, volumeNumber, title, synopsis, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'volumes';
  @override
  VerificationContext validateIntegrity(Insertable<Volume> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(_workIdMeta,
          workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta));
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('volume_number')) {
      context.handle(
          _volumeNumberMeta,
          volumeNumber.isAcceptableOrUnknown(
              data['volume_number']!, _volumeNumberMeta));
    } else if (isInserting) {
      context.missing(_volumeNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('synopsis')) {
      context.handle(_synopsisMeta,
          synopsis.isAcceptableOrUnknown(data['synopsis']!, _synopsisMeta));
    } else if (isInserting) {
      context.missing(_synopsisMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Volume map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Volume(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      workId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}work_id'])!,
      volumeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}volume_number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      synopsis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synopsis'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VolumesTable createAlias(String alias) {
    return $VolumesTable(attachedDatabase, alias);
  }
}

class Volume extends DataClass implements Insertable<Volume> {
  String id;
  String workId;
  int volumeNumber;
  String title;
  String synopsis;
  DateTime createdAt;
  DateTime updatedAt;
  Volume(
      {required this.id,
      required this.workId,
      required this.volumeNumber,
      required this.title,
      required this.synopsis,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['work_id'] = Variable<String>(workId);
    map['volume_number'] = Variable<int>(volumeNumber);
    map['title'] = Variable<String>(title);
    map['synopsis'] = Variable<String>(synopsis);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VolumesCompanion toCompanion(bool nullToAbsent) {
    return VolumesCompanion(
      id: Value(id),
      workId: Value(workId),
      volumeNumber: Value(volumeNumber),
      title: Value(title),
      synopsis: Value(synopsis),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Volume.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Volume(
      id: serializer.fromJson<String>(json['id']),
      workId: serializer.fromJson<String>(json['workId']),
      volumeNumber: serializer.fromJson<int>(json['volumeNumber']),
      title: serializer.fromJson<String>(json['title']),
      synopsis: serializer.fromJson<String>(json['synopsis']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workId': serializer.toJson<String>(workId),
      'volumeNumber': serializer.toJson<int>(volumeNumber),
      'title': serializer.toJson<String>(title),
      'synopsis': serializer.toJson<String>(synopsis),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Volume copyWith(
          {String? id,
          String? workId,
          int? volumeNumber,
          String? title,
          String? synopsis,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Volume(
        id: id ?? this.id,
        workId: workId ?? this.workId,
        volumeNumber: volumeNumber ?? this.volumeNumber,
        title: title ?? this.title,
        synopsis: synopsis ?? this.synopsis,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Volume copyWithCompanion(VolumesCompanion data) {
    return Volume(
      id: data.id.present ? data.id.value : this.id,
      workId: data.workId.present ? data.workId.value : this.workId,
      volumeNumber: data.volumeNumber.present
          ? data.volumeNumber.value
          : this.volumeNumber,
      title: data.title.present ? data.title.value : this.title,
      synopsis: data.synopsis.present ? data.synopsis.value : this.synopsis,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Volume(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('volumeNumber: $volumeNumber, ')
          ..write('title: $title, ')
          ..write('synopsis: $synopsis, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, workId, volumeNumber, title, synopsis, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Volume &&
          other.id == this.id &&
          other.workId == this.workId &&
          other.volumeNumber == this.volumeNumber &&
          other.title == this.title &&
          other.synopsis == this.synopsis &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VolumesCompanion extends UpdateCompanion<Volume> {
  Value<String> id;
  Value<String> workId;
  Value<int> volumeNumber;
  Value<String> title;
  Value<String> synopsis;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  VolumesCompanion({
    this.id = const Value.absent(),
    this.workId = const Value.absent(),
    this.volumeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VolumesCompanion.insert({
    required String id,
    required String workId,
    required int volumeNumber,
    required String title,
    required String synopsis,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        workId = Value(workId),
        volumeNumber = Value(volumeNumber),
        title = Value(title),
        synopsis = Value(synopsis),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Volume> custom({
    Expression<String>? id,
    Expression<String>? workId,
    Expression<int>? volumeNumber,
    Expression<String>? title,
    Expression<String>? synopsis,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workId != null) 'work_id': workId,
      if (volumeNumber != null) 'volume_number': volumeNumber,
      if (title != null) 'title': title,
      if (synopsis != null) 'synopsis': synopsis,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VolumesCompanion copyWith(
      {Value<String>? id,
      Value<String>? workId,
      Value<int>? volumeNumber,
      Value<String>? title,
      Value<String>? synopsis,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return VolumesCompanion(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (volumeNumber.present) {
      map['volume_number'] = Variable<int>(volumeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (synopsis.present) {
      map['synopsis'] = Variable<String>(synopsis.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VolumesCompanion(')
          ..write('id: $id, ')
          ..write('workId: $workId, ')
          ..write('volumeNumber: $volumeNumber, ')
          ..write('title: $title, ')
          ..write('synopsis: $synopsis, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _volumeIdMeta =
      const VerificationMeta('volumeId');
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
      'volume_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterNumberMeta =
      const VerificationMeta('chapterNumber');
  @override
  late final GeneratedColumn<int> chapterNumber = GeneratedColumn<int>(
      'chapter_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _synopsisMeta =
      const VerificationMeta('synopsis');
  @override
  late final GeneratedColumn<String> synopsis = GeneratedColumn<String>(
      'synopsis', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, volumeId, chapterNumber, title, synopsis, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(Insertable<Chapter> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(_volumeIdMeta,
          volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta));
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('chapter_number')) {
      context.handle(
          _chapterNumberMeta,
          chapterNumber.isAcceptableOrUnknown(
              data['chapter_number']!, _chapterNumberMeta));
    } else if (isInserting) {
      context.missing(_chapterNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('synopsis')) {
      context.handle(_synopsisMeta,
          synopsis.isAcceptableOrUnknown(data['synopsis']!, _synopsisMeta));
    } else if (isInserting) {
      context.missing(_synopsisMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      volumeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}volume_id'])!,
      chapterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      synopsis: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synopsis'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  String id;
  String volumeId;
  int chapterNumber;
  String title;
  String synopsis;
  DateTime createdAt;
  DateTime updatedAt;
  Chapter(
      {required this.id,
      required this.volumeId,
      required this.chapterNumber,
      required this.title,
      required this.synopsis,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['volume_id'] = Variable<String>(volumeId);
    map['chapter_number'] = Variable<int>(chapterNumber);
    map['title'] = Variable<String>(title);
    map['synopsis'] = Variable<String>(synopsis);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      volumeId: Value(volumeId),
      chapterNumber: Value(chapterNumber),
      title: Value(title),
      synopsis: Value(synopsis),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<String>(json['id']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      chapterNumber: serializer.fromJson<int>(json['chapterNumber']),
      title: serializer.fromJson<String>(json['title']),
      synopsis: serializer.fromJson<String>(json['synopsis']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'volumeId': serializer.toJson<String>(volumeId),
      'chapterNumber': serializer.toJson<int>(chapterNumber),
      'title': serializer.toJson<String>(title),
      'synopsis': serializer.toJson<String>(synopsis),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chapter copyWith(
          {String? id,
          String? volumeId,
          int? chapterNumber,
          String? title,
          String? synopsis,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Chapter(
        id: id ?? this.id,
        volumeId: volumeId ?? this.volumeId,
        chapterNumber: chapterNumber ?? this.chapterNumber,
        title: title ?? this.title,
        synopsis: synopsis ?? this.synopsis,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      chapterNumber: data.chapterNumber.present
          ? data.chapterNumber.value
          : this.chapterNumber,
      title: data.title.present ? data.title.value : this.title,
      synopsis: data.synopsis.present ? data.synopsis.value : this.synopsis,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('volumeId: $volumeId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('title: $title, ')
          ..write('synopsis: $synopsis, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, volumeId, chapterNumber, title, synopsis, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.volumeId == this.volumeId &&
          other.chapterNumber == this.chapterNumber &&
          other.title == this.title &&
          other.synopsis == this.synopsis &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  Value<String> id;
  Value<String> volumeId;
  Value<int> chapterNumber;
  Value<String> title;
  Value<String> synopsis;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  ChaptersCompanion({
    this.id = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.chapterNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String id,
    required String volumeId,
    required int chapterNumber,
    required String title,
    required String synopsis,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        volumeId = Value(volumeId),
        chapterNumber = Value(chapterNumber),
        title = Value(title),
        synopsis = Value(synopsis),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Chapter> custom({
    Expression<String>? id,
    Expression<String>? volumeId,
    Expression<int>? chapterNumber,
    Expression<String>? title,
    Expression<String>? synopsis,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (volumeId != null) 'volume_id': volumeId,
      if (chapterNumber != null) 'chapter_number': chapterNumber,
      if (title != null) 'title': title,
      if (synopsis != null) 'synopsis': synopsis,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith(
      {Value<String>? id,
      Value<String>? volumeId,
      Value<int>? chapterNumber,
      Value<String>? title,
      Value<String>? synopsis,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ChaptersCompanion(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (chapterNumber.present) {
      map['chapter_number'] = Variable<int>(chapterNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (synopsis.present) {
      map['synopsis'] = Variable<String>(synopsis.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('volumeId: $volumeId, ')
          ..write('chapterNumber: $chapterNumber, ')
          ..write('title: $title, ')
          ..write('synopsis: $synopsis, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScenesTable extends Scenes with TableInfo<$ScenesTable, Scene> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScenesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sceneNumberMeta =
      const VerificationMeta('sceneNumber');
  @override
  late final GeneratedColumn<int> sceneNumber = GeneratedColumn<int>(
      'scene_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _outlineDescriptionMeta =
      const VerificationMeta('outlineDescription');
  @override
  late final GeneratedColumn<String> outlineDescription =
      GeneratedColumn<String>('outline_description', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationIdMeta =
      const VerificationMeta('locationId');
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
      'location_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timelineEventIdMeta =
      const VerificationMeta('timelineEventId');
  @override
  late final GeneratedColumn<String> timelineEventId = GeneratedColumn<String>(
      'timeline_event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'document_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        chapterId,
        sceneNumber,
        title,
        outlineDescription,
        locationId,
        timelineEventId,
        documentId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scenes';
  @override
  VerificationContext validateIntegrity(Insertable<Scene> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('scene_number')) {
      context.handle(
          _sceneNumberMeta,
          sceneNumber.isAcceptableOrUnknown(
              data['scene_number']!, _sceneNumberMeta));
    } else if (isInserting) {
      context.missing(_sceneNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('outline_description')) {
      context.handle(
          _outlineDescriptionMeta,
          outlineDescription.isAcceptableOrUnknown(
              data['outline_description']!, _outlineDescriptionMeta));
    } else if (isInserting) {
      context.missing(_outlineDescriptionMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
          _locationIdMeta,
          locationId.isAcceptableOrUnknown(
              data['location_id']!, _locationIdMeta));
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('timeline_event_id')) {
      context.handle(
          _timelineEventIdMeta,
          timelineEventId.isAcceptableOrUnknown(
              data['timeline_event_id']!, _timelineEventIdMeta));
    } else if (isInserting) {
      context.missing(_timelineEventIdMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['document_id']!, _documentIdMeta));
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Scene map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Scene(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_id'])!,
      sceneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scene_number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      outlineDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}outline_description'])!,
      locationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_id'])!,
      timelineEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}timeline_event_id'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ScenesTable createAlias(String alias) {
    return $ScenesTable(attachedDatabase, alias);
  }
}

class Scene extends DataClass implements Insertable<Scene> {
  String id;
  String chapterId;
  int sceneNumber;
  String title;
  String outlineDescription;
  String locationId;
  String timelineEventId;
  String documentId;
  DateTime createdAt;
  DateTime updatedAt;
  Scene(
      {required this.id,
      required this.chapterId,
      required this.sceneNumber,
      required this.title,
      required this.outlineDescription,
      required this.locationId,
      required this.timelineEventId,
      required this.documentId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chapter_id'] = Variable<String>(chapterId);
    map['scene_number'] = Variable<int>(sceneNumber);
    map['title'] = Variable<String>(title);
    map['outline_description'] = Variable<String>(outlineDescription);
    map['location_id'] = Variable<String>(locationId);
    map['timeline_event_id'] = Variable<String>(timelineEventId);
    map['document_id'] = Variable<String>(documentId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScenesCompanion toCompanion(bool nullToAbsent) {
    return ScenesCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      sceneNumber: Value(sceneNumber),
      title: Value(title),
      outlineDescription: Value(outlineDescription),
      locationId: Value(locationId),
      timelineEventId: Value(timelineEventId),
      documentId: Value(documentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Scene.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Scene(
      id: serializer.fromJson<String>(json['id']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      sceneNumber: serializer.fromJson<int>(json['sceneNumber']),
      title: serializer.fromJson<String>(json['title']),
      outlineDescription:
          serializer.fromJson<String>(json['outlineDescription']),
      locationId: serializer.fromJson<String>(json['locationId']),
      timelineEventId: serializer.fromJson<String>(json['timelineEventId']),
      documentId: serializer.fromJson<String>(json['documentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chapterId': serializer.toJson<String>(chapterId),
      'sceneNumber': serializer.toJson<int>(sceneNumber),
      'title': serializer.toJson<String>(title),
      'outlineDescription': serializer.toJson<String>(outlineDescription),
      'locationId': serializer.toJson<String>(locationId),
      'timelineEventId': serializer.toJson<String>(timelineEventId),
      'documentId': serializer.toJson<String>(documentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Scene copyWith(
          {String? id,
          String? chapterId,
          int? sceneNumber,
          String? title,
          String? outlineDescription,
          String? locationId,
          String? timelineEventId,
          String? documentId,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Scene(
        id: id ?? this.id,
        chapterId: chapterId ?? this.chapterId,
        sceneNumber: sceneNumber ?? this.sceneNumber,
        title: title ?? this.title,
        outlineDescription: outlineDescription ?? this.outlineDescription,
        locationId: locationId ?? this.locationId,
        timelineEventId: timelineEventId ?? this.timelineEventId,
        documentId: documentId ?? this.documentId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Scene copyWithCompanion(ScenesCompanion data) {
    return Scene(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      sceneNumber:
          data.sceneNumber.present ? data.sceneNumber.value : this.sceneNumber,
      title: data.title.present ? data.title.value : this.title,
      outlineDescription: data.outlineDescription.present
          ? data.outlineDescription.value
          : this.outlineDescription,
      locationId:
          data.locationId.present ? data.locationId.value : this.locationId,
      timelineEventId: data.timelineEventId.present
          ? data.timelineEventId.value
          : this.timelineEventId,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Scene(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('sceneNumber: $sceneNumber, ')
          ..write('title: $title, ')
          ..write('outlineDescription: $outlineDescription, ')
          ..write('locationId: $locationId, ')
          ..write('timelineEventId: $timelineEventId, ')
          ..write('documentId: $documentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      chapterId,
      sceneNumber,
      title,
      outlineDescription,
      locationId,
      timelineEventId,
      documentId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scene &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.sceneNumber == this.sceneNumber &&
          other.title == this.title &&
          other.outlineDescription == this.outlineDescription &&
          other.locationId == this.locationId &&
          other.timelineEventId == this.timelineEventId &&
          other.documentId == this.documentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScenesCompanion extends UpdateCompanion<Scene> {
  Value<String> id;
  Value<String> chapterId;
  Value<int> sceneNumber;
  Value<String> title;
  Value<String> outlineDescription;
  Value<String> locationId;
  Value<String> timelineEventId;
  Value<String> documentId;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  ScenesCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.sceneNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.outlineDescription = const Value.absent(),
    this.locationId = const Value.absent(),
    this.timelineEventId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScenesCompanion.insert({
    required String id,
    required String chapterId,
    required int sceneNumber,
    required String title,
    required String outlineDescription,
    required String locationId,
    required String timelineEventId,
    required String documentId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        chapterId = Value(chapterId),
        sceneNumber = Value(sceneNumber),
        title = Value(title),
        outlineDescription = Value(outlineDescription),
        locationId = Value(locationId),
        timelineEventId = Value(timelineEventId),
        documentId = Value(documentId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Scene> custom({
    Expression<String>? id,
    Expression<String>? chapterId,
    Expression<int>? sceneNumber,
    Expression<String>? title,
    Expression<String>? outlineDescription,
    Expression<String>? locationId,
    Expression<String>? timelineEventId,
    Expression<String>? documentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (sceneNumber != null) 'scene_number': sceneNumber,
      if (title != null) 'title': title,
      if (outlineDescription != null) 'outline_description': outlineDescription,
      if (locationId != null) 'location_id': locationId,
      if (timelineEventId != null) 'timeline_event_id': timelineEventId,
      if (documentId != null) 'document_id': documentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScenesCompanion copyWith(
      {Value<String>? id,
      Value<String>? chapterId,
      Value<int>? sceneNumber,
      Value<String>? title,
      Value<String>? outlineDescription,
      Value<String>? locationId,
      Value<String>? timelineEventId,
      Value<String>? documentId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ScenesCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      sceneNumber: sceneNumber ?? this.sceneNumber,
      title: title ?? this.title,
      outlineDescription: outlineDescription ?? this.outlineDescription,
      locationId: locationId ?? this.locationId,
      timelineEventId: timelineEventId ?? this.timelineEventId,
      documentId: documentId ?? this.documentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (sceneNumber.present) {
      map['scene_number'] = Variable<int>(sceneNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (outlineDescription.present) {
      map['outline_description'] = Variable<String>(outlineDescription.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (timelineEventId.present) {
      map['timeline_event_id'] = Variable<String>(timelineEventId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScenesCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('sceneNumber: $sceneNumber, ')
          ..write('title: $title, ')
          ..write('outlineDescription: $outlineDescription, ')
          ..write('locationId: $locationId, ')
          ..write('timelineEventId: $timelineEventId, ')
          ..write('documentId: $documentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _worldIdMeta =
      const VerificationMeta('worldId');
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
      'world_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
      'work_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentSceneIdMeta =
      const VerificationMeta('currentSceneId');
  @override
  late final GeneratedColumn<String> currentSceneId = GeneratedColumn<String>(
      'current_scene_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, worldId, workId, filePath, currentSceneId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(Insertable<Document> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(_worldIdMeta,
          worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta));
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(_workIdMeta,
          workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta));
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('current_scene_id')) {
      context.handle(
          _currentSceneIdMeta,
          currentSceneId.isAcceptableOrUnknown(
              data['current_scene_id']!, _currentSceneIdMeta));
    } else if (isInserting) {
      context.missing(_currentSceneIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      worldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}world_id'])!,
      workId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}work_id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      currentSceneId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_scene_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class Document extends DataClass implements Insertable<Document> {
  String id;
  String worldId;
  String workId;
  String filePath;
  String currentSceneId;
  DateTime createdAt;
  DateTime updatedAt;
  Document(
      {required this.id,
      required this.worldId,
      required this.workId,
      required this.filePath,
      required this.currentSceneId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['world_id'] = Variable<String>(worldId);
    map['work_id'] = Variable<String>(workId);
    map['file_path'] = Variable<String>(filePath);
    map['current_scene_id'] = Variable<String>(currentSceneId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      worldId: Value(worldId),
      workId: Value(workId),
      filePath: Value(filePath),
      currentSceneId: Value(currentSceneId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Document.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      id: serializer.fromJson<String>(json['id']),
      worldId: serializer.fromJson<String>(json['worldId']),
      workId: serializer.fromJson<String>(json['workId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      currentSceneId: serializer.fromJson<String>(json['currentSceneId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'worldId': serializer.toJson<String>(worldId),
      'workId': serializer.toJson<String>(workId),
      'filePath': serializer.toJson<String>(filePath),
      'currentSceneId': serializer.toJson<String>(currentSceneId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Document copyWith(
          {String? id,
          String? worldId,
          String? workId,
          String? filePath,
          String? currentSceneId,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Document(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        workId: workId ?? this.workId,
        filePath: filePath ?? this.filePath,
        currentSceneId: currentSceneId ?? this.currentSceneId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      id: data.id.present ? data.id.value : this.id,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      workId: data.workId.present ? data.workId.value : this.workId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      currentSceneId: data.currentSceneId.present
          ? data.currentSceneId.value
          : this.currentSceneId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('workId: $workId, ')
          ..write('filePath: $filePath, ')
          ..write('currentSceneId: $currentSceneId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, worldId, workId, filePath, currentSceneId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.id == this.id &&
          other.worldId == this.worldId &&
          other.workId == this.workId &&
          other.filePath == this.filePath &&
          other.currentSceneId == this.currentSceneId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  Value<String> id;
  Value<String> worldId;
  Value<String> workId;
  Value<String> filePath;
  Value<String> currentSceneId;
  Value<DateTime> createdAt;
  Value<DateTime> updatedAt;
  Value<int> rowid;
  DocumentsCompanion({
    this.id = const Value.absent(),
    this.worldId = const Value.absent(),
    this.workId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.currentSceneId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String worldId,
    required String workId,
    required String filePath,
    required String currentSceneId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        worldId = Value(worldId),
        workId = Value(workId),
        filePath = Value(filePath),
        currentSceneId = Value(currentSceneId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Document> custom({
    Expression<String>? id,
    Expression<String>? worldId,
    Expression<String>? workId,
    Expression<String>? filePath,
    Expression<String>? currentSceneId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (worldId != null) 'world_id': worldId,
      if (workId != null) 'work_id': workId,
      if (filePath != null) 'file_path': filePath,
      if (currentSceneId != null) 'current_scene_id': currentSceneId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? worldId,
      Value<String>? workId,
      Value<String>? filePath,
      Value<String>? currentSceneId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DocumentsCompanion(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      workId: workId ?? this.workId,
      filePath: filePath ?? this.filePath,
      currentSceneId: currentSceneId ?? this.currentSceneId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (currentSceneId.present) {
      map['current_scene_id'] = Variable<String>(currentSceneId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('worldId: $worldId, ')
          ..write('workId: $workId, ')
          ..write('filePath: $filePath, ')
          ..write('currentSceneId: $currentSceneId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WorldDatabase extends GeneratedDatabase {
  _$WorldDatabase(QueryExecutor e) : super(e);
  _$WorldDatabase.connect(DatabaseConnection c) : super.connect(c);
  $WorldDatabaseManager get managers => $WorldDatabaseManager(this);
  late final $CharactersTable characters = $CharactersTable(this);
  late final $IdentitiesTable identities = $IdentitiesTable(this);
  late final $WeightSpecsTable weightSpecs = $WeightSpecsTable(this);
  late final $CharacterRelationsTable characterRelations =
      $CharacterRelationsTable(this);
  late final $RelationStagesTable relationStages = $RelationStagesTable(this);
  late final $LocationsTable locations = $LocationsTable(this);
  late final $LoresTable lores = $LoresTable(this);
  late final $WorldRulesTable worldRules = $WorldRulesTable(this);
  late final $TimelineEventsTable timelineEvents = $TimelineEventsTable(this);
  late final $FactionsTable factions = $FactionsTable(this);
  late final $ForeshadowingsTable foreshadowings = $ForeshadowingsTable(this);
  late final $ButterflyAnalysesTable butterflyAnalyses =
      $ButterflyAnalysesTable(this);
  late final $SceneSummariesTable sceneSummaries = $SceneSummariesTable(this);
  late final $ChapterSummariesTable chapterSummaries =
      $ChapterSummariesTable(this);
  late final $VolumeSummariesTable volumeSummaries =
      $VolumeSummariesTable(this);
  late final $WorksTable works = $WorksTable(this);
  late final $VolumesTable volumes = $VolumesTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $ScenesTable scenes = $ScenesTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        characters,
        identities,
        weightSpecs,
        characterRelations,
        relationStages,
        locations,
        lores,
        worldRules,
        timelineEvents,
        factions,
        foreshadowings,
        butterflyAnalyses,
        sceneSummaries,
        chapterSummaries,
        volumeSummaries,
        works,
        volumes,
        chapters,
        scenes,
        documents
      ];
}

typedef $$CharactersTableCreateCompanionBuilder = CharactersCompanion Function({
  required String id,
  required String worldId,
  required String name,
  required String description,
  required String role,
  required String personality,
  required String backstory,
  required String motivation,
  required String arc,
  required int baseWeight,
  required int tempWeight,
  required String currentStatus,
  required String currentLocationId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CharactersTableUpdateCompanionBuilder = CharactersCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> name,
  Value<String> description,
  Value<String> role,
  Value<String> personality,
  Value<String> backstory,
  Value<String> motivation,
  Value<String> arc,
  Value<int> baseWeight,
  Value<int> tempWeight,
  Value<String> currentStatus,
  Value<String> currentLocationId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CharactersTableFilterComposer
    extends Composer<_$WorldDatabase, $CharactersTable> {
  $$CharactersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personality => $composableBuilder(
      column: $table.personality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backstory => $composableBuilder(
      column: $table.backstory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motivation => $composableBuilder(
      column: $table.motivation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arc => $composableBuilder(
      column: $table.arc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseWeight => $composableBuilder(
      column: $table.baseWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tempWeight => $composableBuilder(
      column: $table.tempWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentStatus => $composableBuilder(
      column: $table.currentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentLocationId => $composableBuilder(
      column: $table.currentLocationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CharactersTableOrderingComposer
    extends Composer<_$WorldDatabase, $CharactersTable> {
  $$CharactersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personality => $composableBuilder(
      column: $table.personality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backstory => $composableBuilder(
      column: $table.backstory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motivation => $composableBuilder(
      column: $table.motivation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arc => $composableBuilder(
      column: $table.arc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseWeight => $composableBuilder(
      column: $table.baseWeight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tempWeight => $composableBuilder(
      column: $table.tempWeight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentStatus => $composableBuilder(
      column: $table.currentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentLocationId => $composableBuilder(
      column: $table.currentLocationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CharactersTableAnnotationComposer
    extends Composer<_$WorldDatabase, $CharactersTable> {
  $$CharactersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get personality => $composableBuilder(
      column: $table.personality, builder: (column) => column);

  GeneratedColumn<String> get backstory =>
      $composableBuilder(column: $table.backstory, builder: (column) => column);

  GeneratedColumn<String> get motivation => $composableBuilder(
      column: $table.motivation, builder: (column) => column);

  GeneratedColumn<String> get arc =>
      $composableBuilder(column: $table.arc, builder: (column) => column);

  GeneratedColumn<int> get baseWeight => $composableBuilder(
      column: $table.baseWeight, builder: (column) => column);

  GeneratedColumn<int> get tempWeight => $composableBuilder(
      column: $table.tempWeight, builder: (column) => column);

  GeneratedColumn<String> get currentStatus => $composableBuilder(
      column: $table.currentStatus, builder: (column) => column);

  GeneratedColumn<String> get currentLocationId => $composableBuilder(
      column: $table.currentLocationId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CharactersTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $CharactersTable,
    Character,
    $$CharactersTableFilterComposer,
    $$CharactersTableOrderingComposer,
    $$CharactersTableAnnotationComposer,
    $$CharactersTableCreateCompanionBuilder,
    $$CharactersTableUpdateCompanionBuilder,
    (Character, BaseReferences<_$WorldDatabase, $CharactersTable, Character>),
    Character,
    PrefetchHooks Function()> {
  $$CharactersTableTableManager(_$WorldDatabase db, $CharactersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharactersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharactersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharactersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> personality = const Value.absent(),
            Value<String> backstory = const Value.absent(),
            Value<String> motivation = const Value.absent(),
            Value<String> arc = const Value.absent(),
            Value<int> baseWeight = const Value.absent(),
            Value<int> tempWeight = const Value.absent(),
            Value<String> currentStatus = const Value.absent(),
            Value<String> currentLocationId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CharactersCompanion(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            role: role,
            personality: personality,
            backstory: backstory,
            motivation: motivation,
            arc: arc,
            baseWeight: baseWeight,
            tempWeight: tempWeight,
            currentStatus: currentStatus,
            currentLocationId: currentLocationId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String name,
            required String description,
            required String role,
            required String personality,
            required String backstory,
            required String motivation,
            required String arc,
            required int baseWeight,
            required int tempWeight,
            required String currentStatus,
            required String currentLocationId,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CharactersCompanion.insert(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            role: role,
            personality: personality,
            backstory: backstory,
            motivation: motivation,
            arc: arc,
            baseWeight: baseWeight,
            tempWeight: tempWeight,
            currentStatus: currentStatus,
            currentLocationId: currentLocationId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CharactersTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $CharactersTable,
    Character,
    $$CharactersTableFilterComposer,
    $$CharactersTableOrderingComposer,
    $$CharactersTableAnnotationComposer,
    $$CharactersTableCreateCompanionBuilder,
    $$CharactersTableUpdateCompanionBuilder,
    (Character, BaseReferences<_$WorldDatabase, $CharactersTable, Character>),
    Character,
    PrefetchHooks Function()>;
typedef $$IdentitiesTableCreateCompanionBuilder = IdentitiesCompanion Function({
  required String id,
  required String characterId,
  required String name,
  required String description,
  required int weight,
  required bool autoDetected,
  required String organizationId,
  required String establishedAfterEventId,
  required String expiresAfterEventId,
  Value<int> rowid,
});
typedef $$IdentitiesTableUpdateCompanionBuilder = IdentitiesCompanion Function({
  Value<String> id,
  Value<String> characterId,
  Value<String> name,
  Value<String> description,
  Value<int> weight,
  Value<bool> autoDetected,
  Value<String> organizationId,
  Value<String> establishedAfterEventId,
  Value<String> expiresAfterEventId,
  Value<int> rowid,
});

class $$IdentitiesTableFilterComposer
    extends Composer<_$WorldDatabase, $IdentitiesTable> {
  $$IdentitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoDetected => $composableBuilder(
      column: $table.autoDetected, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get establishedAfterEventId => $composableBuilder(
      column: $table.establishedAfterEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expiresAfterEventId => $composableBuilder(
      column: $table.expiresAfterEventId,
      builder: (column) => ColumnFilters(column));
}

class $$IdentitiesTableOrderingComposer
    extends Composer<_$WorldDatabase, $IdentitiesTable> {
  $$IdentitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoDetected => $composableBuilder(
      column: $table.autoDetected,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizationId => $composableBuilder(
      column: $table.organizationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get establishedAfterEventId => $composableBuilder(
      column: $table.establishedAfterEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expiresAfterEventId => $composableBuilder(
      column: $table.expiresAfterEventId,
      builder: (column) => ColumnOrderings(column));
}

class $$IdentitiesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $IdentitiesTable> {
  $$IdentitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<bool> get autoDetected => $composableBuilder(
      column: $table.autoDetected, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
      column: $table.organizationId, builder: (column) => column);

  GeneratedColumn<String> get establishedAfterEventId => $composableBuilder(
      column: $table.establishedAfterEventId, builder: (column) => column);

  GeneratedColumn<String> get expiresAfterEventId => $composableBuilder(
      column: $table.expiresAfterEventId, builder: (column) => column);
}

class $$IdentitiesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $IdentitiesTable,
    Identity,
    $$IdentitiesTableFilterComposer,
    $$IdentitiesTableOrderingComposer,
    $$IdentitiesTableAnnotationComposer,
    $$IdentitiesTableCreateCompanionBuilder,
    $$IdentitiesTableUpdateCompanionBuilder,
    (Identity, BaseReferences<_$WorldDatabase, $IdentitiesTable, Identity>),
    Identity,
    PrefetchHooks Function()> {
  $$IdentitiesTableTableManager(_$WorldDatabase db, $IdentitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdentitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdentitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdentitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> characterId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> weight = const Value.absent(),
            Value<bool> autoDetected = const Value.absent(),
            Value<String> organizationId = const Value.absent(),
            Value<String> establishedAfterEventId = const Value.absent(),
            Value<String> expiresAfterEventId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IdentitiesCompanion(
            id: id,
            characterId: characterId,
            name: name,
            description: description,
            weight: weight,
            autoDetected: autoDetected,
            organizationId: organizationId,
            establishedAfterEventId: establishedAfterEventId,
            expiresAfterEventId: expiresAfterEventId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String characterId,
            required String name,
            required String description,
            required int weight,
            required bool autoDetected,
            required String organizationId,
            required String establishedAfterEventId,
            required String expiresAfterEventId,
            Value<int> rowid = const Value.absent(),
          }) =>
              IdentitiesCompanion.insert(
            id: id,
            characterId: characterId,
            name: name,
            description: description,
            weight: weight,
            autoDetected: autoDetected,
            organizationId: organizationId,
            establishedAfterEventId: establishedAfterEventId,
            expiresAfterEventId: expiresAfterEventId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IdentitiesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $IdentitiesTable,
    Identity,
    $$IdentitiesTableFilterComposer,
    $$IdentitiesTableOrderingComposer,
    $$IdentitiesTableAnnotationComposer,
    $$IdentitiesTableCreateCompanionBuilder,
    $$IdentitiesTableUpdateCompanionBuilder,
    (Identity, BaseReferences<_$WorldDatabase, $IdentitiesTable, Identity>),
    Identity,
    PrefetchHooks Function()>;
typedef $$WeightSpecsTableCreateCompanionBuilder = WeightSpecsCompanion
    Function({
  required String id,
  required String characterId,
  required String description,
  required String volumeId,
  required String eventId,
  required String chapterId,
  required int weightDelta,
  required bool promoteToMain,
  Value<int> rowid,
});
typedef $$WeightSpecsTableUpdateCompanionBuilder = WeightSpecsCompanion
    Function({
  Value<String> id,
  Value<String> characterId,
  Value<String> description,
  Value<String> volumeId,
  Value<String> eventId,
  Value<String> chapterId,
  Value<int> weightDelta,
  Value<bool> promoteToMain,
  Value<int> rowid,
});

class $$WeightSpecsTableFilterComposer
    extends Composer<_$WorldDatabase, $WeightSpecsTable> {
  $$WeightSpecsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weightDelta => $composableBuilder(
      column: $table.weightDelta, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get promoteToMain => $composableBuilder(
      column: $table.promoteToMain, builder: (column) => ColumnFilters(column));
}

class $$WeightSpecsTableOrderingComposer
    extends Composer<_$WorldDatabase, $WeightSpecsTable> {
  $$WeightSpecsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weightDelta => $composableBuilder(
      column: $table.weightDelta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get promoteToMain => $composableBuilder(
      column: $table.promoteToMain,
      builder: (column) => ColumnOrderings(column));
}

class $$WeightSpecsTableAnnotationComposer
    extends Composer<_$WorldDatabase, $WeightSpecsTable> {
  $$WeightSpecsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get volumeId =>
      $composableBuilder(column: $table.volumeId, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<int> get weightDelta => $composableBuilder(
      column: $table.weightDelta, builder: (column) => column);

  GeneratedColumn<bool> get promoteToMain => $composableBuilder(
      column: $table.promoteToMain, builder: (column) => column);
}

class $$WeightSpecsTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $WeightSpecsTable,
    WeightSpec,
    $$WeightSpecsTableFilterComposer,
    $$WeightSpecsTableOrderingComposer,
    $$WeightSpecsTableAnnotationComposer,
    $$WeightSpecsTableCreateCompanionBuilder,
    $$WeightSpecsTableUpdateCompanionBuilder,
    (
      WeightSpec,
      BaseReferences<_$WorldDatabase, $WeightSpecsTable, WeightSpec>
    ),
    WeightSpec,
    PrefetchHooks Function()> {
  $$WeightSpecsTableTableManager(_$WorldDatabase db, $WeightSpecsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightSpecsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightSpecsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightSpecsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> characterId = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> volumeId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> chapterId = const Value.absent(),
            Value<int> weightDelta = const Value.absent(),
            Value<bool> promoteToMain = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WeightSpecsCompanion(
            id: id,
            characterId: characterId,
            description: description,
            volumeId: volumeId,
            eventId: eventId,
            chapterId: chapterId,
            weightDelta: weightDelta,
            promoteToMain: promoteToMain,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String characterId,
            required String description,
            required String volumeId,
            required String eventId,
            required String chapterId,
            required int weightDelta,
            required bool promoteToMain,
            Value<int> rowid = const Value.absent(),
          }) =>
              WeightSpecsCompanion.insert(
            id: id,
            characterId: characterId,
            description: description,
            volumeId: volumeId,
            eventId: eventId,
            chapterId: chapterId,
            weightDelta: weightDelta,
            promoteToMain: promoteToMain,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeightSpecsTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $WeightSpecsTable,
    WeightSpec,
    $$WeightSpecsTableFilterComposer,
    $$WeightSpecsTableOrderingComposer,
    $$WeightSpecsTableAnnotationComposer,
    $$WeightSpecsTableCreateCompanionBuilder,
    $$WeightSpecsTableUpdateCompanionBuilder,
    (
      WeightSpec,
      BaseReferences<_$WorldDatabase, $WeightSpecsTable, WeightSpec>
    ),
    WeightSpec,
    PrefetchHooks Function()>;
typedef $$CharacterRelationsTableCreateCompanionBuilder
    = CharacterRelationsCompanion Function({
  required String id,
  required String characterId,
  required String relatedCharacterId,
  required String relationType,
  required int intimacy,
  required String description,
  Value<int> rowid,
});
typedef $$CharacterRelationsTableUpdateCompanionBuilder
    = CharacterRelationsCompanion Function({
  Value<String> id,
  Value<String> characterId,
  Value<String> relatedCharacterId,
  Value<String> relationType,
  Value<int> intimacy,
  Value<String> description,
  Value<int> rowid,
});

class $$CharacterRelationsTableFilterComposer
    extends Composer<_$WorldDatabase, $CharacterRelationsTable> {
  $$CharacterRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relatedCharacterId => $composableBuilder(
      column: $table.relatedCharacterId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relationType => $composableBuilder(
      column: $table.relationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intimacy => $composableBuilder(
      column: $table.intimacy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));
}

class $$CharacterRelationsTableOrderingComposer
    extends Composer<_$WorldDatabase, $CharacterRelationsTable> {
  $$CharacterRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relatedCharacterId => $composableBuilder(
      column: $table.relatedCharacterId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relationType => $composableBuilder(
      column: $table.relationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intimacy => $composableBuilder(
      column: $table.intimacy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));
}

class $$CharacterRelationsTableAnnotationComposer
    extends Composer<_$WorldDatabase, $CharacterRelationsTable> {
  $$CharacterRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => column);

  GeneratedColumn<String> get relatedCharacterId => $composableBuilder(
      column: $table.relatedCharacterId, builder: (column) => column);

  GeneratedColumn<String> get relationType => $composableBuilder(
      column: $table.relationType, builder: (column) => column);

  GeneratedColumn<int> get intimacy =>
      $composableBuilder(column: $table.intimacy, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);
}

class $$CharacterRelationsTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $CharacterRelationsTable,
    CharacterRelation,
    $$CharacterRelationsTableFilterComposer,
    $$CharacterRelationsTableOrderingComposer,
    $$CharacterRelationsTableAnnotationComposer,
    $$CharacterRelationsTableCreateCompanionBuilder,
    $$CharacterRelationsTableUpdateCompanionBuilder,
    (
      CharacterRelation,
      BaseReferences<_$WorldDatabase, $CharacterRelationsTable,
          CharacterRelation>
    ),
    CharacterRelation,
    PrefetchHooks Function()> {
  $$CharacterRelationsTableTableManager(
      _$WorldDatabase db, $CharacterRelationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterRelationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> characterId = const Value.absent(),
            Value<String> relatedCharacterId = const Value.absent(),
            Value<String> relationType = const Value.absent(),
            Value<int> intimacy = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CharacterRelationsCompanion(
            id: id,
            characterId: characterId,
            relatedCharacterId: relatedCharacterId,
            relationType: relationType,
            intimacy: intimacy,
            description: description,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String characterId,
            required String relatedCharacterId,
            required String relationType,
            required int intimacy,
            required String description,
            Value<int> rowid = const Value.absent(),
          }) =>
              CharacterRelationsCompanion.insert(
            id: id,
            characterId: characterId,
            relatedCharacterId: relatedCharacterId,
            relationType: relationType,
            intimacy: intimacy,
            description: description,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CharacterRelationsTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $CharacterRelationsTable,
    CharacterRelation,
    $$CharacterRelationsTableFilterComposer,
    $$CharacterRelationsTableOrderingComposer,
    $$CharacterRelationsTableAnnotationComposer,
    $$CharacterRelationsTableCreateCompanionBuilder,
    $$CharacterRelationsTableUpdateCompanionBuilder,
    (
      CharacterRelation,
      BaseReferences<_$WorldDatabase, $CharacterRelationsTable,
          CharacterRelation>
    ),
    CharacterRelation,
    PrefetchHooks Function()>;
typedef $$RelationStagesTableCreateCompanionBuilder = RelationStagesCompanion
    Function({
  required String id,
  required String relationId,
  required int atIntimacy,
  required String stageName,
  required DateTime reachedAt,
  required String triggerEventId,
  required bool confirmed,
  Value<int> rowid,
});
typedef $$RelationStagesTableUpdateCompanionBuilder = RelationStagesCompanion
    Function({
  Value<String> id,
  Value<String> relationId,
  Value<int> atIntimacy,
  Value<String> stageName,
  Value<DateTime> reachedAt,
  Value<String> triggerEventId,
  Value<bool> confirmed,
  Value<int> rowid,
});

class $$RelationStagesTableFilterComposer
    extends Composer<_$WorldDatabase, $RelationStagesTable> {
  $$RelationStagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relationId => $composableBuilder(
      column: $table.relationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get atIntimacy => $composableBuilder(
      column: $table.atIntimacy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stageName => $composableBuilder(
      column: $table.stageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reachedAt => $composableBuilder(
      column: $table.reachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get triggerEventId => $composableBuilder(
      column: $table.triggerEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get confirmed => $composableBuilder(
      column: $table.confirmed, builder: (column) => ColumnFilters(column));
}

class $$RelationStagesTableOrderingComposer
    extends Composer<_$WorldDatabase, $RelationStagesTable> {
  $$RelationStagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relationId => $composableBuilder(
      column: $table.relationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get atIntimacy => $composableBuilder(
      column: $table.atIntimacy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stageName => $composableBuilder(
      column: $table.stageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reachedAt => $composableBuilder(
      column: $table.reachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get triggerEventId => $composableBuilder(
      column: $table.triggerEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get confirmed => $composableBuilder(
      column: $table.confirmed, builder: (column) => ColumnOrderings(column));
}

class $$RelationStagesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $RelationStagesTable> {
  $$RelationStagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relationId => $composableBuilder(
      column: $table.relationId, builder: (column) => column);

  GeneratedColumn<int> get atIntimacy => $composableBuilder(
      column: $table.atIntimacy, builder: (column) => column);

  GeneratedColumn<String> get stageName =>
      $composableBuilder(column: $table.stageName, builder: (column) => column);

  GeneratedColumn<DateTime> get reachedAt =>
      $composableBuilder(column: $table.reachedAt, builder: (column) => column);

  GeneratedColumn<String> get triggerEventId => $composableBuilder(
      column: $table.triggerEventId, builder: (column) => column);

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);
}

class $$RelationStagesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $RelationStagesTable,
    RelationStage,
    $$RelationStagesTableFilterComposer,
    $$RelationStagesTableOrderingComposer,
    $$RelationStagesTableAnnotationComposer,
    $$RelationStagesTableCreateCompanionBuilder,
    $$RelationStagesTableUpdateCompanionBuilder,
    (
      RelationStage,
      BaseReferences<_$WorldDatabase, $RelationStagesTable, RelationStage>
    ),
    RelationStage,
    PrefetchHooks Function()> {
  $$RelationStagesTableTableManager(
      _$WorldDatabase db, $RelationStagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelationStagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelationStagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelationStagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> relationId = const Value.absent(),
            Value<int> atIntimacy = const Value.absent(),
            Value<String> stageName = const Value.absent(),
            Value<DateTime> reachedAt = const Value.absent(),
            Value<String> triggerEventId = const Value.absent(),
            Value<bool> confirmed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RelationStagesCompanion(
            id: id,
            relationId: relationId,
            atIntimacy: atIntimacy,
            stageName: stageName,
            reachedAt: reachedAt,
            triggerEventId: triggerEventId,
            confirmed: confirmed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String relationId,
            required int atIntimacy,
            required String stageName,
            required DateTime reachedAt,
            required String triggerEventId,
            required bool confirmed,
            Value<int> rowid = const Value.absent(),
          }) =>
              RelationStagesCompanion.insert(
            id: id,
            relationId: relationId,
            atIntimacy: atIntimacy,
            stageName: stageName,
            reachedAt: reachedAt,
            triggerEventId: triggerEventId,
            confirmed: confirmed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RelationStagesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $RelationStagesTable,
    RelationStage,
    $$RelationStagesTableFilterComposer,
    $$RelationStagesTableOrderingComposer,
    $$RelationStagesTableAnnotationComposer,
    $$RelationStagesTableCreateCompanionBuilder,
    $$RelationStagesTableUpdateCompanionBuilder,
    (
      RelationStage,
      BaseReferences<_$WorldDatabase, $RelationStagesTable, RelationStage>
    ),
    RelationStage,
    PrefetchHooks Function()>;
typedef $$LocationsTableCreateCompanionBuilder = LocationsCompanion Function({
  required String id,
  required String worldId,
  required String name,
  required String description,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocationsTableUpdateCompanionBuilder = LocationsCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> name,
  Value<String> description,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocationsTableFilterComposer
    extends Composer<_$WorldDatabase, $LocationsTable> {
  $$LocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocationsTableOrderingComposer
    extends Composer<_$WorldDatabase, $LocationsTable> {
  $$LocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocationsTableAnnotationComposer
    extends Composer<_$WorldDatabase, $LocationsTable> {
  $$LocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocationsTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $LocationsTable,
    Location,
    $$LocationsTableFilterComposer,
    $$LocationsTableOrderingComposer,
    $$LocationsTableAnnotationComposer,
    $$LocationsTableCreateCompanionBuilder,
    $$LocationsTableUpdateCompanionBuilder,
    (Location, BaseReferences<_$WorldDatabase, $LocationsTable, Location>),
    Location,
    PrefetchHooks Function()> {
  $$LocationsTableTableManager(_$WorldDatabase db, $LocationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocationsCompanion(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String name,
            required String description,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocationsCompanion.insert(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocationsTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $LocationsTable,
    Location,
    $$LocationsTableFilterComposer,
    $$LocationsTableOrderingComposer,
    $$LocationsTableAnnotationComposer,
    $$LocationsTableCreateCompanionBuilder,
    $$LocationsTableUpdateCompanionBuilder,
    (Location, BaseReferences<_$WorldDatabase, $LocationsTable, Location>),
    Location,
    PrefetchHooks Function()>;
typedef $$LoresTableCreateCompanionBuilder = LoresCompanion Function({
  required String id,
  required String worldId,
  required String name,
  required String type,
  required String description,
  required String triggerKeywords,
  required bool enabled,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LoresTableUpdateCompanionBuilder = LoresCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> name,
  Value<String> type,
  Value<String> description,
  Value<String> triggerKeywords,
  Value<bool> enabled,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LoresTableFilterComposer
    extends Composer<_$WorldDatabase, $LoresTable> {
  $$LoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get triggerKeywords => $composableBuilder(
      column: $table.triggerKeywords,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LoresTableOrderingComposer
    extends Composer<_$WorldDatabase, $LoresTable> {
  $$LoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get triggerKeywords => $composableBuilder(
      column: $table.triggerKeywords,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LoresTableAnnotationComposer
    extends Composer<_$WorldDatabase, $LoresTable> {
  $$LoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get triggerKeywords => $composableBuilder(
      column: $table.triggerKeywords, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LoresTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $LoresTable,
    Lore,
    $$LoresTableFilterComposer,
    $$LoresTableOrderingComposer,
    $$LoresTableAnnotationComposer,
    $$LoresTableCreateCompanionBuilder,
    $$LoresTableUpdateCompanionBuilder,
    (Lore, BaseReferences<_$WorldDatabase, $LoresTable, Lore>),
    Lore,
    PrefetchHooks Function()> {
  $$LoresTableTableManager(_$WorldDatabase db, $LoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> triggerKeywords = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoresCompanion(
            id: id,
            worldId: worldId,
            name: name,
            type: type,
            description: description,
            triggerKeywords: triggerKeywords,
            enabled: enabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String name,
            required String type,
            required String description,
            required String triggerKeywords,
            required bool enabled,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LoresCompanion.insert(
            id: id,
            worldId: worldId,
            name: name,
            type: type,
            description: description,
            triggerKeywords: triggerKeywords,
            enabled: enabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoresTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $LoresTable,
    Lore,
    $$LoresTableFilterComposer,
    $$LoresTableOrderingComposer,
    $$LoresTableAnnotationComposer,
    $$LoresTableCreateCompanionBuilder,
    $$LoresTableUpdateCompanionBuilder,
    (Lore, BaseReferences<_$WorldDatabase, $LoresTable, Lore>),
    Lore,
    PrefetchHooks Function()>;
typedef $$WorldRulesTableCreateCompanionBuilder = WorldRulesCompanion Function({
  required String id,
  required String worldId,
  required String name,
  required String description,
  required String scope,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$WorldRulesTableUpdateCompanionBuilder = WorldRulesCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> name,
  Value<String> description,
  Value<String> scope,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$WorldRulesTableFilterComposer
    extends Composer<_$WorldDatabase, $WorldRulesTable> {
  $$WorldRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WorldRulesTableOrderingComposer
    extends Composer<_$WorldDatabase, $WorldRulesTable> {
  $$WorldRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorldRulesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $WorldRulesTable> {
  $$WorldRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorldRulesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $WorldRulesTable,
    WorldRule,
    $$WorldRulesTableFilterComposer,
    $$WorldRulesTableOrderingComposer,
    $$WorldRulesTableAnnotationComposer,
    $$WorldRulesTableCreateCompanionBuilder,
    $$WorldRulesTableUpdateCompanionBuilder,
    (WorldRule, BaseReferences<_$WorldDatabase, $WorldRulesTable, WorldRule>),
    WorldRule,
    PrefetchHooks Function()> {
  $$WorldRulesTableTableManager(_$WorldDatabase db, $WorldRulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorldRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorldRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorldRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> scope = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorldRulesCompanion(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            scope: scope,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String name,
            required String description,
            required String scope,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorldRulesCompanion.insert(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            scope: scope,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorldRulesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $WorldRulesTable,
    WorldRule,
    $$WorldRulesTableFilterComposer,
    $$WorldRulesTableOrderingComposer,
    $$WorldRulesTableAnnotationComposer,
    $$WorldRulesTableCreateCompanionBuilder,
    $$WorldRulesTableUpdateCompanionBuilder,
    (WorldRule, BaseReferences<_$WorldDatabase, $WorldRulesTable, WorldRule>),
    WorldRule,
    PrefetchHooks Function()>;
typedef $$TimelineEventsTableCreateCompanionBuilder = TimelineEventsCompanion
    Function({
  required String id,
  required String worldId,
  required String title,
  required String description,
  required String orderKey,
  required String inStoryDate,
  required int inStoryDay,
  required String duration,
  required String chapterAnchor,
  required String branchId,
  required String parentEventId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TimelineEventsTableUpdateCompanionBuilder = TimelineEventsCompanion
    Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> title,
  Value<String> description,
  Value<String> orderKey,
  Value<String> inStoryDate,
  Value<int> inStoryDay,
  Value<String> duration,
  Value<String> chapterAnchor,
  Value<String> branchId,
  Value<String> parentEventId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TimelineEventsTableFilterComposer
    extends Composer<_$WorldDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderKey => $composableBuilder(
      column: $table.orderKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inStoryDate => $composableBuilder(
      column: $table.inStoryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get inStoryDay => $composableBuilder(
      column: $table.inStoryDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapterAnchor => $composableBuilder(
      column: $table.chapterAnchor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentEventId => $composableBuilder(
      column: $table.parentEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TimelineEventsTableOrderingComposer
    extends Composer<_$WorldDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderKey => $composableBuilder(
      column: $table.orderKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inStoryDate => $composableBuilder(
      column: $table.inStoryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get inStoryDay => $composableBuilder(
      column: $table.inStoryDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapterAnchor => $composableBuilder(
      column: $table.chapterAnchor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentEventId => $composableBuilder(
      column: $table.parentEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TimelineEventsTableAnnotationComposer
    extends Composer<_$WorldDatabase, $TimelineEventsTable> {
  $$TimelineEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<String> get inStoryDate => $composableBuilder(
      column: $table.inStoryDate, builder: (column) => column);

  GeneratedColumn<int> get inStoryDay => $composableBuilder(
      column: $table.inStoryDay, builder: (column) => column);

  GeneratedColumn<String> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get chapterAnchor => $composableBuilder(
      column: $table.chapterAnchor, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get parentEventId => $composableBuilder(
      column: $table.parentEventId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TimelineEventsTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $TimelineEventsTable,
    TimelineEvent,
    $$TimelineEventsTableFilterComposer,
    $$TimelineEventsTableOrderingComposer,
    $$TimelineEventsTableAnnotationComposer,
    $$TimelineEventsTableCreateCompanionBuilder,
    $$TimelineEventsTableUpdateCompanionBuilder,
    (
      TimelineEvent,
      BaseReferences<_$WorldDatabase, $TimelineEventsTable, TimelineEvent>
    ),
    TimelineEvent,
    PrefetchHooks Function()> {
  $$TimelineEventsTableTableManager(
      _$WorldDatabase db, $TimelineEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> orderKey = const Value.absent(),
            Value<String> inStoryDate = const Value.absent(),
            Value<int> inStoryDay = const Value.absent(),
            Value<String> duration = const Value.absent(),
            Value<String> chapterAnchor = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> parentEventId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimelineEventsCompanion(
            id: id,
            worldId: worldId,
            title: title,
            description: description,
            orderKey: orderKey,
            inStoryDate: inStoryDate,
            inStoryDay: inStoryDay,
            duration: duration,
            chapterAnchor: chapterAnchor,
            branchId: branchId,
            parentEventId: parentEventId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String title,
            required String description,
            required String orderKey,
            required String inStoryDate,
            required int inStoryDay,
            required String duration,
            required String chapterAnchor,
            required String branchId,
            required String parentEventId,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TimelineEventsCompanion.insert(
            id: id,
            worldId: worldId,
            title: title,
            description: description,
            orderKey: orderKey,
            inStoryDate: inStoryDate,
            inStoryDay: inStoryDay,
            duration: duration,
            chapterAnchor: chapterAnchor,
            branchId: branchId,
            parentEventId: parentEventId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimelineEventsTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $TimelineEventsTable,
    TimelineEvent,
    $$TimelineEventsTableFilterComposer,
    $$TimelineEventsTableOrderingComposer,
    $$TimelineEventsTableAnnotationComposer,
    $$TimelineEventsTableCreateCompanionBuilder,
    $$TimelineEventsTableUpdateCompanionBuilder,
    (
      TimelineEvent,
      BaseReferences<_$WorldDatabase, $TimelineEventsTable, TimelineEvent>
    ),
    TimelineEvent,
    PrefetchHooks Function()>;
typedef $$FactionsTableCreateCompanionBuilder = FactionsCompanion Function({
  required String id,
  required String worldId,
  required String name,
  required String description,
  required String type,
  required int power,
  required String territory,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FactionsTableUpdateCompanionBuilder = FactionsCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> name,
  Value<String> description,
  Value<String> type,
  Value<int> power,
  Value<String> territory,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$FactionsTableFilterComposer
    extends Composer<_$WorldDatabase, $FactionsTable> {
  $$FactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get territory => $composableBuilder(
      column: $table.territory, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FactionsTableOrderingComposer
    extends Composer<_$WorldDatabase, $FactionsTable> {
  $$FactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get territory => $composableBuilder(
      column: $table.territory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FactionsTableAnnotationComposer
    extends Composer<_$WorldDatabase, $FactionsTable> {
  $$FactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get power =>
      $composableBuilder(column: $table.power, builder: (column) => column);

  GeneratedColumn<String> get territory =>
      $composableBuilder(column: $table.territory, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FactionsTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $FactionsTable,
    Faction,
    $$FactionsTableFilterComposer,
    $$FactionsTableOrderingComposer,
    $$FactionsTableAnnotationComposer,
    $$FactionsTableCreateCompanionBuilder,
    $$FactionsTableUpdateCompanionBuilder,
    (Faction, BaseReferences<_$WorldDatabase, $FactionsTable, Faction>),
    Faction,
    PrefetchHooks Function()> {
  $$FactionsTableTableManager(_$WorldDatabase db, $FactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> power = const Value.absent(),
            Value<String> territory = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FactionsCompanion(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            type: type,
            power: power,
            territory: territory,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String name,
            required String description,
            required String type,
            required int power,
            required String territory,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FactionsCompanion.insert(
            id: id,
            worldId: worldId,
            name: name,
            description: description,
            type: type,
            power: power,
            territory: territory,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FactionsTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $FactionsTable,
    Faction,
    $$FactionsTableFilterComposer,
    $$FactionsTableOrderingComposer,
    $$FactionsTableAnnotationComposer,
    $$FactionsTableCreateCompanionBuilder,
    $$FactionsTableUpdateCompanionBuilder,
    (Faction, BaseReferences<_$WorldDatabase, $FactionsTable, Faction>),
    Faction,
    PrefetchHooks Function()>;
typedef $$ForeshadowingsTableCreateCompanionBuilder = ForeshadowingsCompanion
    Function({
  required String id,
  required String worldId,
  required String plantedEventId,
  required String harvestedEventId,
  required String status,
  required int subtlety,
  required String description,
  required String note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ForeshadowingsTableUpdateCompanionBuilder = ForeshadowingsCompanion
    Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> plantedEventId,
  Value<String> harvestedEventId,
  Value<String> status,
  Value<int> subtlety,
  Value<String> description,
  Value<String> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ForeshadowingsTableFilterComposer
    extends Composer<_$WorldDatabase, $ForeshadowingsTable> {
  $$ForeshadowingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plantedEventId => $composableBuilder(
      column: $table.plantedEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get harvestedEventId => $composableBuilder(
      column: $table.harvestedEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get subtlety => $composableBuilder(
      column: $table.subtlety, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ForeshadowingsTableOrderingComposer
    extends Composer<_$WorldDatabase, $ForeshadowingsTable> {
  $$ForeshadowingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plantedEventId => $composableBuilder(
      column: $table.plantedEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get harvestedEventId => $composableBuilder(
      column: $table.harvestedEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get subtlety => $composableBuilder(
      column: $table.subtlety, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ForeshadowingsTableAnnotationComposer
    extends Composer<_$WorldDatabase, $ForeshadowingsTable> {
  $$ForeshadowingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get plantedEventId => $composableBuilder(
      column: $table.plantedEventId, builder: (column) => column);

  GeneratedColumn<String> get harvestedEventId => $composableBuilder(
      column: $table.harvestedEventId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get subtlety =>
      $composableBuilder(column: $table.subtlety, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ForeshadowingsTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $ForeshadowingsTable,
    Foreshadowing,
    $$ForeshadowingsTableFilterComposer,
    $$ForeshadowingsTableOrderingComposer,
    $$ForeshadowingsTableAnnotationComposer,
    $$ForeshadowingsTableCreateCompanionBuilder,
    $$ForeshadowingsTableUpdateCompanionBuilder,
    (
      Foreshadowing,
      BaseReferences<_$WorldDatabase, $ForeshadowingsTable, Foreshadowing>
    ),
    Foreshadowing,
    PrefetchHooks Function()> {
  $$ForeshadowingsTableTableManager(
      _$WorldDatabase db, $ForeshadowingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ForeshadowingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ForeshadowingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ForeshadowingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> plantedEventId = const Value.absent(),
            Value<String> harvestedEventId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> subtlety = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ForeshadowingsCompanion(
            id: id,
            worldId: worldId,
            plantedEventId: plantedEventId,
            harvestedEventId: harvestedEventId,
            status: status,
            subtlety: subtlety,
            description: description,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String plantedEventId,
            required String harvestedEventId,
            required String status,
            required int subtlety,
            required String description,
            required String note,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ForeshadowingsCompanion.insert(
            id: id,
            worldId: worldId,
            plantedEventId: plantedEventId,
            harvestedEventId: harvestedEventId,
            status: status,
            subtlety: subtlety,
            description: description,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ForeshadowingsTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $ForeshadowingsTable,
    Foreshadowing,
    $$ForeshadowingsTableFilterComposer,
    $$ForeshadowingsTableOrderingComposer,
    $$ForeshadowingsTableAnnotationComposer,
    $$ForeshadowingsTableCreateCompanionBuilder,
    $$ForeshadowingsTableUpdateCompanionBuilder,
    (
      Foreshadowing,
      BaseReferences<_$WorldDatabase, $ForeshadowingsTable, Foreshadowing>
    ),
    Foreshadowing,
    PrefetchHooks Function()>;
typedef $$ButterflyAnalysesTableCreateCompanionBuilder
    = ButterflyAnalysesCompanion Function({
  required String id,
  required String worldId,
  required String eventId,
  required String analysisText,
  required String predictedDirection,
  required int tokenCost,
  required double estimatedCost,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ButterflyAnalysesTableUpdateCompanionBuilder
    = ButterflyAnalysesCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> eventId,
  Value<String> analysisText,
  Value<String> predictedDirection,
  Value<int> tokenCost,
  Value<double> estimatedCost,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ButterflyAnalysesTableFilterComposer
    extends Composer<_$WorldDatabase, $ButterflyAnalysesTable> {
  $$ButterflyAnalysesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisText => $composableBuilder(
      column: $table.analysisText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get predictedDirection => $composableBuilder(
      column: $table.predictedDirection,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tokenCost => $composableBuilder(
      column: $table.tokenCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ButterflyAnalysesTableOrderingComposer
    extends Composer<_$WorldDatabase, $ButterflyAnalysesTable> {
  $$ButterflyAnalysesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisText => $composableBuilder(
      column: $table.analysisText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get predictedDirection => $composableBuilder(
      column: $table.predictedDirection,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tokenCost => $composableBuilder(
      column: $table.tokenCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ButterflyAnalysesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $ButterflyAnalysesTable> {
  $$ButterflyAnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get analysisText => $composableBuilder(
      column: $table.analysisText, builder: (column) => column);

  GeneratedColumn<String> get predictedDirection => $composableBuilder(
      column: $table.predictedDirection, builder: (column) => column);

  GeneratedColumn<int> get tokenCost =>
      $composableBuilder(column: $table.tokenCost, builder: (column) => column);

  GeneratedColumn<double> get estimatedCost => $composableBuilder(
      column: $table.estimatedCost, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ButterflyAnalysesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $ButterflyAnalysesTable,
    ButterflyAnalysis,
    $$ButterflyAnalysesTableFilterComposer,
    $$ButterflyAnalysesTableOrderingComposer,
    $$ButterflyAnalysesTableAnnotationComposer,
    $$ButterflyAnalysesTableCreateCompanionBuilder,
    $$ButterflyAnalysesTableUpdateCompanionBuilder,
    (
      ButterflyAnalysis,
      BaseReferences<_$WorldDatabase, $ButterflyAnalysesTable,
          ButterflyAnalysis>
    ),
    ButterflyAnalysis,
    PrefetchHooks Function()> {
  $$ButterflyAnalysesTableTableManager(
      _$WorldDatabase db, $ButterflyAnalysesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ButterflyAnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ButterflyAnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ButterflyAnalysesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> analysisText = const Value.absent(),
            Value<String> predictedDirection = const Value.absent(),
            Value<int> tokenCost = const Value.absent(),
            Value<double> estimatedCost = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ButterflyAnalysesCompanion(
            id: id,
            worldId: worldId,
            eventId: eventId,
            analysisText: analysisText,
            predictedDirection: predictedDirection,
            tokenCost: tokenCost,
            estimatedCost: estimatedCost,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String eventId,
            required String analysisText,
            required String predictedDirection,
            required int tokenCost,
            required double estimatedCost,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ButterflyAnalysesCompanion.insert(
            id: id,
            worldId: worldId,
            eventId: eventId,
            analysisText: analysisText,
            predictedDirection: predictedDirection,
            tokenCost: tokenCost,
            estimatedCost: estimatedCost,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ButterflyAnalysesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $ButterflyAnalysesTable,
    ButterflyAnalysis,
    $$ButterflyAnalysesTableFilterComposer,
    $$ButterflyAnalysesTableOrderingComposer,
    $$ButterflyAnalysesTableAnnotationComposer,
    $$ButterflyAnalysesTableCreateCompanionBuilder,
    $$ButterflyAnalysesTableUpdateCompanionBuilder,
    (
      ButterflyAnalysis,
      BaseReferences<_$WorldDatabase, $ButterflyAnalysesTable,
          ButterflyAnalysis>
    ),
    ButterflyAnalysis,
    PrefetchHooks Function()>;
typedef $$SceneSummariesTableCreateCompanionBuilder = SceneSummariesCompanion
    Function({
  required String id,
  required String sceneId,
  required String chapterId,
  required String worldId,
  required String summary,
  required String keywords,
  required String characters,
  required String location,
  required String mood,
  required String inStoryDay,
  required String causeEvent,
  required String effectEvent,
  required String characterEmotions,
  required String conflictType,
  required String suspenseTags,
  required String keyDialogues,
  required String signatureMoments,
  required String foreshadowingIds,
  required int wordCount,
  required int sceneOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SceneSummariesTableUpdateCompanionBuilder = SceneSummariesCompanion
    Function({
  Value<String> id,
  Value<String> sceneId,
  Value<String> chapterId,
  Value<String> worldId,
  Value<String> summary,
  Value<String> keywords,
  Value<String> characters,
  Value<String> location,
  Value<String> mood,
  Value<String> inStoryDay,
  Value<String> causeEvent,
  Value<String> effectEvent,
  Value<String> characterEmotions,
  Value<String> conflictType,
  Value<String> suspenseTags,
  Value<String> keyDialogues,
  Value<String> signatureMoments,
  Value<String> foreshadowingIds,
  Value<int> wordCount,
  Value<int> sceneOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SceneSummariesTableFilterComposer
    extends Composer<_$WorldDatabase, $SceneSummariesTable> {
  $$SceneSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sceneId => $composableBuilder(
      column: $table.sceneId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keywords => $composableBuilder(
      column: $table.keywords, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get characters => $composableBuilder(
      column: $table.characters, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inStoryDay => $composableBuilder(
      column: $table.inStoryDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get causeEvent => $composableBuilder(
      column: $table.causeEvent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effectEvent => $composableBuilder(
      column: $table.effectEvent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get characterEmotions => $composableBuilder(
      column: $table.characterEmotions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conflictType => $composableBuilder(
      column: $table.conflictType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get suspenseTags => $composableBuilder(
      column: $table.suspenseTags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyDialogues => $composableBuilder(
      column: $table.keyDialogues, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signatureMoments => $composableBuilder(
      column: $table.signatureMoments,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get foreshadowingIds => $composableBuilder(
      column: $table.foreshadowingIds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sceneOrder => $composableBuilder(
      column: $table.sceneOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SceneSummariesTableOrderingComposer
    extends Composer<_$WorldDatabase, $SceneSummariesTable> {
  $$SceneSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sceneId => $composableBuilder(
      column: $table.sceneId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keywords => $composableBuilder(
      column: $table.keywords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characters => $composableBuilder(
      column: $table.characters, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inStoryDay => $composableBuilder(
      column: $table.inStoryDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get causeEvent => $composableBuilder(
      column: $table.causeEvent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effectEvent => $composableBuilder(
      column: $table.effectEvent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characterEmotions => $composableBuilder(
      column: $table.characterEmotions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conflictType => $composableBuilder(
      column: $table.conflictType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get suspenseTags => $composableBuilder(
      column: $table.suspenseTags,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyDialogues => $composableBuilder(
      column: $table.keyDialogues,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signatureMoments => $composableBuilder(
      column: $table.signatureMoments,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get foreshadowingIds => $composableBuilder(
      column: $table.foreshadowingIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sceneOrder => $composableBuilder(
      column: $table.sceneOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SceneSummariesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $SceneSummariesTable> {
  $$SceneSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sceneId =>
      $composableBuilder(column: $table.sceneId, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  GeneratedColumn<String> get characters => $composableBuilder(
      column: $table.characters, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get inStoryDay => $composableBuilder(
      column: $table.inStoryDay, builder: (column) => column);

  GeneratedColumn<String> get causeEvent => $composableBuilder(
      column: $table.causeEvent, builder: (column) => column);

  GeneratedColumn<String> get effectEvent => $composableBuilder(
      column: $table.effectEvent, builder: (column) => column);

  GeneratedColumn<String> get characterEmotions => $composableBuilder(
      column: $table.characterEmotions, builder: (column) => column);

  GeneratedColumn<String> get conflictType => $composableBuilder(
      column: $table.conflictType, builder: (column) => column);

  GeneratedColumn<String> get suspenseTags => $composableBuilder(
      column: $table.suspenseTags, builder: (column) => column);

  GeneratedColumn<String> get keyDialogues => $composableBuilder(
      column: $table.keyDialogues, builder: (column) => column);

  GeneratedColumn<String> get signatureMoments => $composableBuilder(
      column: $table.signatureMoments, builder: (column) => column);

  GeneratedColumn<String> get foreshadowingIds => $composableBuilder(
      column: $table.foreshadowingIds, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<int> get sceneOrder => $composableBuilder(
      column: $table.sceneOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SceneSummariesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $SceneSummariesTable,
    SceneSummary,
    $$SceneSummariesTableFilterComposer,
    $$SceneSummariesTableOrderingComposer,
    $$SceneSummariesTableAnnotationComposer,
    $$SceneSummariesTableCreateCompanionBuilder,
    $$SceneSummariesTableUpdateCompanionBuilder,
    (
      SceneSummary,
      BaseReferences<_$WorldDatabase, $SceneSummariesTable, SceneSummary>
    ),
    SceneSummary,
    PrefetchHooks Function()> {
  $$SceneSummariesTableTableManager(
      _$WorldDatabase db, $SceneSummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SceneSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SceneSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SceneSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sceneId = const Value.absent(),
            Value<String> chapterId = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> keywords = const Value.absent(),
            Value<String> characters = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<String> mood = const Value.absent(),
            Value<String> inStoryDay = const Value.absent(),
            Value<String> causeEvent = const Value.absent(),
            Value<String> effectEvent = const Value.absent(),
            Value<String> characterEmotions = const Value.absent(),
            Value<String> conflictType = const Value.absent(),
            Value<String> suspenseTags = const Value.absent(),
            Value<String> keyDialogues = const Value.absent(),
            Value<String> signatureMoments = const Value.absent(),
            Value<String> foreshadowingIds = const Value.absent(),
            Value<int> wordCount = const Value.absent(),
            Value<int> sceneOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SceneSummariesCompanion(
            id: id,
            sceneId: sceneId,
            chapterId: chapterId,
            worldId: worldId,
            summary: summary,
            keywords: keywords,
            characters: characters,
            location: location,
            mood: mood,
            inStoryDay: inStoryDay,
            causeEvent: causeEvent,
            effectEvent: effectEvent,
            characterEmotions: characterEmotions,
            conflictType: conflictType,
            suspenseTags: suspenseTags,
            keyDialogues: keyDialogues,
            signatureMoments: signatureMoments,
            foreshadowingIds: foreshadowingIds,
            wordCount: wordCount,
            sceneOrder: sceneOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sceneId,
            required String chapterId,
            required String worldId,
            required String summary,
            required String keywords,
            required String characters,
            required String location,
            required String mood,
            required String inStoryDay,
            required String causeEvent,
            required String effectEvent,
            required String characterEmotions,
            required String conflictType,
            required String suspenseTags,
            required String keyDialogues,
            required String signatureMoments,
            required String foreshadowingIds,
            required int wordCount,
            required int sceneOrder,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SceneSummariesCompanion.insert(
            id: id,
            sceneId: sceneId,
            chapterId: chapterId,
            worldId: worldId,
            summary: summary,
            keywords: keywords,
            characters: characters,
            location: location,
            mood: mood,
            inStoryDay: inStoryDay,
            causeEvent: causeEvent,
            effectEvent: effectEvent,
            characterEmotions: characterEmotions,
            conflictType: conflictType,
            suspenseTags: suspenseTags,
            keyDialogues: keyDialogues,
            signatureMoments: signatureMoments,
            foreshadowingIds: foreshadowingIds,
            wordCount: wordCount,
            sceneOrder: sceneOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SceneSummariesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $SceneSummariesTable,
    SceneSummary,
    $$SceneSummariesTableFilterComposer,
    $$SceneSummariesTableOrderingComposer,
    $$SceneSummariesTableAnnotationComposer,
    $$SceneSummariesTableCreateCompanionBuilder,
    $$SceneSummariesTableUpdateCompanionBuilder,
    (
      SceneSummary,
      BaseReferences<_$WorldDatabase, $SceneSummariesTable, SceneSummary>
    ),
    SceneSummary,
    PrefetchHooks Function()>;
typedef $$ChapterSummariesTableCreateCompanionBuilder
    = ChapterSummariesCompanion Function({
  required String id,
  required String chapterId,
  required String volumeId,
  required String worldId,
  required String summary,
  required String hook,
  required String majorEvents,
  required String characterArcs,
  required String conflictResolution,
  required String emotionalClimax,
  required String unansweredQuestions,
  required int sceneCount,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ChapterSummariesTableUpdateCompanionBuilder
    = ChapterSummariesCompanion Function({
  Value<String> id,
  Value<String> chapterId,
  Value<String> volumeId,
  Value<String> worldId,
  Value<String> summary,
  Value<String> hook,
  Value<String> majorEvents,
  Value<String> characterArcs,
  Value<String> conflictResolution,
  Value<String> emotionalClimax,
  Value<String> unansweredQuestions,
  Value<int> sceneCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ChapterSummariesTableFilterComposer
    extends Composer<_$WorldDatabase, $ChapterSummariesTable> {
  $$ChapterSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hook => $composableBuilder(
      column: $table.hook, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get majorEvents => $composableBuilder(
      column: $table.majorEvents, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get characterArcs => $composableBuilder(
      column: $table.characterArcs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conflictResolution => $composableBuilder(
      column: $table.conflictResolution,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emotionalClimax => $composableBuilder(
      column: $table.emotionalClimax,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unansweredQuestions => $composableBuilder(
      column: $table.unansweredQuestions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sceneCount => $composableBuilder(
      column: $table.sceneCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChapterSummariesTableOrderingComposer
    extends Composer<_$WorldDatabase, $ChapterSummariesTable> {
  $$ChapterSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hook => $composableBuilder(
      column: $table.hook, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get majorEvents => $composableBuilder(
      column: $table.majorEvents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characterArcs => $composableBuilder(
      column: $table.characterArcs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conflictResolution => $composableBuilder(
      column: $table.conflictResolution,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emotionalClimax => $composableBuilder(
      column: $table.emotionalClimax,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unansweredQuestions => $composableBuilder(
      column: $table.unansweredQuestions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sceneCount => $composableBuilder(
      column: $table.sceneCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChapterSummariesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $ChapterSummariesTable> {
  $$ChapterSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<String> get volumeId =>
      $composableBuilder(column: $table.volumeId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get hook =>
      $composableBuilder(column: $table.hook, builder: (column) => column);

  GeneratedColumn<String> get majorEvents => $composableBuilder(
      column: $table.majorEvents, builder: (column) => column);

  GeneratedColumn<String> get characterArcs => $composableBuilder(
      column: $table.characterArcs, builder: (column) => column);

  GeneratedColumn<String> get conflictResolution => $composableBuilder(
      column: $table.conflictResolution, builder: (column) => column);

  GeneratedColumn<String> get emotionalClimax => $composableBuilder(
      column: $table.emotionalClimax, builder: (column) => column);

  GeneratedColumn<String> get unansweredQuestions => $composableBuilder(
      column: $table.unansweredQuestions, builder: (column) => column);

  GeneratedColumn<int> get sceneCount => $composableBuilder(
      column: $table.sceneCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChapterSummariesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $ChapterSummariesTable,
    ChapterSummary,
    $$ChapterSummariesTableFilterComposer,
    $$ChapterSummariesTableOrderingComposer,
    $$ChapterSummariesTableAnnotationComposer,
    $$ChapterSummariesTableCreateCompanionBuilder,
    $$ChapterSummariesTableUpdateCompanionBuilder,
    (
      ChapterSummary,
      BaseReferences<_$WorldDatabase, $ChapterSummariesTable, ChapterSummary>
    ),
    ChapterSummary,
    PrefetchHooks Function()> {
  $$ChapterSummariesTableTableManager(
      _$WorldDatabase db, $ChapterSummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChapterSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChapterSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChapterSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> chapterId = const Value.absent(),
            Value<String> volumeId = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> hook = const Value.absent(),
            Value<String> majorEvents = const Value.absent(),
            Value<String> characterArcs = const Value.absent(),
            Value<String> conflictResolution = const Value.absent(),
            Value<String> emotionalClimax = const Value.absent(),
            Value<String> unansweredQuestions = const Value.absent(),
            Value<int> sceneCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChapterSummariesCompanion(
            id: id,
            chapterId: chapterId,
            volumeId: volumeId,
            worldId: worldId,
            summary: summary,
            hook: hook,
            majorEvents: majorEvents,
            characterArcs: characterArcs,
            conflictResolution: conflictResolution,
            emotionalClimax: emotionalClimax,
            unansweredQuestions: unansweredQuestions,
            sceneCount: sceneCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String chapterId,
            required String volumeId,
            required String worldId,
            required String summary,
            required String hook,
            required String majorEvents,
            required String characterArcs,
            required String conflictResolution,
            required String emotionalClimax,
            required String unansweredQuestions,
            required int sceneCount,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChapterSummariesCompanion.insert(
            id: id,
            chapterId: chapterId,
            volumeId: volumeId,
            worldId: worldId,
            summary: summary,
            hook: hook,
            majorEvents: majorEvents,
            characterArcs: characterArcs,
            conflictResolution: conflictResolution,
            emotionalClimax: emotionalClimax,
            unansweredQuestions: unansweredQuestions,
            sceneCount: sceneCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChapterSummariesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $ChapterSummariesTable,
    ChapterSummary,
    $$ChapterSummariesTableFilterComposer,
    $$ChapterSummariesTableOrderingComposer,
    $$ChapterSummariesTableAnnotationComposer,
    $$ChapterSummariesTableCreateCompanionBuilder,
    $$ChapterSummariesTableUpdateCompanionBuilder,
    (
      ChapterSummary,
      BaseReferences<_$WorldDatabase, $ChapterSummariesTable, ChapterSummary>
    ),
    ChapterSummary,
    PrefetchHooks Function()>;
typedef $$VolumeSummariesTableCreateCompanionBuilder = VolumeSummariesCompanion
    Function({
  required String id,
  required String volumeId,
  required String worldId,
  required String summary,
  required String status,
  required String mainCharacters,
  required String storyArc,
  required String majorPlotPoints,
  required String unresolvedThreads,
  required int chapterCount,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$VolumeSummariesTableUpdateCompanionBuilder = VolumeSummariesCompanion
    Function({
  Value<String> id,
  Value<String> volumeId,
  Value<String> worldId,
  Value<String> summary,
  Value<String> status,
  Value<String> mainCharacters,
  Value<String> storyArc,
  Value<String> majorPlotPoints,
  Value<String> unresolvedThreads,
  Value<int> chapterCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$VolumeSummariesTableFilterComposer
    extends Composer<_$WorldDatabase, $VolumeSummariesTable> {
  $$VolumeSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mainCharacters => $composableBuilder(
      column: $table.mainCharacters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storyArc => $composableBuilder(
      column: $table.storyArc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get majorPlotPoints => $composableBuilder(
      column: $table.majorPlotPoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unresolvedThreads => $composableBuilder(
      column: $table.unresolvedThreads,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterCount => $composableBuilder(
      column: $table.chapterCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$VolumeSummariesTableOrderingComposer
    extends Composer<_$WorldDatabase, $VolumeSummariesTable> {
  $$VolumeSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mainCharacters => $composableBuilder(
      column: $table.mainCharacters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storyArc => $composableBuilder(
      column: $table.storyArc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get majorPlotPoints => $composableBuilder(
      column: $table.majorPlotPoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unresolvedThreads => $composableBuilder(
      column: $table.unresolvedThreads,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterCount => $composableBuilder(
      column: $table.chapterCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$VolumeSummariesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $VolumeSummariesTable> {
  $$VolumeSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get volumeId =>
      $composableBuilder(column: $table.volumeId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get mainCharacters => $composableBuilder(
      column: $table.mainCharacters, builder: (column) => column);

  GeneratedColumn<String> get storyArc =>
      $composableBuilder(column: $table.storyArc, builder: (column) => column);

  GeneratedColumn<String> get majorPlotPoints => $composableBuilder(
      column: $table.majorPlotPoints, builder: (column) => column);

  GeneratedColumn<String> get unresolvedThreads => $composableBuilder(
      column: $table.unresolvedThreads, builder: (column) => column);

  GeneratedColumn<int> get chapterCount => $composableBuilder(
      column: $table.chapterCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VolumeSummariesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $VolumeSummariesTable,
    VolumeSummary,
    $$VolumeSummariesTableFilterComposer,
    $$VolumeSummariesTableOrderingComposer,
    $$VolumeSummariesTableAnnotationComposer,
    $$VolumeSummariesTableCreateCompanionBuilder,
    $$VolumeSummariesTableUpdateCompanionBuilder,
    (
      VolumeSummary,
      BaseReferences<_$WorldDatabase, $VolumeSummariesTable, VolumeSummary>
    ),
    VolumeSummary,
    PrefetchHooks Function()> {
  $$VolumeSummariesTableTableManager(
      _$WorldDatabase db, $VolumeSummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VolumeSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VolumeSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VolumeSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> volumeId = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> mainCharacters = const Value.absent(),
            Value<String> storyArc = const Value.absent(),
            Value<String> majorPlotPoints = const Value.absent(),
            Value<String> unresolvedThreads = const Value.absent(),
            Value<int> chapterCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VolumeSummariesCompanion(
            id: id,
            volumeId: volumeId,
            worldId: worldId,
            summary: summary,
            status: status,
            mainCharacters: mainCharacters,
            storyArc: storyArc,
            majorPlotPoints: majorPlotPoints,
            unresolvedThreads: unresolvedThreads,
            chapterCount: chapterCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String volumeId,
            required String worldId,
            required String summary,
            required String status,
            required String mainCharacters,
            required String storyArc,
            required String majorPlotPoints,
            required String unresolvedThreads,
            required int chapterCount,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VolumeSummariesCompanion.insert(
            id: id,
            volumeId: volumeId,
            worldId: worldId,
            summary: summary,
            status: status,
            mainCharacters: mainCharacters,
            storyArc: storyArc,
            majorPlotPoints: majorPlotPoints,
            unresolvedThreads: unresolvedThreads,
            chapterCount: chapterCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VolumeSummariesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $VolumeSummariesTable,
    VolumeSummary,
    $$VolumeSummariesTableFilterComposer,
    $$VolumeSummariesTableOrderingComposer,
    $$VolumeSummariesTableAnnotationComposer,
    $$VolumeSummariesTableCreateCompanionBuilder,
    $$VolumeSummariesTableUpdateCompanionBuilder,
    (
      VolumeSummary,
      BaseReferences<_$WorldDatabase, $VolumeSummariesTable, VolumeSummary>
    ),
    VolumeSummary,
    PrefetchHooks Function()>;
typedef $$WorksTableCreateCompanionBuilder = WorksCompanion Function({
  required String id,
  required String worldId,
  required String title,
  required String description,
  required String type,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$WorksTableUpdateCompanionBuilder = WorksCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> title,
  Value<String> description,
  Value<String> type,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$WorksTableFilterComposer
    extends Composer<_$WorldDatabase, $WorksTable> {
  $$WorksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WorksTableOrderingComposer
    extends Composer<_$WorldDatabase, $WorksTable> {
  $$WorksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorksTableAnnotationComposer
    extends Composer<_$WorldDatabase, $WorksTable> {
  $$WorksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorksTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $WorksTable,
    Work,
    $$WorksTableFilterComposer,
    $$WorksTableOrderingComposer,
    $$WorksTableAnnotationComposer,
    $$WorksTableCreateCompanionBuilder,
    $$WorksTableUpdateCompanionBuilder,
    (Work, BaseReferences<_$WorldDatabase, $WorksTable, Work>),
    Work,
    PrefetchHooks Function()> {
  $$WorksTableTableManager(_$WorldDatabase db, $WorksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorksCompanion(
            id: id,
            worldId: worldId,
            title: title,
            description: description,
            type: type,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String title,
            required String description,
            required String type,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorksCompanion.insert(
            id: id,
            worldId: worldId,
            title: title,
            description: description,
            type: type,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorksTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $WorksTable,
    Work,
    $$WorksTableFilterComposer,
    $$WorksTableOrderingComposer,
    $$WorksTableAnnotationComposer,
    $$WorksTableCreateCompanionBuilder,
    $$WorksTableUpdateCompanionBuilder,
    (Work, BaseReferences<_$WorldDatabase, $WorksTable, Work>),
    Work,
    PrefetchHooks Function()>;
typedef $$VolumesTableCreateCompanionBuilder = VolumesCompanion Function({
  required String id,
  required String workId,
  required int volumeNumber,
  required String title,
  required String synopsis,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$VolumesTableUpdateCompanionBuilder = VolumesCompanion Function({
  Value<String> id,
  Value<String> workId,
  Value<int> volumeNumber,
  Value<String> title,
  Value<String> synopsis,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$VolumesTableFilterComposer
    extends Composer<_$WorldDatabase, $VolumesTable> {
  $$VolumesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workId => $composableBuilder(
      column: $table.workId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get volumeNumber => $composableBuilder(
      column: $table.volumeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$VolumesTableOrderingComposer
    extends Composer<_$WorldDatabase, $VolumesTable> {
  $$VolumesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workId => $composableBuilder(
      column: $table.workId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get volumeNumber => $composableBuilder(
      column: $table.volumeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$VolumesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $VolumesTable> {
  $$VolumesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workId =>
      $composableBuilder(column: $table.workId, builder: (column) => column);

  GeneratedColumn<int> get volumeNumber => $composableBuilder(
      column: $table.volumeNumber, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get synopsis =>
      $composableBuilder(column: $table.synopsis, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VolumesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $VolumesTable,
    Volume,
    $$VolumesTableFilterComposer,
    $$VolumesTableOrderingComposer,
    $$VolumesTableAnnotationComposer,
    $$VolumesTableCreateCompanionBuilder,
    $$VolumesTableUpdateCompanionBuilder,
    (Volume, BaseReferences<_$WorldDatabase, $VolumesTable, Volume>),
    Volume,
    PrefetchHooks Function()> {
  $$VolumesTableTableManager(_$WorldDatabase db, $VolumesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VolumesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VolumesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VolumesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> workId = const Value.absent(),
            Value<int> volumeNumber = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> synopsis = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VolumesCompanion(
            id: id,
            workId: workId,
            volumeNumber: volumeNumber,
            title: title,
            synopsis: synopsis,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String workId,
            required int volumeNumber,
            required String title,
            required String synopsis,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VolumesCompanion.insert(
            id: id,
            workId: workId,
            volumeNumber: volumeNumber,
            title: title,
            synopsis: synopsis,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VolumesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $VolumesTable,
    Volume,
    $$VolumesTableFilterComposer,
    $$VolumesTableOrderingComposer,
    $$VolumesTableAnnotationComposer,
    $$VolumesTableCreateCompanionBuilder,
    $$VolumesTableUpdateCompanionBuilder,
    (Volume, BaseReferences<_$WorldDatabase, $VolumesTable, Volume>),
    Volume,
    PrefetchHooks Function()>;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  required String id,
  required String volumeId,
  required int chapterNumber,
  required String title,
  required String synopsis,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<String> id,
  Value<String> volumeId,
  Value<int> chapterNumber,
  Value<String> title,
  Value<String> synopsis,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ChaptersTableFilterComposer
    extends Composer<_$WorldDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterNumber => $composableBuilder(
      column: $table.chapterNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$WorldDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get volumeId => $composableBuilder(
      column: $table.volumeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterNumber => $composableBuilder(
      column: $table.chapterNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get synopsis => $composableBuilder(
      column: $table.synopsis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$WorldDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get volumeId =>
      $composableBuilder(column: $table.volumeId, builder: (column) => column);

  GeneratedColumn<int> get chapterNumber => $composableBuilder(
      column: $table.chapterNumber, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get synopsis =>
      $composableBuilder(column: $table.synopsis, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChaptersTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, BaseReferences<_$WorldDatabase, $ChaptersTable, Chapter>),
    Chapter,
    PrefetchHooks Function()> {
  $$ChaptersTableTableManager(_$WorldDatabase db, $ChaptersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> volumeId = const Value.absent(),
            Value<int> chapterNumber = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> synopsis = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersCompanion(
            id: id,
            volumeId: volumeId,
            chapterNumber: chapterNumber,
            title: title,
            synopsis: synopsis,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String volumeId,
            required int chapterNumber,
            required String title,
            required String synopsis,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersCompanion.insert(
            id: id,
            volumeId: volumeId,
            chapterNumber: chapterNumber,
            title: title,
            synopsis: synopsis,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChaptersTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $ChaptersTable,
    Chapter,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (Chapter, BaseReferences<_$WorldDatabase, $ChaptersTable, Chapter>),
    Chapter,
    PrefetchHooks Function()>;
typedef $$ScenesTableCreateCompanionBuilder = ScenesCompanion Function({
  required String id,
  required String chapterId,
  required int sceneNumber,
  required String title,
  required String outlineDescription,
  required String locationId,
  required String timelineEventId,
  required String documentId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ScenesTableUpdateCompanionBuilder = ScenesCompanion Function({
  Value<String> id,
  Value<String> chapterId,
  Value<int> sceneNumber,
  Value<String> title,
  Value<String> outlineDescription,
  Value<String> locationId,
  Value<String> timelineEventId,
  Value<String> documentId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ScenesTableFilterComposer
    extends Composer<_$WorldDatabase, $ScenesTable> {
  $$ScenesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sceneNumber => $composableBuilder(
      column: $table.sceneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outlineDescription => $composableBuilder(
      column: $table.outlineDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locationId => $composableBuilder(
      column: $table.locationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timelineEventId => $composableBuilder(
      column: $table.timelineEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ScenesTableOrderingComposer
    extends Composer<_$WorldDatabase, $ScenesTable> {
  $$ScenesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sceneNumber => $composableBuilder(
      column: $table.sceneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outlineDescription => $composableBuilder(
      column: $table.outlineDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationId => $composableBuilder(
      column: $table.locationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timelineEventId => $composableBuilder(
      column: $table.timelineEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ScenesTableAnnotationComposer
    extends Composer<_$WorldDatabase, $ScenesTable> {
  $$ScenesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<int> get sceneNumber => $composableBuilder(
      column: $table.sceneNumber, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get outlineDescription => $composableBuilder(
      column: $table.outlineDescription, builder: (column) => column);

  GeneratedColumn<String> get locationId => $composableBuilder(
      column: $table.locationId, builder: (column) => column);

  GeneratedColumn<String> get timelineEventId => $composableBuilder(
      column: $table.timelineEventId, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ScenesTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $ScenesTable,
    Scene,
    $$ScenesTableFilterComposer,
    $$ScenesTableOrderingComposer,
    $$ScenesTableAnnotationComposer,
    $$ScenesTableCreateCompanionBuilder,
    $$ScenesTableUpdateCompanionBuilder,
    (Scene, BaseReferences<_$WorldDatabase, $ScenesTable, Scene>),
    Scene,
    PrefetchHooks Function()> {
  $$ScenesTableTableManager(_$WorldDatabase db, $ScenesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScenesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScenesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScenesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> chapterId = const Value.absent(),
            Value<int> sceneNumber = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> outlineDescription = const Value.absent(),
            Value<String> locationId = const Value.absent(),
            Value<String> timelineEventId = const Value.absent(),
            Value<String> documentId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScenesCompanion(
            id: id,
            chapterId: chapterId,
            sceneNumber: sceneNumber,
            title: title,
            outlineDescription: outlineDescription,
            locationId: locationId,
            timelineEventId: timelineEventId,
            documentId: documentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String chapterId,
            required int sceneNumber,
            required String title,
            required String outlineDescription,
            required String locationId,
            required String timelineEventId,
            required String documentId,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ScenesCompanion.insert(
            id: id,
            chapterId: chapterId,
            sceneNumber: sceneNumber,
            title: title,
            outlineDescription: outlineDescription,
            locationId: locationId,
            timelineEventId: timelineEventId,
            documentId: documentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScenesTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $ScenesTable,
    Scene,
    $$ScenesTableFilterComposer,
    $$ScenesTableOrderingComposer,
    $$ScenesTableAnnotationComposer,
    $$ScenesTableCreateCompanionBuilder,
    $$ScenesTableUpdateCompanionBuilder,
    (Scene, BaseReferences<_$WorldDatabase, $ScenesTable, Scene>),
    Scene,
    PrefetchHooks Function()>;
typedef $$DocumentsTableCreateCompanionBuilder = DocumentsCompanion Function({
  required String id,
  required String worldId,
  required String workId,
  required String filePath,
  required String currentSceneId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> id,
  Value<String> worldId,
  Value<String> workId,
  Value<String> filePath,
  Value<String> currentSceneId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DocumentsTableFilterComposer
    extends Composer<_$WorldDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workId => $composableBuilder(
      column: $table.workId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentSceneId => $composableBuilder(
      column: $table.currentSceneId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$WorldDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get worldId => $composableBuilder(
      column: $table.worldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workId => $composableBuilder(
      column: $table.workId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentSceneId => $composableBuilder(
      column: $table.currentSceneId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$WorldDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get workId =>
      $composableBuilder(column: $table.workId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get currentSceneId => $composableBuilder(
      column: $table.currentSceneId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DocumentsTableTableManager extends RootTableManager<
    _$WorldDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, BaseReferences<_$WorldDatabase, $DocumentsTable, Document>),
    Document,
    PrefetchHooks Function()> {
  $$DocumentsTableTableManager(_$WorldDatabase db, $DocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> worldId = const Value.absent(),
            Value<String> workId = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String> currentSceneId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion(
            id: id,
            worldId: worldId,
            workId: workId,
            filePath: filePath,
            currentSceneId: currentSceneId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String worldId,
            required String workId,
            required String filePath,
            required String currentSceneId,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion.insert(
            id: id,
            worldId: worldId,
            workId: workId,
            filePath: filePath,
            currentSceneId: currentSceneId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentsTableProcessedTableManager = ProcessedTableManager<
    _$WorldDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, BaseReferences<_$WorldDatabase, $DocumentsTable, Document>),
    Document,
    PrefetchHooks Function()>;

class $WorldDatabaseManager {
  final _$WorldDatabase _db;
  $WorldDatabaseManager(this._db);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db, _db.characters);
  $$IdentitiesTableTableManager get identities =>
      $$IdentitiesTableTableManager(_db, _db.identities);
  $$WeightSpecsTableTableManager get weightSpecs =>
      $$WeightSpecsTableTableManager(_db, _db.weightSpecs);
  $$CharacterRelationsTableTableManager get characterRelations =>
      $$CharacterRelationsTableTableManager(_db, _db.characterRelations);
  $$RelationStagesTableTableManager get relationStages =>
      $$RelationStagesTableTableManager(_db, _db.relationStages);
  $$LocationsTableTableManager get locations =>
      $$LocationsTableTableManager(_db, _db.locations);
  $$LoresTableTableManager get lores =>
      $$LoresTableTableManager(_db, _db.lores);
  $$WorldRulesTableTableManager get worldRules =>
      $$WorldRulesTableTableManager(_db, _db.worldRules);
  $$TimelineEventsTableTableManager get timelineEvents =>
      $$TimelineEventsTableTableManager(_db, _db.timelineEvents);
  $$FactionsTableTableManager get factions =>
      $$FactionsTableTableManager(_db, _db.factions);
  $$ForeshadowingsTableTableManager get foreshadowings =>
      $$ForeshadowingsTableTableManager(_db, _db.foreshadowings);
  $$ButterflyAnalysesTableTableManager get butterflyAnalyses =>
      $$ButterflyAnalysesTableTableManager(_db, _db.butterflyAnalyses);
  $$SceneSummariesTableTableManager get sceneSummaries =>
      $$SceneSummariesTableTableManager(_db, _db.sceneSummaries);
  $$ChapterSummariesTableTableManager get chapterSummaries =>
      $$ChapterSummariesTableTableManager(_db, _db.chapterSummaries);
  $$VolumeSummariesTableTableManager get volumeSummaries =>
      $$VolumeSummariesTableTableManager(_db, _db.volumeSummaries);
  $$WorksTableTableManager get works =>
      $$WorksTableTableManager(_db, _db.works);
  $$VolumesTableTableManager get volumes =>
      $$VolumesTableTableManager(_db, _db.volumes);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$ScenesTableTableManager get scenes =>
      $$ScenesTableTableManager(_db, _db.scenes);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
}
