import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:lingbi/core/database/database_manager.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/data/repositories/canon_repository.dart';
import 'package:lingbi/data/repositories/chapter_repository.dart';
import 'package:lingbi/data/repositories/character_repository.dart';
import 'package:lingbi/data/repositories/faction_repository.dart';
import 'package:lingbi/data/repositories/scene_repository.dart';
import 'package:lingbi/data/repositories/timeline_repository.dart';
import 'package:lingbi/data/repositories/volume_repository.dart';
import 'package:lingbi/data/repositories/work_repository.dart';
import 'package:lingbi/services/world_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _MemoryDatabaseManager databaseManager;
  late WorldService worldService;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('lingbi_world_service_test_');
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

  test('createWorld creates the default editable narrative chain', () async {
    final world = await worldService.createWorld(name: '星穹之下');
    final db = await databaseManager.getDatabase(world.id);

    final works = await db.select(db.works).get();
    expect(works, hasLength(1));
    expect(works.single.title, '未命名作品');

    final volumes = await db.select(db.volumes).get();
    expect(volumes, hasLength(1));
    expect(volumes.single.workId, works.single.id);
    expect(volumes.single.volumeNumber, 1);

    final chapters = await db.select(db.chapters).get();
    expect(chapters, hasLength(1));
    expect(chapters.single.volumeId, volumes.single.id);
    expect(chapters.single.chapterNumber, 1);

    final scenes = await db.select(db.scenes).get();
    expect(scenes, hasLength(1));
    expect(scenes.single.chapterId, chapters.single.id);
    expect(scenes.single.sceneNumber, 1);

    final documents = await db.select(db.documents).get();
    expect(documents, hasLength(1));
    expect(documents.single.worldId, world.id);
    expect(documents.single.workId, works.single.id);
    expect(documents.single.currentSceneId, scenes.single.id);
    expect(scenes.single.documentId, documents.single.id);

    final documentFile = File(documents.single.filePath);
    expect(await documentFile.exists(), isTrue);
    expect(await documentFile.readAsString(), contains('# 第一章'));
  });

  test('createChapterWithDocument appends an editable chapter to a volume',
      () async {
    final world = await worldService.createWorld(name: '星穹之下');
    final db = await databaseManager.getDatabase(world.id);
    final volume = (await db.select(db.volumes).get()).single;

    final chapter = await worldService.createChapterWithDocument(
      worldId: world.id,
      workId: volume.workId,
      volumeId: volume.id,
      title: '第二章',
    );

    expect(chapter.chapterNumber, 2);

    final chapters = await db.select(db.chapters).get();
    expect(chapters, hasLength(2));

    final scenes = await db.select(db.scenes).get();
    expect(scenes, hasLength(2));
    expect(scenes.last.chapterId, chapter.id);

    final documents = await db.select(db.documents).get();
    expect(documents, hasLength(2));
    expect(documents.last.currentSceneId, scenes.last.id);
    expect(scenes.last.documentId, documents.last.id);

    final documentFile = File(documents.last.filePath);
    expect(await documentFile.exists(), isTrue);
    expect(await documentFile.readAsString(), contains('# 第二章'));
  });
}
