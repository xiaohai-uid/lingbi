/// 短篇写作支持 — 单元测试
///
/// 覆盖：短篇流程/拆文/扫榜
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/short_story_service.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/core/ai/ai_provider.dart';

// ─── Mock ───

class MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};

  @override
  Future<Map<String, dynamic>?> read(String projectId, String key) async {
    return _store[projectId]?[key];
  }

  @override
  Future<void> write(
      String projectId, String key, Map<String, dynamic> value) async {
    _store.putIfAbsent(projectId, () => {});
    _store[projectId]![key] = value;
  }

  @override
  Future<void> delete(String projectId, String key) async {
    _store[projectId]?.remove(key);
  }

  @override
  Future<List<String>> list(String projectId) async {
    return _store[projectId]?.keys.toList() ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAIProvider implements AIProvider {
  String mockResponse = '';

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
  group('WritingMode', () {
    test('label 中文标签', () {
      expect(WritingMode.longForm.label, '长篇');
      expect(WritingMode.shortForm.label, '短篇');
    });

    test('fromString 解析', () {
      expect(WritingMode.fromString('shortForm'), WritingMode.shortForm);
      expect(WritingMode.fromString('unknown'), WritingMode.longForm);
    });
  });

  group('ShortStoryStep', () {
    test('label 和 description', () {
      expect(ShortStoryStep.emotionDesign.label, '情绪设计');
      expect(ShortStoryStep.reversalDesign.label, '反转构思');
      expect(ShortStoryStep.polishOutput.label, '精修出稿');

      for (final step in ShortStoryStep.values) {
        expect(step.description, isNotEmpty);
      }
    });

    test('order 顺序', () {
      expect(ShortStoryStep.emotionDesign.order, 0);
      expect(ShortStoryStep.reversalDesign.order, 1);
      expect(ShortStoryStep.polishOutput.order, 2);
    });
  });

  group('EmotionPoint', () {
    test('fromJson / toJson 往返', () {
      const point = EmotionPoint(
        position: '高潮',
        emotion: '震撼',
        intensity: 9,
        description: '真相揭露',
      );

      final json = point.toJson();
      final restored = EmotionPoint.fromJson(json);

      expect(restored.position, '高潮');
      expect(restored.emotion, '震撼');
      expect(restored.intensity, 9);
    });
  });

  group('ShortStoryFlowState', () {
    test('fromJson / toJson 往返', () {
      const state = ShortStoryFlowState(
        currentStep: ShortStoryStep.reversalDesign,
        emotionCurve: [
          EmotionPoint(position: '开篇', emotion: '好奇', intensity: 6),
        ],
        reversalIdea: '凶手是叙述者',
        draft: '初稿内容',
      );

      final json = state.toJson();
      final restored = ShortStoryFlowState.fromJson(json);

      expect(restored.currentStep, ShortStoryStep.reversalDesign);
      expect(restored.emotionCurve.length, 1);
      expect(restored.reversalIdea, '凶手是叙述者');
      expect(restored.isComplete, isFalse);
    });

    test('copyWith 更新', () {
      const state = ShortStoryFlowState();
      final updated = state.copyWith(
        currentStep: ShortStoryStep.polishOutput,
        isComplete: true,
      );

      expect(updated.currentStep, ShortStoryStep.polishOutput);
      expect(updated.isComplete, isTrue);
      expect(updated.emotionCurve, isEmpty); // 未变
    });
  });

  group('模式管理', () {
    late ShortStoryService service;

    setUp(() {
      service = ShortStoryService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );
    });

    test('默认长篇模式', () async {
      final mode = await service.getWritingMode('p1');
      expect(mode, WritingMode.longForm);
    });

    test('切换短篇模式', () async {
      await service.setWritingMode('p1', WritingMode.shortForm);
      final mode = await service.getWritingMode('p1');
      expect(mode, WritingMode.shortForm);
    });

    test('flowSteps 三步', () {
      expect(service.flowSteps.length, 3);
      expect(service.flowSteps.first, ShortStoryStep.emotionDesign);
    });
  });

  group('短篇引导流程', () {
    late ShortStoryService service;

    setUp(() {
      service = ShortStoryService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );
    });

    test('完整流程：情绪→反转→精修', () async {
      // 初始状态
      var state = await service.loadFlowState('p1');
      expect(state.currentStep, ShortStoryStep.emotionDesign);
      expect(state.isComplete, isFalse);

      // 完成情绪设计
      state = await service.completeEmotionDesign('p1', const [
        EmotionPoint(position: '开篇', emotion: '悬念', intensity: 7),
        EmotionPoint(position: '高潮', emotion: '震撼', intensity: 10),
      ]);
      expect(state.currentStep, ShortStoryStep.reversalDesign);
      expect(state.emotionCurve.length, 2);

      // 完成反转构思
      state = await service.completeReversalDesign('p1', '叙述者即凶手');
      expect(state.currentStep, ShortStoryStep.polishOutput);
      expect(state.reversalIdea, '叙述者即凶手');

      // 完成精修
      state = await service.completePolish('p1', '最终稿内容');
      expect(state.isComplete, isTrue);
      expect(state.draft, '最终稿内容');
    });

    test('状态持久化', () async {
      await service.completeEmotionDesign('p1', const [
        EmotionPoint(position: '开篇', emotion: '好奇', intensity: 5),
      ]);

      // 重新加载
      final state = await service.loadFlowState('p1');
      expect(state.currentStep, ShortStoryStep.reversalDesign);
      expect(state.emotionCurve.length, 1);
    });

    test('suggestEmotionCurve AI建议', () async {
      final aiProvider = MockAIProvider();
      aiProvider.mockResponse = jsonEncode([
        {
          'position': '开篇',
          'emotion': '好奇',
          'intensity': 6,
          'description': '设置悬念',
        },
        {
          'position': '高潮',
          'emotion': '震撼',
          'intensity': 9,
          'description': '反转揭示',
        },
      ]);

      final service = ShortStoryService(
        metaRepository: MockMetaRepository(),
        aiProvider: aiProvider,
      );

      final curve = await service.suggestEmotionCurve(
        storyIdea: '一个侦探发现自己才是凶手',
      );

      expect(curve.length, 2);
      expect(curve.first.emotion, '好奇');
      expect(curve.last.intensity, 9);
    });
  });

  group('短篇拆文', () {
    test('analyzeShortStory 五维分析', () async {
      final aiProvider = MockAIProvider();
      aiProvider.mockResponse = jsonEncode({
        'story_core': '一个关于救赎的故事',
        'structure': '三幕式：铺垫→冲突→解决',
        'emotion_line': [
          {
            'position': '开篇',
            'emotion': '压抑',
            'intensity': 4,
            'description': '主角困境',
          },
        ],
        'reversal_design': '结尾揭示主角早已死去',
        'resonance_points': ['孤独感', '对亲情的渴望'],
        'word_count': 8000,
      });

      final service = ShortStoryService(
        metaRepository: MockMetaRepository(),
        aiProvider: aiProvider,
      );

      final analysis = await service.analyzeShortStory('一篇短篇小说...');

      expect(analysis.isSuccess, isTrue);
      expect(analysis.storyCore, '一个关于救赎的故事');
      expect(analysis.emotionLine.length, 1);
      expect(analysis.reversalDesign, contains('死去'));
      expect(analysis.resonancePoints.length, 2);
      expect(analysis.wordCount, 8000);
    });

    test('analyzeShortStory 空文本', () async {
      final service = ShortStoryService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final analysis = await service.analyzeShortStory('');
      expect(analysis.isSuccess, isFalse);
      expect(analysis.error, contains('为空'));
    });
  });

  group('短篇扫榜', () {
    test('analyzeTrends 趋势分析', () async {
      final aiProvider = MockAIProvider();
      aiProvider.mockResponse = jsonEncode({
        'hot_topics': ['重生复仇', '甜宠日常'],
        'structure_patterns': ['开篇即冲突', '三段式反转'],
        'emotion_trends': '读者偏好强情绪开篇',
        'suggestions': ['尝试重生+悬疑组合', '控制字数在1.5万字内'],
      });

      final service = ShortStoryService(
        metaRepository: MockMetaRepository(),
        aiProvider: aiProvider,
      );

      final report = await service.analyzeTrends(
        entries: const [
          TrendingEntry(
            title: '重生之都市逆袭',
            platform: '知乎盐言',
            heat: 9800,
            tags: ['重生', '都市'],
          ),
          TrendingEntry(
            title: '甜蜜陷阱',
            platform: '番茄短篇',
            heat: 8500,
            tags: ['甜宠', '反转'],
          ),
        ],
      );

      expect(report.hotTopics.length, 2);
      expect(report.structurePatterns.length, 2);
      expect(report.emotionTrends, isNotEmpty);
      expect(report.suggestions.length, 2);
      expect(report.rawEntries.length, 2);
    });

    test('analyzeTrends 空数据', () async {
      final service = ShortStoryService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final report = await service.analyzeTrends(entries: []);
      expect(report.hotTopics, isEmpty);
      expect(report.rawEntries, isEmpty);
    });

    test('TrendingPlatform 标签', () {
      expect(TrendingPlatform.zhihuYanyan.label, '知乎盐言');
      expect(TrendingPlatform.fanqieShort.label, '番茄短篇');
    });
  });
}
