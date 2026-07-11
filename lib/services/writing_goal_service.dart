/// WritingGoalService — 写作目标/日历服务
///
/// 管理每日写作统计、目标设定、连续天数追踪。
library;

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import '../core/database/database_manager.dart';
import '../data/database/world_database.dart';

const _uuid = Uuid();

/// 目标进度
class GoalProgress {
  final String goalId;
  final String type;
  final int targetWordCount;
  final int currentWordCount;
  final double percentage;
  final int streak;

  const GoalProgress({
    required this.goalId,
    required this.type,
    required this.targetWordCount,
    required this.currentWordCount,
    required this.percentage,
    this.streak = 0,
  });
}

/// 写作目标服务
class WritingGoalService {
  WritingGoalService({
    required DatabaseManager databaseManager,
  }) : _databaseManager = databaseManager;

  final DatabaseManager _databaseManager;

  Future<WorldDatabase> _db(String worldId) =>
      _databaseManager.getDatabase(worldId);

  String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 记录今日写作
  Future<DailyWritingStat> recordWriting({
    required String worldId,
    required int wordCount,
    int minutesSpent = 0,
    int aiCallCount = 0,
  }) async {
    final db = await _db(worldId);
    final dateStr = _todayDateStr();
    final id = '$dateStr-$worldId';
    final now = DateTime.now();

    // Check if already exists
    final existing = await (db.select(db.dailyWritingStats)
      ..where((t) => t.id.equals(id))).get();

    if (existing.isNotEmpty) {
      // Update: accumulate
      final current = existing.first;
      await (db.update(db.dailyWritingStats)..where((t) => t.id.equals(id)))
          .write(DailyWritingStatsCompanion(
            wordCount: Value(current.wordCount + wordCount),
            sessionCount: Value(current.sessionCount + 1),
            aiCallCount: Value(current.aiCallCount + aiCallCount),
            minutesSpent: Value(current.minutesSpent + minutesSpent),
            updatedAt: Value(now),
          ));
      return current.copyWith(
        wordCount: current.wordCount + wordCount,
        sessionCount: current.sessionCount + 1,
        aiCallCount: current.aiCallCount + aiCallCount,
        minutesSpent: current.minutesSpent + minutesSpent,
        updatedAt: now,
      );
    } else {
      // Create new
      await db.into(db.dailyWritingStats).insert(DailyWritingStatsCompanion.insert(
        id: id, worldId: worldId, date: dateStr,
        wordCount: wordCount, sessionCount: 1,
        aiCallCount: aiCallCount, minutesSpent: minutesSpent,
        createdAt: now, updatedAt: now,
      ));
      return DailyWritingStat(
        id: id, worldId: worldId, date: dateStr,
        wordCount: wordCount, sessionCount: 1,
        aiCallCount: aiCallCount, minutesSpent: minutesSpent,
        createdAt: now, updatedAt: now,
      );
    }
  }

  /// 获取今日统计
  Future<DailyWritingStat?> getTodayStats(String worldId) async {
    final db = await _db(worldId);
    final dateStr = _todayDateStr();
    final id = '$dateStr-$worldId';
    final rows = await (db.select(db.dailyWritingStats)
      ..where((t) => t.id.equals(id))).get();
    return rows.isEmpty ? null : rows.first;
  }

  /// 获取某月统计
  Future<List<DailyWritingStat>> getMonthStats(
    String worldId, int year, int month,
  ) async {
    final db = await _db(worldId);
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return (db.select(db.dailyWritingStats)
      ..where((t) => t.date.like('$prefix%'))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).get();
  }

  /// 获取连续写作天数
  Future<int> getStreak(String worldId) async {
    final db = await _db(worldId);
    final all = await (db.select(db.dailyWritingStats)
      ..where((t) => t.worldId.equals(worldId))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).get();

    if (all.isEmpty) return 0;

    int streak = 1;
    for (var i = 0; i < all.length - 1; i++) {
      final current = DateTime.parse(all[i].date);
      final next = DateTime.parse(all[i + 1].date);
      final diff = current.difference(next).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 设置目标
  Future<void> setGoal(String worldId, String type, int targetWordCount) async {
    final db = await _db(worldId);
    final now = DateTime.now();
    final id = _uuid.v4();

    // Deactivate existing goals
    await (db.update(db.writingGoals)..where((t) => t.worldId.equals(worldId)))
        .write(WritingGoalsCompanion(isActive: Value(false)));

    // Create new goal
    await db.into(db.writingGoals).insert(WritingGoalsCompanion.insert(
      id: id, worldId: worldId, type: type,
      targetWordCount: targetWordCount, startDate: now,

      isActive: true, createdAt: now, updatedAt: now,
    ));
  }

  /// 获取当前活跃目标
  Future<WritingGoal?> getActiveGoal(String worldId) async {
    final db = await _db(worldId);
    final rows = await (db.select(db.writingGoals)
      ..where((t) => t.worldId.equals(worldId) & t.isActive.equals(true))
      ..limit(1)
    ).get();
    return rows.isEmpty ? null : rows.first;
  }

  /// 获取目标进度
  Future<GoalProgress?> getGoalProgress(String worldId) async {
    final goal = await getActiveGoal(worldId);
    if (goal == null) return null;

    final todayStats = await getTodayStats(worldId);
    final currentWordCount = todayStats?.wordCount ?? 0;
    final streak = await getStreak(worldId);

    return GoalProgress(
      goalId: goal.id,
      type: goal.type,
      targetWordCount: goal.targetWordCount,
      currentWordCount: currentWordCount,
      percentage: goal.targetWordCount > 0
          ? (currentWordCount / goal.targetWordCount) * 100
          : 0,
      streak: streak,
    );
  }
}
