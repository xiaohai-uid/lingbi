/// 测试：按章节 ID 查找关联文档
///
/// Bug 复现: _loadDocument() 取所有文档的第一个，而非按当前章节加载
/// 本测试验证 Chapter→Scene→Document 映射链路是否正确。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/database_manager.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/data/repositories/chapter_repository.dart';
import 'package:lingbi/data/repositories/scene_repository.dart';
import 'package:lingbi/data/repositories/volume_repository.dart';
import 'package:lingbi/data/repositories/work_repository.dart';
import 'package:lingbi/data/repositories/canon_repository.dart';
import 'package:lingbi/data/repositories/character_repository.dart';
import 'package:lingbi/data/repositories/timeline_repository.dart';
import 'package:lingbi/data/repositories/faction_repository.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';

/// 内存数据库管理器 — 不写磁盘
class _MemoryDatabaseManager extends DatabaseManager {
  final Map<String, WorldDatabase> _databases = {};

  @override
  Future<WorldDatabase> getDatabase(String worldId) async {
    return _databases.putIfAbsent(
      worldId,
      () => WorldDatabase(NativeDatabase.memory()),
    );
  }

  @override
  Future<void> closeAll() async {
    for (final db in _databases.values) {
      await db.close();
    }
    _databases.clear();
  }
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  late Directory tempDir;
  late _MemoryDatabaseManager databaseManager;
  late WorldService worldService;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('lingbi_cdoc_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    databaseManager = _MemoryDatabaseManager();
    worldService = WorldService(
      databaseManager: databaseManager,
      workRepository: WorkRepository(databaseManager),
      volumeRepository: VolumeRepository(databaseManager),
      chapterRepository: ChapterRepository(databaseManager),
      sceneRepository: SceneRepository(databaseManager),
      characterRepository: CharacterRepository(databaseManager),
      canonRepository: CanonRepository(databaseManager),
      timelineRepository: TimelineRepository(databaseManager),
      factionRepository: FactionRepository(databaseManager),
    );
  });

  tearDown(() async {
    await databaseManager.closeAll();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Chapter→Scene→Document 映射', () {
    test('WorldService.getDocumentForChapter 返回正确文档', () async {
      final worldId = 'world-1';
      final db = await databaseManager.getDatabase(worldId);
      final now = DateTime.now();

      // 创建作品
      await db.into(db.works).insert(WorksCompanion.insert(
            id: 'work-1',
            worldId: worldId,
            title: '测试作品',
            description: '',
            type: 'novel',
            createdAt: now,
            updatedAt: now,
          ));

      // 创建卷
      await db.into(db.volumes).insert(VolumesCompanion.insert(
            id: 'vol-1',
            workId: 'work-1',
            volumeNumber: 1,
            title: '第一卷',
            synopsis: '',
            createdAt: now,
            updatedAt: now,
          ));

      // 章节 1 — 文档 doc-1
      await db.into(db.documents).insert(DocumentsCompanion.insert(
            id: 'doc-1',
            worldId: worldId,
            workId: 'work-1',
            filePath: '/chapters/doc-1.md',
            currentSceneId: 'scene-1',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.chapters).insert(ChaptersCompanion.insert(
            id: 'ch-1',
            volumeId: 'vol-1',
            chapterNumber: 1,
            title: '第一章',
            synopsis: '',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.scenes).insert(ScenesCompanion.insert(
            id: 'scene-1',
            chapterId: 'ch-1',
            sceneNumber: 1,
            title: '第一场景',
            outlineDescription: '',
            locationId: '',
            timelineEventId: '',
            documentId: 'doc-1',
            createdAt: now,
            updatedAt: now,
          ));

      // 章节 2 — 文档 doc-2
      await db.into(db.documents).insert(DocumentsCompanion.insert(
            id: 'doc-2',
            worldId: worldId,
            workId: 'work-1',
            filePath: '/chapters/doc-2.md',
            currentSceneId: 'scene-2',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.chapters).insert(ChaptersCompanion.insert(
            id: 'ch-2',
            volumeId: 'vol-1',
            chapterNumber: 2,
            title: '第二章',
            synopsis: '',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.scenes).insert(ScenesCompanion.insert(
            id: 'scene-2',
            chapterId: 'ch-2',
            sceneNumber: 1,
            title: '第一场景',
            outlineDescription: '',
            locationId: '',
            timelineEventId: '',
            documentId: 'doc-2',
            createdAt: now,
            updatedAt: now,
          ));

      // 章节 3 — 无场景和文档（空章节）
      await db.into(db.chapters).insert(ChaptersCompanion.insert(
            id: 'ch-3',
            volumeId: 'vol-1',
            chapterNumber: 3,
            title: '第三章',
            synopsis: '',
            createdAt: now,
            updatedAt: now,
          ));

      // ⚠️ Bug 复现: 取所有文档的第一个会返回 doc-1
      final allDocs = await db.select(db.documents).get();
      expect(allDocs.first.id, 'doc-1');

      // ✅ 正确行为: 按章节查询
      final doc1 = await worldService.getDocumentForChapter('ch-1', worldId);
      expect(doc1, isA<Document>());
      expect(doc1!.id, 'doc-1');

      final doc2 = await worldService.getDocumentForChapter('ch-2', worldId);
      expect(doc2, isA<Document>());
      expect(doc2!.id, 'doc-2');

      final doc3 = await worldService.getDocumentForChapter('ch-3', worldId);
      expect(doc3 == null, isTrue);
    });
  });
}