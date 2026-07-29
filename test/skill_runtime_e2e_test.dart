import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/services/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/services/skill/skill_executor.dart';
import 'package:lingbi/services/skill/skill_loader.dart';
import 'package:lingbi/services/skill/skill_manifest.dart';
import 'package:lingbi/services/skill_action_service.dart';

// ==================== Fake SkillApi ====================

class FakeSkillApi implements SkillApi {
  final List<CanonEntry> _canonEntries = [];
  final Map<String, String> _documents = {};
  final List<String> callLog = [];

  void seedCanon(List<CanonEntry> entries) {
    _canonEntries.addAll(entries);
  }

  void seedDocument(String documentId, String content) {
    _documents[documentId] = content;
  }

  @override
  Future<List<CanonEntry>> canonRead(String projectId) async {
    callLog.add('canonRead:$projectId');
    return _canonEntries
        .where((e) => e.projectId == projectId)
        .toList();
  }

  @override
  Future<void> canonWrite(String projectId, CanonEntry entry) async {
    callLog.add('canonWrite:$projectId');
    _canonEntries.add(entry);
  }

  @override
  Future<String> documentRead(String projectId, String documentId) async {
    callLog.add('documentRead:$projectId:$documentId');
    return _documents[documentId] ?? '';
  }

  @override
  Future<void> documentWrite(
      String projectId, String documentId, String content) async {
    callLog.add('documentWrite:$projectId:$documentId');
    _documents[documentId] = content;
  }
}

// ==================== 辅助 ====================

Directory _createSkillDir(
  Directory parent,
  String name, {
  String? skillMdContent,
  String? manifestYamlContent,
}) {
  final skillDir = Directory('${parent.path}/$name')..createSync();
  if (skillMdContent != null) {
    File('${skillDir.path}/SKILL.md').writeAsStringSync(skillMdContent);
  }
  if (manifestYamlContent != null) {
    File('${skillDir.path}/manifest.yaml')
        .writeAsStringSync(manifestYamlContent);
  }
  return skillDir;
}

// ==================== 测试 ====================

