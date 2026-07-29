import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/canon_entry.dart';
import 'package:lingbi/services/web_search_service.dart';
import 'package:lingbi/ui_v2/components/ai_context_browser.dart';

void main() {
  Widget buildSubject({
    required Future<List<SearchResult>> Function(String query) searchWeb,
    required Future<List<CanonEntry>> Function(String query) searchCanon,
    required ValueChanged<String> onInsertContext,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 340,
          child: AiContextBrowser(
            searchWeb: searchWeb,
            searchCanon: searchCanon,
            onInsertContext: onInsertContext,
          ),
        ),
      ),
    );
  }

  testWidgets('searches the web and inserts a source-backed context block',
      (tester) async {
    String? inserted;
    await tester.pumpWidget(
      buildSubject(
        searchWeb: (query) async => const [
          SearchResult(
            title: '宋代城市生活',
            url: 'https://example.com/song-city',
            snippet: '坊市制度逐渐松动，夜市活动更为常见。',
          ),
        ],
        searchCanon: (_) async => [],
        onInsertContext: (value) => inserted = value,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('ai-context-query')),
      '宋代城市',
    );
    await tester.tap(find.byKey(const ValueKey('ai-context-search')));
    await tester.pumpAndSettle();

    expect(find.text('宋代城市生活'), findsOneWidget);
    expect(find.textContaining('坊市制度逐渐松动'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('insert-web-context-0')));
    expect(inserted, contains('https://example.com/song-city'));
    expect(inserted, contains('宋代城市生活'));
  });

  testWidgets('searches project canon and inserts the selected entry',
      (tester) async {
    String? inserted;
    await tester.pumpWidget(
      buildSubject(
        searchWeb: (_) async => [],
        searchCanon: (query) async => [
          CanonEntry(
            projectId: 'project-1',
            type: CanonEntryType.character,
            name: '沈砚',
            description: '谨慎的巡检司书吏。',
          ),
        ],
        onInsertContext: (value) => inserted = value,
      ),
    );

    await tester.tap(find.text('正典'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai-context-query')),
      '沈砚',
    );
    await tester.tap(find.byKey(const ValueKey('ai-context-search')));
    await tester.pumpAndSettle();

    expect(find.text('沈砚'), findsAtLeastNWidgets(1));
    expect(find.text('谨慎的巡检司书吏。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('insert-canon-context-0')));
    expect(inserted, contains('角色'));
    expect(inserted, contains('沈砚'));
  });

  testWidgets('shows a recoverable error when a search fails', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        searchWeb: (_) async => throw const SearchException('搜索后端未配置'),
        searchCanon: (_) async => [],
        onInsertContext: (_) {},
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('ai-context-query')),
      '测试',
    );
    await tester.tap(find.byKey(const ValueKey('ai-context-search')));
    await tester.pumpAndSettle();

    expect(find.textContaining('搜索后端未配置'), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-context-search')), findsOneWidget);
  });
}
