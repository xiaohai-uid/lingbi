/// 势力仓库 — Faction CRUD
library faction_repository;

import '../database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 势力查询仓库
class FactionRepository {
  FactionRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  /// 获取世界所有势力
  Future<List<Faction>> getFactions(String worldId) async {
    final db = await _db(worldId);
    return (db.select(db.factions)..where((t) => t.worldId.equals(worldId)))
        .get();
  }

  /// 根据 ID 获取势力
  Future<Faction?> getFaction(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.factions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 创建势力
  Future<Faction> createFaction(String worldId, FactionsCompanion entry) async {
    final db = await _db(worldId);
    await db.into(db.factions).insert(entry);
    final faction = await getFaction(entry.id.value, worldId: worldId);
    if (faction == null) throw Exception('Failed to create faction');
    return faction;
  }

  /// 更新势力
  Future<void> updateFaction(String id, FactionsCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.factions)..where((t) => t.id.equals(id))).write(entry);
  }

  /// 删除势力
  Future<void> deleteFaction(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.delete(db.factions)..where((t) => t.id.equals(id))).go();
  }
}
