import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/models/codex_entry.dart';
import 'package:lingbi/utils/markdown_helper.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/services/quota_service.dart';

void main() {
  group('Project', () {
    test('creates with default values', () {
      final project = Project(name: 'Test', directoryPath: '/test');
      expect(project.name, 'Test');
      expect(project.description, '');
      expect(project.id.isNotEmpty, true);
    });

    test('serializes to/from JSON', () {
      final project = Project(
        id: 'test-id',
        name: '我的小说',
        description: '一本小说',
        directoryPath: '/docs/novel',
      );
      final json = project.toJson();
      final restored = Project.fromJson(json);
      expect(restored.id, 'test-id');
      expect(restored.name, '我的小说');
      expect(restored.directoryPath, '/docs/novel');
    });

    test('toJson contains all fields', () {
      final project = Project(name: 'Test', directoryPath: '/test');
      final json = project.toJson();
      expect(json.containsKey('id'), true);
      expect(json.containsKey('name'), true);
      expect(json.containsKey('createdAt'), true);
      expect(json.containsKey('updatedAt'), true);
    });
  });

  group('Document', () {
    test('creates with default values', () {
      final doc = Document(
        projectId: 'proj-1',
        title: '第1章',
        filePath: '/docs/ch1.md',
      );
      expect(doc.projectId, 'proj-1');
      expect(doc.wordCount, 0);
    });

    test('serializes to/from JSON', () {
      final doc = Document(
        id: 'doc-1',
        projectId: 'proj-1',
        title: '第1章',
        filePath: '/docs/ch1.md',
        wordCount: 500,
      );
      final json = doc.toJson();
      final restored = Document.fromJson(json);
      expect(restored.id, 'doc-1');
      expect(restored.title, '第1章');
      expect(restored.wordCount, 500);
    });

    test('updatedAt changes on save', () {
      final doc = Document(
        projectId: 'proj-1',
        title: '测试',
        filePath: '/docs/test.md',
      );
      final original = doc.updatedAt;
      doc.updatedAt = DateTime.now().add(const Duration(hours: 1));
      expect(doc.updatedAt.isAfter(original), true);
    });
  });

  group('CodexEntry', () {
    test('creates with default type and UUID', () {
      final entry = CodexEntry(
        projectId: 'proj-1',
        name: '张三',
        type: CodexEntryType.character,
      );
      expect(entry.projectId, 'proj-1');
      expect(entry.name, '张三');
      expect(entry.type, CodexEntryType.character);
      expect(entry.id.isNotEmpty, true);
    });

    test('serializes to/from JSON', () {
      final entry = CodexEntry(
        projectId: 'proj-1',
        name: '长安城',
        type: CodexEntryType.location,
        description: '唐朝都城',
      );
      final json = entry.toJson();
      final restored = CodexEntry.fromJson(json);
      expect(restored.name, '长安城');
      expect(restored.type, CodexEntryType.location);
      expect(restored.description, '唐朝都城');
    });

    test('CodexEntryType enum has all values', () {
      expect(CodexEntryType.values.length, 4);
      expect(CodexEntryType.values.contains(CodexEntryType.character), true);
      expect(CodexEntryType.values.contains(CodexEntryType.location), true);
      expect(CodexEntryType.values.contains(CodexEntryType.lore), true);
      expect(CodexEntryType.values.contains(CodexEntryType.plotNode), true);
    });
  });

  group('QuotaService', () {
    test('singleton instance works', () {
      final instance = QuotaService();
      expect(instance, isNotNull);
    });

    test('daily limit is positive', () {
      expect(QuotaService().dailyLimit, greaterThan(0));
    });
  });

  group('MarkdownHelper', () {
    test('extracts headings', () {
      const content = '# Title\n\nSome text\n## Subtitle\n\nMore text\n### Subsub';
      final headings = MarkdownHelper.extractHeadings(content);
      expect(headings, ['Title', 'Subtitle', 'Subsub']);
    });

    test('extracts title from H1', () {
      const content = '# My Doc\n\nContent here';
      expect(MarkdownHelper.extractTitle(content), 'My Doc');
    });

    test('builds outline', () {
      const content = '# H1\n\n## H2\n\n### H3';
      final outline = MarkdownHelper.buildOutline(content);
      expect(outline.length, 3);
      expect(outline[0].level, 1);
      expect(outline[1].level, 2);
      expect(outline[2].level, 3);
    });
  });

  group('FileService', () {
    test('countWords counts mixed Chinese/English correctly', () {
      final service = FileService();
      expect(service.countWords(''), 0);
      expect(service.countWords('Hello World'), 2);
      expect(service.countWords('你好世界'), 4);
      expect(service.countWords('Hello 你好 World 世界'), 6);
      expect(service.countWords('测试 sentence。'), 4);
    });
  });
}