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
import '../services/document_service.dart';
import '../core/models/document.dart';
import '../utils/memory_prompt_templates.dart';
import 'generation/context_builder.dart';
import 'embedding_service.dart';
import 'memory_storage_client.dart';

const _uuid = Uuid();

/// 写作记忆服务
class MemoryService implements IMemoryService {
  MemoryService({
    required DatabaseManager databaseManager,
    required AIService aiService,
    DocumentService? documentService,
    EmbeddingService? embeddingService,
    MemoryStorageClient? storageClient,
  })  : _databaseManager = databaseManager,
        _aiService = aiService,
        _documentService = documentService,
        _embeddingService = embeddingService,
        _storageClient = storageClient;

  final DatabaseManager _databaseManager;
  final AIService _aiService;
  final DocumentService? _documentService;
  final EmbeddingService? _embeddingService;
  final MemoryStorageClient? _storageClient;

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
    if (_documentService == null) {
      throw StateError('DocumentService required for summarization');
    }
    final doc = await _documentService!.getDocumentBySceneId(sceneId);
    if (doc == null) {
      throw StateError('No document found for scene $sceneId');
    }
    final text = await _documentService!.readContent(doc.filePath);
    if (text.isEmpty) {
      throw StateError('Empty content for scene $sceneId');
    }

    final prompt = sceneSummaryPrompt(text);
    final chunks = <String>[];
    await for (final chunk in _aiService.chat(
      message: '请分析并输出结构化JSON摘要: ' + text,
      systemPrompt: prompt,
    )) {
      chunks.add(chunk);
    }
    final response = chunks.join('');
    final json = jsonDecode(response) as Map<String, dynamic>;

    // 从 Document 关联的 Scene 获取 worldId
    String worldId = '';
    if (doc.currentSceneId != null && doc.currentSceneId!.isNotEmpty) {
      try {
        final db = await _databaseManager.getDatabase('default');
        final scenes = await (db.select(db.scenes)
          ..where((t) => t.id.equals(doc.currentSceneId!))).get();
        if (scenes.isNotEmpty) {
          final scene = scenes.first;
          // 通过 Scene -> Chapter -> Volume -> Work 获取 worldId
          final chapters = await (db.select(db.chapters)
            ..where((t) => t.id.equals(scene.chapterId))).get();
          if (chapters.isNotEmpty) {
            final volumes = await (db.select(db.volumes)
              ..where((t) => t.id.equals(chapters.first.volumeId))).get();
            if (volumes.isNotEmpty) {
              final works = await (db.select(db.works)
                ..where((t) => t.id.equals(volumes.first.workId))).get();
              if (works.isNotEmpty) {
                worldId = works.first.worldId;
              }
            }
          }
        }
      } catch (_) {
        // worldId 获取失败时使用空字符串，后续可修复
      }
    }

    final summary = createSceneSummary(
      sceneId: sceneId,
      chapterId: doc.currentSceneId ?? '',
      worldId: worldId,
      summary: json['summary'] as String? ?? '',
      keywords: (json['keywords'] as List?)?.join(',') ?? '',
      characters: jsonEncode(json['characters'] ?? []),
      location: json['location'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      inStoryDay: json['inStoryDay'] as String? ?? '',
      causeEvent: json['causeEvent'] as String? ?? '',
      effectEvent: json['effectEvent'] as String? ?? '',
      characterEmotions: jsonEncode(json['characterEmotions'] ?? {}),
      conflictType: json['conflictType'] as String? ?? '',
      suspenseTags: jsonEncode(json['suspenseTags'] ?? []),
      keyDialogues: jsonEncode(json['keyDialogues'] ?? []),
      signatureMoments: jsonEncode(json['signatureMoments'] ?? []),
      foreshadowingIds: jsonEncode(json['foreshadowingIds'] ?? []),
      wordCount: text.length,
      sceneOrder: 0,
    );
  }

  @override
  Future<ChapterSummary> summarizeChapter(String chapterId) async {
    // 从场景摘要聚合生成章级摘要
    // TODO: 需要 worldId 参数
    throw UnimplementedError('summarizeChapter requires worldId parameter');
  }

  @override
  Future<VolumeSummary> summarizeVolume(String volumeId) async {
    // 从章节摘要聚合生成卷级摘要
    // TODO: 需要 worldId 参数
    throw UnimplementedError('summarizeVolume requires worldId parameter');
  }

  // ═════════════════════════════════════
  // 上下文构建
  // ═════════════════════════════════════