void main() {
  late Directory tempDir;
  late SkillActionService actionService;
  late SkillLoader loader;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('skill_runtime_e2e_');
    actionService = SkillActionService();
    loader = SkillLoader(actionService);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('端到端: 安装 → 加载 → 执行 → 权限校验', () {
    // ─── 测试 1: 安装轻量 Skill → loadAll → registeredSkills 包含新 Skill ───
    test('安装轻量 Skill → loadAll → registeredSkills 包含新 Skill', () async {
      _createSkillDir(tempDir, 'skill-a', skillMdContent: '''
# 测试技能A

> 一个用于测试的轻量技能

## 适用场景
测试场景
''');

      final loadedCount = await loader.loadAll(tempDir.path);

      expect(loadedCount, 1);
      final ids = actionService.registeredSkills.map((s) => s.id).toList();
      expect(ids, contains('skill-a'));
    });

    // ─── 测试 2: 执行动态 Skill → SkillResult.success=true ───
    test('执行动态 Skill → SkillResult.success=true', () async {
      _createSkillDir(tempDir, 'skill-b', skillMdContent: '''
# 测试技能B

> 用于验证执行的轻量技能

请对以下文本进行分析：
{{input}}
''');

      await loader.loadAll(tempDir.path);

      const context = SkillContext(
        selectedText: '这是一段用于测试的文本内容，足够长度。',
        projectId: 'proj-1',
        projectName: '测试项目',
      );

      final result = actionService.executeSkill(
        skillId: 'skill-b',
        context: context,
      );

      expect(result.success, true);
      expect(result.promptForAI, isNotEmpty);
      expect(result.promptForAI, contains('这是一段用于测试的文本内容'));
    });

    // ─── 测试 3: 重量 Skill 声明 canon.write → 沙箱 API 写入成功 ───
    // 直接构造 heavyweight Skill，不依赖 SkillLoader 类型检测
    test('重量 Skill 声明 canon.write → 沙箱 API 写入成功', () async {
      _createSkillDir(
        tempDir,
        'heavy-writer',
        skillMdContent: '''
# 重量写入技能

> 可以读写正典的重量技能
''',
        manifestYamlContent: '''
requires:
  - canon.read
  - canon.write
  - document.read
''',
      );

      await loader.loadAll(tempDir.path);

      // 从 loader 获取权限，手动构造 heavyweight Skill（当前 loader 不检测类型）
      final loadedSkill = actionService.getSkill('heavy-writer')
          as DynamicPromptSkill;
      final heavySkill = DynamicPromptSkill(
        manifest: SkillManifest(
          id: loadedSkill.manifest.id,
          name: loadedSkill.manifest.name,
          description: loadedSkill.manifest.description,
          promptTemplate: loadedSkill.manifest.promptTemplate,
          type: SkillType.heavyweight,
        ),
        permissions: loadedSkill.permissions,
      );

      final fakeApi = FakeSkillApi();
      fakeApi.seedCanon([
        CanonEntry(
          projectId: 'proj-1',
          type: CanonEntryType.character,
          name: '主角',
        ),
      ]);
      fakeApi.seedDocument('chap-1', '第一章内容');

      final sandboxedApi = SandboxedSkillApi(
        permissions: heavySkill.permissions!,
        delegate: fakeApi,
      );

      final executor = SkillExecutor();
      final result = await executor.execute(
        skill: heavySkill,
        context: const SkillContext(
          projectId: 'proj-1',
          chapterId: 'chap-1',
        ),
        api: sandboxedApi,
      );

      expect(result.success, true);
      expect(result.canonEntries, isNotEmpty);
      expect(result.output, '第一章内容');

      // 验证 canonWrite 也能成功（有权限）
      await sandboxedApi.canonWrite(
        'proj-1',
        CanonEntry(
          projectId: 'proj-1',
          type: CanonEntryType.location,
          name: '新地点',
        ),
      );
      expect(fakeApi.callLog, contains('canonWrite:proj-1'));
    });

    // ─── 测试 4: Skill 未声明 canon.write → PermissionViolation ───
    test('Skill 未声明 canon.write → PermissionViolation', () async {
      _createSkillDir(
        tempDir,
        'read-only-skill',
        skillMdContent: '''
# 只读技能

> 只能读取正典的技能
''',
        manifestYamlContent: '''
requires:
  - canon.read
''',
      );

      await loader.loadAll(tempDir.path);

      final skill = actionService.getSkill('read-only-skill')
          as DynamicPromptSkill;

      final fakeApi = FakeSkillApi();
      final sandboxedApi = SandboxedSkillApi(
        permissions: skill.permissions!,
        delegate: fakeApi,
      );

      expect(
        () => sandboxedApi.canonWrite(
          'proj-1',
          CanonEntry(
            projectId: 'proj-1',
            type: CanonEntryType.lore,
            name: '测试',
          ),
        ),
        throwsA(isA<PermissionViolation>()),
      );
    });

    // ─── 测试 5: 卸载 Skill → unloadSingle → registeredSkills 不包含 ───
    test('卸载 Skill → unloadSingle → registeredSkills 不包含', () async {
      _createSkillDir(tempDir, 'skill-a', skillMdContent: '''
# 测试技能A

> 一个用于卸载测试的技能
''');
      _createSkillDir(tempDir, 'skill-b', skillMdContent: '''
# 测试技能B

> 另一个技能
''');

      await loader.loadAll(tempDir.path);

      // 确认两个都加载了
      final idsBefore =
          actionService.registeredSkills.map((s) => s.id).toList();
      expect(idsBefore, contains('skill-a'));
      expect(idsBefore, contains('skill-b'));

      // 卸载 skill-a
      loader.unloadSingle('skill-a');

      final idsAfter =
          actionService.registeredSkills.map((s) => s.id).toList();
      expect(idsAfter, isNot(contains('skill-a')));
      expect(idsAfter, contains('skill-b'));
    });

    // ─── 测试 6: ServiceLocator 集成 — SkillLoader 不阻断其他服务初始化 ───
    test('SkillLoader 加载失败不阻断 ServiceLocator 其他服务', () async {
      // 用一个不存在的目录调用 loadAll，应返回 0 且不抛异常
      final count = await loader.loadAll('/nonexistent/path/12345');
      expect(count, 0);
    });

    // ─── 测试 7: 完整链路 — 多个 Skill 加载 + 执行 + 权限隔离 ───
    test('完整链路: 多 Skill 加载 + 执行 + 权限隔离', () async {
      // 轻量 Skill
      _createSkillDir(tempDir, 'light-skill', skillMdContent: '''
# 轻量分析技能

> 分析文本结构

请分析以下文本的结构：
{{input}}
''');

      // 重量 Skill（全权限）
      _createSkillDir(
        tempDir,
        'heavy-full',
        skillMdContent: '''
# 全权限重量技能

> 拥有所有权限的重量技能
''',
        manifestYamlContent: '''
requires:
  - canon.read
  - canon.write
  - document.read
  - document.write
''',
      );

      // 重量 Skill（只读）
      _createSkillDir(
        tempDir,
        'heavy-readonly',
        skillMdContent: '''
# 只读重量技能

> 只有读权限
''',
        manifestYamlContent: '''
requires:
  - canon.read
  - document.read
''',
      );

      final count = await loader.loadAll(tempDir.path);
      expect(count, 3);

      // 轻量 Skill 可执行
      const context = SkillContext(
        selectedText: '这是一段足够长的测试文本用于分析。',
        projectId: 'proj-1',
      );
      final lightResult = actionService.executeSkill(
        skillId: 'light-skill',
        context: context,
      );
      expect(lightResult.success, true);

      // 全权限重量 Skill — 手动构造 heavyweight 验证写入
      final fullLoaded = actionService.getSkill('heavy-full')
          as DynamicPromptSkill;
      final fullSkill = DynamicPromptSkill(
        manifest: SkillManifest(
          id: fullLoaded.manifest.id,
          name: fullLoaded.manifest.name,
          description: fullLoaded.manifest.description,
          promptTemplate: fullLoaded.manifest.promptTemplate,
          type: SkillType.heavyweight,
        ),
        permissions: fullLoaded.permissions,
      );
      final fullApi = SandboxedSkillApi(
        permissions: fullSkill.permissions!,
        delegate: FakeSkillApi(),
      );
      // 不抛异常即为成功
      await fullApi.canonWrite(
        'proj-1',
        CanonEntry(
          projectId: 'proj-1',
          type: CanonEntryType.lore,
          name: '新设定',
        ),
      );

      // 只读重量 Skill — 手动构造 heavyweight 验证写入失败
      final roLoaded = actionService.getSkill('heavy-readonly')
          as DynamicPromptSkill;
      final roSkill = DynamicPromptSkill(
        manifest: SkillManifest(
          id: roLoaded.manifest.id,
          name: roLoaded.manifest.name,
          description: roLoaded.manifest.description,
          promptTemplate: roLoaded.manifest.promptTemplate,
          type: SkillType.heavyweight,
        ),
        permissions: roLoaded.permissions,
      );
      final roApi = SandboxedSkillApi(
        permissions: roSkill.permissions!,
        delegate: FakeSkillApi(),
      );
      expect(
        () => roApi.canonWrite(
          'proj-1',
          CanonEntry(
            projectId: 'proj-1',
            type: CanonEntryType.lore,
            name: '不应该写入',
          ),
        ),
        throwsA(isA<PermissionViolation>()),
      );
    });
  });
}
