import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/skill/skill_manifest.dart';

void main() {
  group('SkillManifestParser', () {
    test('解析含 Anthropic frontmatter 的 SKILL.md', () {
      const content = '''---
name: test-skill
description: A test skill
---

This is the prompt template body.
''';
      final manifest = SkillManifestParser.parse(content, 'test-skill');
      expect(manifest.name, 'test-skill');
      expect(manifest.description, 'A test skill');
      expect(manifest.promptTemplate, contains('prompt template'));
      expect(manifest.id, 'test-skill');
    });

    test('解析纯 Markdown 格式的 SKILL.md', () {
      const content = '''# 伏笔管理器

> 管理和追踪小说中的伏笔线索

## 适用场景
- 需要追踪伏笔时
''';
      final manifest =
          SkillManifestParser.parse(content, 'foreshadow-manager');
      expect(manifest.name, '伏笔管理器');
      expect(manifest.description, '管理和追踪小说中的伏笔线索');
      expect(manifest.promptTemplate, contains('适用场景'));
    });

    test('空内容抛出 FormatException', () {
      expect(
        () => SkillManifestParser.parse('', 'test'),
        throwsFormatException,
      );
    });

    test('缺少标题行的纯 Markdown 抛出 FormatException', () {
      expect(
        () => SkillManifestParser.parse('没有标题的内容', 'test'),
        throwsFormatException,
      );
    });

    test('默认 type 为 lightweight', () {
      const content = '# Test\n> desc\nbody';
      final manifest = SkillManifestParser.parse(content, 'test');
      expect(manifest.type, SkillType.lightweight);
    });
  });
}
