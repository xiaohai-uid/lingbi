/// StyleDetectionService — 文风检测服务
///
/// 分析文本写作风格，生成结构化 StyleProfile，支持风格漂移检测。
library;

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide isNull;
import '../core/database/database_manager.dart';
import '../data/database/world_database.dart';
import '../services/interfaces/i_style_detection_service.dart';
import '../services/document_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../utils/style_prompt_templates.dart';

const _uuid = Uuid();

/// 风格检测服务

class _AggregatedStyle {

  const _AggregatedStyle({
    required this.tone,
    required this.vocabularyLevel,
    required this.dialogueRatio,
    required this.sentenceComplexity,
    required this.pacing,
    required this.paragraphLength,
    required this.rhetoricalDevices,
    required this.keywords,
  });
  final String tone;
  final String vocabularyLevel;
  final double dialogueRatio;
  final double sentenceComplexity;
  final String pacing;
  final double paragraphLength;
  final String rhetoricalDevices;
  final String keywords;
}


class StyleDetectionService implements IStyleDetectionService {
  StyleDetectionService({
    required DatabaseManager databaseManager,
    required IAIService aiService,
    DocumentService? documentService,
  })  : _databaseManager = databaseManager,
        _aiService = aiService,
        _documentService = documentService;

  final DatabaseManager _databaseManager;
  final IAIService _aiService;
  final DocumentService? _documentService;

  Future<WorldDatabase> _db(String worldId) =>
      _databaseManager.getDatabase(worldId);

  /// 调用 LLM 并解析 JSON 响应
  Future<Map<String, dynamic>> _callLlm(String systemPrompt, String userMessage) async {
    final chunks = <String>[];
    await for (final chunk in _aiService.chat(
      message: userMessage,
      systemPrompt: systemPrompt,
    )) {
      chunks.add(chunk);
    }
    final response = chunks.join();
    return jsonDecode(response) as Map<String, dynamic>;
  }

  @override
  Future<StyleProfile> analyzeScene(String sceneId, String text, String worldId) async {
    final db = await _db(worldId);
    final json = await _callLlm(
      styleAnalysisPrompt(text),
      '请分析以下场景正文的风格：\n\n$text',
    );

    final now = DateTime.now();
    final id = _uuid.v4();
    await db.into(db.styleProfiles).insert(StyleProfilesCompanion.insert(
      id: id, worldId: worldId,
      sceneId: Value(sceneId),
      summary: json['summary'] as String? ?? '',
      tone: json['tone'] as String? ?? '',
      vocabularyLevel: json['vocabularyLevel'] as String? ?? '',
      dialogueRatio: (json['dialogueRatio'] as num?)?.toDouble() ?? 0.0,
      sentenceComplexity: (json['sentenceComplexity'] as num?)?.toDouble() ?? 0.0,
      pacing: json['pacing'] as String? ?? '',
      rhetoricalDevices: jsonEncode(json['rhetoricalDevices'] ?? []),
      paragraphLength: (json['paragraphLength'] as num?)?.toDouble() ?? 0.5,
      keywords: json['keywords'] as String? ?? '',
      rawAnalysis: jsonEncode(json),
      createdAt: now, updatedAt: now,
    ));

    return (await db.select(db.styleProfiles).get()).first;
  }

/// 聚合风格画像：分类取众数，数值取平均
  _AggregatedStyle _aggregateProfiles(List<StyleProfile> profiles) {
    final toneCount = <String, int>{};
    final vocabCount = <String, int>{};
    final pacingCount = <String, int>{};
    double avgDialogue = 0, avgComplexity = 0, avgParagraph = 0;

    for (final p in profiles) {
      toneCount[p.tone] = (toneCount[p.tone] ?? 0) + 1;
      vocabCount[p.vocabularyLevel] = (vocabCount[p.vocabularyLevel] ?? 0) + 1;
      pacingCount[p.pacing] = (pacingCount[p.pacing] ?? 0) + 1;
      avgDialogue += p.dialogueRatio;
      avgComplexity += p.sentenceComplexity;
      avgParagraph += p.paragraphLength;
    }

    if (profiles.isNotEmpty) {
      avgDialogue /= profiles.length;
      avgComplexity /= profiles.length;
      avgParagraph /= profiles.length;
    }

    String mostFrequent(Map<String, int> counts) {
      return counts.entries.fold('', (a, b) => b.value > (counts[a] ?? 0) ? b.key : a);
    }

    return _AggregatedStyle(
      tone: mostFrequent(toneCount),
      vocabularyLevel: mostFrequent(vocabCount),
      dialogueRatio: avgDialogue,
      sentenceComplexity: avgComplexity,
      pacing: mostFrequent(pacingCount),
      paragraphLength: avgParagraph,
      rhetoricalDevices: profiles.first.rhetoricalDevices,
      keywords: profiles.first.keywords,
    );
  }

