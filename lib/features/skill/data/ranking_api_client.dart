/// 网文排行 API 客户端 — 复刻 OpenWrite 的 novel_ranking 工具数据源。
///
/// 对接 OpenWrite 镜像扫榜 API，失败时 fallback 到本地 JSON。
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class RankingApiClient {
  RankingApiClient({
    http.Client? client,
    String? baseUrl,
    Future<String> Function(String assetPath)? assetLoader,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl,
        _assetLoader = assetLoader ?? rootBundle.loadString;

  final http.Client _client;
  final String _baseUrl;
  final Future<String> Function(String assetPath) _assetLoader;

  /// OpenWrite 扫榜镜像 API
  static const _defaultBaseUrl = 'http://111.170.163.42:4650/api/index.php';
  static const _timeout = Duration(seconds: 5);

  /// 查询排行数据。
  ///
  /// [endpoint] 如 'top', 'books', 'stats', 'categories', 'ranks', 'rank_top' 等。
  /// [params] 额外查询参数。
  Future<String> query(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'action': 'novel_ranking',
      'endpoint': endpoint,
      ...?params,
    });
    try {
      final resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode == 200) return resp.body;
    } catch (_) {
      // Mirror unavailable; fall through to bundled samples.
    }
    return _bundledFallback(endpoint);
  }

  /// 获取热门榜单摘要（供 AI 工具快速返回）。
  Future<String> getTopSummary() async {
    return query('rank_top', params: {'limit': '10'});
  }

  /// 返回随包样例，并明确标注不是实时商业数据。
  Future<String> _bundledFallback(String endpoint) async {
    try {
      final indexRaw = await _assetLoader('assets/market/rankings/index.json');
      final index = jsonDecode(indexRaw);
      final files = index is List ? index.cast<String>() : const <String>[];
      final snapshots = <Map<String, dynamic>>[];
      for (final name in files) {
        final raw = await _assetLoader('assets/market/rankings/$name');
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) snapshots.add(decoded);
      }
      return jsonEncode({
        'success': true,
        'source': 'bundled',
        'endpoint': endpoint,
        'notice': '内置样例数据，非实时榜单；授权市场数据仍为 BLOCKED_EXTERNAL',
        'data': snapshots,
      });
    } catch (_) {
      return jsonEncode({
        'error': 'ranking_unavailable_no_bundled',
        'source': 'bundled',
        'notice': '排行榜源不可用，且未找到内置样例数据',
      });
    }
  }

  void dispose() => _client.close();
}
