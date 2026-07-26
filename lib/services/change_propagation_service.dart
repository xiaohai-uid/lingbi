/// 变更传播服务
///
/// 修改设定后自动识别受影响章节：
/// - 设定变更时触发影响分析
/// - 通过 RAG 语义检索定位引用了该设定的段落
/// - 受影响章节列表 + 具体影响位置
/// - 逐章修复建议（AI 生成修改方案）
/// - 批量修复（确认后一键应用）
library;

import 'dart:convert';

import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/services/vector_knowledge_service.dart';

// ─── 数据模型 ───

/// 影响位置
class ImpactLocation {
  const ImpactLocation({
    required this.chapterId,
    required this.paragraphIndex,
    this.excerpt = '',
    this.relevanceScore = 0,
  });

  factory ImpactLocation.fromJson(Map<String, dynamic> json) {
    return ImpactLocation(
      chapterId: json['chapter_id'] as String? ?? '',
      paragraphIndex: json['paragraph_index'] as int? ?? 0,
      excerpt: json['excerpt'] as String? ?? '',
      relevanceScore:
          (json['relevance_score'] as num?)?.toDouble() ?? 0,
    );
  }

  final String chapterId;
  final int paragraphIndex;
  final String excerpt;
  final double relevanceScore;

  Map<String, dynamic> toJson() => {
        'chapter_id': chapterId,
        'paragraph_index': paragraphIndex,
        'excerpt': excerpt,
        'relevance_score': relevanceScore,
      };
}

