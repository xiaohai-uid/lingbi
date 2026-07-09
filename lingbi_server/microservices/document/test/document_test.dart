import 'dart:io';

import 'package:document/database_service.dart';
import 'package:document/document.dart';
import 'package:test/test.dart';

void main() {
  group('Document model', () {
    test('calculateWordCount should count Latin words', () {
      expect(Document.calculateWordCount('hello world'), 2);
      expect(Document.calculateWordCount('one two three four'), 4);
      expect(Document.calculateWordCount(''), 0);
      expect(Document.calculateWordCount('   '), 0);
    });

    test('calculateWordCount should count CJK characters', () {
      expect(Document.calculateWordCount('你好世界'), 4);
      expect(Document.calculateWordCount('这是一个测试'), 6);
    });

    test('calculateWordCount should handle mixed CJK and Latin', () {
      expect(Document.calculateWordCount('Hello 你好 World 世界'), 6);
      expect(Document.calculateWordCount('测试123'), 3); // 测试 = 2, "123" = 1 word
    });

    test('toJson and fromJson should round-trip', () {
      final original = Document(
        id: 'test-id-1',
        projectId: 'proj-1',
        title: 'Test Title',
        content: 'Hello 你好',
        wordCount: 4,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = original.toJson();
      final reconstructed = Document.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.projectId, original.projectId);
      expect(reconstructed.title, original.title);
      expect(reconstructed.content, original.content);
      expect(reconstructed.wordCount, original.wordCount);
      expect(reconstructed.createdAt, original.createdAt);
      expect(reconstructed.updatedAt, original.updatedAt);
    });

    test('copyWith should update only specified fields', () {
      final doc = Document(
        id: 'id-1',
        projectId: 'proj-1',
        title: 'Original Title',
        content: 'Original content',
        wordCount: 2,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updated = doc.copyWith(
        title: 'New Title',
        wordCount: 5,
      );

      expect(updated.id, 'id-1');
      expect(updated.title, 'New Title');
      expect(updated.content, 'Original content');
      expect(updated.wordCount, 5);
    });

    test('calculateWordCount should handle Markdown text', () {
      final markdown = '''
# Chapter 1
This is a paragraph with several words.
## Section 1.1
Another paragraph here.
''';
      // Words: #(1) Chapter(1) 1(1) This(1) is(1) a(1) paragraph(1) with(1)
      //   several(1) words(1) ##(1) Section(1) 1.1(1) Another(1)
      //   paragraph(1) here(1)
      // = 16 Latin words/symbols
      expect(Document.calculateWordCount(markdown), 16);
    });
  });

  group('DatabaseService', () {
    late DatabaseService service;
    final testDbPath = 'data/test_documents.db';

    setUp(() async {
      // Clean up any leftover test DB
      final testFile = File(testDbPath);
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
      final testDir = Directory('data');
      if (testDir.existsSync()) {
        // Remove all files
        for (var f in testDir.listSync()) {
          if (f is File && f.path.contains('test_documents')) {
            f.deleteSync();
          }
        }
      }

      // Create a fresh instance
      service = DatabaseService();
      // Override the internal db path by calling init first
      await service.init();
    });

    tearDown(() {
      service.close();
      // Clean up test database files
      final testFile = File(testDbPath);
      if (testFile.existsSync()) {
        testFile.deleteSync();
      }
      final walFile = File('$testDbPath-wal');
      if (walFile.existsSync()) {
        walFile.deleteSync();
      }
      final shmFile = File('$testDbPath-shm');
      if (shmFile.existsSync()) {
        shmFile.deleteSync();
      }
      // Also clean the data dir
      final dir = Directory('data');
      for (var f in dir.listSync()) {
        if (f is File && f.path.contains('documents')) {
          f.deleteSync();
        }
      }
    });

    test('should create and retrieve a document', () {
      final doc = Document(
        id: 'test-create-1',
        projectId: 'proj-1',
        title: 'Test Document',
        content: 'Hello World',
        wordCount: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      service.create(doc);
      final retrieved = service.getById('test-create-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Test Document');
      expect(retrieved.content, 'Hello World');
    });

    test('should return null for non-existent document', () {
      final retrieved = service.getById('non-existent-id');
      expect(retrieved, isNull);
    });

    test('should list all documents', () {
      final now = DateTime.now();
      final docs = [
        Document(
            id: 'list-1',
            projectId: 'proj-a',
            title: 'Doc A',
            content: 'a',
            wordCount: 1,
            createdAt: now,
            updatedAt: now),
        Document(
            id: 'list-2',
            projectId: 'proj-b',
            title: 'Doc B',
            content: 'b',
            wordCount: 1,
            createdAt: now,
            updatedAt: now),
        Document(
            id: 'list-3',
            projectId: 'proj-a',
            title: 'Doc C',
            content: 'c',
            wordCount: 1,
            createdAt: now,
            updatedAt: now),
      ];

      for (final d in docs) {
        service.create(d);
      }

      final allDocs = service.list();
      expect(allDocs.length, 3);

      final filteredDocs = service.list(projectId: 'proj-a');
      expect(filteredDocs.length, 2);
    });

    test('should update a document', () {
      final now = DateTime.now();
      final doc = Document(
        id: 'update-test-1',
        projectId: 'proj-1',
        title: 'Original Title',
        content: 'Original content',
        wordCount: 2,
        createdAt: now,
        updatedAt: now,
      );
      service.create(doc);

      final updated = service.update('update-test-1', title: 'Updated Title');
      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Title');
      expect(updated.content, 'Original content');

      // Also update content
      final updated2 =
          service.update('update-test-1', content: 'New content here');
      expect(updated2, isNotNull);
      expect(updated2!.content, 'New content here');
      expect(updated2.wordCount, 3);
    });

    test('should delete a document', () {
      final now = DateTime.now();
      final doc = Document(
        id: 'delete-test-1',
        projectId: 'proj-1',
        title: 'To Delete',
        content: 'bye',
        wordCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      service.create(doc);

      expect(service.getById('delete-test-1'), isNotNull);
      final deleted = service.delete('delete-test-1');
      expect(deleted, true);
      expect(service.getById('delete-test-1'), isNull);

      // Delete non-existent should return false
      expect(service.delete('non-existent'), false);
    });

    test('should search documents using FTS', () {
      final now = DateTime.now();
      final docs = [
        Document(
            id: 'search-1',
            projectId: 'proj-1',
            title: 'Flutter Introduction',
            content: 'Flutter is a UI toolkit for building applications.',
            wordCount: 9,
            createdAt: now,
            updatedAt: now),
        Document(
            id: 'search-2',
            projectId: 'proj-1',
            title: 'Dart Programming',
            content: 'Dart is the language used by Flutter.',
            wordCount: 8,
            createdAt: now,
            updatedAt: now),
        Document(
            id: 'search-3',
            projectId: 'proj-2',
            title: 'SQLite Database',
            content: 'SQLite is a lightweight database engine.',
            wordCount: 7,
            createdAt: now,
            updatedAt: now),
      ];

      for (final d in docs) {
        service.create(d);
      }

      // Search for "flutter"
      final results = service.search('flutter');
      expect(results.length, greaterThanOrEqualTo(2)); // title + content match

      // Search with project filter
      final filteredResults = service.search('flutter', projectId: 'proj-1');
      expect(filteredResults.length, greaterThanOrEqualTo(1));

      // Search with limit
      final limitedResults = service.search('flutter', limit: 1);
      expect(limitedResults.length, 1);
    });

    test('should extract Markdown outline', () {
      final now = DateTime.now();
      final doc = Document(
        id: 'outline-test-1',
        projectId: 'proj-1',
        title: 'Markdown Doc',
        content: '''# Chapter 1
Some text here.
## Section 1.1
More text.
### Subsection 1.1.1
Details.
# Chapter 2
Another chapter.
## Section 2.1
End text.''',
        wordCount: Document.calculateWordCount(
            '''# Chapter 1\nSome text here.\n## Section 1.1\nMore text.\n### Subsection 1.1.1\nDetails.\n# Chapter 2\nAnother chapter.\n## Section 2.1\nEnd text.'''),
        createdAt: now,
        updatedAt: now,
      );
      service.create(doc);

      final outline = service.getOutline('outline-test-1');
      expect(outline.entries.length, 5);
      expect(outline.entries[0].level, 1);
      expect(outline.entries[0].title, 'Chapter 1');
      expect(outline.entries[2].level, 3);
      expect(outline.entries[2].title, 'Subsection 1.1.1');

      // Non-existent doc should return empty outline
      final noDocOutline = service.getOutline('non-existent');
      expect(noDocOutline.entries.length, 0);
    });

    test('should compute document statistics', () {
      final now = DateTime.now();
      final doc = Document(
        id: 'stats-test-1',
        projectId: 'proj-1',
        title: 'Stats Test',
        content: '''# Title
This is a paragraph with some words.
## Subtitle
Another paragraph here.
### Detail
Third paragraph with more content.''',
        wordCount: 0, // Will be recalculated
        createdAt: now,
        updatedAt: now,
      );
      // Override wordCount with actual calculation
      final docWithStats =
          doc.copyWith(wordCount: Document.calculateWordCount(doc.content));
      service.create(docWithStats);

      final stats = service.getStats('stats-test-1');
      expect(stats.wordCount, greaterThan(0));
      expect(stats.headingCount, 3);
      expect(stats.paragraphCount, greaterThan(0));
      expect(stats.characterCount, greaterThan(0));

      // Non-existent doc should return zero stats
      final noStats = service.getStats('non-existent');
      expect(noStats.wordCount, 0);
      expect(noStats.headingCount, 0);
      expect(noStats.paragraphCount, 0);
      expect(noStats.characterCount, 0);
    });

    test('should handle empty search query', () {
      final results = service.search('');
      expect(results.length, 0);
    });
  });
}
