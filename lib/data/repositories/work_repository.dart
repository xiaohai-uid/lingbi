/// 作品仓库 — Work 层级 CRUD
library work_repository;

import 'package:drift/drift.dart';
import '../database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 作品查询仓库
class WorkRepository {
  WorkRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  /// 获取世界的所有作品
  Future<List<Work>> getWorks(String worldId) async {
    final db = await _db(worldId);
    return (db.select(db.works)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// 根据 ID 获取作品
  Future<Work?> getWork(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final work = await (db.select(db.works)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (work == null) return null;

    return Work(
      id: work.id,
      worldId: work.worldId,
      title: work.title,
      description: work.description,
      type: work.type,
      createdAt: work.createdAt,
      updatedAt: work.updatedAt,
    );
  }

  /// 创建作品
  Future<Work> createWork(String worldId, WorksCompanion entry) async {
    final db = await _db(worldId);
    await db.into(db.works).insert(entry);
    final work = await getWork(entry.id.value, worldId: worldId);
    if (work == null) throw Exception('Failed to create work');
    return work;
  }

  /// 更新作品
  Future<void> updateWork(String id, WorksCompanion entry,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    await (db.update(db.works)..where((t) => t.id.equals(id))).write(entry);
  }

  /// 删除作品（级联删除卷/章/场景）
  Future<void> deleteWork(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final volumes = await getVolumes(id, worldId: worldId);
    for (final volume in volumes) {
      await deleteVolume(volume.id, worldId: worldId);
    }
    await (db.delete(db.works)..where((t) => t.id.equals(id))).go();
  }

  /// 删除卷（级联删除章节/场景）
  Future<void> deleteVolume(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final chapters = await getVolumes(id, worldId: worldId);
    for (final chapter in chapters) {
      await deleteChapter(chapter.id, worldId: worldId);
    }
    await (db.delete(db.volumes)..where((t) => t.id.equals(id))).go();
  }

  /// 删除章节（级联删除场景）
  Future<void> deleteChapter(String id, {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final scenes = await (db.select(db.scenes)
          ..where((t) => t.chapterId.equals(id)))
        .get();
    for (final scene in scenes) {
      await (db.delete(db.scenes)..where((t) => t.id.equals(scene.id))).go();
    }
    await (db.delete(db.chapters)..where((t) => t.id.equals(id))).go();
  }

  /// 获取作品的所有卷
  Future<List<Volume>> getVolumes(String workId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.volumes)
          ..where((t) => t.workId.equals(workId))
          ..orderBy([(t) => OrderingTerm(expression: t.volumeNumber)]))
        .get();
  }

  /// 获取作品的章节树结构
  Future<List<VolumeWithChapters>> getWorkTree(String workId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final volumes = await getVolumes(workId, worldId: worldId);
    final result = <VolumeWithChapters>[];

    for (final volume in volumes) {
      final chapters = await (db.select(db.chapters)
            ..where((t) => t.volumeId.equals(volume.id))
            ..orderBy([(t) => OrderingTerm(expression: t.chapterNumber)]))
          .get();
      result.add(VolumeWithChapters(
        volume: volume,
        chapters: chapters,
      ));
    }

    return result;
  }
}

/// 卷 + 章节树节点
class VolumeWithChapters {
  VolumeWithChapters({
    required this.volume,
    required this.chapters,
  });
  final Volume volume;
  final List<Chapter> chapters;
}