/// 变更影响报告
class ChangeImpactReport {
  ChangeImpactReport({
    required this.settingId,
    required this.settingName,
    required this.changeDescription,
    this.affectedLocations = const [],
    this.affectedChapterIds = const [],
    this.totalAffected = 0,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  factory ChangeImpactReport.fromJson(Map<String, dynamic> json) {
    return ChangeImpactReport(
      settingId: json['setting_id'] as String? ?? '',
      settingName: json['setting_name'] as String? ?? '',
      changeDescription: json['change_description'] as String? ?? '',
      affectedLocations: (json['affected_locations'] as List?)
              ?.map(
                  (e) => ImpactLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      affectedChapterIds:
          (json['affected_chapter_ids'] as List?)?.cast<String>() ?? [],
      totalAffected: json['total_affected'] as int? ?? 0,
      analyzedAt: DateTime.tryParse(json['analyzed_at'] as String? ?? ''),
    );
  }

  final String settingId;
  final String settingName;
  final String changeDescription;
  final List<ImpactLocation> affectedLocations;
  final List<String> affectedChapterIds;
  final int totalAffected;
  final DateTime analyzedAt;

  Map<String, dynamic> toJson() => {
        'setting_id': settingId,
        'setting_name': settingName,
        'change_description': changeDescription,
        'affected_locations':
            affectedLocations.map((e) => e.toJson()).toList(),
        'affected_chapter_ids': affectedChapterIds,
        'total_affected': totalAffected,
        'analyzed_at': analyzedAt.toIso8601String(),
      };
}

/// 修复建议
class FixSuggestion {
  const FixSuggestion({
    required this.chapterId,
    required this.paragraphIndex,
    required this.originalText,
    required this.suggestedText,
    this.reason = '',
    this.applied = false,
  });

  factory FixSuggestion.fromJson(Map<String, dynamic> json) {
    return FixSuggestion(
      chapterId: json['chapter_id'] as String? ?? '',
      paragraphIndex: json['paragraph_index'] as int? ?? 0,
      originalText: json['original_text'] as String? ?? '',
      suggestedText: json['suggested_text'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      applied: json['applied'] as bool? ?? false,
    );
  }

  final String chapterId;
  final int paragraphIndex;
  final String originalText;
  final String suggestedText;
  final String reason;
  final bool applied;

  FixSuggestion copyWith({bool? applied}) {
    return FixSuggestion(
      chapterId: chapterId,
      paragraphIndex: paragraphIndex,
      originalText: originalText,
      suggestedText: suggestedText,
      reason: reason,
      applied: applied ?? this.applied,
    );
  }

  Map<String, dynamic> toJson() => {
        'chapter_id': chapterId,
        'paragraph_index': paragraphIndex,
        'original_text': originalText,
        'suggested_text': suggestedText,
        'reason': reason,
        'applied': applied,
      };
}

// ─── 服务 ───

/// 变更传播服务
class ChangePropagationService {
  ChangePropagationService({
    required VectorKnowledgeService vectorKnowledgeService,
    required AIProvider aiProvider,
  })  : _vectorService = vectorKnowledgeService,
        _aiProvider = aiProvider;

  final VectorKnowledgeService _vectorService;
  final AIProvider _aiProvider;

  // ─── 1. 影响分析 ───

  /// 分析设定变更的影响范围
  ///
  /// 通过 RAG 语义检索找到引用了该设定的章节/段落。
  Future<ChangeImpactReport> analyzeImpact({
    required String projectId,
    required String settingId,
    required String settingName,
    required String changeDescription,
  }) async {
    // 用设定名称+变更描述作为查询
    final query = '$settingName $changeDescription';
    final results = await _vectorService.search(
      projectId,
      query,
      k: 20,
      threshold: 0.2,
    );

    final locations = <ImpactLocation>[];
    final chapterIds = <String>{};

    for (final r in results) {
      final chapterId = r.entry.metadata['chapter_id'] as String? ??
          r.entry.id;
      final paragraphIdx =
          r.entry.metadata['paragraph_index'] as int? ?? 0;

      locations.add(ImpactLocation(
        chapterId: chapterId,
        paragraphIndex: paragraphIdx,
        excerpt: r.entry.content.length > 200
            ? '${r.entry.content.substring(0, 200)}…'
            : r.entry.content,
        relevanceScore: r.score,
      ));
      chapterIds.add(chapterId);
    }

    return ChangeImpactReport(
      settingId: settingId,
      settingName: settingName,
      changeDescription: changeDescription,
      affectedLocations: locations,
      affectedChapterIds: chapterIds.toList(),
      totalAffected: chapterIds.length,
    );
  }

  // ─── 2. 修复建议 ───

  /// 为受影响章节生成修复建议
  Future<List<FixSuggestion>> generateFixSuggestions({
    required ChangeImpactReport report,
    required Map<String, String> chapterContents,
  }) async {
    final suggestions = <FixSuggestion>[];

    for (final chapterId in report.affectedChapterIds) {
      final content = chapterContents[chapterId];
      if (content == null || content.isEmpty) continue;

      try {
        final fix = await _generateChapterFix(
          settingName: report.settingName,
          changeDescription: report.changeDescription,
          chapterContent: content,
          chapterId: chapterId,
        );
        suggestions.addAll(fix);
      } catch (_) {
        // 单章失败不阻断
      }
    }

    return suggestions;
  }

  // ─── 3. 批量修复 ───

  /// 应用修复建议（返回修改后的章节内容映射）
  ///
  /// [persist] 为可注入的文件写入函数（便于测试）。
  Future<Map<String, String>> applyFixes({
    required List<FixSuggestion> suggestions,
    required Map<String, String> chapterContents,
    Future<void> Function(String chapterId, String newContent)? persist,
  }) async {
    final updatedContents = Map<String, String>.from(chapterContents);

    for (final fix in suggestions) {
      if (!fix.applied) continue;
      final content = updatedContents[fix.chapterId];
      if (content == null) continue;

      // 替换原文
      if (fix.originalText.isNotEmpty &&
          content.contains(fix.originalText)) {
        updatedContents[fix.chapterId] =
            content.replaceFirst(fix.originalText, fix.suggestedText);
      }
    }

    // 持久化
    if (persist != null) {
      for (final entry in updatedContents.entries) {
        if (chapterContents[entry.key] != entry.value) {
          await persist(entry.key, entry.value);
        }
      }
    }

    return updatedContents;
  }

  // ─── 辅助方法 ───

  Future<List<FixSuggestion>> _generateChapterFix({
    required String settingName,
    required String changeDescription,
    required String chapterContent,
    required String chapterId,
  }) async {
    final truncated = chapterContent.length > 4000
        ? chapterContent.substring(0, 4000)
        : chapterContent;

    final result = await _aiProvider.chatSync(
      messages: [
        const ChatMessage(
            role: 'system',
            content: '你是小说修订专家。根据设定变更找出需要修改的段落并给出修改建议。'),
        ChatMessage(
            role: 'user',
            content: '''
设定变更：「$settingName」— $changeDescription

请找出以下章节中需要相应修改的内容，以 JSON 数组格式输出：
[{"paragraph_index": 0, "original_text": "原文片段", "suggested_text": "修改后", "reason": "原因"}]

如果没有需要修改的内容，输出空数组 []。

章节内容：
$truncated'''),
      ],
    );

    return _parseFixSuggestions(result, chapterId);
  }

  List<FixSuggestion> _parseFixSuggestions(
      String response, String chapterId) {
    final suggestions = <FixSuggestion>[];
    try {
      final start = response.indexOf('[');
      final end = response.lastIndexOf(']');
      if (start < 0 || end <= start) return [];

      final jsonStr = response.substring(start, end + 1);
      final list = jsonDecode(jsonStr) as List;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          suggestions.add(FixSuggestion(
            chapterId: chapterId,
            paragraphIndex: item['paragraph_index'] as int? ?? 0,
            originalText: item['original_text'] as String? ?? '',
            suggestedText: item['suggested_text'] as String? ?? '',
            reason: item['reason'] as String? ?? '',
          ));
        }
      }
    } catch (_) {}
    return suggestions;
  }
}
