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

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';

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
    this.source = 'api',
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
      source: json['source'] as String? ?? 'api',
    );
  }

  final String platform;
  final String genre;
  final DateTime fetchedAt;
  final List<MarketTrendEntry> trends;
  final int avgChapterWords;
  final List<String> hotTags;

  /// 数据来源：`api`（用户自配）/`cache`（本地缓存）/`bundled`（内置样例）。
  final String source;

  /// 是否为随包内置的样例数据。
  bool get isBundled => source == 'bundled';

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'genre': genre,
        'fetched_at': fetchedAt.toIso8601String(),
        'trends': trends.map((e) => e.toJson()).toList(),
        'avg_chapter_words': avgChapterWords,
        'hot_tags': hotTags,
        'source': source,
      };
}

/// 市场情报服务
class MarketIntelService {
  MarketIntelService({
    required String cacheDir,
    http.Client? client,
    this.apiUrl = '',
    Future<String> Function(String assetPath)? assetLoader,
  })  : _cacheDir = cacheDir,
        _client = client ?? http.Client(),
        _assetLoader = assetLoader ?? rootBundle.loadString;

  final String _cacheDir;
  final http.Client _client;

  /// 读取随包资产的函数（可注入以便单测）。
  final Future<String> Function(String assetPath) _assetLoader;

  /// 用户配置的爬虫 API 地址（可选）
  final String apiUrl;

