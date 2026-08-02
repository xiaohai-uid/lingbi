/// 六维审稿 — 单元测试
///
/// 覆盖：评分/问题定位/修复建议
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/review/data/six_dimension_review_service.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

// ─── Mock ───

class MockAIProvider implements AIProvider {
  String mockResponse = '{}';

  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      mockResponse;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield mockResponse;
  }

  @override
  Future<List<double>> embed(String text) async => [];
  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ReviewDimension', () {
    test('label 中文标签', () {
      expect(ReviewDimension.satisfaction.label, '爽点');
      expect(ReviewDimension.consistency.label, '一致性');
      expect(ReviewDimension.pacing.label, '节奏');
      expect(ReviewDimension.ooc.label, 'OOC');
      expect(ReviewDimension.continuity.label, '连续性');
      expect(ReviewDimension.readability.label, '追读力');
    });
  });

  group('DimensionScore', () {
    test('fromJson / toJson 往返', () {
      const score = DimensionScore(
        dimension: ReviewDimension.pacing,
        score: 4,
        comment: '节奏偏慢',
        issues: [
          ReviewIssue(
            dimension: ReviewDimension.pacing,
            description: '第3段描写过于冗长',
            paragraphIndex: 3,
            severity: 'high',
          ),
        ],
      );

      final json = score.toJson();
      final restored = DimensionScore.fromJson(json);

      expect(restored.dimension, ReviewDimension.pacing);
      expect(restored.score, 4);
      expect(restored.isLow, isTrue);
      expect(restored.issues.length, 1);
      expect(restored.issues[0].paragraphIndex, 3);
    });

    test('isLow 判断', () {
      const low = DimensionScore(
          dimension: ReviewDimension.ooc, score: 5);
      expect(low.isLow, isTrue);

      const high = DimensionScore(
          dimension: ReviewDimension.ooc, score: 6);
      expect(high.isLow, isFalse);
    });
  });

  group('ReviewReport', () {
    test('lowScoreDimensions 筛选', () {
      final report = ReviewReport(
        chapterId: 'ch1',
        scores: const [
          DimensionScore(dimension: ReviewDimension.satisfaction, score: 8),
          DimensionScore(dimension: ReviewDimension.consistency, score: 4),
          DimensionScore(dimension: ReviewDimension.pacing, score: 3),
          DimensionScore(dimension: ReviewDimension.ooc, score: 9),
          DimensionScore(dimension: ReviewDimension.continuity, score: 7),
          DimensionScore(dimension: ReviewDimension.readability, score: 6),
        ],
        overallScore: 6,
      );

      expect(report.lowScoreDimensions.length, 2);
      expect(report.lowScoreDimensions[0].dimension,
          ReviewDimension.consistency);
    });

    test('allIssues 汇总', () {
      final report = ReviewReport(
        chapterId: 'ch1',
        scores: const [
          DimensionScore(
            dimension: ReviewDimension.satisfaction,
            score: 5,
            issues: [
              ReviewIssue(
                  dimension: ReviewDimension.satisfaction,
                  description: '缺少高潮'),
            ],
          ),
          DimensionScore(
            dimension: ReviewDimension.pacing,
            score: 4,
            issues: [
              ReviewIssue(
                  dimension: ReviewDimension.pacing,
                  description: '开头拖沓'),
              ReviewIssue(
                  dimension: ReviewDimension.pacing,
                  description: '结尾仓促'),
            ],
          ),
        ],
      );

      expect(report.allIssues.length, 3);
    });

    test('getScore 获取指定维度', () {
      final report = ReviewReport(
        chapterId: 'ch1',
        scores: const [
          DimensionScore(dimension: ReviewDimension.ooc, score: 9),
        ],
      );

      expect(report.getScore(ReviewDimension.ooc)?.score, 9);
      expect(report.getScore(ReviewDimension.pacing), isNull);
    });
  });

  group('SixDimensionReviewService', () {
    late MockAIProvider aiProvider;
    late SixDimensionReviewService service;

    setUp(() {
      aiProvider = MockAIProvider();
      service = SixDimensionReviewService(aiProvider: aiProvider);
    });

    test('review 正常解析 AI 返回', () async {
      aiProvider.mockResponse = '''
{
  "scores": [
    {"dimension": "satisfaction", "score": 8, "comment": "爽点充足", "issues": []},
    {"dimension": "consistency", "score": 7, "comment": "基本自洽", "issues": []},
    {"dimension": "pacing", "score": 5, "comment": "中段偏慢", "issues": [{"description": "第5段拖沓", "paragraph_index": 5, "severity": "medium"}]},
    {"dimension": "ooc", "score": 9, "comment": "角色一致", "issues": []},
    {"dimension": "continuity", "score": 8, "comment": "衔接良好", "issues": []},
    {"dimension": "readability", "score": 7, "comment": "追读欲强", "issues": []}
  ],
  "overall_score": 7,
  "summary": "整体质量良好，节奏可优化"
}''';

      final report = await service.review(
        chapterId: 'ch_001',
        content: '这是一段测试章节内容。' * 50,
      );

      expect(report.chapterId, 'ch_001');
      expect(report.scores.length, 6);
      expect(report.overallScore, 7);
      expect(report.summary, contains('节奏'));
      expect(report.getScore(ReviewDimension.pacing)?.score, 5);
      expect(report.allIssues.length, 1);
      expect(report.allIssues[0].paragraphIndex, 5);
    });

    test('review AI 返回无效 JSON 时降级', () async {
      aiProvider.mockResponse = '这不是 JSON';

      final report = await service.review(
        chapterId: 'ch_002',
        content: '内容',
      );

      expect(report.scores.length, 6);
      expect(report.overallScore, 5);
      expect(report.summary, contains('解析失败'));
    });

    test('generateFixSuggestions 为低分维度生成建议', () async {
      aiProvider.mockResponse = '1. 增加冲突\n2. 加快节奏\n3. 补充伏笔';

      final report = ReviewReport(
        chapterId: 'ch1',
        scores: const [
          DimensionScore(
            dimension: ReviewDimension.pacing,
            score: 3,
            issues: [
              ReviewIssue(
                  dimension: ReviewDimension.pacing,
                  description: '节奏过慢'),
            ],
          ),
        ],
      );

      final suggestions = await service.generateFixSuggestions(
        '章节内容',
        report,
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.length, 3);
    });

    test('generateFixSuggestions 无低分时返回空', () async {
      final report = ReviewReport(
        chapterId: 'ch1',
        scores: const [
          DimensionScore(dimension: ReviewDimension.satisfaction, score: 8),
        ],
      );

      final suggestions = await service.generateFixSuggestions(
        '内容',
        report,
      );
      expect(suggestions, isEmpty);
    });
  });
}
