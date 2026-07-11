/// LoreService — 世界设定管理 (Lorebook)
library;

import 'package:drift/drift.dart';
import 'package:lingbi/core/database/database_manager.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class LoreEntry {
  final String id;
  final String worldId;
  final String name;
  final String type;
  final String description;
  final String triggerKeywords;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoreEntry({
    required this.id,
    required this.worldId,
    required this.name,
    this.type = 'location',
    this.description = '',
    this.triggerKeywords = '',
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoreEntry.fromDb(Lore row) => LoreEntry(
        id: row.id,
        worldId: row.worldId,
        name: row.name,
        type: row.type,
        description: row.description,
        triggerKeywords: row.triggerKeywords,
        enabled: row.enabled,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}

class LoreService {
  final DatabaseManager databaseManager;
  LoreService({required this.databaseManager});

  Future<WorldDatabase> _db(String worldId) =>
      databaseManager.getDatabase(worldId);

  Future<LoreEntry> createLore({
    required String worldId,
    required String name,
    required String type,
    String description = '',
    String triggerKeywords = '',
    bool enabled = true,
  }) async {
    final db = await _db(worldId);
    final now = DateTime.now();
    final id = _uuid.v4();
    await db.into(db.lores).insert(LoresCompanion.insert(
          id: id, worldId: worldId, name: name, type: type,
          description: description, triggerKeywords: triggerKeywords,
          enabled: enabled, createdAt: now, updatedAt: now,
        ));
    return LoreEntry(id: id, worldId: worldId, name: name, type: type,
        description: description, triggerKeywords: triggerKeywords,
        enabled: enabled, createdAt: now, updatedAt: now);
  }

  Future<List<LoreEntry>> getLores(String worldId) async {
    final db = await _db(worldId);
    return (await db.select(db.lores).get()).map((r) => LoreEntry.fromDb(r)).toList();
  }

  Future<LoreEntry?> getLore(String id, {required String worldId}) async {
    final db = await _db(worldId);
    final row = await (db.select(db.lores)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? LoreEntry.fromDb(row) : null;
  }

  Future<void> updateLore(String id, {required String worldId, String? name, bool? enabled}) async {
    final db = await _db(worldId);
    await (db.update(db.lores)..where((t) => t.id.equals(id))).write(
      LoresCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        enabled: enabled != null ? Value(enabled) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteLore(String id, {required String worldId}) async {
    final db = await _db(worldId);
    await (db.delete(db.lores)..where((t) => t.id.equals(id))).go();
  }

  Future<List<LoreEntry>> matchContext({required String worldId, required String text}) async {
    final allLores = await getLores(worldId);
    final matched = <LoreEntry>[];
    for (final lore in allLores) {
      if (!lore.enabled) continue;
      if (lore.triggerKeywords.isEmpty) continue;
      final keywords = lore.triggerKeywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty);
      for (final kw in keywords) {
        if (text.contains(kw)) { matched.add(lore); break; }
      }
    }
    return matched;
  }

  Future<String> buildPromptContext({required String worldId, required String text}) async {
    final matched = await matchContext(worldId: worldId, text: text);
    if (matched.isEmpty) return '';
    final buf = StringBuffer('\n[世界设定引用]\n');
    for (final lore in matched) {
      buf.writeln('- [${lore.type}] ${lore.name}: ${lore.description}');
    }
    return buf.toString();
  }
}