/// 去AI味引擎 — 单元测试
///
/// 覆盖：检测/改写/批量
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/review/data/de_ai_flavor_service.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

// ─── Mock ───

class MockAIProvider implements AIProvider {
  String mockResponse = '改写后的文本';

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
  group('DetectionRule', () {
    test('fromJson / toJson 往返', () {
      const rule = DetectionRule(
        id: 'test_1',
        type: RuleType.phrase,
        pattern: '值得注意的是',
        description: '测试规则',
        severity: 'high',
        category: 'transition',
      );

      final json = rule.toJson();
      final restored = DetectionRule.fromJson(json);

      expect(restored.id, 'test_1');
      expect(restored.type, RuleType.phrase);
      expect(restored.pattern, '值得注意的是');
    });
  });

  group('DeAiFlavorService 检测', () {
    late MockAIProvider aiProvider;
    late DeAiFlavorService service;

    setUp(() {
      aiProvider = MockAIProvider();
      service = DeAiFlavorService(aiProvider: aiProvider);
    });

    test('检测高频词命中', () {
      const text = '值得注意的是，他不禁后退了一步。\n与此同时，她缓缓转身。';

      final result = service.detect(text);

      expect(result.hasIssues, isTrue);
      expect(result.hits.length, greaterThanOrEqualTo(3));
      expect(result.suspiciousParagraphs, contains(0));
      expect(result.suspiciousParagraphs, contains(1));
    });

    test('干净文本无命中', () {
      const text = '他握紧剑柄，目光如炬。\n"来吧。"他沉声道。';

      final result = service.detect(text);
      expect(result.hasIssues, isFalse);
      expect(result.aiScore, 0);
    });

    test('AI味评分随命中数增加', () {
      const clean = '正常文本段落一。\n正常文本段落二。';
      const aiHeavy = '值得注意的是，他不禁感到震撼。\n'
          '与此同时，她缓缓开口，不由自主地颤抖。\n'
          '仿佛一切都已注定。';

      final cleanResult = service.detect(clean);
      final aiResult = service.detect(aiHeavy);

      expect(aiResult.aiScore, greaterThan(cleanResult.aiScore));
    });

    test('正则规则匹配', () {
      const text = '他的眼中闪过一丝杀意。';

      final result = service.detect(text);
      expect(result.hasIssues, isTrue);
      expect(result.hits.any((h) => h.rule.id == 'p_001'), isTrue);
    });

    test('自定义规则', () {
      final customService = DeAiFlavorService(
        aiProvider: aiProvider,
        customRules: const [
          DetectionRule(
            id: 'custom_1',
            type: RuleType.word,
            pattern: '测试自定义',
            severity: 'high',
          ),
        ],
      );

      final result = customService.detect('这里有测试自定义词汇');
      expect(result.hasIssues, isTrue);
      expect(result.hits.first.rule.id, 'custom_1');
    });

    test('addRule / removeRule', () {
      const newRule = DetectionRule(
        id: 'new_1',
        type: RuleType.word,
        pattern: '新增词',
      );

      service.addRule(newRule);
      expect(service.rules.any((r) => r.id == 'new_1'), isTrue);

      service.removeRule('new_1');
      expect(service.rules.any((r) => r.id == 'new_1'), isFalse);
    });
  });

  group('改写', () {
    late MockAIProvider aiProvider;
    late DeAiFlavorService service;

    setUp(() {
      aiProvider = MockAIProvider();
      service = DeAiFlavorService(aiProvider: aiProvider);
    });

    test('rewriteParagraph 返回改写结果', () async {
      aiProvider.mockResponse = '他后退了一步，心跳加速。';

      final result = await service.rewriteParagraph(
        paragraphIndex: 0,
        original: '值得注意的是，他不禁后退了一步。',
      );

      expect(result.paragraphIndex, 0);
      expect(result.original, contains('不禁'));
      expect(result.rewritten, '他后退了一步，心跳加速。');
    });

    test('rewriteChapter 批量改写可疑段落', () async {
      aiProvider.mockResponse = '改写结果';

      const text = '值得注意的是，战斗开始了。\n他握紧了剑。\n与此同时，敌人缓缓逼近。';

      final results = await service.rewriteChapter(text);

      // 只改写可疑段落（第0段和第2段）
      expect(results.length, 2);
      expect(results[0].paragraphIndex, 0);
      expect(results[1].paragraphIndex, 2);
    });

    test('applyRewrites 应用改写', () {
      const text = '段落A\n段落B\n段落C';
      const rewrites = [
        RewriteResult(
          paragraphIndex: 1,
          original: '段落B',
          rewritten: '改写B',
        ),
      ];

      final result = service.applyRewrites(text, rewrites);
      expect(result, contains('段落A'));
      expect(result, contains('改写B'));
      expect(result, contains('段落C'));
      expect(result, isNot(contains('段落B')));
    });

    test('无问题时 rewriteChapter 返回空', () async {
      const text = '他握紧剑柄。\n"来吧。"';

      final results = await service.rewriteChapter(text);
      expect(results, isEmpty);
    });
  });
}
