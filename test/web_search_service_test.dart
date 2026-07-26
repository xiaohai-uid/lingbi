/// AI 联网搜索服务 — 单元测试
///
/// 覆盖：搜索/注入/降级
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/web_search_service.dart';

void main() {
  group('SearchResult 数据模型', () {
    test('fromJson 正确解析', () {
      final result = SearchResult.fromJson({
        'title': 'Flutter 3.0 发布',
        'url': 'https://flutter.dev/blog',
        'snippet': 'Flutter 3.0 带来了全新特性...',
        'source': 'google',
        'publishedDate': '2026-01-01',
      });

      expect(result.title, 'Flutter 3.0 发布');
      expect(result.url, 'https://flutter.dev/blog');
      expect(result.snippet, contains('全新特性'));
      expect(result.source, 'google');
    });

    test('toContextText 格式化正确', () {
      const result = SearchResult(
        title: '测试标题',
        url: 'https://example.com',
        snippet: '这是摘要内容',
      );

      final text = result.toContextText();
      expect(text, contains('测试标题'));
      expect(text, contains('这是摘要内容'));
      expect(text, contains('https://example.com'));
    });
  });

  group('SearchBackendConfig', () {
    test('未配置时 isConfigured 为 false', () {
      const config = SearchBackendConfig();
      expect(config.isConfigured, false);
    });

    test('配置了 baseUrl 后 isConfigured 为 true', () {
      const config = SearchBackendConfig(baseUrl: 'http://localhost:8080');
      expect(config.isConfigured, true);
    });

    test('fromJson / toJson 往返一致', () {
      const config = SearchBackendConfig(
        baseUrl: 'http://searxng.local',
        backendType: SearchBackendType.searxng,
        apiKey: 'test-key',
        maxResults: 8,
        timeoutSeconds: 15,
      );

      final json = config.toJson();
      final restored = SearchBackendConfig.fromJson(json);

      expect(restored.baseUrl, 'http://searxng.local');
      expect(restored.backendType, SearchBackendType.searxng);
      expect(restored.apiKey, 'test-key');
      expect(restored.maxResults, 8);
      expect(restored.timeoutSeconds, 15);
    });
  });

  group('降级行为', () {
    test('未配置后端时 search 抛出配置异常', () async {
      final service = WebSearchService();

      expect(
        () => service.search('测试查询'),
        throwsA(
          isA<SearchException>().having(
            (e) => e.isConfigError,
            'isConfigError',
            true,
          ),
        ),
      );
    });

    test('未配置后端时 searchForContext 返回降级提示', () async {
      final service = WebSearchService();
      final text = await service.searchForContext('测试');

      expect(text, contains('联网搜索不可用'));
      expect(text, contains('未配置搜索后端'));
    });

    test('isAvailable 未配置时为 false', () {
      final service = WebSearchService();
      expect(service.isAvailable, false);
    });

    test('配置后 isAvailable 为 true', () {
      final service = WebSearchService(
        config: const SearchBackendConfig(baseUrl: 'http://localhost:8888'),
      );
      expect(service.isAvailable, true);
    });
  });

  group('搜索结果格式化注入', () {
    test('formatResultsForContext 正确格式化', () {
      final service = WebSearchService();
      const results = [
        SearchResult(
          title: '结果一',
          url: 'https://a.com',
          snippet: '摘要A',
          publishedDate: '2026-01-01',
        ),
        SearchResult(
          title: '结果二',
          url: 'https://b.com',
          snippet: '摘要B',
        ),
      ];

      final text = service.formatResultsForContext('小说素材', results);

      expect(text, contains('联网搜索结果'));
      expect(text, contains('小说素材'));
      expect(text, contains('1. 结果一'));
      expect(text, contains('摘要A'));
      expect(text, contains('https://a.com'));
      expect(text, contains('2026-01-01'));
      expect(text, contains('2. 结果二'));
      expect(text, contains('注明信息来源'));
    });

    test('空结果返回提示', () async {
      // 使用不可达地址测试搜索失败降级
      final service = WebSearchService(
        config: const SearchBackendConfig(
          baseUrl: 'http://192.0.2.1:9999', // 不可达地址
          timeoutSeconds: 1,
        ),
      );

      final text = await service.searchForContext('测试');
      expect(text, contains('联网搜索失败'));
    });
  });

  group('搜索触发判断', () {
    test('包含触发词时返回 true', () {
      final service = WebSearchService();

      expect(service.shouldTriggerSearch('帮我搜索一下唐朝历史'), true);
      expect(service.shouldTriggerSearch('查一下最新的网文趋势'), true);
      expect(service.shouldTriggerSearch('找一些修仙素材'), true);
    });

    test('不包含触发词时返回 false', () {
      final service = WebSearchService();

      expect(service.shouldTriggerSearch('写一段打斗场景'), false);
      expect(service.shouldTriggerSearch('继续上一章'), false);
    });
  });

  group('updateConfig', () {
    test('动态更新配置', () {
      final service = WebSearchService();
      expect(service.isAvailable, false);

      service.updateConfig(
        const SearchBackendConfig(baseUrl: 'http://my-searxng:8080'),
      );
      expect(service.isAvailable, true);
      expect(service.config.baseUrl, 'http://my-searxng:8080');
    });
  });
}
