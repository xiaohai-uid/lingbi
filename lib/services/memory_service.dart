/// MemoryService — 写作记忆服务
///
/// 负责长文本自动摘要 + 上下文管理的完整实现。
/// Phase 1: Drift SQLite 存储，按章节位置 + 关键词匹配检索。
library;

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide isNull;
import '../core/database/database_manager.dart';
import '../data/database/world_database.dart';
import '../services/interfaces/i_memory_service.dart';
import '../services/ai_service.dart';
import '../utils/memory_prompt_templates.dart';
import 'generation/context_builder.dart';

const _uuid = Uuid();

/// 写作记忆服务
class MemoryService implements IMemoryService {
  MemoryService({
    required DatabaseManager databaseManager,
    required AIService aiService,
    DocumentService? documentService,
  })  : _databaseManager = databaseManager,
        _aiService = aiService,
        _documentService = documentService;

  final DatabaseManager _databaseManager;
  final AIService _aiService;
  final DocumentService? _documentService;

  Future<WorldDatabase> _db(String worldId) =>
      _databaseManager.getDatabase(worldId);

  // ═════════════════════════════════════
  // 场景摘要 CRUD
  // ═════════════════════════════════════

  Future<SceneSummary> createSceneSummary({
    required String sceneId,
    required String chapterId,
    required String worldId,
    required String summary,
    String keywords = '',
    String characters = '',
    String location = '',
    String mood = '',
    String inStoryDay = '',
    String causeEvent = '',
    String effectEvent = '',
    String characterEmotions = '',
    String conflictType = '',
    String suspenseTags = '',
    String keyDialogues = '',
    String signatureMoments = '',
    String foreshadowingIds = '',
    int wordCount = 0,
    int sceneOrder = 0,
  }) async {
    final db = await _db(worldId);
    final now = DateTime.now();
    final id = _uuid.v4();
    await db.into(db.sceneSummaries).insert(SceneSummariesCompanion.insert(
      id: id,
      sceneId: sceneId,
      chapterId: chapterId,
      worldId: worldId,
      summary: summary,
      keywords: keywords,
      characters: characters,
      location: location,
      mood: mood,
      inStoryDay: inStoryDay,
      causeEvent: causeEvent,
      effectEvent: effectEvent,
      characterEmotions: characterEmotions,
      conflictType: conflictType,
      suspenseTags: suspenseTags,
      keyDialogues: keyDialogues,
      signatureMoments: signatureMoments,
      foreshadowingIds: foreshadowingIds,
      wordCount: wordCount,
      sceneOrder: sceneOrder,
      createdAt: now,
      updatedAt: now,
    ));
    return SceneSummary(
      id: id,
      sceneId: sceneId,
      chapterId: chapterId,
      worldId: worldId,
      summary: summary,
      keywords: keywords,
      characters: characters,
      location: location,
      mood: mood,
      inStoryDay: inStoryDay,
      causeEvent: causeEvent,
      effectEvent: effectEvent,
      characterEmotions: characterEmotions,
      conflictType: conflictType,
      suspenseTags: suspenseTags,
      keyDialogues: keyDialogues,
      signatureMoments: signatureMoments,
      foreshadowingIds: foreshadowingIds,
      wordCount: wordCount,
      sceneOrder: sceneOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<SceneSummary?> getSceneSummary(String id, {required String worldId}) async {
    final db = await _db(worldId);
    final rows = await (db.select(db.sceneSummaries)
      ..where((t) => t.id.equals(id))).get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<SceneSummary>> getSceneSummariesByChapter(String chapterId, {required String worldId}) async {
    final db = await _db(worldId);
    return (db.select(db.sceneSummaries)
      ..where((t) => t.chapterId.equals(chapterId))
      ..orderBy([(t) => OrderingTerm(expression: t.sceneOrder)])
    ).get();
  }

  Future<void> updateSceneSummary(String id, {required String worldId, String? summary, int? wordCount}) async {
    final db = await _db(worldId);
    await (db.update(db.sceneSummaries)..where((t) => t.id.equals(id)))
        .write(SceneSummariesCompanion(
          summary: summary != null ? Value(summary) : const Value.absent(),
          wordCount: wordCount != null ? Value(wordCount) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> deleteSceneSummary(String id, {required String worldId}) async {
    final db = await _db(worldId);
    await (db.delete(db.sceneSummaries)..where((t) => t.id.equals(id))).go();
  }

  // ═════════════════════════════════════
  // 章节摘要 CRUD
  // ═════════════════════════════════════

  Future<ChapterSummary> createChapterSummary({
    required String chapterId,
    required String volumeId,
    required String worldId,
    required String summary,
    String hook = '',
    String majorEvents = '',
    String characterArcs = '',
    String conflictResolution = '',
    String emotionalClimax = '',
    String unansweredQuestions = '',
    int sceneCount = 0,
  }) async {
    final db = await _db(worldId);
    final now = DateTime.now();
    final id = _uuid.v4();
    await db.into(db.chapterSummaries).insert(ChapterSummariesCompanion.insert(
      id: id, chapterId: chapterId, volumeId: volumeId, worldId: worldId,
      summary: summary, hook: hook, majorEvents: majorEvents,
      characterArcs: characterArcs, conflictResolution: conflictResolution,
      emotionalClimax: emotionalClimax, unansweredQuestions: unansweredQuestions,
      sceneCount: sceneCount, createdAt: now, updatedAt: now,
    ));
    return ChapterSummary(
      id: id, chapterId: chapterId, volumeId: volumeId, worldId: worldId,
      summary: summary, hook: hook, majorEvents: majorEvents,
      characterArcs: characterArcs, conflictResolution: conflictResolution,
      emotionalClimax: emotionalClimax, unansweredQuestions: unansweredQuestions,
      sceneCount: sceneCount, createdAt: now, updatedAt: now,
    );
  }

  Future<ChapterSummary?> getChapterSummary(String id, {required String worldId}) async {
    final db = await _db(worldId);
    final rows = await (db.select(db.chapterSummaries)
      ..where((t) => t.id.equals(id))).get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<ChapterSummary>> getChapterSummariesByVolume(String volumeId, {required String worldId}) async {
    final db = await _db(worldId);
    return (db.select(db.chapterSummaries)
      ..where((t) => t.volumeId.equals(volumeId))).get();
  }

  // ═════════════════════════════════════
  // 卷摘要 CRUD
  // ═════════════════════════════════════

  Future<VolumeSummary> createVolumeSummary({
    required String volumeId,
    required String worldId,
    required String summary,
    String status = 'writing',
    String mainCharacters = '',
    String storyArc = '',
    String majorPlotPoints = '',
    String unresolvedThreads = '',
    int chapterCount = 0,
  }) async {
    final db = await _db(worldId);
    final now = DateTime.now();
    final id = _uuid.v4();
    await db.into(db.volumeSummaries).insert(VolumeSummariesCompanion.insert(
      id: id, volumeId: volumeId, worldId: worldId, summary: summary,
      status: status, mainCharacters: mainCharacters, storyArc: storyArc,
      majorPlotPoints: majorPlotPoints, unresolvedThreads: unresolvedThreads,
      chapterCount: chapterCount, createdAt: now, updatedAt: now,
    ));
    return VolumeSummary(
      id: id, volumeId: volumeId, worldId: worldId, summary: summary,
      status: status, mainCharacters: mainCharacters, storyArc: storyArc,
      majorPlotPoints: majorPlotPoints, unresolvedThreads: unresolvedThreads,
      chapterCount: chapterCount, createdAt: now, updatedAt: now,
    );
  }

  Future<VolumeSummary?> getVolumeSummary(String id, {required String worldId}) async {
    final db = await _db(worldId);
    final rows = await (db.select(db.volumeSummaries)
      ..where((t) => t.id.equals(id))).get();
    return rows.isEmpty ? null : rows.first;
  }

  // ═════════════════════════════════════
  // 摘要生成 (LLM 调用)
  // ═════════════════════════════════════

  @override
  Future<SceneSummary> summarizeScene(String sceneId) async {
    // TODO: Phase 1 — 实现 LLM 摘要生成
    // 1. 通过 world_service 获取场景正文
    // 2. 调用 _aiService.generateText() 传入 sceneSummaryPrompt
    // 3. 