  /// 从远程 API 拉取市场数据
  ///
  /// 优先级：用户自配 apiUrl > 本地缓存 > 随包内置样例数据。
  /// 消除“默认无数据”：即使未配置 apiUrl 也能看到带标注的内置样例。
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
    final cached = await loadCache(platform, genre);
    if (cached != null) return cached;
    return loadBundled(platform: platform, genre: genre);
  }

  /// 从随包内置资产加载样例榜单（`assets/market/rankings/`）。
  Future<MarketIntelSnapshot?> loadBundled({
    required String platform,
    required String genre,
  }) async {
    try {
      final indexRaw =
          await _assetLoader('assets/market/rankings/index.json');
      final files = (jsonDecode(indexRaw) as List).cast<String>();
      MarketIntelSnapshot? genreMatch;
      for (final name in files) {
        final raw = await _assetLoader('assets/market/rankings/$name');
        final snap = MarketIntelSnapshot.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        if (snap.genre != genre) continue;
        genreMatch ??= snap;
        if (platform.isEmpty || snap.platform == platform) return snap;
      }
      return genreMatch;
    } catch (_) {
      return null;
    }
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
    if (snapshot.isBundled) {
      final d = snapshot.fetchedAt;
      final date =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      sb.writeln('数据来源: 内置样例数据（最后更新 $date）');
    }
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

/// AI 趋势分析结果
class MarketIntelAnalysis {
  const MarketIntelAnalysis({
    required this.id,
    required this.platform,
    required this.crawledAt,
    this.trends = const [],
    this.summary = '',
    this.openingPatterns = const [],
    this.satisfactionDensity = '',
  });

  factory MarketIntelAnalysis.fromJson(Map<String, dynamic> json) {
    return MarketIntelAnalysis(
      id: json['id'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      crawledAt: json['crawledAt'] != null
          ? DateTime.parse(json['crawledAt'] as String)
          : DateTime.now(),
      trends: (json['trends'] as List<dynamic>?)
              ?.map((e) => GenreTrend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      summary: json['summary'] as String? ?? '',
      openingPatterns:
          (json['openingPatterns'] as List<dynamic>?)?.cast<String>() ??
              const [],
      satisfactionDensity: json['satisfactionDensity'] as String? ?? '',
    );
  }

  final String id;
  final String platform;
  final DateTime crawledAt;
  final List<GenreTrend> trends;
  final String summary;
  final List<String> openingPatterns;
  final String satisfactionDensity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform,
        'crawledAt': crawledAt.toIso8601String(),
        'trends': trends.map((t) => t.toJson()).toList(),
        'summary': summary,
        'openingPatterns': openingPatterns,
        'satisfactionDensity': satisfactionDensity,
      };
}

/// 题材趋势条目
class GenreTrend {
  const GenreTrend({
    required this.genre,
    this.tags = const [],
    this.heatScore = 0,
    this.patterns = const [],
  });

  factory GenreTrend.fromJson(Map<String, dynamic> json) {
    return GenreTrend(
      genre: json['genre'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      heatScore: json['heatScore'] as int? ?? 0,
      patterns:
          (json['patterns'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  final String genre;
  final List<String> tags;
  final int heatScore;
  final List<String> patterns;

  Map<String, dynamic> toJson() => {
        'genre': genre,
        'tags': tags,
        'heatScore': heatScore,
        'patterns': patterns,
      };
}

/// 市场情报分析服务（AI 增强版）
///
/// 在基础 MarketIntelService 之上增加：
/// - AI 趋势分析（调用用户 API）
/// - 分析结果存储在 project_meta/market_intel/
/// - ContextAssembler 可选注入
class MarketIntelAnalysisService {
  MarketIntelAnalysisService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  set aiProvider(AIProvider provider) {
    _aiProvider = provider;
  }

  /// 使用 AI 分析榜单数据
  Future<MarketIntelAnalysis> analyzeTrends({
    required String platform,
    required MarketIntelSnapshot snapshot,
  }) async {
    final trendData = snapshot.trends
        .map((t) => '${t.rank}. ${t.title} [题材:${t.genre}] '
            '标签:${t.tags.join("/")} 热度:${t.heatScore}')
        .join('\n');

    final prompt = '''
你是一位网文市场分析师。请分析以下$platform榜单数据，以 JSON 格式输出：

{
  "summary": "一段话总结当前市场趋势（100字以内）",
  "trends": [
    {"genre": "题材名", "tags": ["热门标签"], "heatScore": 95, "patterns": ["创作模式/套路"]}
  ],
  "openingPatterns": ["开头模式1", "开头模式2"],
  "satisfactionDensity": "爽点密度分析（如：平均每3章一个小高潮）"
}

榜单数据：
$trendData

热门标签: ${snapshot.hotTags.join("、")}''';

    try {
      final result = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
              role: 'system', content: '你是网文市场分析师，只输出 JSON。'),
          ChatMessage(role: 'user', content: prompt),
        ],
      );

      final jsonStr = _extractJson(result);
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return MarketIntelAnalysis(
          id: 'mi_${DateTime.now().millisecondsSinceEpoch}',
          platform: platform,
          crawledAt: snapshot.fetchedAt,
          trends: (data['trends'] as List<dynamic>?)
                  ?.map(
                      (e) => GenreTrend.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          summary: data['summary'] as String? ?? '',
          openingPatterns:
              (data['openingPatterns'] as List<dynamic>?)?.cast<String>() ??
                  [],
          satisfactionDensity:
              data['satisfactionDensity'] as String? ?? '',
        );
      }
    } catch (_) {
      // AI 分析失败降级
    }

    return MarketIntelAnalysis(
      id: 'mi_${DateTime.now().millisecondsSinceEpoch}',
      platform: platform,
      crawledAt: snapshot.fetchedAt,
      summary: 'AI 分析未能完成，请重试。',
    );
  }

  /// 保存分析结果到 project_meta/market_intel/
  Future<void> saveAnalysis(
      String projectId, MarketIntelAnalysis analysis) async {
    await _metaRepository.write(
      projectId,
      'market_intel_${analysis.id}.json',
      analysis.toJson(),
    );
  }

  /// 加载项目所有市场情报分析
  Future<List<MarketIntelAnalysis>> listAnalyses(
      String projectId) async {
    final files = await _metaRepository.list(projectId);
    final intelFiles =
        files.where((f) => f.startsWith('market_intel_')).toList()
          ..sort();

    final results = <MarketIntelAnalysis>[];
    for (final file in intelFiles) {
      final data = await _metaRepository.read(projectId, file);
      if (data != null) {
        results.add(MarketIntelAnalysis.fromJson(data));
      }
    }
    return results;
  }

  /// 构建市场情报上下文（供 ContextAssembler 注入）
  Future<String> buildContextText(String projectId) async {
    final analyses = await listAnalyses(projectId);
    if (analyses.isEmpty) return '';

    final latest = analyses.last;
    final buffer = StringBuffer();
    buffer.writeln('【市场情报分析 — ${latest.platform}】');
    if (latest.summary.isNotEmpty) {
      buffer.writeln('趋势: ${latest.summary}');
    }
    if (latest.trends.isNotEmpty) {
      buffer.writeln('热门题材:');
      for (final t in latest.trends.take(5)) {
        buffer.writeln(
            '- ${t.genre}(热度${t.heatScore}) ${t.tags.take(3).join("/")}');
      }
    }
    if (latest.openingPatterns.isNotEmpty) {
      buffer.writeln('开头模式: ${latest.openingPatterns.join("、")}');
    }
    if (latest.satisfactionDensity.isNotEmpty) {
      buffer.writeln('爽点密度: ${latest.satisfactionDensity}');
    }
    return buffer.toString();
  }

  String? _extractJson(String text) {
    try {
      jsonDecode(text);
      return text;
    } catch (_) {}

    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) return match.group(1)?.trim();

    final braceStart = text.indexOf('{');
    final braceEnd = text.lastIndexOf('}');
    if (braceStart != -1 && braceEnd > braceStart) {
      return text.substring(braceStart, braceEnd + 1);
    }
    return null;
  }
}
