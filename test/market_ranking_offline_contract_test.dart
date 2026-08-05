import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lingbi/features/skill/data/ranking_api_client.dart';
import 'package:lingbi/features/skill/data/skill_marketplace.dart';

void main() {
  group('SkillMarketplace OpenWrite response contract', () {
    test('parses current data.skills envelope', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/index.php' &&
            request.url.queryParameters['action'] == 'marketplace_list') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'skills': [
                  {
                    'id': 42,
                    'skill_name': 'sample-skill',
                    'description': 'sample',
                    'uploader_nickname': 'tester',
                    'version': 3,
                    'skill_type': 'text',
                    'download_count': 7,
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });
      final marketplace = SkillMarketplace(
        registryUrl: 'https://registry.invalid/registry.json',
        openWriteApiBase: 'https://mirror.invalid/api/index.php',
        client: client,
      );
      addTearDown(marketplace.dispose);

      final items = await marketplace.fetchSkillsWithFallback();

      expect(items, hasLength(1));
      expect(items.single.id, '42');
      expect(items.single.name, 'sample-skill');
      expect(items.single.downloadCount, 7);
      expect(
        items.single.downloadUrl,
        'https://mirror.invalid/api/index.php?action=marketplace_download&id=42',
      );
    });

    test('keeps legacy data list parsing', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'legacy-1',
                'name': 'legacy',
                'description': 'legacy skill',
                'author': 'tester',
                'version': '1.0.0',
                'category': 'general',
                'download_url': 'https://example.com/skill.md',
                'download_count': 1,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final marketplace = SkillMarketplace(
        registryUrl: 'https://registry.invalid/registry.json',
        openWriteApiBase: 'https://mirror.invalid/api/index.php',
        client: client,
      );
      addTearDown(marketplace.dispose);

      final items = await marketplace.fetchSkillsWithFallback();

      expect(items, hasLength(1));
      expect(items.single.id, 'legacy-1');
      expect(items.single.name, 'legacy');
    });
  });

  group('RankingApiClient bundled fallback', () {
    test('returns labeled bundled samples when mirror rejects', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({'success': false, 'message': 'Invalid action'}),
          400,
        ),
      );
      final ranking = RankingApiClient(
        client: client,
        assetLoader: (path) async {
          switch (path) {
            case 'assets/market/rankings/index.json':
              return jsonEncode(['qidian_xuanhuan.json']);
            case 'assets/market/rankings/qidian_xuanhuan.json':
              return jsonEncode({
                'platform': '起点',
                'genre': '玄幻',
                'fetched_at': '2025-06-01T00:00:00.000Z',
                'source': 'bundled',
                'avg_chapter_words': 3000,
                'hot_tags': ['东方玄幻'],
                'trends': [
                  {
                    'title': '苍天霸体诀',
                    'platform': '起点',
                    'genre': '玄幻',
                    'rank': 1,
                    'heat_score': 9750,
                    'tags': ['东方玄幻'],
                    'author': '样例作者',
                    'word_count': 4200000,
                  },
                ],
              });
          }
          throw StateError('unexpected asset $path');
        },
      );
      addTearDown(ranking.dispose);

      final body = await ranking.query('rank_top');
      final decoded = jsonDecode(body) as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(decoded['source'], 'bundled');
      expect(decoded['endpoint'], 'rank_top');
      expect(decoded['notice'], contains('BLOCKED_EXTERNAL'));
      expect(decoded['data'], isA<List<dynamic>>());
      expect(
        (decoded['data'] as List).single['platform'],
        '起点',
      );
    });

    test('returns remote body when mirror succeeds', () async {
      final client = MockClient(
        (request) async => http.Response('{"source":"remote"}', 200),
      );
      final ranking = RankingApiClient(client: client);
      addTearDown(ranking.dispose);

      final body = await ranking.query('rank_top');

      expect(body, '{"source":"remote"}');
    });
  });
}
