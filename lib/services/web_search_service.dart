/// AI 联网搜索服务
///
/// 职责：
/// 1. 定义 WebSearchService 接口：search(query) -> List<SearchResult>
/// 2. 支持配置搜索后端 URL（AnySearch/SearXNG/自建）
/// 3. 搜索结果格式化后注入当前对话上下文
/// 4. 搜索结果带来源标注（URL + 摘要）
/// 5. 无搜索后端配置时优雅降级（提示用户配置）
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// 搜索结果条目
class SearchResult {
  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.source = '',
    this.publishedDate = '',
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      snippet: json['snippet'] as String? ??
          json['content'] as String? ??
          '',
      source: json['source'] as String? ??
          json['engine'] as String? ??
          '',
      publishedDate: json['publishedDate'] as String? ?? '',
    );
  }

  /// 标题
  final String title;

  /// 来源 URL
  final String url;

  /// 摘要片段
  final String snippet;

  /// 来源引擎/网站
  final String source;

  /// 发布日期
  final String publishedDate;

  /// 格式化为上下文文本
  String toContextText() {
    final parts = <String>['- $title'];
    if (snippet.isNotEmpty) parts.add('  $snippet');
    parts.add('  来源: $url');
    return parts.join('\n');
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'snippet': snippet,
        'source': source,
        'publishedDate': publishedDate,
      };
}

/// 搜索后端类型
enum SearchBackendType {
  /// SearXNG 实例
  searxng,

  /// AnySearch API
  anysearch,

  /// 自建搜索服务
  custom;

  static SearchBackendType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'anysearch':
        return SearchBackendType.anysearch;
      case 'custom':
        return SearchBackendType.custom;
      default:
        return SearchBackendType.searxng;
    }
  }

  String get value => name;
}

/// 搜索后端配置
class SearchBackendConfig {
  const SearchBackendConfig({
    this.baseUrl = '',
    this.backendType = SearchBackendType.searxng,
    this.apiKey = '',
    this.maxResults = 5,
    this.timeoutSeconds = 10,
  });

  factory SearchBackendConfig.fromJson(Map<String, dynamic> json) {
    return SearchBackendConfig(
      baseUrl: json['baseUrl'] as String? ?? '',
      backendType: SearchBackendType.fromString(
          json['backendType'] as String? ?? 'searxng'),
      apiKey: json['apiKey'] as String? ?? '',
      maxResults: json['maxResults'] as int? ?? 5,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 10,
    );
  }

  /// 搜索后端 URL
  final String baseUrl;

  /// 后端类型
  final SearchBackendType backendType;

  /// API Key（部分后端需要）
  final String apiKey;

  /// 最大结果数
  final int maxResults;

  /// 超时秒数
  final int timeoutSeconds;

  /// 是否已配置
  bool get isConfigured => baseUrl.isNotEmpty;

  SearchBackendConfig copyWith({
    String? baseUrl,
    SearchBackendType? backendType,
    String? apiKey,
    int? maxResults,
    int? timeoutSeconds,
  }) {
    return SearchBackendConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      backendType: backendType ?? this.backendType,
      apiKey: apiKey ?? this.apiKey,
      maxResults: maxResults ?? this.maxResults,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'backendType': backendType.value,
        'apiKey': apiKey,
        'maxResults': maxResults,
        'timeoutSeconds': timeoutSeconds,
      };
}

/// 搜索异常
class SearchException implements Exception {
  const SearchException(this.message, {this.isConfigError = false});

  final String message;

  /// 是否为配置错误（未配置后端）
  final bool isConfigError;

  @override
  String toString() => message;
}

/// AI 联网搜索服务
class WebSearchService {
  WebSearchService({SearchBackendConfig? config})
      : _config = config ?? const SearchBackendConfig();

  SearchBackendConfig _config;

  /// 获取当前配置
  SearchBackendConfig get config => _config;

  /// 更新搜索后端配置
  void updateConfig(SearchBackendConfig config) {
    _config = config;
  }

  /// 是否可用（已配置后端）
  bool get isAvailable => _config.isConfigured;

