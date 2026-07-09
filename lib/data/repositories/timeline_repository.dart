/// 时间线仓库 — 事件/分支/蝴蝶效应 相关查询
library timeline_repository;

import 'package:drift/drift.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/core/database/database_manager.dart';

/// 时间线查询仓库
class TimelineRepository {
  TimelineRepository(this.databaseManager);
  final DatabaseManager databaseManager;

  /// 获取指定世界的数据库
  Future<WorldDatabase> _db(String worldId) async =>
      databaseManager.getDatabase(worldId);

  /// 获取某世界的所有时间线事件（按 orderKey 排序）
  Future<List<TimelineEvent>> getEvents(String worldId,
      {String? branchId}) async {
    final db = await _db(worldId);
    final query = db.select(db.timelineEvents)
      ..where((t) => t.worldId.equals(worldId))
      ..orderBy([(t) => OrderingTerm(expression: t.orderKey)]);

    if (branchId != null) {
      query.where((t) => t.branchId.equals(branchId));
    }

    return query.get();
  }

  /// 插入事件到两个现有事件之间（分数索引）
  Future<String> insertBetween({
    required String worldId,
    required String title,
    required String description,
    String? beforeOrderKey,
    String? afterOrderKey,
  }) async {
    final db = await _db(worldId);
    final newOrderKey = _midpoint(beforeOrderKey ?? 'a', afterOrderKey ?? 'z');
    final id = _uuid();

    await db.into(db.timelineEvents).insert(TimelineEventsCompanion.insert(
          id: id,
          worldId: worldId,
          title: title,
          description: description,
          orderKey: newOrderKey,
          branchId: '',
          chapterAnchor: '',
          duration: '',
          inStoryDate: '',
          inStoryDay: 0,
          parentEventId: '',
          createdAt: DateTime.now(),
        ));

    return id;
  }

  /// 计算两个分数索引的中点
  ///
  /// 实现：高效分数索引算法（类似 fractional-indexing）
  /// 输入 a < b 的字符串，输出 a < result < b 的字符串。
  /// 使用 base-64 字符集，保证字典序。
  static const _chars =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  String _midpoint(String a, String b) {
    if (a.isEmpty) a = 'a';
    if (b.isEmpty) b = 'z';
    if (a.compareTo(b) >= 0) {
      return '$a${_chars[0]}';
    }

    final result = StringBuffer();
    int i = 0;

    while (true) {
      final ac = i < a.length ? a.codeUnitAt(i) : -1;
      final bc = i < b.length ? b.codeUnitAt(i) : -1;

      if (ac == bc) {
        result.writeCharCode(ac);
        i++;
        continue;
      }

      if (ac < 0) {
        result.writeCharCode(bc);
        final last = result.toString();
        final mid = ((_chars.length - 1) / 2).floor();
        return '${last.substring(0, last.length - 1)}${_chars[mid]}';
      }

      if (bc < 0) {
        return '$a${_chars[0]}';
      }

      final mid = ((ac + bc) / 2).floor();
      if (mid == ac) {
        result.writeCharCode(ac);
        result.writeCharCode(((bc - ac) / 2).floor() + 1);
      } else {
        result.writeCharCode(mid);
      }
      return result.toString();
    }
  }

  /// 获取最近 N 个事件
  Future<List<TimelineEvent>> getRecentEvents(String worldId,
      {int limit = 5}) async {
    final db = await _db(worldId);
    return (db.select(db.timelineEvents)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.orderKey, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  /// 创建分支
  Future<String> createBranch(
      String worldId, String eventId, String branchName) async {
    final db = await _db(worldId);
    final event = await (db.select(db.timelineEvents)
          ..where((t) => t.id.equals(eventId)))
        .getSingleOrNull();
    if (event == null) throw Exception('Event not found: $eventId');

    final branchId = _uuid();
    final newId = _uuid();
    await db.into(db.timelineEvents).insert(TimelineEventsCompanion.insert(
          id: newId,
          worldId: worldId,
          title: '[$branchName] ${event.title}',
          description: event.description,
          orderKey: event.orderKey,
          branchId: branchId,
          chapterAnchor: '',
          duration: '',
          inStoryDate: '',
          inStoryDay: 0,
          parentEventId: eventId,
          createdAt: DateTime.now(),
        ));

    return branchId;
  }

  /// 保存蝴蝶效应分析结果
  Future<void> saveButterflyAnalysis({
    required String worldId,
    required String eventId,
    required int tokenCost,
    required double estimatedCost,
    required List<CharacterImpactData> impacts,
  }) async {
    final db = await _db(worldId);
    final analysisText = impacts
        .map((i) =>
            '${i.characterId}: ${i.weightDelta > 0 ? '+' : ''}${i.weightDelta} (${i.reason})')
        .join('\n');
    final predictedDirection =
        impacts.isNotEmpty ? impacts.map((i) => i.reason).join('；') : '无明显影响';

    await db
        .into(db.butterflyAnalyses)
        .insert(ButterflyAnalysesCompanion.insert(
          id: 'ba-${DateTime.now().microsecondsSinceEpoch}',
          worldId: worldId,
          eventId: eventId,
          analysisText: analysisText,
          predictedDirection: predictedDirection,
          tokenCost: tokenCost,
          estimatedCost: estimatedCost,
          createdAt: DateTime.now(),
        ));
  }

  String _uuid() => 'tl-${DateTime.now().microsecondsSinceEpoch}';
}

/// 蝴蝶效应影响数据
class CharacterImpactData {
  const CharacterImpactData({
    required this.characterId,
    required this.weightDelta,
    required this.reason,
  });
  final String characterId;
  final int weightDelta;
  final String reason;
}
