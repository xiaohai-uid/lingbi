/// 拆书知识库 + 参考书管理服务
///
/// 提供：
/// - 参考书导入（URL/本地文件）
/// - 断点续爬（网络中断后从上次进度继续）
/// - 四层深度分析（风格/人物/情节/氛围）
/// - 分析结果回灌到生成上下文
/// - 全部使用用户自己的 API Key 调用 LLM 完成分析
library;


import 'package:http/http.dart' as http;

import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

// ─── 数据模型 ───

/// 参考书来源类型
enum ReferenceSourceType { url, file, manual;

  static ReferenceSourceType fromString(String s) {
    return ReferenceSourceType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ReferenceSourceType.manual,
    );
  }
}

/// 爬取状态
enum CrawlStatus { idle, crawling, paused, completed, failed;

  static CrawlStatus fromString(String s) {
    return CrawlStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => CrawlStatus.idle,
    );
  }
}

/// 四层深度分析结果
class BookAnalysis {
  const BookAnalysis({
    this.style = '',
    this.characters = '',
    this.plot = '',
    this.atmosphere = '',
    this.analyzedAt = '',
  });

  factory BookAnalysis.fromJson(Map<String, dynamic> json) {
    return BookAnalysis(
      style: json['style'] as String? ?? '',
      characters: json['characters'] as String? ?? '',
      plot: json['plot'] as String? ?? '',
      atmosphere: json['atmosphere'] as String? ?? '',
      analyzedAt: json['analyzed_at'] as String? ?? '',
    );
  }

  /// 风格分析
  final String style;

  /// 人物分析
  final String characters;

  /// 情节分析
  final String plot;

  /// 氛围分析
  final String atmosphere;

  final String analyzedAt;

  bool get isComplete =>
      style.isNotEmpty &&
      characters.isNotEmpty &&
      plot.isNotEmpty &&
      atmosphere.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'style': style,
        'characters': characters,
        'plot': plot,
        'atmosphere': atmosphere,
        'analyzed_at': analyzedAt,
      };
}

/// 参考书数据模型
class ReferenceBook {
  ReferenceBook({
    required this.id,
    required this.title,
    required this.sourceType,
    this.sourceUrl = '',
    this.filePath = '',
    this.author = '',
    this.crawlStatus = CrawlStatus.idle,
    this.crawlProgress = 0.0,
    this.totalChapters = 0,
    this.crawledChapters = 0,
    this.content = '',
    this.analysis = const BookAnalysis(),
    this.addedAt = '',
    this.updatedAt = '',
  });

