/// 场景仓库 — 场景/章节/卷 层级查询
library scene_repository;

import 'dart:io';
import 'package:drift/drift.dart';
import '../database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 场景查询仓库
class SceneRepository {
  SceneRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  /// 获取某章的所有场景
  Future<List<Scene>> getScenesForChapter(String chapterId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    return (db.select(db.scenes)
          ..where((t) => t.chapterId.equals(chapterId))
          ..orderBy([(t) => OrderingTerm(expression: t.sceneNumber)]))
        .get();
  }

  /// 获取某卷的所有场景（跨章节）
  Future<List<Scene>> getScenesForVolume(String volumeId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final chapters = await (db.select(db.chapters)
          ..where((t) => t.volumeId.equals(volumeId)))
        .get();
    if (chapters.isEmpty) return [];

    final chapterIds = chapters.map((c) => c.id).toList();
    return (db.select(db.scenes)
          ..where((t) => t.chapterId.isIn(chapterIds))
          ..orderBy([(t) => OrderingTerm(expression: t.sceneNumber)]))
        .get();
  }

  /// 获取场景的完整上下文
  Future<SceneContext?> getSceneContext(String sceneId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final scene = await (db.select(db.scenes)
          ..where((t) => t.id.equals(sceneId)))
        .getSingleOrNull();
    if (scene == null) return null;

    Location? location;
    if (scene.locationId.isNotEmpty) {
      location = await (db.select(db.locations)
            ..where((t) => t.id.equals(scene.locationId)))
          .getSingleOrNull();
    }

    return SceneContext(
      scene: scene,
      location: location,
    );
  }

  /// 获取文档内容
  Future<String?> getDocumentContent(String documentId,
      {String worldId = 'default'}) async {
    final db = await _db(worldId);
    final doc = await (db.select(db.documents)
          ..where((t) => t.id.equals(documentId)))
        .getSingleOrNull();
    if (doc == null) return null;

    final file = File(doc.filePath);
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }
}

/// 场景上下文
class SceneContext {
  const SceneContext({
    required this.scene,
    this.location,
  });
  final Scene scene;
  final Location? location;
}
