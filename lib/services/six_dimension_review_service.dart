/// 六维审稿服务
///
/// 生成后从六个维度自动审稿：
/// - 爽点（Satisfaction）
/// - 一致性（Consistency）
/// - 节奏（Pacing）
/// - OOC（Out of Character）
/// - 连续性（Continuity）
/// - 追读力（Readability）
///
/// 结果以评分 + 具体问题列表呈现，低分可触发 AI 修复建议。
library;

import 'dart:convert';

import 'package:lingbi/core/ai/ai_provider.dart';

// ─── 数据模型 ───

/// 审稿维度
enum ReviewDimension {
  satisfaction,
  consistency,
  pacing,
  ooc,
  continuity,
  readability;

  String get label => switch (this) {
        ReviewDimension.satisfaction => '爽点',
        ReviewDimension.consistency => '一致性',
        ReviewDimension.pacing => '节奏',
        ReviewDimension.ooc => 'OOC',
        ReviewDimension.continuity => '连续性',
        ReviewDimension.readability => '追读力',
      };

  static ReviewDimension fromString(String s) {
    return ReviewDimension.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ReviewDimension.readability,
    );
  }
}

/// 单条审稿问题
class ReviewIssue {
  const ReviewIssue({
    required this.dimension,
    required this.description,
    this.paragraphIndex = -1,
    this.severity = 'medium',
    this.suggestion = '',
  });

  factory ReviewIssue.fromJson(Map<String, dynamic> json) {
    return ReviewIssue(
      dimension: ReviewDimension.fromString(
          json['dimension'] as String? ?? 'readability'),
      description: json['description'] as String? ?? '',
      paragraphIndex: json['paragraph_index'] as int? ?? -1,
      severity: json['severity'] as String? ?? 'medium',
      suggestion: json['suggestion'] as String? ?? '',
    );
  }

  final ReviewDimension dimension;
  final String description;

  /// 问题所在段落索引（-1 表示全局）
  final int paragraphIndex;

  /// 严重程度：low / medium / high
  final String severity;

  /// 修复建议
  final String suggestion;

  Map<String, dynamic> toJson() => {
        'dimension': dimension.name,
        'description': description,
        'paragraph_index': paragraphIndex,
        'severity': severity,
        'suggestion': suggestion,
      };
}

/// 单维度评分结果
class DimensionScore {
  const DimensionScore({
    required this.dimension,
    required this.score,
    this.issues = const [],
    this.comment = '',
  });

  factory DimensionScore.fromJson(Map<String, dynamic> json) {
    return DimensionScore(
      dimension: ReviewDimension.fromString(
          json['dimension'] as String? ?? 'readability'),
      score: json['score'] as int? ?? 5,
      issues: (json['issues'] as List?)
              ?.map((e) => ReviewIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comment: json['comment'] as String? ?? '',
    );
  }

  final ReviewDimension dimension;

  /// 1-10 分
  final int score;
  final List<ReviewIssue> issues;
  final String comment;

  bool get isLow => score <= 5;

  Map<String, dynamic> toJson() => {
        'dimension': dimension.name,
        'score': score,
        'issues': issues.map((e) => e.toJson()).toList(),
        'comment': comment,
      };
}

/// 六维审稿报告
class ReviewReport {
  ReviewReport({
    required this.chapterId,
    required this.scores,
    this.overallScore = 0,
    this.summary = '',
    this.fixSuggestions = const [],
    DateTime? reviewedAt,
  }) : reviewedAt = reviewedAt ?? DateTime.now();

