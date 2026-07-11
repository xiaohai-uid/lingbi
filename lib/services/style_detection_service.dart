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
    final response = chunks.join('');
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

  @override
  Future<StyleProfile> analyzeChapter(String chapterId, String worldId) async {
    throw UnimplementedError('analyzeChapter: aggregate scene styles');
  }

  @override
  Future<StyleProfile> analyzeWork(String workId, String worldId) async {
    throw UnimplementedError('analyzeWork: aggregate chapter/volume styles');
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
        parts.add('${p.summary}');
      }
    }

    return parts.join('\n');
  }
}
