/// 卷仓库 — Volume 层级 CRUD
library volume_repository;

import 'package:drift/drift.dart';
import '../database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 卷查询仓库
class VolumeRepository {
  VolumeRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  /// 获取作品的所有卷
  Future<List<Volume>> getVolumes(String workId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.volumes)
          ..where((t) => t.workId.equals(workId))
          ..orderBy([(t) => OrderingTerm(expression: t.volumeNumber)]))
        .get();
  }

  /// 根据 ID 获取卷
  Future<Volume?> getVolume(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final volume = await (db.select(db.volumes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (volume == null) return null;

    return Volume(
      id: volume.id,
      workId: volume.workId,
      volumeNumber: volume.volumeNumber,
      title: volume.title,
      synopsis: volume.synopsis,
      createdAt: volume.createdAt,
      updatedAt: volume.updatedAt,
    );
  }

  /// 创建卷
  Future<Volume> createVolume(String workId, VolumesCompanion entry) async {
    final db = await _db(workId);
    await db.into(db.volumes).insert(entry);
    final volume = await getVolume(entry.id.value, worldId: workId);
    if (volume == null) throw Exception('Failed to create volume');
    return volume;
  }

  /// 更新卷
  Future<void> updateVolume(String id, VolumesCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.volumes)..where((t) => t.id.equals(id))).write(entry);
  }

  /// 删除卷（级联删除章节/场景）
  Future<void> deleteVolume(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final chapters = await getChapters(id, worldId: worldId);
    for (final chapter in chapters) {
      await deleteChapter(chapter.id, worldId: worldId);
    }
    await (db.delete(db.volumes)..where((t) => t.id.equals(id))).go();
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

  /// 获取卷的所有章节
  Future<List<Chapter>> getChapters(String volumeId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.chapters)
          ..where((t) => t.volumeId.equals(volumeId))
          ..orderBy([(t) => OrderingTerm(expression: t.chapterNumber)]))
        .get();
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
