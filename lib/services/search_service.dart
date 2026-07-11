/// SearchService — AI 联网搜索客户端
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final String content;

  const SearchResult({
    required this.title,
    required this.url,
    this.snippet = '',
    this.content = '',
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
    snippet: json['snippet'] as String? ?? '',
    content: json['content'] as String? ?? '',
  );
}

class SearchResponse {
  final String query;
  final List<SearchResult> results;
  final String summary;

  const SearchResponse({
    required this.query,
    this.results = const [],
    this.summary = '',
  });
}

class SearchService {
  SearchService({this.baseUrl = 'http://localhost:8098'});

  final String baseUrl;
  final http.Client _client = http.Client();

  /// AI 联网搜索
  Future<SearchResponse> searchWeb({
    required String query,
    int maxResults = 5,
    bool summary = true,
  }) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/v1/search/web'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'max_results': maxResults,
        'summary': summary,
      }),
    );

    if (resp.statusCode != 200) {
      throw StateError('Search failed: ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return SearchResponse(
      query: body['query'] as String? ?? query,
      results: ((body['results'] as List?) ?? [])
          .map((r) => SearchResult.fromJson(r))
          .toList(),
      summary: body['summary'] as String? ?? '',
    );
  }
}
