/// 批次3 端到端测试 — Store 联动 + 蒸馏
///
/// 验证：
/// 1. SkillMarketplace 安装/卸载事件流正确发射
/// 2. SkillLoader 监听事件后实时注册/注销 Skill
/// 3. DistillationService 蒸馏流程（Canon + 风格 → SKILL.md）
/// 4. notifyInstalled 触发 SkillLoader 自动加载
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/services/skill/skill_loader.dart';
import 'package:lingbi/services/skill/skill_manifest.dart';
import 'package:lingbi/services/skill/distillation_service.dart';
import 'package:lingbi/services/skill_action_service.dart';
import 'package:lingbi/services/skill_marketplace.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  // 1. SkillMarketplace 事件流
  // ═══════════════════════════════════════════════════════
  group('SkillMarketplace 事件流', () {
    late SkillMarketplace marketplace;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('skill_market_test_');
      marketplace = SkillMarketplace();
    });

    tearDown(() async {
      marketplace.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('install 成功后发射 installed 事件', () async {
      // 准备：创建一个本地 community/skills 目录模拟
      final skillDir = Directory('${tempDir.path}/test-skill');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: test-skill
description: A test skill
---
Hello input
''');

      final events = <SkillMarketEvent>[];
      marketplace.events.listen(events.add);

      // 使用 notifyInstalled 模拟安装完成
      marketplace.notifyInstalled('test-skill');

      // 等待事件传播
      await Future.delayed(const Duration(milliseconds: 50));

      expect(events.length, 1);
      expect(events.first.type, SkillMarketEventType.installed);
      expect(events.first.skillId, 'test-skill');
    });

    test('uninstall 成功后发射 uninstalled 事件', () async {
      final events = <SkillMarketEvent>[];
      marketplace.events.listen(events.add);

      // 先标记为已安装
      marketplace.notifyInstalled('my-skill');
      await Future.delayed(const Duration(milliseconds: 50));

      // 卸载（目录不存在也不会报错）
      final result = await marketplace.uninstall('my-skill');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(result, true);
      expect(events.length, 2);
      expect(events[1].type, SkillMarketEventType.uninstalled);
      expect(events[1].skillId, 'my-skill');
    });

    test('notifyInstalled 更新 isInstalled 状态', () {
      expect(marketplace.isInstalled('new-skill'), false);
      marketplace.notifyInstalled('new-skill');
      expect(marketplace.isInstalled('new-skill'), true);
    });

    test('事件流是 broadcast 支持多订阅者', () async {
      final events1 = <SkillMarketEvent>[];
      final events2 = <SkillMarketEvent>[];
      marketplace.events.listen(events1.add);
      marketplace.events.listen(events2.add);

      marketplace.notifyInstalled('multi-listener-skill');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(events1.length, 1);
      expect(events2.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 2. SkillLoader 实时刷新（Store ↔ Runtime 联动）
  // ═══════════════════════════════════════════════════════
  group('SkillLoader 实时刷新', () {
    late SkillActionService actionService;
    late SkillLoader loader;
    late SkillMarketplace marketplace;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('skill_loader_test_');
      actionService = SkillActionService();
      loader = SkillLoader(actionService);
      marketplace = SkillMarketplace();
    });

    tearDown(() async {
      loader.dispose();
      marketplace.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadAll 加载目录中的 Skill', () async {
      // 创建一个 Skill 目录
      final skillDir = Directory('${tempDir.path}/my-writing-skill');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: 写作助手
description: 帮助写作
---
请根据 input 续写。
''');

      final count = await loader.loadAll(tempDir.path);
      expect(count, 1);
      expect(actionService.getSkill('my-writing-skill'), isNotNull);
      expect(actionService.getSkill('my-writing-skill')!.name, '写作助手');
    });

    test('监听 Marketplace 事件 — 安装后自动注册', () async {
      // 先 loadAll 设置 _installDir
      await loader.loadAll(tempDir.path);
      loader.listenToMarketplace(marketplace);

      // 模拟：先写文件到磁盘，再触发事件
      final skillDir = Directory('${tempDir.path}/new-skill');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: 新技能
description: 刚安装的技能
---
分析 input 的风格。
''');

      // 触发安装事件
      marketplace.notifyInstalled('new-skill');

      // 等待异步加载完成
      await Future.delayed(const Duration(milliseconds: 200));

      expect(actionService.getSkill('new-skill'), isNotNull);
      expect(actionService.getSkill('new-skill')!.name, '新技能');
    });

    test('监听 Marketplace 事件 — 卸载后自动注销', () async {
      // 先创建一个 Skill 并加载
      final skillDir = Directory('${tempDir.path}/removable-skill');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: 可移除技能
description: 将被卸载
---
Hello input
''');
      await loader.loadAll(tempDir.path);
      loader.listenToMarketplace(marketplace);

      expect(actionService.getSkill('removable-skill'), isNotNull);

      // 触发卸载事件
      await marketplace.uninstall('removable-skill');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(actionService.getSkill('removable-skill'), isNull);
    });

    test('loadAll 记住 installDir 供后续 reload 使用', () async {
      await loader.loadAll(tempDir.path);

      // 写入新 Skill 后通过事件触发加载
      loader.listenToMarketplace(marketplace);
      final skillDir = Directory('${tempDir.path}/delayed-skill');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
# 延迟加载

> 通过事件触发加载

使用 input 生成内容。
''');

      marketplace.notifyInstalled('delayed-skill');
      await Future.delayed(const Duration(milliseconds: 200));

      expect(actionService.getSkill('delayed-skill'), isNotNull);
      expect(actionService.getSkill('delayed-skill')!.name, '延迟加载');
    });

    test('单个 Skill 加载失败不阻断其他', () async {
      // 一个有效 + 一个无效
      final goodDir = Directory('${tempDir.path}/good-skill');
      await goodDir.create(recursive: true);
      await File('${goodDir.path}/SKILL.md').writeAsString('''
---
name: 好的技能
description: 正常
---
Prompt here.
''');

      final badDir = Directory('${tempDir.path}/bad-skill');
      await badDir.create(recursive: true);
      await File('${badDir.path}/SKILL.md').writeAsString(''); // 空文件会抛异常

      final count = await loader.loadAll(tempDir.path);
      expect(count, 1);
      expect(actionService.getSkill('good-skill'), isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 3. DistillationService 单元测试
  // ═══════════════════════════════════════════════════════
  group('DistillationService', () {
    test('DistillationConfig 默认值正确', () {
      const config = DistillationConfig(
        projectId: 'p1',
        projectName: '测试项目',
      );
      expect(config.projectId, 'p1');
      expect(config.projectName, '测试项目');
      expect(config.documentPaths, isEmpty);
      expect(config.maxSampleChars, 6000);
      expect(config.skillName, '');
    });

    test('DistillationResult 成功状态', () {
      const result = DistillationResult(
        success: true,
        skillId: 'my-style',
        skillName: '我的风格',
        skillMdContent: '---\nname: test\n---\nbody',
      );
      expect(result.success, true);
      expect(result.skillId, 'my-style');
      expect(result.error, isNull);
    });

    test('DistillationResult 失败状态', () {
      const result = DistillationResult(
        success: false,
        error: '没有可用的素材',
      );
      expect(result.success, false);
      expect(result.error, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 4. 端到端：安装 → 斜杠命令可用 → 卸载 → 不可用
  // ═══════════════════════════════════════════════════════
  group('端到端：Store → Runtime → 斜杠命令', () {
    late SkillActionService actionService;
    late SkillLoader loader;
    late SkillMarketplace marketplace;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('e2e_store_test_');
      actionService = SkillActionService()..initializeBuiltinSkills();
      loader = SkillLoader(actionService);
      marketplace = SkillMarketplace();
    });

    tearDown(() async {
      loader.dispose();
      marketplace.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('安装社区 Skill → 斜杠命令中立即可用', () async {
      // 初始加载
      await loader.loadAll(tempDir.path);
      loader.listenToMarketplace(marketplace);

      // 初始只有 3 个内置技能
      final initialSkills = actionService.searchSkills('');
      expect(initialSkills.length, 3);

      // 模拟从 Store 安装一个社区 Skill
      final skillDir = Directory('${tempDir.path}/foreshadow-manager');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: 伏笔管理器
description: 管理小说中的伏笔和回收
---
请分析以下文本中的伏笔线索，并给出回收建议。

input

canon_summary
''');

      // 触发安装事件（模拟 SkillMarketplace.install 完成后的通知）
      marketplace.notifyInstalled('foreshadow-manager');
      await Future.delayed(const Duration(milliseconds: 200));

      // 验证：斜杠命令搜索能找到
      final searchResult = actionService.searchSkills('伏笔');
      expect(searchResult.length, 1);
      expect(searchResult.first.name, '伏笔管理器');
      expect(searchResult.first.id, 'foreshadow-manager');

      // 验证：总数变为 4
      expect(actionService.registeredSkills.length, 4);
    });

    test('卸载 Skill → 斜杠命令中立即消失', () async {
      // 先安装
      final skillDir = Directory('${tempDir.path}/temp-skill');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: 临时技能
description: 将被卸载
---
Prompt.
''');
      await loader.loadAll(tempDir.path);
      loader.listenToMarketplace(marketplace);

      expect(actionService.searchSkills('临时').length, 1);

      // 卸载
      await marketplace.uninstall('temp-skill');
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证：搜索不到了
      expect(actionService.searchSkills('临时').length, 0);
      expect(actionService.getSkill('temp-skill'), isNull);
    });

    test('DynamicPromptSkill 执行 — 占位符替换正确', () async {
      final skillDir = Directory('${tempDir.path}/style-skill');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: 风格模仿
description: 模仿特定风格续写
---
请以以下风格续写：

【前文】
input

【世界观】
canon_summary
''');

      await loader.loadAll(tempDir.path);
      final skill = actionService.getSkill('style-skill') as DynamicPromptSkill;

      final result = skill.execute(
        context: const SkillContext(
          selectedText: '月光洒在古老的城墙上。',
          canonSummary: '角色：林远，性格坚韧。',
        ),
      );

      expect(result.success, true);
      expect(result.promptForAI, contains('月光洒在古老的城墙上。'));
      expect(result.promptForAI, contains('角色：林远，性格坚韧。'));
    });

    test('SkillActionService notifyListeners 在注册时触发', () async {
      int notifyCount = 0;
      actionService.addListener(() => notifyCount++);

      final skillDir = Directory('${tempDir.path}/notify-test');
      await skillDir.create(recursive: true);
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: 通知测试
description: test
---
Prompt.
''');

      await loader.loadAll(tempDir.path);
      // loadAll 内部 registerSkill 会触发 notifyListeners
      expect(notifyCount, greaterThan(0));
    });
  });

  // ═══════════════════════════════════════════════════════
  // 5. SkillManifest 解析（蒸馏生成的格式）
  // ═══════════════════════════════════════════════════════
  group('蒸馏生成的 SKILL.md 格式解析', () {
    test('标准 frontmatter 格式可被正确解析', () {
      const content = '''
---
name: 玄幻风格
description: 基于《星辰变》蒸馏的写作风格技能
---
你是一位玄幻小说作家。请模仿以下风格续写：

【风格特征】
- 句式：短句为主，节奏明快
- 用词：古风与现代混搭
- 修辞：大量比喻和夸张

【世界观参考】
canon_summary

【前文】
input

请直接输出续写正文。
''';

      final manifest = SkillManifestParser.parse(content, 'xuanhuan-style');
      expect(manifest.name, '玄幻风格');
      expect(manifest.description, contains('星辰变'));
      expect(manifest.promptTemplate, contains('canon_summary'));
      expect(manifest.promptTemplate, contains('input'));
      expect(manifest.type, SkillType.lightweight);
    });

    test('纯 Markdown 格式（无 frontmatter）也可解析', () {
      const content = '''
# 我的写作风格

> 从我的作品蒸馏而来

## 风格指令

请模仿以下风格续写 input：
- 细腻的心理描写
- 短句交替长句
''';

      final manifest = SkillManifestParser.parse(content, 'my-style');
      expect(manifest.name, '我的写作风格');
      expect(manifest.description, '从我的作品蒸馏而来');
      expect(manifest.promptTemplate, contains('input'));
    });
  });
}