  @override
  Future<String> buildMemoryContext({
    required String worldId,
    required String currentChapterId,
    String? currentSceneId,
    bool includeVolumeSummary = true,
    int previousChaptersLimit = 5,
    Set<String> excludeIds = const {},
  }) async {
    final db = await _db(worldId);

    var scenesQuery = (db.select(db.sceneSummaries)
      ..where((t) => t.chapterId.equals(currentChapterId))
      ..orderBy([(t) => OrderingTerm(expression: t.sceneOrder)]));
    final sceneSummaries = (await scenesQuery.get()).where((s) => !excludeIds.contains(s.id)).toList();

    var chaptersQuery = db.select(db.chapterSummaries);
    final allChapterSummaries = (await chaptersQuery.get()).where((c) => !excludeIds.contains(c.id)).toList();

    final result = MemoryContextBuilder.build(
      sceneSummaries: sceneSummaries,
      chapterSummaries: allChapterSummaries,
      volumeSummary: includeVolumeSummary ? null : null,
      previousChaptersLimit: previousChaptersLimit,
    );

    return result.text;
  }

  @override
  Future<MemoryContextPreview> getContextPreview({
    required String worldId,
    required String chapterId,
    String? sceneId,
  }) async {
    final context = await buildMemoryContext(
      worldId: worldId,
      currentChapterId: chapterId,
      currentSceneId: sceneId,
    );
    final db = await _db(worldId);

    final entries = <ContextEntry>[];

    final scenes = await (db.select(db.sceneSummaries)
      ..where((t) => t.chapterId.equals(chapterId))
      ..orderBy([(t) => OrderingTerm(expression: t.sceneOrder)])
    ).get();
    for (final s in scenes) {
      entries.add(ContextEntry(
        id: s.id, type: SummaryType.scene,
        label: '场景${s.sceneOrder}摘要', summary: s.summary,
        autoInjected: true,
      ));
    }

    final chapters = await db.select(db.chapterSummaries).get();
    for (final c in chapters) {
      entries.add(ContextEntry(
        id: c.id, type: SummaryType.chapter,
        label: '章摘要', summary: c.summary,
        autoInjected: true,
      ));
    }

    return MemoryContextPreview(entries: entries, assembledText: context);
  }

  @override
  Future<void> updateSummary(SummaryType type, String id, String newContent) async {
    throw UnimplementedError('use type-specific update methods');
  }

  @override
  Future<List<SummaryMeta>> getRecentMemories(String worldId, {int limit = 20}) async {
    final db = await _db(worldId);
    final result = <SummaryMeta>[];

    final scenes = await (db.select(db.sceneSummaries)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
      ..limit(limit)
    ).get();
    for (final s in scenes) {
      result.add(SummaryMeta(
        id: s.id, type: SummaryType.scene,
        parentId: s.sceneId, summary: s.summary,
        createdAt: s.createdAt, updatedAt: s.updatedAt,
      ));
    }

    return result;
  }

  @override
  Future<List<SummaryMeta>> searchMemories(String worldId, String keyword) async {
    final db = await _db(worldId);
    final result = <SummaryMeta>[];

    final scenes = await (db.select(db.sceneSummaries)
      ..where((t) => t.summary.like('%$keyword%') | t.keywords.like('%$keyword%'))
      ..limit(20)
    ).get();
    for (final s in scenes) {
      result.add(SummaryMeta(
        id: s.id, type: SummaryType.scene,
        parentId: s.sceneId, summary: s.summary,
        createdAt: s.createdAt, updatedAt: s.updatedAt,
      ));
    }

    return result;
  }

  // ═════════════════════════════════════
  // 语义搜索 (Phase 2)
  // ═════════════════════════════════════

  /// 语义搜索记忆 — 优先使用向量检索，降级到关键词搜索
  Future<List<SummaryMeta>> semanticSearchMemories(
    String worldId,
    String query, {
    int limit = 10,
  }) async {
    // 1. 尝试语义搜索
    if (_embeddingService != null && _storageClient != null) {
      try {
        final vector = await _embeddingService!.embed(query);
        final results = await _storageClient!.searchVectors(
          vector: vector,
          limit: limit,
        );

        return results.map((r) => SummaryMeta(
          id: r.id,
          type: SummaryType.scene,
          parentId: r.payload['sceneId'] as String? ?? '',
          summary: r.payload['summary'] as String? ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )).toList();
      } catch (_) {
        // 语义搜索失败，降级到关键词搜索
      }
    }

    // 2. 降级: 关键词搜索
    return searchMemories(worldId, query);
  }
}