  factory ReviewReport.fromJson(Map<String, dynamic> json) {
    return ReviewReport(
      chapterId: json['chapter_id'] as String? ?? '',
      scores: (json['scores'] as List?)
              ?.map(
                  (e) => DimensionScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallScore: json['overall_score'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      fixSuggestions:
          (json['fix_suggestions'] as List?)?.cast<String>() ?? [],
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
    );
  }

  final String chapterId;
  final List<DimensionScore> scores;
  final int overallScore;
  final String summary;
  final List<String> fixSuggestions;
  final DateTime reviewedAt;

  /// 获取指定维度评分
  DimensionScore? getScore(ReviewDimension dim) {
    try {
      return scores.firstWhere((s) => s.dimension == dim);
    } catch (_) {
      return null;
    }
  }

  /// 获取低分维度（<=5）
  List<DimensionScore> get lowScoreDimensions =>
      scores.where((s) => s.isLow).toList();

  /// 获取所有问题
  List<ReviewIssue> get allIssues =>
      scores.expand((s) => s.issues).toList();

  Map<String, dynamic> toJson() => {
        'chapter_id': chapterId,
        'scores': scores.map((s) => s.toJson()).toList(),
        'overall_score': overallScore,
        'summary': summary,
        'fix_suggestions': fixSuggestions,
        'reviewed_at': reviewedAt.toIso8601String(),
      };
}

// ─── 服务 ───

/// 六维审稿服务
class SixDimensionReviewService {
  SixDimensionReviewService({
    required AIProvider aiProvider,
    this.autoReview = true,
    this.lowScoreThreshold = 5,
  }) : _aiProvider = aiProvider;

  final AIProvider _aiProvider;

  /// 是否生成后自动审稿
  final bool autoReview;

  /// 低分阈值（触发修复建议）
  final int lowScoreThreshold;

  // ─── 1. 执行审稿 ───

  /// 对章节内容执行六维审稿
  Future<ReviewReport> review({
    required String chapterId,
    required String content,
    String context = '',
  }) async {
    final prompt = _buildReviewPrompt(content, context);

    final result = await _aiProvider.chatSync(
      messages: [
        const ChatMessage(
            role: 'system',
            content: '你是网文质量审稿专家。严格按 JSON 格式输出六维评分。'),
        ChatMessage(role: 'user', content: prompt),
      ],
    );

    final jsonStr = _extractJson(result);
    if (jsonStr != null) {
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return _parseReport(chapterId, data);
      } catch (_) {}
    }

    // 解析失败返回默认中等评分
    return _defaultReport(chapterId);
  }

  // ─── 2. 修复建议 ───

  /// 为低分维度生成修复建议
  Future<List<String>> generateFixSuggestions(
    String content,
    ReviewReport report,
  ) async {
    final lowDims = report.lowScoreDimensions;
    if (lowDims.isEmpty) return [];

    final dimText = lowDims
        .map((d) =>
            '${d.dimension.label}(${d.score}分): ${d.issues.map((i) => i.description).join("; ")}')
        .join('\n');

    try {
      final result = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
              role: 'system', content: '你是网文修改顾问，输出具体可操作的修改建议。'),
          ChatMessage(
              role: 'user',
              content: '以下章节在六维审稿中得分较低，请给出具体修改建议：\n\n'
                  '低分维度：\n$dimText\n\n'
                  '章节内容（前2000字）：\n${content.length > 2000 ? content.substring(0, 2000) : content}'),
        ],
      );
      return result
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .take(5)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── 辅助方法 ───

  String _buildReviewPrompt(String content, String context) {
    final truncated =
        content.length > 6000 ? content.substring(0, 6000) : content;
    return '''
请对以下章节进行六维审稿，以 JSON 格式输出：

{
  "scores": [
    {"dimension": "satisfaction", "score": 8, "comment": "评价", "issues": [{"description": "问题", "paragraph_index": 2, "severity": "medium"}]},
    {"dimension": "consistency", "score": 7, "comment": "", "issues": []},
    {"dimension": "pacing", "score": 6, "comment": "", "issues": []},
    {"dimension": "ooc", "score": 9, "comment": "", "issues": []},
    {"dimension": "continuity", "score": 7, "comment": "", "issues": []},
    {"dimension": "readability", "score": 8, "comment": "", "issues": []}
  ],
  "overall_score": 7,
  "summary": "总体评价（50字以内）"
}

六维说明：
- satisfaction（爽点）：是否有让读者兴奋/满足的情节
- consistency（一致性）：设定/人物/逻辑是否自洽
- pacing（节奏）：快慢是否得当，有无拖沓或仓促
- ooc（OOC）：角色言行是否符合人设
- continuity（连续性）：与前后文是否衔接
- readability（追读力）：是否让读者想继续看下去

${context.isNotEmpty ? '上下文参考：\n$context\n' : ''}
章节内容：
$truncated''';
  }

  ReviewReport _parseReport(String chapterId, Map<String, dynamic> data) {
    final scoresList = (data['scores'] as List? ?? [])
        .map((e) => DimensionScore.fromJson(e as Map<String, dynamic>))
        .toList();

    // 确保六个维度都有
    for (final dim in ReviewDimension.values) {
      if (!scoresList.any((s) => s.dimension == dim)) {
        scoresList.add(DimensionScore(dimension: dim, score: 5));
      }
    }

    final overall = data['overall_score'] as int? ??
        (scoresList.isNotEmpty
            ? (scoresList.map((s) => s.score).reduce((a, b) => a + b) /
                    scoresList.length)
                .round()
            : 5);

    return ReviewReport(
      chapterId: chapterId,
      scores: scoresList,
      overallScore: overall,
      summary: data['summary'] as String? ?? '',
    );
  }

  ReviewReport _defaultReport(String chapterId) {
    return ReviewReport(
      chapterId: chapterId,
      scores: ReviewDimension.values
          .map((d) => DimensionScore(dimension: d, score: 5, comment: '解析失败'))
          .toList(),
      overallScore: 5,
      summary: '审稿解析失败，默认中等评分',
    );
  }

  String? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }
}
