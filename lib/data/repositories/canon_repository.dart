/// 世界正典仓库 — Canon 条目 CRUD
///
/// v3.2+ 替代旧的 CodexService。
/// Canon 是世界观知识的统一容器，包含 Character / Location / Lore / WorldRule。
library canon_repository;

import 'package:drift/drift.dart';
import '../database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 正典查询仓库
class CanonRepository {
  CanonRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  // ─── 角色 ───

  /// 获取世界所有角色
  Future<List<Character>> getCharacters(String worldId) async {
    final db = await _db(worldId);
    return (db.select(db.characters)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.baseWeight, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 根据 ID 获取角色（含身份列表）
  Future<CharacterWithIdentities?> getCharacter(String id,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final char = await (db.select(db.characters)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (char == null) return null;

    final identities = await (db.select(db.identities)
          ..where((t) => t.characterId.equals(id)))
        .get();

    return CharacterWithIdentities(
      character: char,
      identities: identities,
    );
  }

  /// 创建角色
  Future<Character> createCharacter(CharactersCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await db.into(db.characters).insert(entry);
    final char = await (db.select(db.characters)
          ..where((t) => t.id.equals(entry.id.value)))
        .getSingleOrNull();
    if (char == null) throw Exception('Failed to create character');
    return char;
  }

  /// 更新角色
  Future<void> updateCharacter(String id, CharactersCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.characters)..where((t) => t.id.equals(id)))
        .write(entry);
  }

  /// 删除角色（级联删除身份/关系）
  Future<void> deleteCharacter(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.delete(db.identities)..where((t) => t.characterId.equals(id)))
        .go();
    await (db.delete(db.characterRelations)
          ..where((t) =>
              t.characterId.equals(id) | t.relatedCharacterId.equals(id)))
        .go();
    await (db.delete(db.characters)..where((t) => t.id.equals(id))).go();
  }

  // ─── 地点 ───

  Future<List<Location>> getLocations(String worldId) async {
    final db = await _db(worldId);
    return (db.select(db.locations)..where((t) => t.worldId.equals(worldId)))
        .get();
  }

  Future<Location?> getLocation(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.locations)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Location> createLocation(LocationsCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await db.into(db.locations).insert(entry);
    final loc = await getLocation(entry.id.value, worldId: worldId);
    if (loc == null) throw Exception('Failed to create location');
    return loc;
  }

  Future<void> updateLocation(String id, LocationsCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.locations)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteLocation(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.delete(db.locations)..where((t) => t.id.equals(id))).go();
  }

  // ─── 传说 ───

  Future<List<Lore>> getLores(String worldId) async {
    final db = await _db(worldId);
    return (db.select(db.lores)..where((t) => t.worldId.equals(worldId))).get();
  }

  Future<Lore?> getLore(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.lores)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Lore> createLore(LoresCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await db.into(db.lores).insert(entry);
    final lore = await getLore(entry.id.value, worldId: worldId);
    if (lore == null) throw Exception('Failed to create lore');
    return lore;
  }

  Future<void> updateLore(String id, LoresCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.lores)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteLore(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.delete(db.lores)..where((t) => t.id.equals(id))).go();
  }

  // ─── 世界观规则 ───

  Future<List<WorldRule>> getWorldRules(String worldId) async {
    final db = await _db(worldId);
    return (db.select(db.worldRules)..where((t) => t.worldId.equals(worldId)))
        .get();
  }

  Future<WorldRule?> getWorldRule(String id,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.worldRules)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<WorldRule> createWorldRule(WorldRulesCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await db.into(db.worldRules).insert(entry);
    final rule = await getWorldRule(entry.id.value, worldId: worldId);
    if (rule == null) throw Exception('Failed to create world rule');
    return rule;
  }

  Future<void> updateWorldRule(String id, WorldRulesCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.worldRules)..where((t) => t.id.equals(id)))
        .write(entry);
  }

  Future<void> deleteWorldRule(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.delete(db.worldRules)..where((t) => t.id.equals(id))).go();
  }
}

/// 角色 + 身份关联数据
class CharacterWithIdentities {
  CharacterWithIdentities({
    required this.character,
    required this.identities,
  });
  final Character character;
  final List<Identity> identities;
}
