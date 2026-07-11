/// 测试: MemoryService — 写作记忆系统数据层
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/database_manager.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';

class _MemoryDatabaseManager extends DatabaseManager {
  final Map<String, WorldDatabase> _databases = {};
  @override
  Future<WorldDatabase> getDatabase(String worldId) async =>
      _databases.putIfAbsent(worldId, () => WorldDatabase(NativeDatabase.memory()));
  @override
  Future<void> closeAll() async {
    for (final db in _databases.values) await db.close();
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
  late _MemoryDatabaseManager databaseManager;
  late WorldDatabase db;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('lingbi_memory_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    databaseManager = _MemoryDatabaseManager();
    db = await databaseManager.getDatabase('test-world-1');
  });

  tearDown(() async {
    await databaseManager.closeAll();
  });

  group('SceneSummaries CRUD', () {
    test('插入并读取 SceneSummary', () async {
      final now = DateTime.now();
      await db.into(db.sceneSummaries).insert(SceneSummariesCompanion.insert(
        id: 's1',
        sceneId: 'scene-1',
        chapterId: 'ch-1',
        worldId: 'test-world-1',
        summary: '主角在青云门测试中展现实力，引起长老注意',
        keywords: '青云门,入门测试,展现实力',
        characters: '["char-1","char-2"]',
        location: '青云门演武场',
        mood: '紧张',
        inStoryDay: '第3天',
        causeEvent: 'evt-enter-sect',
        effectEvent: 'evt-recruited',
        characterEmotions: '{"char-1":"紧张","char-2":"惊讶"}',
        conflictType: '人物',
        suspenseTags: '["主角真实身份","长老意图"]',
        keyDialogues: '[{"speaker":"长老","line":"此子根骨奇佳"}]',
        signatureMoments: '["主角一拳击碎测试石碑"]',
        foreshadowingIds: '["fore-1"]',
        wordCount: 1500,
        sceneOrder: 1,
        createdAt: now,
        updatedAt: now,
      ));

      final rows = await db.select(db.sceneSummaries).get();
      expect(rows.length, 1);
      final row = rows.first;
      expect(row.id, 's1');
      expect(row.sceneId, 'scene-1');
      expect(row.chapterId, 'ch-1');
      expect(row.worldId, 'test-world-1');
      expect(row.summary, contains('青云门'));
      expect(row.keywords, contains('入门测试'));
      expect(row.characters, contains('char-1'));
      expect(row.location, '青云门演武场');
      expect(row.mood, '紧张');
      expect(row.inStoryDay, '第3天');
      expect(row.characterEmotions, contains('char-1'));
      expect(row.conflictType, '人物');
      expect(row.wordCount, 1500);
      expect(row.sceneOrder, 1);
    expect(row.embeddingId, isNull); // 新字段默认为空
    });

    test('更新 SceneSummary', () async {
      final now = DateTime.now();
      await db.into(db.sceneSummaries).insert(SceneSummariesCompanion.insert(
        id: 's2', sceneId: 'scene-2', chapterId: 'ch-1',
        worldId: 'test-world-1', summary: '原始摘要',
        keywords: '', characters: '', location: '', mood: '',
        inStoryDay: '', causeEvent: '', effectEvent: '',
        characterEmotions: '', conflictType: '', suspenseTags: '',
        keyDialogues: '', signatureMoments: '', foreshadowingIds: '',
        wordCount: 1000, sceneOrder: 2, createdAt: now, updatedAt: now,
      ));

      await db.update(db.sceneSummaries).replace(SceneSummary(
        id: 's2', sceneId: 'scene-2', chapterId: 'ch-1',
        worldId: 'test-world-1', summary: '更新后的摘要',
        keywords: '', characters: '', location: '', mood: '',
        inStoryDay: '', causeEvent: '', effectEvent: '',
        characterEmotions: '', conflictType: '', suspenseTags: '',
        keyDialogues: '', signatureMoments: '', foreshadowingIds: '',
        wordCount: 2000, sceneOrder: 2, createdAt: now, updatedAt: now,
      ));

      final row = await (db.select(db.sceneSummaries)..where((t) => t.id.equals('s2'))).getSingle();
      expect(row.summary, '更新后的摘要');
      expect(row.wordCount, 2000);
    });

    test('删除 SceneSummary', () async {
      final now = DateTime.now();
      await db.into(db.sceneSummaries).insert(SceneSummariesCompanion.insert(
        id: 's3', sceneId: 'scene-3', chapterId: 'ch-1',
        worldId: 'test-world-1', summary: '待删除',
        keywords: '', characters: '', location: '', mood: '',
        inStoryDay: '', causeEvent: '', effectEvent: '',
        characterEmotions: '', conflictType: '', suspenseTags: '',
        keyDialogues: '', signatureMoments: '', foreshadowingIds: '',
        wordCount: 500, sceneOrder: 3, createdAt: now, updatedAt: now,
      ));

      await db.delete(db.sceneSummaries).go();
      final rows = await db.select(db.sceneSummaries).get();
      expect(rows.length, 0);
    });
  });