  /// 执行搜索
  ///
  /// [query] — 搜索关键词
  /// 返回搜索结果列表。
  /// 未配置后端时抛出 [SearchException]（isConfigError = true）。
  Future<List<SearchResult>> search(String query) async {
    if (!_config.isConfigured) {
      throw const SearchException(
        '未配置搜索后端。请在设置中配置 SearXNG/AnySearch 实例地址。',
        isConfigError: true,
      );
    }

    try {
      switch (_config.backendType) {
        case SearchBackendType.searxng:
          return await _searchSearxng(query);
        case SearchBackendType.anysearch:
          return await _searchAnySearch(query);
        case SearchBackendType.custom:
          return await _searchCustom(query);
      }
    } on SearchException {
      rethrow;
    } catch (e) {
      throw SearchException('搜索失败: $e');
    }
  }

  /// 搜索并格式化为上下文文本（供 AI 对话注入）
  ///
  /// 未配置时返回降级提示文本。
  Future<String> searchForContext(String query) async {
    if (!isAvailable) {
      return '【联网搜索不可用】未配置搜索后端，无法获取实时资料。'
          '请在设置 → 联网搜索中配置 SearXNG 或 AnySearch 实例。';
    }

    try {
      final results = await search(query);
      if (results.isEmpty) {
        return '【联网搜索】未找到与「$query」相关的结果。';
      }
      return formatResultsForContext(query, results);
    } catch (e) {
      return '【联网搜索失败】$e';
    }
  }

  /// 格式化搜索结果为上下文文本
  String formatResultsForContext(
      String query, List<SearchResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('【联网搜索结果 — "$query"】');
    buffer.writeln();
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      buffer.writeln('${i + 1}. ${r.title}');
      if (r.snippet.isNotEmpty) {
        buffer.writeln('   ${r.snippet}');
      }
      buffer.writeln('   来源: ${r.url}');
      if (r.publishedDate.isNotEmpty) {
        buffer.writeln('   日期: ${r.publishedDate}');
      }
      buffer.writeln();
    }
    buffer.writeln('请基于以上搜索结果回答用户问题，并注明信息来源。');
    return buffer.toString();
  }

  /// 判断用户消息是否需要触发搜索
  ///
  /// 简单关键词匹配（后续可升级为 AI 判断）
  bool shouldTriggerSearch(String userMessage) {
    const triggerPatterns = [
      '搜索',
      '查一下',
      '帮我找',
      '最新',
      '现在',
      '目前',
      '最近',
      '网上',
      '资料',
      '素材',
      '参考',
    ];
    return triggerPatterns.any((p) => userMessage.contains(p));
  }

  // ─── 搜索后端实现 ───

  /// SearXNG 搜索
  Future<List<SearchResult>> _searchSearxng(String query) async {
    final uri = Uri.parse('${_config.baseUrl}/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'categories': 'general',
      },
    );

    final response = await http
        .get(uri, headers: _buildHeaders())
        .timeout(Duration(seconds: _config.timeoutSeconds));

    if (response.statusCode != 200) {
      throw SearchException(
          'SearXNG 返回 ${response.statusCode}，请检查实例地址');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>?)
            ?.take(_config.maxResults)
            .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return results;
  }

  /// AnySearch 搜索
  Future<List<SearchResult>> _searchAnySearch(String query) async {
    final uri = Uri.parse('${_config.baseUrl}/api/search').replace(
      queryParameters: {
        'q': query,
        'count': '${_config.maxResults}',
      },
    );

    final response = await http
        .get(uri, headers: _buildHeaders())
        .timeout(Duration(seconds: _config.timeoutSeconds));

    if (response.statusCode != 200) {
      throw SearchException(
          'AnySearch 返回 ${response.statusCode}，请检查配置');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['results'] as List<dynamic>?) ??
        (data['items'] as List<dynamic>?) ??
        [];
    return items
        .take(_config.maxResults)
        .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 自建搜索服务
  Future<List<SearchResult>> _searchCustom(String query) async {
    final uri = Uri.parse(_config.baseUrl);

    final response = await http
        .post(
          uri,
          headers: {
            ..._buildHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'query': query,
            'maxResults': _config.maxResults,
          }),
        )
        .timeout(Duration(seconds: _config.timeoutSeconds));

    if (response.statusCode != 200) {
      throw SearchException(
          '搜索服务返回 ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return data
          .take(_config.maxResults)
          .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final results = (data['results'] as List<dynamic>?) ?? [];
      return results
          .take(_config.maxResults)
          .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 构建请求头
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (_config.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_config.apiKey}';
    }
    return headers;
  }
}
