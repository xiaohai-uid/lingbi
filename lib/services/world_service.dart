/// WorldService — 世界管理服务
///
/// v4.0 替代旧的 ProjectService。
/// 使用 DatabaseManager 管理多世界数据库，Repository 层处理结构化查询。
library;

import 'package:uuid/uuid.dart';
import '../core/models/world.dart';
import '../core/database/database_manager.dart';
import '../data/repositories/work_repository.dart';
import '../data/repositories/canon_repository.dart';
import '../data/repositories/faction_repository.dart';
import '../data/repositories/timeline_repository.dart';
import '../data/repositories/volume_repository.dart';
import '../data/repositories/chapter_repository.dart';
import '../data/repositories/scene_repository.dart';
import '../data/repositories/character_repository.dart';
import '../data/database/world_database.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const _uuid = Uuid();

/// 世界管理服务
class WorldService {
  WorldService({
    required this.databaseManager,
    required this.workRepository,
    required this.volumeRepository,
    required this.chapterRepository,
    required this.sceneRepository,
    required this.characterRepository,
    required this.canonRepository,
    required this.timelineRepository,
    required this.factionRepository,
  });
  final DatabaseManager databaseManager;
  final WorkRepository workRepository;
  final VolumeRepository volumeRepository;
  final ChapterRepository chapterRepository;
  final SceneRepository sceneRepository;
  final CharacterRepository characterRepository;
  final CanonRepository canonRepository;
  final TimelineRepository timelineRepository;
  final FactionRepository factionRepository;

  /// 创建世界
  Future<World> createWorld({
    required String name,
    String description = '',
    List<String> genres = const [],
    String timelineMode = 'linear',
  }) async {
    final worldId = _uuid.v4();
    final now = DateTime.now();

    final world = World(
      id: worldId,
      name: name,
      description: description,
      genres: genres,
      timelineMode: timelineMode,
      createdAt: now,
      updatedAt: now,
    );

    // 写入 world.json 元数据
    await _saveWorldMeta(world);

    // 初始化该世界的数据库（自动创建 world.db）
    final db = await databaseManager.getDatabase(worldId);

    final workId = _uuid.v4();
    await db.into(db.works).insert(WorksCompanion.insert(
          id: workId,
          worldId: worldId,
          title: '未命名作品',
          description: '',
          type: 'novel',
          createdAt: now,
          updatedAt: now,
        ));

    final volumeId = _uuid.v4();
    await _createVolume(db,
        workId: workId, volumeId: volumeId, title: '第一卷', now: now);
    await createChapterWithDocument(
      worldId: worldId,
      workId: workId,
      volumeId: volumeId,
      title: '第一章',
    );

    return world;
  }

  /// 创建可立即编辑的章节、默认场景、文档索引和 Markdown 文件。
  Future<Chapter> createChapterWithDocument({
    required String worldId,
    required String workId,
    required String volumeId,
    required String title,
    String synopsis = '',
  }) async {
    final db = await databaseManager.getDatabase(worldId);
    final now = DateTime.now();
    final existingChapters =
        await chapterRepository.getChapters(volumeId, worldId: worldId);
    final chapterNumber = existingChapters.length + 1;
    final chapterId = _uuid.v4();
    final sceneId = _uuid.v4();
    final documentId = _uuid.v4();
    final documentPath = p.join(
      await _getWorldsDirPath(),
      worldId,
      'works',
      workId,
      'chapters',
      chapterNumber.toString().padLeft(3, '0'),
      '$documentId.md',
    );

    final chapter = await chapterRepository.createChapter(
      ChaptersCompanion.insert(
        id: chapterId,
        volumeId: volumeId,
        chapterNumber: chapterNumber,
        title: title,
        synopsis: synopsis,
        createdAt: now,
        updatedAt: now,
      ),
      worldId: worldId,
    );

    await db.into(db.documents).insert(DocumentsCompanion.insert(
          id: documentId,
          worldId: worldId,
          workId: workId,
          filePath: documentPath,
          currentSceneId: sceneId,
          createdAt: now,
          updatedAt: now,
        ));

    await db.into(db.scenes).insert(ScenesCompanion.insert(
          id: sceneId,
          chapterId: chapterId,
          sceneNumber: 1,
          title: '第一场景',
          outlineDescription: '',
          locationId: '',
          timelineEventId: '',
          documentId: documentId,
          createdAt: now,
          updatedAt: now,
        ));

    await File(documentPath).create(recursive: true);
    await File(documentPath).writeAsString('# $title\n\n');
    return chapter;
  }

  Future<void> _createVolume(
    WorldDatabase db, {
    required String workId,
    required String volumeId,
    required String title,
    required DateTime now,
  }) async {
    await db.into(db.volumes).insert(VolumesCompanion.insert(
          id: volumeId,
          workId: workId,
          volumeNumber: 1,
          title: title,
          synopsis: '',
          createdAt: now,
          updatedAt: now,
        ));
  }

  /// 获取所有世界
  Future<List<World>> listWorlds() async {
    final worldsDir = await _getWorldsDir();
    if (!await worldsDir.exists()) return [];

    final worlds = <World>[];
    await for (final entry in worldsDir.list()) {
      if (entry is! Directory) continue;
      final metaFile = File(p.join(entry.path, 'world.json'));
      if (!await metaFile.exists()) continue;
      try {
        final json = jsonDecode(await metaFile.readAsString());
        worlds.add(World.fromJson(json as Map<String, dynamic>));
      } catch (_) {}
    }

    worlds.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return worlds;
  }

  /// 获取单个世界
  Future<World?> getWorld(String id) async {
    final file = File(p.join(await _getWorldsDirPath(), id, 'world.json'));
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString());
    return World.fromJson(json as Map<String, dynamic>);
  }

  /// 获取世界的作品列表
  Future<List<Work>> getWorks(String worldId) async {
    return workRepository.getWorks(worldId);
  }

  /// 更新世界元数据
  Future<void> updateWorld(World world) async {
    await _saveWorldMeta(world.copyWith());
  }

  /// 删除世界（级联删除数据库文件和元数据）
  Future<void> deleteWorld(String worldId) async {
    // 关闭数据库连接
    await databaseManager.closeDatabase(worldId);

    // 删除目录
    final worldDir = Directory(p.join(await _getWorldsDirPath(), worldId));
    if (await worldDir.exists()) {
      await worldDir.delete(recursive: true);
    }
  }

  Future<void> _saveWorldMeta(World meta) async {
    final dir = Directory(p.join(await _getWorldsDirPath(), meta.id));
    await dir.create(recursive: true);
    await File(p.join(dir.path, 'world.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(meta.toJson()),
    );
  }

  Future<String> _getWorldsDirPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, '灵笔', 'Worlds');
  }

  Future<Directory> _getWorldsDir() async {
    return Directory(await _getWorldsDirPath());
  }
}
