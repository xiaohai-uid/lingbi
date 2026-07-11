/// 测试: WritingGoal — Drift 表 CRUD + WritingGoalService
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/database_manager.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/services/writing_goal_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
  late WritingGoalService service;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('lingbi_goal_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    databaseManager = _MemoryDatabaseManager();
    db = await databaseManager.getDatabase('test-world-1');
    service = WritingGoalService(databaseManager: databaseManager);
  });

  tearDown(() async {
    await databaseManager.closeAll();
  });

  group('DailyWritingStats CRUD', () {
    test('insert and read daily stat', () async {
      final now = DateTime.now();
      await db.into(db.dailyWritingStats).insert(DailyWritingStatsCompanion.insert(
        id: '2026-07-11-test-world-1',
        worldId: 'test-world-1', date: '2026-07-11',
        wordCount: 2500, sessionCount: 3, aiCallCount: 5, minutesSpent: 45,
        createdAt: now, updatedAt: now,
      ));

      final rows = await db.select(db.dailyWritingStats).get();
      expect(rows.length, 1);
      final row = rows.first;
      expect(row.wordCount, 2500);
      expect(row.sessionCount, 3);
    });

    test('update adds to existing word count', () async {
      final now = DateTime.now();
      await db.into(db.dailyWritingStats).insert(DailyWritingStatsCompanion.insert(
        id: '2026-07-11-test-world-1', worldId: 'test-world-1', date: '2026-07-11',
        wordCount: 1000, sessionCount: 1, aiCallCount: 2, minutesSpent: 15,
        createdAt: now, updatedAt: now,
      ));

      await (db.update(db.dailyWritingStats)..where((t) => t.id.equals('2026-07-11-test-world-1')))
        .write(DailyWritingStatsCompanion(
          wordCount: Value(2500),
          sessionCount: Value(4),
          updatedAt: Value(now),
        ));

      final row = await db.select(db.dailyWritingStats).getSingle();
      expect(row.wordCount, 2500);
      expect(row.sessionCount, 4);
    });
  });

  group('WritingGoals CRUD', () {
    test('insert and read goal', () async {
      final now = DateTime.now();
      await db.into(db.writingGoals).insert(WritingGoalsCompanion.insert(
        id: 'g1', worldId: 'test-world-1', type: 'daily',
        targetWordCount: 3000, startDate: now,
        isActive: true, createdAt: now, updatedAt: now,
      ));

      final row = await db.select(db.writingGoals).getSingle();
      expect(row.targetWordCount, 3000);
      expect(row.type, 'daily');
      expect(row.isActive, true);
    });
  });

  group('WritingGoalService', () {
    test('recordWriting creates or updates daily stat', () async {
      await service.recordWriting(
        worldId: 'test-world-1', wordCount: 1500, minutesSpent: 30,
      );

      final stats = await service.getTodayStats('test-world-1');
      expect(stats, isNotNull);
      expect(stats!.wordCount, 1500);
    });

    test('setGoal creates active goal', () async {
      await service.setGoal('test-world-1', 'daily', 3000);

      final goal = await service.getActiveGoal('test-world-1');
      expect(goal, isNotNull);
      expect(goal!.targetWordCount, 3000);
    });

    test('getGoalProgress returns progress for daily goal', () async {
      final now = DateTime.now();
      await db.into(db.writingGoals).insert(WritingGoalsCompanion.insert(
        id: 'g1', worldId: 'test-world-1', type: 'daily',
        targetWordCount: 3000, startDate: now,
        isActive: true, createdAt: now, updatedAt: now,
      ));
      await service.recordWriting(worldId: 'test-world-1', wordCount: 1500, minutesSpent: 30);

      final progress = await service.getGoalProgress('test-world-1');
      expect(progress, isNotNull);
      expect(progress!.targetWordCount, 3000);
      expect(progress.currentWordCount, 1500);
      expect(progress.percentage, 50.0);
    });

    test('getStreak returns consecutive writing days', () async {
      final today = DateTime.now();
      // Insert some recent records
      for (var i = 0; i < 5; i++) {
        final day = today.subtract(Duration(days: i));
        final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        await db.into(db.dailyWritingStats).insert(DailyWritingStatsCompanion.insert(
          id: '$dateStr-test-world-1', worldId: 'test-world-1', date: dateStr,
          wordCount: 1000, sessionCount: 1, aiCallCount: 0, minutesSpent: 10,
          createdAt: today, updatedAt: today,
        ));
      }

      final streak = await service.getStreak('test-world-1');
      expect(streak, greaterThanOrEqualTo(5));
    });
  });
}
