/// 角色仓库 — 角色/身份/权重/关系 相关查询
library character_repository;

import 'package:drift/drift.dart';
import '../database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 角色查询仓库
class CharacterRepository {
  CharacterRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  /// 按有效权重排序获取场景角色
  Future<List<SceneCharacter>> getCharactersForScene({
    required String sceneId,
    required String volumeId,
    String worldId = 'default',
    int topN = 5,
  }) async {
    final db = await _db(worldId);
    final scene = await (db.select(db.scenes)
          ..where((t) => t.id.equals(sceneId)))
        .getSingleOrNull();
    if (scene == null) return [];

    final highWeightChars = await getHighWeightCharacters(volumeId,
        worldId: worldId, minWeight: 30);

    final result = <SceneCharacter>[];
    for (final char in highWeightChars.take(topN)) {
      final identities = await getIdentities(char.id, worldId: worldId);
      final weight = await getEffectiveWeight(char.id,
          volumeId: volumeId, worldId: worldId);
      result.add(SceneCharacter(
        character: char,
        effectiveWeight: weight,
        activeIdentities: identities,
      ));
    }

    result.sort((a, b) => b.effectiveWeight.compareTo(a.effectiveWeight));
    return result;
  }

  /// 获取角色的所有身份
  Future<List<Identity>> getIdentities(String characterId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.identities)
          ..where((t) => t.characterId.equals(characterId)))
        .get();
  }

  /// 查询某卷中权重 > 阈值的角色
  Future<List<Character>> getHighWeightCharacters(String volumeId,
      {String worldId = 'default', int minWeight = 50}) async {
    final db = await _db(worldId);
    final baseQuery = (db.select(db.characters)
      ..where((t) => t.baseWeight.isBiggerOrEqualValue(minWeight)));
    final baseChars = await baseQuery.get();

    final specQuery = (db.select(db.weightSpecs)
      ..where((t) => t.volumeId.equals(volumeId))
      ..where((t) => t.weightDelta.isNotNull()));
    final specs = await specQuery.get();
    if (specs.isEmpty) return baseChars;

    final weighted = <_WeightedChar>[];
    for (final char in baseChars) {
      int totalDelta = 0;
      for (final spec in specs) {
        if (spec.characterId == char.id) {
          totalDelta += spec.weightDelta;
        }
      }
      if (char.baseWeight + totalDelta >= minWeight) {
        weighted.add(_WeightedChar(char, char.baseWeight + totalDelta));
      }
    }

    weighted.sort((a, b) => b.weight.compareTo(a.weight));
    return weighted.map((w) => w.char).toList();
  }

  /// 获取与某角色关系为指定类型的角色
  Future<List<Character>> getRelatedCharacters(
    String characterId, {
    String worldId = 'default',
    String? relationType,
  }) async {
    final db = await _db(worldId);
    final query = db.select(db.characterRelations)
      ..where((t) => t.characterId.equals(characterId));
    if (relationType != null) {
      query.where((t) => t.relationType.equals(relationType));
    }
    final relations = await query.get();
    if (relations.isEmpty) return [];

    final relatedIds = relations.map((r) => r.relatedCharacterId).toList();
    return (db.select(db.characters)..where((t) => t.id.isIn(relatedIds)))
        .get();
  }

  /// 获取角色有效权重
  Future<int> getEffectiveWeight(String characterId,
      {String? volumeId, String worldId = 'default'}) async {
    final db = await _db(worldId);
    final char = await (db.select(db.characters)
          ..where((t) => t.id.equals(characterId)))
        .getSingleOrNull();
    if (char == null) return 0;

    int weight = char.baseWeight;
    weight += char.tempWeight;

    if (volumeId != null) {
      final specs = await (db.select(db.weightSpecs)
            ..where((t) => t.characterId.equals(characterId))
            ..where((t) => t.volumeId.equals(volumeId)))
          .get();
      for (final spec in specs) {
        weight += spec.weightDelta;
      }
    }

    return weight.clamp(0, 100);
  }

  /// 更新身份权重并重新计算 baseWeight
  Future<void> updateIdentityWeight(String identityId, int newWeight,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final identity = await (db.select(db.identities)
          ..where((t) => t.id.equals(identityId)))
        .getSingleOrNull();
    if (identity == null) return;

    await (db.update(db.identities)..where((t) => t.id.equals(identityId)))
        .write(IdentitiesCompanion(weight: Value(newWeight)));

    final allIdentities = await (db.select(db.identities)
          ..where((t) => t.characterId.equals(identity.characterId)))
        .get();
    final maxWeight = allIdentities
        .map((i) => i.weight)
        .fold(0, (int max, int w) => w > max ? w : max);

    await (db.update(db.characters)
          ..where((t) => t.id.equals(identity.characterId)))
        .write(CharactersCompanion(baseWeight: Value(maxWeight)));
  }
}

/// 场景角色（含权重信息）
class SceneCharacter {
  const SceneCharacter({
    required this.character,
    required this.effectiveWeight,
    this.activeIdentities = const [],
  });
  final Character character;
  final int effectiveWeight;
  final List<Identity> activeIdentities;
}

/// 带权重的角色（内部辅助类）
class _WeightedChar {
  const _WeightedChar(this.char, this.weight);
  final Character char;
  final int weight;
}
