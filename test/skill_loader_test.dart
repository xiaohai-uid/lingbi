import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/skill/data/skill/skill_loader.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

void main() {
  late Directory tempDir;
  late SkillActionService actionService;
  late SkillLoader loader;
  int notifyCount = 0;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('skill_loader_test_');
    actionService = SkillActionService();
    loader = SkillLoader(actionService);
    notifyCount = 0;
    actionService.addListener(() => notifyCount++);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// 辅助：在 tempDir 下创建一个 Skill 子目录（含 SKILL.md）
  Directory createSkillDir(String name, {String? skillMdContent, String? manifestYamlContent}) {
    final skillDir = Directory('${tempDir.path}/$name')..createSync();
    if (skillMdContent != null) {
      File('${skillDir.path}/SKILL.md').writeAsStringSync(skillMdContent);
    }
    if (manifestYamlContent != null) {
      File('${skillDir.path}/manifest.yaml').writeAsStringSync(manifestYamlContent);
    }
    return skillDir;
  }

  group('SkillLoader', () {
    test('空目录加载 → 注册 0 个 Skill', () async {
      final loaded = await loader.loadAll(tempDir.path);
      expect(loaded, 0);
      expect(actionService.registeredSkills, isEmpty);
    });

    test('单 Skill 加载 → registeredSkills 包含该 Skill', () async {
      createSkillDir('test-skill', skillMdContent: '''---
name: 测试技能
description: 一个测试用技能
---
这是 prompt 模板：{{input}}
''');

      final loaded = await loader.loadAll(tempDir.path);
      expect(loaded, 1);
      expect(actionService.registeredSkills.length, 1);
      final skill = actionService.getSkill('test-skill');
      expect(skill, isNotNull);
      expect(skill!.name, '测试技能');
      expect(skill.description, '一个测试用技能');
    });

    test('多 Skill 批量加载 → 全部注册', () async {
      createSkillDir('skill-a', skillMdContent: '''---
name: 技能A
description: A
---
prompt A
''');
      createSkillDir('skill-b', skillMdContent: '''---
name: 技能B
description: B
---
prompt B
''');
      createSkillDir('skill-c', skillMdContent: '''---
name: 技能C
description: C
---
prompt C
''');

      final loaded = await loader.loadAll(tempDir.path);
      expect(loaded, 3);
      expect(actionService.registeredSkills.length, 3);
      expect(actionService.getSkill('skill-a'), isNotNull);
      expect(actionService.getSkill('skill-b'), isNotNull);
      expect(actionService.getSkill('skill-c'), isNotNull);
    });

    test('损坏 SKILL.md 跳过 → 不崩溃', () async {
      // 空 SKILL.md
      createSkillDir('broken-skill', skillMdContent: '');
      // 正常 Skill
      createSkillDir('good-skill', skillMdContent: '''---
name: 好技能
description: 正常
---
prompt
''');

      final loaded = await loader.loadAll(tempDir.path);
      expect(loaded, 1);
      expect(actionService.registeredSkills.length, 1);
      expect(actionService.getSkill('good-skill'), isNotNull);
    });

    test('带 manifest.yaml 的重量 Skill → 解析权限', () async {
      createSkillDir('heavy-skill', skillMdContent: '''---
name: 重量技能
description: 带权限的技能
---
prompt
''', manifestYamlContent: '''
requires:
  - canon.read
  - canon.write
  - document.read
''');

      final loaded = await loader.loadAll(tempDir.path);
      expect(loaded, 1);
      final skill = actionService.getSkill('heavy-skill');
      expect(skill, isNotNull);
    });

    test('unloadSingle → 从 registeredSkills 移除', () async {
      createSkillDir('to-remove', skillMdContent: '''---
name: 待移除
description: 将被卸载
---
prompt
''');

      await loader.loadAll(tempDir.path);
      expect(actionService.registeredSkills.length, 1);

      loader.unloadSingle('to-remove');
      expect(actionService.registeredSkills, isEmpty);
      expect(actionService.getSkill('to-remove'), isNull);
    });

    test('loadAll 批量注册触发 notifyListeners', () async {
      createSkillDir('skill-x', skillMdContent: '''---
name: X
description: x
---
prompt
''');
      createSkillDir('skill-y', skillMdContent: '''---
name: Y
description: y
---
prompt
''');

      // 方案A：每次 registerSkill 都 notify，2 个 Skill → 2 次
      await loader.loadAll(tempDir.path);
      expect(notifyCount, 2);
    });

    test('不存在的目录 → 返回 0', () async {
      final loaded = await loader.loadAll('${tempDir.path}/nonexistent');
      expect(loaded, 0);
    });

    test('子目录无 SKILL.md → 跳过', () async {
      // 创建一个不含 SKILL.md 的目录
      Directory('${tempDir.path}/no-skill').createSync();

      final loaded = await loader.loadAll(tempDir.path);
      expect(loaded, 0);
    });
  });
}
