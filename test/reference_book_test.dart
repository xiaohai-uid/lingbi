/// 拆书知识库 + 参考书管理 — 单元测试
///
/// 覆盖：CRUD/断点续爬/四层分析/上下文注入
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/reference_book_service.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/core/ai/ai_provider.dart';

// ─── Mocks ───

class MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<Map<String, dynamic>?> read(
      String projectId, String fileName) async {
    return _store['$projectId/$fileName'];
  }

  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
    _store['$projectId/$fileName'] = data;
  }

  @override
  Future<List<String>> list(String projectId) async {
    return _store.keys
        .where((k) => k.startsWith('$projectId/'))
        .map((k) => k.replaceFirst('$projectId/', ''))
        .toList();
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    _store.remove('$projectId/$fileName');
  }

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
      String projectId, WorldConstitution constitution) async {}

  @override
  Future<String> getMetaDirPath(String projectId) async => '/mock/$projectId';
}

class MockAIProvider implements AIProvider {
  String mockResponse = '分析结果';

  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      mockResponse;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield mockResponse;
  }

  @override
  Future<List<double>> embed(String text) async => [0.1, 0.2, 0.3];
  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ReferenceBook 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      final book = ReferenceBook(
        id: 'ref_001',
        title: '斗破苍穹',
        sourceType: ReferenceSourceType.url,
        sourceUrl: 'https://example.com/novel',
        author: '天蚕土豆',
        crawlStatus: CrawlStatus.completed,
        crawlProgress: 1,
        totalChapters: 100,
        crawledChapters: 100,
        content: '内容...',
        analysis: const BookAnalysis(
          style: '热血风格',
          characters: '主角萧炎',
          plot: '升级流',
          atmosphere: '紧张刺激',
          analyzedAt: '2026-07-25',
        ),
        addedAt: '2026-07-25',
        updatedAt: '2026-07-25',
      );

      final json = book.toJson();
      final restored = ReferenceBook.fromJson(json);

      expect(restored.id, 'ref_001');
      expect(restored.title, '斗破苍穹');
      expect(restored.sourceType, ReferenceSourceType.url);
      expect(restored.crawlStatus, CrawlStatus.completed);
      expect(restored.analysis.style, '热血风格');
      expect(restored.analysis.isComplete, isTrue);
    });

    test('copyWith 正确更新字段', () {
      final book = ReferenceBook(
        id: 'ref_002',
        title: '测试',
        sourceType: ReferenceSourceType.file,
      );

      final updated = book.copyWith(
        crawlStatus: CrawlStatus.crawling,
        crawlProgress: 0.5,
        crawledChapters: 50,
      );

      expect(updated.crawlStatus, CrawlStatus.crawling);
      expect(updated.crawlProgress, 0.5);
      expect(updated.crawledChapters, 50);
      expect(updated.title, '测试'); // 未变
    });
  });

  group('BookAnalysis', () {
    test('isComplete 判断', () {
      const incomplete = BookAnalysis(style: '有', characters: '有');
      expect(incomplete.isComplete, isFalse);

      const complete = BookAnalysis(
        style: 'a',
        characters: 'b',
        plot: 'c',
        atmosphere: 'd',
      );
      expect(complete.isComplete, isTrue);
    });
  });

  group('ReferenceBookService CRUD', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late ReferenceBookService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = ReferenceBookService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('addBook + listBooks', () async {
      await service.addBook(
        'proj1',
        title: '参考书A',
        sourceType: ReferenceSourceType.manual,
        content: '手动录入内容',
      );
      await service.addBook(
        'proj1',
        title: '参考书B',
        sourceType: ReferenceSourceType.url,
        sourceUrl: 'https://example.com',
      );

      final books = await service.listBooks('proj1');
      expect(books.length, 2);
      expect(books[0].title, '参考书A');
      expect(books[1].title, '参考书B');
    });

    test('getBook 获取单本', () async {
      final added = await service.addBook(
        'proj1',
        title: '目标书',
        sourceType: ReferenceSourceType.manual,
      );

      final found = await service.getBook('proj1', added.id);
      expect(found, isNotNull);
      expect(found!.title, '目标书');
    });

    test('getBook 不存在返回 null', () async {
      final found = await service.getBook('proj1', 'nonexist');
      expect(found, isNull);
    });

    test('removeBook 删除', () async {
      final book = await service.addBook(
        'proj1',
        title: '待删除',
        sourceType: ReferenceSourceType.manual,
      );
      await service.removeBook('proj1', book.id);

      final books = await service.listBooks('proj1');
      expect(books, isEmpty);
    });
  });

  group('断点续爬', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late ReferenceBookService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = ReferenceBookService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('正常爬取完成', () async {
      final book = await service.addBook(
        'proj1',
        title: '爬取测试',
        sourceType: ReferenceSourceType.url,
        sourceUrl: 'https://novel.example.com',
      );

      // 设置总章节数
      final books = await service.listBooks('proj1');
      books[0] = books[0].copyWith(totalChapters: 10);
      await metaRepo.write('proj1', 'references_index.json', {
        'books': books.map((b) => b.toJson()).toList(),
      });

      final result = await service.crawl(
        projectId: 'proj1',
        bookId: book.id,
        fetchChapter: (url, idx) async => '第${idx + 1}章内容',
      );

      expect(result.crawlStatus, CrawlStatus.completed);
      expect(result.crawledChapters, 10);
      expect(result.crawlProgress, 1.0);
      expect(result.content, contains('第1章内容'));
      expect(result.content, contains('第10章内容'));
    });

    test('断点续爬从中断处继续', () async {
      final book = await service.addBook(
        'proj1',
        title: '断点测试',
        sourceType: ReferenceSourceType.url,
        sourceUrl: 'https://novel.example.com',
      );

      // 模拟已爬取 5 章
      final books = await service.listBooks('proj1');
      books[0] = books[0].copyWith(
        totalChapters: 10,
        crawledChapters: 5,
        crawlProgress: 0.5,
        content: '前5章内容',
        crawlStatus: CrawlStatus.failed,
      );
      await metaRepo.write('proj1', 'references_index.json', {
        'books': books.map((b) => b.toJson()).toList(),
      });

      final fetchedIndices = <int>[];
      final result = await service.crawl(
        projectId: 'proj1',
        bookId: book.id,
        fetchChapter: (url, idx) async {
          fetchedIndices.add(idx);
          return '第${idx + 1}章';
        },
      );

      // 应从第 5 章开始（index=5）
      expect(fetchedIndices.first, 5);
      expect(result.crawlStatus, CrawlStatus.completed);
      expect(result.content, contains('前5章内容'));
      expect(result.content, contains('第6章'));
    });

    test('爬取失败保存进度', () async {
      final book = await service.addBook(
        'proj1',
        title: '失败测试',
        sourceType: ReferenceSourceType.url,
        sourceUrl: 'https://novel.example.com',
      );

      final books = await service.listBooks('proj1');
      books[0] = books[0].copyWith(totalChapters: 20);
      await metaRepo.write('proj1', 'references_index.json', {
        'books': books.map((b) => b.toJson()).toList(),
      });

      var callCount = 0;
      final result = await service.crawl(
        projectId: 'proj1',
        bookId: book.id,
        fetchChapter: (url, idx) async {
          callCount++;
          if (callCount > 3) throw Exception('网络中断');
          return '内容$idx';
        },
      );

      expect(result.crawlStatus, CrawlStatus.failed);
      expect(result.content, isNotEmpty); // 已爬取内容保留
    });
  });

  group('四层深度分析', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late ReferenceBookService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = ReferenceBookService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('analyze 完成四维分析', () async {
      final book = await service.addBook(
        'proj1',
        title: '分析目标',
        sourceType: ReferenceSourceType.manual,
        content: '这是一段足够长的小说文本用于分析。' * 10,
      );

      aiProvider.mockResponse = '这是分析结果';
      final analysis = await service.analyze('proj1', book.id);

      expect(analysis.style, '这是分析结果');
      expect(analysis.characters, '这是分析结果');
      expect(analysis.plot, '这是分析结果');
      expect(analysis.atmosphere, '这是分析结果');
      expect(analysis.isComplete, isTrue);
    });

    test('analyze 无内容抛出异常', () async {
      final book = await service.addBook(
        'proj1',
        title: '空书',
        sourceType: ReferenceSourceType.manual,
      );

      expect(
        () => service.analyze('proj1', book.id),
        throwsA(isA<StateError>()),
      );
    });

    test('analyze 结果保存到 project_meta', () async {
      final book = await service.addBook(
        'proj1',
        title: '存储测试',
        sourceType: ReferenceSourceType.manual,
        content: '有内容的书',
      );

      await service.analyze('proj1', book.id);

      final saved =
          await metaRepo.read('proj1', 'references/${book.id}.json');
      expect(saved, isNotNull);
      expect(saved!['style'], isNotEmpty);
    });
  });

  group('ContextAssembler 集成', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late ReferenceBookService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = ReferenceBookService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('buildContextText 有分析结果时返回文本', () async {
      final book = await service.addBook(
        'proj1',
        title: '注入测试',
        sourceType: ReferenceSourceType.manual,
        content: '内容',
      );
      await service.analyze('proj1', book.id);

      final text = await service.buildContextText('proj1');
      expect(text, contains('参考书分析'));
      expect(text, contains('注入测试'));
    });

    test('buildContextText 无分析结果时返回空', () async {
      await service.addBook(
        'proj1',
        title: '未分析',
        sourceType: ReferenceSourceType.manual,
      );

      final text = await service.buildContextText('proj1');
      expect(text, isEmpty);
    });
  });
}
