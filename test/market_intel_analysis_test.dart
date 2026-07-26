/// 市场情报扫榜 — 单元测试
///
/// 覆盖：爬取/分析/存储/引用
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/market_intel_service.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/core/ai/ai_provider.dart';

// ─── Mocks ───

class MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<Map<String, dynamic>?> read(
      String projectId, String fileName) async {
    return _store['$projectId/$fileName'];
  }

  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
    _store['$projectId/$fileName'] = data;
  }

  @override
  Future<List<String>> list(String projectId) async {
    return _store.keys
        .where((k) => k.startsWith('$projectId/'))
        .map((k) => k.replaceFirst('$projectId/', ''))
        .toList();
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    _store.remove('$projectId/$fileName');
  }

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
      String projectId, WorldConstitution constitution) async {}

  @override
  Future<String> getMetaDirPath(String projectId) async => '/mock/$projectId';
}

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
  group('MarketTrendEntry 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      const entry = MarketTrendEntry(
        title: '斗破苍穹',
        platform: '起点',
        genre: '玄幻',
        rank: 1,
        heatScore: 98000,
        tags: ['热血', '升级', '废柴逆袭'],
        author: '天蚕土豆',
        wordCount: 5000000,
      );

      final json = entry.toJson();
      final restored = MarketTrendEntry.fromJson(json);

      expect(restored.title, '斗破苍穹');
      expect(restored.platform, '起点');
      expect(restored.genre, '玄幻');
      expect(restored.rank, 1);
      expect(restored.heatScore, 98000);
      expect(restored.tags.length, 3);
    });
  });

  group('MarketIntelSnapshot', () {
    test('fromJson / toJson 往返一致', () {
      final snapshot = MarketIntelSnapshot(
        platform: '番茄',
        genre: '都市',
        fetchedAt: DateTime(2026, 7, 25),
        trends: const [
          MarketTrendEntry(
            title: '测试作品',
            platform: '番茄',
            genre: '都市',
            rank: 1,
            heatScore: 5000,
            tags: ['逆袭'],
          ),
        ],
        avgChapterWords: 2500,
        hotTags: ['系统', '重生', '逆袭'],
      );

      final json = snapshot.toJson();
      final restored = MarketIntelSnapshot.fromJson(json);

      expect(restored.platform, '番茄');
      expect(restored.genre, '都市');
      expect(restored.trends.length, 1);
      expect(restored.avgChapterWords, 2500);
      expect(restored.hotTags, contains('系统'));
    });
  });

  group('buildContextSummary', () {
    test('生成格式化市场情报文本', () {
      final snapshot = MarketIntelSnapshot(
        platform: '起点',
        genre: '玄幻',
        fetchedAt: DateTime.now(),
        trends: const [
          MarketTrendEntry(
            title: '作品A',
            platform: '起点',
            genre: '玄幻',
            rank: 1,
            heatScore: 99000,
            tags: ['升级', '热血'],
          ),
        ],
        avgChapterWords: 3000,
        hotTags: ['系统', '穿越'],
      );

      final text = MarketIntelService.buildContextSummary(snapshot);
      expect(text, contains('市场情报'));
      expect(text, contains('起点'));
      expect(text, contains('玄幻'));
      expect(text, contains('3000'));
      expect(text, contains('系统'));
      expect(text, contains('作品A'));
    });

    test('null 快照返回空字符串', () {
      final text = MarketIntelService.buildContextSummary(null);
      expect(text, isEmpty);
    });
  });

  group('MarketIntelAnalysisService', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late MarketIntelAnalysisService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = MarketIntelAnalysisService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('analyzeTrends AI 正常返回', () async {
      aiProvider.mockResponse = '''
{
  "summary": "玄幻题材持续火热，系统流和升级流占据主流",
  "trends": [
    {"genre": "玄幻", "tags": ["系统", "升级"], "heatScore": 95, "patterns": ["废柴逆袭"]}
  ],
  "openingPatterns": ["金手指开局", "重生回忆"],
  "satisfactionDensity": "平均每2章一个小高潮"
}''';

      final snapshot = MarketIntelSnapshot(
        platform: '起点',
        genre: '玄幻',
        fetchedAt: DateTime.now(),
        trends: const [
          MarketTrendEntry(
            title: '测试',
            platform: '起点',
            genre: '玄幻',
            rank: 1,
            heatScore: 9000,
          ),
        ],
      );

      final analysis = await service.analyzeTrends(
        platform: '起点',
        snapshot: snapshot,
      );

      expect(analysis.platform, '起点');
      expect(analysis.summary, contains('玄幻'));
      expect(analysis.trends.length, 1);
      expect(analysis.trends[0].genre, '玄幻');
      expect(analysis.openingPatterns, contains('金手指开局'));
      expect(analysis.satisfactionDensity, contains('2章'));
    });

    test('saveAnalysis + listAnalyses 往返一致', () async {
      final analysis = MarketIntelAnalysis(
        id: 'mi_001',
        platform: '番茄',
        crawledAt: DateTime(2026, 7, 25),
        summary: '都市题材分析',
        trends: const [
          GenreTrend(genre: '都市', tags: ['逆袭'], heatScore: 88),
        ],
      );

      await service.saveAnalysis('proj1', analysis);
      final list = await service.listAnalyses('proj1');

      expect(list.length, 1);
      expect(list[0].id, 'mi_001');
      expect(list[0].summary, '都市题材分析');
    });

    test('buildContextText 有数据时返回情报文本', () async {
      final analysis = MarketIntelAnalysis(
        id: 'mi_002',
        platform: '晋江',
        crawledAt: DateTime.now(),
        summary: '言情题材回暖',
        trends: const [
          GenreTrend(genre: '言情', tags: ['甜宠'], heatScore: 92),
        ],
        openingPatterns: ['误会开局'],
        satisfactionDensity: '每3章发糖一次',
      );
      await service.saveAnalysis('proj1', analysis);

      final text = await service.buildContextText('proj1');
      expect(text, contains('市场情报'));
      expect(text, contains('晋江'));
      expect(text, contains('言情'));
      expect(text, contains('误会开局'));
    });

    test('buildContextText 无数据时返回空', () async {
      final text = await service.buildContextText('empty_proj');
      expect(text, isEmpty);
    });
  });
}