  group('ChapterSummaries CRUD', () {
    test('插入并读取 ChapterSummary', () async {
      final now = DateTime.now();
      await db.into(db.chapterSummaries).insert(ChapterSummariesCompanion.insert(
        id: 'ch-sum-1', chapterId: 'ch-1', volumeId: 'vol-1',
        worldId: 'test-world-1', summary: '主角入门青云门，结识同门',
        hook: '长老深夜召见主角', majorEvents: '["入门测试","拜师"]',
        characterArcs: '{"char-1":"从废材到显露天赋"}',
        conflictResolution: '测试冲突化解',
        emotionalClimax: '主角获得认可', unansweredQuestions: '["主角身世"]',
        sceneCount: 3, createdAt: now, updatedAt: now,
      ));

      final row = await db.select(db.chapterSummaries).getSingle();
      expect(row.chapterId, 'ch-1');
      expect(row.volumeId, 'vol-1');
      expect(row.summary, contains('青云门'));
      expect(row.hook, '长老深夜召见主角');
      expect(row.sceneCount, 3);
    });
  });

  group('VolumeSummaries CRUD', () {
    test('插入并读取 VolumeSummary', () async {
      final now = DateTime.now();
      await db.into(db.volumeSummaries).insert(VolumeSummariesCompanion.insert(
        id: 'vol-sum-1', volumeId: 'vol-1',
        worldId: 'test-world-1', summary: '第一卷：主角从废材崛起',
        status: 'writing', mainCharacters: '{"char-1":"主角"}',
        storyArc: '废材逆袭', majorPlotPoints: '["入门","试炼","夺宝"]',
        unresolvedThreads: '["幕后黑手"]', chapterCount: 10,
        createdAt: now, updatedAt: now,
      ));

      final row = await db.select(db.volumeSummaries).getSingle();
      expect(row.volumeId, 'vol-1');
      expect(row.status, 'writing');
      expect(row.chapterCount, 10);
      expect(row.storyArc, '废材逆袭');
    });
  });

  group('跨表关联查询', () {
    test('按 chapterId 查询场景摘要', () async {
      final now = DateTime.now();
      // 插入两个场景
      for (var i = 1; i <= 2; i++) {
        await db.into(db.sceneSummaries).insert(SceneSummariesCompanion.insert(
          id: 's$i', sceneId: 'scene-$i', chapterId: 'ch-1',
          worldId: 'test-world-1', summary: '场景$i',
          keywords: '', characters: '', location: '', mood: '',
          inStoryDay: '', causeEvent: '', effectEvent: '',
          characterEmotions: '', conflictType: '', suspenseTags: '',
          keyDialogues: '', signatureMoments: '', foreshadowingIds: '',
          wordCount: 500 * i, sceneOrder: i, createdAt: now, updatedAt: now,
        ));
      }
      // 按 chapterId 查询
      final rows = await (db.select(db.sceneSummaries)
        ..where((t) => t.chapterId.equals('ch-1'))
        ..orderBy([(t) => OrderingTerm(expression: t.sceneOrder)])
      ).get();
      expect(rows.length, 2);
      expect(rows[0].sceneOrder, 1);
      expect(rows[1].sceneOrder, 2);
    });
  });
}
