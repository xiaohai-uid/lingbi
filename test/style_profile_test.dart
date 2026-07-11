/// 测试: StyleProfiles Drift 表 CRUD
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
    final tempDir = await Directory.systemTemp.createTemp('lingbi_style_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    databaseManager = _MemoryDatabaseManager();
    db = await databaseManager.getDatabase('test-world-1');
  });

  tearDown(() async {
    await databaseManager.closeAll();
  });

  group('StyleProfiles CRUD', () {
    test('insert and read StyleProfile', () async {
      final now = DateTime.now();
      await db.into(db.styleProfiles).insert(StyleProfilesCompanion.insert(
        id: 'sp1',
        worldId: 'test-world-1',
        sceneId: Value('scene-1'),
        summary: 'classic xianxia style, refined writing',
        tone: 'serious',
        vocabularyLevel: 'literary',
        dialogueRatio: 0.3,
        sentenceComplexity: 0.7,
        pacing: 'balanced',
        rhetoricalDevices: '["metaphor","parallelism"]',
        paragraphLength: 0.5,
        keywords: 'xianxia,classic,refined',
        rawAnalysis: 'detailed analysis text...',
        createdAt: now,
        updatedAt: now,
      ));

      final rows = await db.select(db.styleProfiles).get();
      expect(rows.length, 1);
      final row = rows.first;
      expect(row.id, 'sp1');
      expect(row.sceneId, 'scene-1');
      expect(row.tone, 'serious');
      expect(row.vocabularyLevel, 'literary');
      expect(row.dialogueRatio, 0.3);
      expect(row.sentenceComplexity, 0.7);
      expect(row.pacing, 'balanced');
    });

    test('update StyleProfile', () async {
      final now = DateTime.now();
      await db.into(db.styleProfiles).insert(StyleProfilesCompanion.insert(
        id: 'sp2', worldId: 'test-world-1',
        summary: 'initial style', tone: 'light', vocabularyLevel: 'casual',
        dialogueRatio: 0.5, sentenceComplexity: 0.3, pacing: 'fast',
        rhetoricalDevices: '', paragraphLength: 0.5, keywords: '',
        rawAnalysis: '', createdAt: now, updatedAt: now,
      ));

      await (db.update(db.styleProfiles)..where((t) => t.id.equals('sp2'))).write(
        StyleProfilesCompanion(
          summary: Value('updated style'),
          tone: Value('humorous'),
          vocabularyLevel: Value('colloquial'),
          dialogueRatio: Value(0.8),
          updatedAt: Value(now),
        ),
      );

      final row = await (db.select(db.styleProfiles)..where((t) => t.id.equals('sp2'))).getSingle();
      expect(row.tone, 'humorous');
      expect(row.dialogueRatio, 0.8);
    });

    test('query by sceneId', () async {
      final now = DateTime.now();
      for (var i = 1; i <= 3; i++) {
        await db.into(db.styleProfiles).insert(StyleProfilesCompanion.insert(
          id: 'sp$i', worldId: 'test-world-1',
          sceneId: Value('scene-$i'),
          summary: 'style$i', tone: 'serious', vocabularyLevel: 'literary',
          dialogueRatio: 0.3, sentenceComplexity: 0.7, pacing: 'fast',
          rhetoricalDevices: '', paragraphLength: 0.5, keywords: '',
          rawAnalysis: '', createdAt: now, updatedAt: now,
        ));
      }

      final rows = await (db.select(db.styleProfiles)
        ..where((t) => t.sceneId.equals('scene-2'))).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'sp2');
    });
  });
}