  @override
  Future<StyleProfile> analyzeChapter(String chapterId, String worldId) async {
    final db = await _db(worldId);

    // 获取本章所有场景的风格画像
    final profiles = await (db.select(db.styleProfiles)
      ..where((t) => t.chapterId.equals(chapterId))).get();

    if (profiles.isEmpty) {
      throw StateError('No style profiles found for chapter $chapterId');
    }

    final agg = _aggregateProfiles(profiles);
    final now = DateTime.now();
    final id = _uuid.v4();
    await db.into(db.styleProfiles).insert(StyleProfilesCompanion.insert(
      id: id, worldId: worldId,
      chapterId: Value(chapterId),
      summary: 'Chapter aggregate: ${profiles.length} scenes',
      tone: agg.tone,
      vocabularyLevel: agg.vocabularyLevel,
      dialogueRatio: agg.dialogueRatio,
      sentenceComplexity: agg.sentenceComplexity,
      pacing: agg.pacing,
      rhetoricalDevices: agg.rhetoricalDevices,
      paragraphLength: agg.paragraphLength,
      keywords: agg.keywords,
      rawAnalysis: 'Aggregated from ${profiles.length} scene profiles',
      createdAt: now, updatedAt: now,
    ));

    return (db.select(db.styleProfiles)..where((t) => t.id.equals(id))).getSingle();
  }

  @override
  Future<StyleProfile> analyzeWork(String workId, String worldId) async {
    final db = await _db(worldId);

    // 获取作品下所有章的 style profiles（通过 workId 关联 chapter 的 profile）
    final vols = await (db.select(db.volumes)..where((t) => t.workId.equals(workId))).get();
    final profiles = <StyleProfile>[];
    for (final vol in vols) {
      final chs = await (db.select(db.chapters)..where((t) => t.volumeId.equals(vol.id))).get();
      for (final ch in chs) {
        final ps = await (db.select(db.styleProfiles)..where((t) => t.chapterId.equals(ch.id))).get();
        profiles.addAll(ps);
      }
    }

    if (profiles.isEmpty) {
      throw StateError('No style profiles found for work $workId');
    }

    final agg = _aggregateProfiles(profiles);
    final now = DateTime.now();
    final id = _uuid.v4();
    await db.into(db.styleProfiles).insert(StyleProfilesCompanion.insert(
      id: id, worldId: worldId,
      workId: Value(workId),
      summary: 'Work aggregate: ${profiles.length} scene profiles',
      tone: agg.tone,
      vocabularyLevel: agg.vocabularyLevel,
      dialogueRatio: agg.dialogueRatio,
      sentenceComplexity: agg.sentenceComplexity,
      pacing: agg.pacing,
      rhetoricalDevices: agg.rhetoricalDevices,
      paragraphLength: agg.paragraphLength,
      keywords: agg.keywords,
      rawAnalysis: 'Aggregated from ${profiles.length} scene profiles across work',
      createdAt: now, updatedAt: now,
    ));

    return (db.select(db.styleProfiles)..where((t) => t.id.equals(id))).getSingle();
  }

  @override
  Future<StyleDriftReport> detectDrift(String textA, String textB) async {
    final json = await _callLlm(
      styleDriftPrompt(textA, textB),
      '请比较以下两段文本的风格差异：',
    );

    return StyleDriftReport(
      driftScore: (json['driftScore'] as num?)?.toDouble() ?? 0.0,
      driftedDimensions: (json['driftedDimensions'] as List?)?.cast<String>() ?? [],
      details: json['details'] as String? ?? '',
      suggestions: json['suggestions'] as String? ?? '',
    );
  }

  @override
  Future<String> buildStyleContext(String worldId, {String? chapterId, String? workId}) async {
    final db = await _db(worldId);
    final parts = <String>[];

    if (chapterId != null) {
      final profiles = await (db.select(db.styleProfiles)
        ..where((t) => t.chapterId.equals(chapterId))).get();
      if (profiles.isNotEmpty) {
        final p = profiles.first;
        parts.add('【风格指南】');
        parts.add('语调：${p.tone}');
        parts.add('词汇层次：${p.vocabularyLevel}');
        parts.add('对话占比：${(p.dialogueRatio * 100).toStringAsFixed(0)}%');
        parts.add('句式复杂度：${p.sentenceComplexity.toStringAsFixed(1)}');
        parts.add('节奏：${p.pacing}');
      }
    }

    if (workId != null && parts.isEmpty) {
      final profiles = await (db.select(db.styleProfiles)
        ..where((t) => t.workId.equals(workId))).get();
      if (profiles.isNotEmpty) {
        final p = profiles.first;
        parts.add('【作品风格】');
        parts.add(p.summary);
      }
    }

    return parts.join('\n');
  }
}
