/// 章节仓库 — Chapter 层级 CRUD
library chapter_repository;

import 'package:drift/drift.dart';
import '../database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 章节查询仓库
class ChapterRepository {
  ChapterRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  /// 获取卷的所有章节
  Future<List<Chapter>> getChapters(String volumeId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.chapters)
          ..where((t) => t.volumeId.equals(volumeId))
          ..orderBy([(t) => OrderingTerm(expression: t.chapterNumber)]))
        .get();
  }

  /// 根据 ID 获取章节（含场景列表）
  Future<Chapter?> getChapter(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final chapter = await (db.select(db.chapters)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (chapter == null) return null;

    return Chapter(
      id: chapter.id,
      volumeId: chapter.volumeId,
      chapterNumber: chapter.chapterNumber,
      title: chapter.title,
      synopsis: chapter.synopsis,
      createdAt: chapter.createdAt,
      updatedAt: chapter.updatedAt,
    );
  }

  /// 创建章节
  Future<Chapter> createChapter(ChaptersCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await db.into(db.chapters).insert(entry);
    final chapter = await getChapter(entry.id.value, worldId: worldId);
    if (chapter == null) throw Exception('Failed to create chapter');
    return chapter;
  }

  /// 更新章节
  Future<void> updateChapter(String id, ChaptersCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.chapters)..where((t) => t.id.equals(id))).write(entry);
  }

  /// 重新排序章节（拖拽后更新序号）
  Future<void> reorderChapters(String volumeId, List<String> chapterIds,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    for (var i = 0; i < chapterIds.length; i++) {
      await (db.update(db.chapters)..where((t) => t.id.equals(chapterIds[i])))
          .write(ChaptersCompanion(
        chapterNumber: Value(i + 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  /// 删除章节（级联删除场景）
  Future<void> deleteChapter(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final scenes = await getScenes(id, worldId: worldId);
    for (final scene in scenes) {
      await deleteScene(scene.id, worldId: worldId);
    }
    await (db.delete(db.chapters)..where((t) => t.id.equals(id))).go();
  }

  /// 删除场景
  Future<void> deleteScene(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.delete(db.scenes)..where((t) => t.id.equals(id))).go();
  }

  /// 获取章节的所有场景
  Future<List<Scene>> getScenes(String chapterId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.scenes)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([(t) => OrderingTerm(expression: t.sceneNumber)]))
        .get();
  }
}
