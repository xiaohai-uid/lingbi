/// MarketIntelService — 市场情报服务
///
/// 提供平台热门趋势数据，支持：
/// - 从配置的 API 端点拉取榜单数据
/// - 本地 JSON 缓存（离线可用）
/// - 生成市场上下文摘要注入 AI
///
/// 数据来源策略（Q8 决策）：
/// - 默认爬取公开榜单（标题/标签/热度）
/// - 用户可接入自己的 API（通过设置页配置爬虫 API 地址）
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// 市场趋势条目 — 单个榜单作品
class MarketTrendEntry {
  const MarketTrendEntry({
    required this.title,
    required this.platform,
    required this.genre,
    required this.rank,
    required this.heatScore,
    this.tags = const [],
    this.author = '',
    this.wordCount = 0,
  });

  factory MarketTrendEntry.fromJson(Map<String, dynamic> json) {
    return MarketTrendEntry(
      title: json['title'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      heatScore: json['heat_score'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      author: json['author'] as String? ?? '',
      wordCount: json['word_count'] as int? ?? 0,
    );
  }

  final String title;
  final String platform;
  final String genre;
  final int rank;
  final int heatScore;
  final List<String> tags;
  final String author;
  final int wordCount;

  Map<String, dynamic> toJson() => {
        'title': title,
        'platform': platform,
        'genre': genre,
        'rank': rank,
        'heat_score': heatScore,
        'tags': tags,
        'author': author,
        'word_count': wordCount,
      };
}

/// 市场情报快照 — 某平台某题材的一次抓取结果
class MarketIntelSnapshot {
  MarketIntelSnapshot({
    required this.platform,
    required this.genre,
    required this.fetchedAt,
    this.trends = const [],
    this.avgChapterWords = 0,
    this.hotTags = const [],
  });

  factory MarketIntelSnapshot.fromJson(Map<String, dynamic> json) {
    return MarketIntelSnapshot(
      platform: json['platform'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      fetchedAt: DateTime.tryParse(json['fetched_at'] as String? ?? '') ??
          DateTime.now(),
      trends: (json['trends'] as List?)
              ?.map((e) => MarketTrendEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      avgChapterWords: json['avg_chapter_words'] as int? ?? 0,
      hotTags: (json['hot_tags'] as List?)?.cast<String>() ?? [],
    );
  }

  final String platform;
  final String genre;
  final DateTime fetchedAt;
  final List<MarketTrendEntry> trends;
  final int avgChapterWords;
  final List<String> hotTags;

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'genre': genre,
        'fetched_at': fetchedAt.toIso8601String(),
        'trends': trends.map((e) => e.toJson()).toList(),
        'avg_chapter_words': avgChapterWords,
        'hot_tags': hotTags,
      };
}

/// 市场情报服务
class MarketIntelService {
  MarketIntelService({
    required String cacheDir,
    http.Client? client,
    this.apiUrl = '',
  })  : _cacheDir = cacheDir,
        _client = client ?? http.Client();

  final String _cacheDir;
  final http.Client _client;

  /// 用户配置的爬虫 API 地址（可选）
  final String apiUrl;

  /// 从远程 API 拉取市场数据
  ///
  /// 如果 apiUrl 为空或请求失败，回退到本地缓存。
  Future<MarketIntelSnapshot?> fetchTrends({
    required String platform,
    required String genre,
  }) async {
    if (apiUrl.isNotEmpty) {
      try {
        final uri = Uri.parse('$apiUrl/trends')
            .replace(queryParameters: {'platform': platform, 'genre': genre});
        final response =
            await _client.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final snapshot = MarketIntelSnapshot.fromJson(data);
          await saveCache(snapshot);
          return snapshot;
        }
      } catch (_) {
        // 网络失败回退缓存
      }
    }
    return loadCache(platform, genre);
  }

  /// 保存快照到本地缓存
  Future<void> saveCache(MarketIntelSnapshot snapshot) async {
    try {
      final dir = Directory(_cacheDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final key = _cacheKey(snapshot.platform, snapshot.genre);
      final file = File('$_cacheDir/$key.json');
      await file.writeAsString(jsonEncode(snapshot.toJson()));
    } catch (_) {
      // 缓存写入失败不阻断
    }
  }

  /// 从本地缓存加载快照
  Future<MarketIntelSnapshot?> loadCache(
      String platform, String genre) async {
    try {
      final key = _cacheKey(platform, genre);
      final file = File('$_cacheDir/$key.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return MarketIntelSnapshot.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// 生成市场上下文摘要（注入 AI prompt）
  ///
  /// 返回格式化的市场情报文本，供 ContextAssembler 使用。
  static String buildContextSummary(MarketIntelSnapshot? snapshot) {
    if (snapshot == null) return '';

    final sb = StringBuffer();
    sb.writeln('【市场情报】');
    sb.writeln('平台: ${snapshot.platform} | 题材: ${snapshot.genre}');

    if (snapshot.avgChapterWords > 0) {
      sb.writeln('同类型平均章长: ${snapshot.avgChapterWords} 字');
    }

    if (snapshot.hotTags.isNotEmpty) {
      sb.writeln('当前热门标签: ${snapshot.hotTags.join('、')}');
    }

    if (snapshot.trends.isNotEmpty) {
      sb.writeln('热门作品 TOP${snapshot.trends.length}:');
      for (final t in snapshot.trends.take(5)) {
        final tags = t.tags.isNotEmpty ? ' [${t.tags.join('/')}]' : '';
        sb.writeln('  ${t.rank}. ${t.title}$tags');
      }
    }

    return sb.toString().trim();
  }

  /// 缓存文件 key（平台+题材）
  String _cacheKey(String platform, String genre) {
    return '${platform}_$genre'.replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), '_');
  }

  void dispose() {
    _client.close();
  }
}
