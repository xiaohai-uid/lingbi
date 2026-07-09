import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/world.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/models/canon_entry.dart';
import 'package:lingbi/utils/markdown_helper.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/services/quota_service.dart';

void main() {
  group('World', () {
    test('creates with default values', () {
      final world = World(name: 'Test');
      expect(world.name, 'Test');
      expect(world.description, '');
      expect(world.id.isNotEmpty, true);
    });

    test('serializes to/from JSON', () {
      final world = World(
        id: 'test-id',
        name: '我的小说',
        description: '一本小说',
      );
      final json = world.toJson();
      final restored = World.fromJson(json);
      expect(restored.id, 'test-id');
      expect(restored.name, '我的小说');
      expect(restored.description, '一本小说');
    });

    test('toJson contains all fields', () {
      final world = World(name: 'Test');
      final json = world.toJson();
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

  group('CanonEntry', () {
    test('creates Character with defaults', () {
      final entry = Character(
        worldId: 'proj-1',
        name: '张三',
      );
      expect(entry.worldId, 'proj-1');
      expect(entry.name, '张三');
      expect(entry.type, CanonType.character);
      expect(entry.id.isNotEmpty, true);
    });

    test('serializes Location to/from JSON', () {
      final entry = Location(
        id: 'test-id',
        worldId: 'proj-1',
        name: '长安城',
        description: '唐朝都城',
      );
      final json = entry.toJson();
      final restored = Location.fromJson(json);
      expect(restored.name, '长安城');
      expect(restored.type, CanonType.location);
      expect(restored.description, '唐朝都城');
    });

    test('CanonType enum has all values', () {
      expect(CanonType.values.length, 4);
      expect(CanonType.values.contains(CanonType.character), true);
      expect(CanonType.values.contains(CanonType.location), true);
      expect(CanonType.values.contains(CanonType.lore), true);
      expect(CanonType.values.contains(CanonType.worldRule), true);
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
      const content =
          '# Title\n\nSome text\n## Subtitle\n\nMore text\n### Subsub';
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