  factory ReferenceBook.fromJson(Map<String, dynamic> json) {
    return ReferenceBook(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sourceType: ReferenceSourceType.fromString(
          json['source_type'] as String? ?? 'manual'),
      sourceUrl: json['source_url'] as String? ?? '',
      filePath: json['file_path'] as String? ?? '',
      author: json['author'] as String? ?? '',
      crawlStatus:
          CrawlStatus.fromString(json['crawl_status'] as String? ?? 'idle'),
      crawlProgress: (json['crawl_progress'] as num?)?.toDouble() ?? 0,
      totalChapters: json['total_chapters'] as int? ?? 0,
      crawledChapters: json['crawled_chapters'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      analysis: json['analysis'] != null
          ? BookAnalysis.fromJson(
              json['analysis'] as Map<String, dynamic>)
          : const BookAnalysis(),
      addedAt: json['added_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final ReferenceSourceType sourceType;
  final String sourceUrl;
  final String filePath;
  final String author;
  final CrawlStatus crawlStatus;
  final double crawlProgress;
  final int totalChapters;
  final int crawledChapters;
  final String content;
  final BookAnalysis analysis;
  final String addedAt;
  final String updatedAt;

  ReferenceBook copyWith({
    CrawlStatus? crawlStatus,
    double? crawlProgress,
    int? totalChapters,
    int? crawledChapters,
    String? content,
    BookAnalysis? analysis,
    String? updatedAt,
  }) {
    return ReferenceBook(
      id: id,
      title: title,
      sourceType: sourceType,
      sourceUrl: sourceUrl,
      filePath: filePath,
      author: author,
      crawlStatus: crawlStatus ?? this.crawlStatus,
      crawlProgress: crawlProgress ?? this.crawlProgress,
      totalChapters: totalChapters ?? this.totalChapters,
      crawledChapters: crawledChapters ?? this.crawledChapters,
      content: content ?? this.content,
      analysis: analysis ?? this.analysis,
      addedAt: addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source_type': sourceType.name,
        'source_url': sourceUrl,
        'file_path': filePath,
        'author': author,
        'crawl_status': crawlStatus.name,
        'crawl_progress': crawlProgress,
        'total_chapters': totalChapters,
        'crawled_chapters': crawledChapters,
        'content': content,
        'analysis': analysis.toJson(),
        'added_at': addedAt,
        'updated_at': updatedAt,
      };
}

// ─── 服务 ───

/// 拆书知识库服务
class ReferenceBookService {
  ReferenceBookService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
    http.Client? client,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider,
        _client = client ?? http.Client();

  final IProjectMetaRepository _metaRepository;
  final AIProvider _aiProvider;
  final http.Client _client;

  static const _indexFile = 'references_index.json';

  // ─── 1. CRUD ───

  /// 添加参考书（手动/URL/文件）
  Future<ReferenceBook> addBook(
    String projectId, {
    required String title,
    required ReferenceSourceType sourceType,
    String sourceUrl = '',
    String filePath = '',
    String author = '',
    String content = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    final book = ReferenceBook(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      sourceType: sourceType,
      sourceUrl: sourceUrl,
      filePath: filePath,
      author: author,
      content: content,
      addedAt: now,
      updatedAt: now,
    );

    final books = await listBooks(projectId);
    books.add(book);
    await _saveIndex(projectId, books);
    return book;
  }

  /// 列出项目所有参考书
  Future<List<ReferenceBook>> listBooks(String projectId) async {
    final data = await _metaRepository.read(projectId, _indexFile);
    if (data == null) return [];
    final list = data['books'] as List? ?? [];
    return list
        .map((e) => ReferenceBook.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取单本参考书
  Future<ReferenceBook?> getBook(String projectId, String bookId) async {
    final books = await listBooks(projectId);
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  /// 删除参考书
  Future<void> removeBook(String projectId, String bookId) async {
    final books = await listBooks(projectId);
    books.removeWhere((b) => b.id == bookId);
    await _saveIndex(projectId, books);
    // 同时删除分析文件
    try {
      await _metaRepository.delete(projectId, 'references/$bookId.json');
    } catch (_) {}
  }

  // ─── 2. 爬取（断点续爬） ───

  /// 开始/继续爬取
  ///
  /// 从 `book.crawledChapters` 处继续，支持断点续爬。
  /// [fetchChapter] 为可注入的爬取函数（便于测试）。
  Future<ReferenceBook> crawl({
    required String projectId,
    required String bookId,
    Future<String> Function(String url, int chapterIndex)? fetchChapter,
    int maxChapters = 100,
  }) async {
    final books = await listBooks(projectId);
    final idx = books.indexWhere((b) => b.id == bookId);
    if (idx < 0) throw ArgumentError('Book not found: $bookId');

    var book = books[idx];
    final effectiveFetch = fetchChapter ?? _defaultFetchChapter;

    // 标记为爬取中
    book = book.copyWith(
      crawlStatus: CrawlStatus.crawling,
      updatedAt: DateTime.now().toIso8601String(),
    );
    books[idx] = book;
    await _saveIndex(projectId, books);

    final contentBuffer = StringBuffer(book.content);
    final startChapter = book.crawledChapters;
    final endChapter = book.totalChapters > 0
        ? book.totalChapters
        : maxChapters;

    try {
      for (var i = startChapter; i < endChapter; i++) {
        final chapterContent =
            await effectiveFetch(book.sourceUrl, i);
        if (chapterContent.isEmpty) break;

        contentBuffer.writeln('\n--- 第${i + 1}章 ---');
        contentBuffer.writeln(chapterContent);

        // 每 5 章保存一次进度（断点）
        if ((i + 1) % 5 == 0) {
          book = book.copyWith(
            crawledChapters: i + 1,
            crawlProgress: endChapter > 0 ? (i + 1) / endChapter : 0,
            content: contentBuffer.toString(),
            updatedAt: DateTime.now().toIso8601String(),
          );
          books[idx] = book;
          await _saveIndex(projectId, books);
        }
      }

      // 完成
      book = book.copyWith(
        crawlStatus: CrawlStatus.completed,
        crawledChapters: endChapter,
        crawlProgress: 1,
        content: contentBuffer.toString(),
        updatedAt: DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // 失败时保存当前进度（断点）
      book = book.copyWith(
        crawlStatus: CrawlStatus.failed,
        content: contentBuffer.toString(),
        updatedAt: DateTime.now().toIso8601String(),
      );
    }

    books[idx] = book;
    await _saveIndex(projectId, books);
    return book;
  }

  // ─── 3. 四层深度分析 ───

  /// 对参考书执行四层深度分析
  ///
  /// 分析维度：风格 / 人物 / 情节 / 氛围
  /// 使用用户 API Key 的 LLM 完成。
  Future<BookAnalysis> analyze(String projectId, String bookId) async {
    final book = await getBook(projectId, bookId);
    if (book == null) throw ArgumentError('Book not found: $bookId');
    if (book.content.isEmpty) {
      throw StateError('Book has no content to analyze');
    }

    // 截取代表性文本（避免超 token）
    final sampleText = _selectSample(book.content);

    final style = await _analyzeDimension(sampleText, '风格', '''
分析以下小说文本的写作风格，包括：
- 句式特点（长短句比例、修辞手法）
- 用词偏好（文言/白话、雅/俗）
- 叙事视角和节奏
- 对话与描写比例
输出 200 字以内的风格总结。''');

    final characters = await _analyzeDimension(sampleText, '人物', '''
分析以下小说文本的人物塑造，包括：
- 主角性格特征和成长弧线
- 配角功能和关系网
- 对话风格与人物区分度
- 人物出场和描写手法
输出 200 字以内的人物分析。''');

    final plot = await _analyzeDimension(sampleText, '情节', '''
分析以下小说文本的情节结构，包括：
- 开篇钩子和节奏控制
- 冲突设置和升级模式
- 爽点/高潮分布密度
- 伏笔和悬念技巧
输出 200 字以内的情节分析。''');

    final atmosphere = await _analyzeDimension(sampleText, '氛围', '''
分析以下小说文本的氛围营造，包括：
- 环境描写手法
- 情绪渲染技巧
- 场景转换节奏
- 五感运用
输出 200 字以内的氛围分析。''');

    final analysis = BookAnalysis(
      style: style,
      characters: characters,
      plot: plot,
      atmosphere: atmosphere,
      analyzedAt: DateTime.now().toIso8601String(),
    );

    // 更新 book 并保存
    final books = await listBooks(projectId);
    final idx = books.indexWhere((b) => b.id == bookId);
    if (idx >= 0) {
      books[idx] = books[idx].copyWith(
        analysis: analysis,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _saveIndex(projectId, books);
    }

    // 单独保存分析结果
    await _metaRepository.write(
      projectId,
      'references/$bookId.json',
      analysis.toJson(),
    );

    return analysis;
  }

  // ─── 4. ContextAssembler 集成 ───

  /// 构建参考书上下文（供 ContextAssembler 注入）
  ///
  /// 将所有已分析参考书的核心发现汇总为 prompt 文本。
  Future<String> buildContextText(String projectId) async {
    final books = await listBooks(projectId);
    final analyzed =
        books.where((b) => b.analysis.isComplete).toList();
    if (analyzed.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('【参考书分析（拆书知识库）】');
    for (final book in analyzed.take(3)) {
      buffer.writeln();
      buffer.writeln('《${book.title}》${book.author.isNotEmpty ? ' — ${book.author}' : ''}');
      buffer.writeln('风格: ${_truncate(book.analysis.style, 100)}');
      buffer.writeln('人物: ${_truncate(book.analysis.characters, 100)}');
      buffer.writeln('情节: ${_truncate(book.analysis.plot, 100)}');
      buffer.writeln('氛围: ${_truncate(book.analysis.atmosphere, 100)}');
    }
    return buffer.toString();
  }

  // ─── 辅助方法 ───

  Future<void> _saveIndex(
      String projectId, List<ReferenceBook> books) async {
    await _metaRepository.write(projectId, _indexFile, {
      'books': books.map((b) => b.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// 默认爬取函数（HTTP GET 提取正文）
  Future<String> _defaultFetchChapter(String baseUrl, int chapterIndex) async {
    try {
      final uri = Uri.parse('$baseUrl/chapter/${chapterIndex + 1}');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        // 简单提取：去除 HTML 标签
        return response.body.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// 分析单个维度
  Future<String> _analyzeDimension(
      String text, String dimension, String instruction) async {
    try {
      final result = await _aiProvider.chatSync(
        messages: [
          ChatMessage(
              role: 'system',
              content: '你是文学分析专家，擅长小说$dimension分析。只输出分析结论。'),
          ChatMessage(
              role: 'user', content: '$instruction\n\n文本：\n$text'),
        ],
      );
      return result.trim();
    } catch (_) {
      return '';
    }
  }

  /// 选取代表性文本片段（前中后各取一段，总计约 8000 字）
  String _selectSample(String content) {
    if (content.length <= 8000) return content;
    final third = content.length ~/ 3;
    final part1 = content.substring(0, 2700);
    final part2 = content.substring(third, third + 2700);
    final part3 = content.substring(content.length - 2600);
    return '$part1\n\n[...中段...]\n\n$part2\n\n[...后段...]\n\n$part3';
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}…';
  }

  void dispose() {
    _client.close();
  }
}
