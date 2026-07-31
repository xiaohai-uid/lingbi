/// 网文排行 API 客户端 — 复刻 OpenWrite 的 novel_ranking 工具数据源。
///
/// 对接 OpenWrite 镜像扫榜 API，失败时 fallback 到本地 JSON。
library;

import 'package:http/http.dart' as http;

class RankingApiClient {
  RankingApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// OpenWrite 扫榜镜像 API
  static const _baseUrl = 'http://111.170.163.42:4650/api/index.php';

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
      final resp = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return resp.body;
      return '{"error":"HTTP ${resp.statusCode}"}';
    } catch (e) {
      return '{"error":"$e"}';
    }
  }

  /// 获取热门榜单摘要（供 AI 工具快速返回）。
  Future<String> getTopSummary() async {
    return query('rank_top', params: {'limit': '10'});
  }

  void dispose() => _client.close();
}
