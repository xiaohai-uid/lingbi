import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/skill/data/skill/skill_manifest.dart';
import 'package:lingbi/features/skill/data/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

void main() {
  group('DynamicPromptSkill 构建', () {
    test('从 SkillManifest 构建 — id/name/description 正确映射', () {
      const manifest = SkillManifest(
        id: 'test-skill',
        name: '测试技能',
        description: '一个测试用的技能',
        promptTemplate: '这是 prompt 模板',
      );
      final skill = DynamicPromptSkill(manifest: manifest);

      expect(skill.id, 'test-skill');
      expect(skill.name, '测试技能');
      expect(skill.description, '一个测试用的技能');
      expect(skill.icon, 'auto_awesome');
    });

    test('默认 inputScope 为 selectionOrDocument', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '', promptTemplate: '',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      expect(skill.inputScope, InputScope.selectionOrDocument);
    });

    test('默认 outputMode 为 candidate', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '', promptTemplate: '',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      expect(skill.outputMode, OutputMode.candidate);
    });

    test('默认 mutationPolicy 为 insertAtCursor', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '', promptTemplate: '',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      expect(skill.mutationPolicy, MutationPolicy.insertAtCursor);
    });
  });

  group('DynamicPromptSkill buildPrompt', () {
    test('替换 input 占位符', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '',
        promptTemplate: '请基于以下内容续写：input',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      const context = SkillContext(
        selectedText: '选中的文本内容',
        fullDocument: '完整文档',
        projectId: 'proj-1',
      );

      final prompt = skill.buildPrompt(context: context);
      expect(prompt, contains('选中的文本内容'));
      expect(prompt, isNot(contains('input')));
    });

    test('替换 canon_summary 占位符', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '',
        promptTemplate: '正典摘要：canon_summary\n请续写',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      const context = SkillContext(
        projectId: 'proj-1',
        canonSummary: '角色A是英雄，角色B是反派',
      );

      final prompt = skill.buildPrompt(context: context);
      expect(prompt, contains('角色A是英雄'));
    });

    test('无占位符时直接返回整篇模板作为 system prompt', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '',
        promptTemplate: '你是一个专业的小说编辑助手。请帮助用户优化文本。',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      const context = SkillContext(
        selectedText: 'some text',
        fullDocument: 'full doc',
        projectId: 'proj-1',
      );

      final prompt = skill.buildPrompt(context: context);
      expect(prompt, '你是一个专业的小说编辑助手。请帮助用户优化文本。');
    });

    test('替换用户参数占位符', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '',
        promptTemplate: '以style风格改写：input',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      const context = SkillContext(
        selectedText: '原文',
        projectId: 'proj-1',
      );

      final prompt = skill.buildPrompt(
        context: context,
        params: {'style': '武侠'},
      );
      expect(prompt, contains('武侠'));
      expect(prompt, contains('原文'));
    });
  });

  group('DynamicPromptSkill execute', () {
    test('execute 返回成功的 SkillResult', () {
      const manifest = SkillManifest(
        id: 'test', name: 'Test', description: '',
        promptTemplate: '请续写：input',
      );
      final skill = DynamicPromptSkill(manifest: manifest);
      const context = SkillContext(
        selectedText: '一段选中文本',
        fullDocument: '完整文档内容',
        projectId: 'proj-1',
      );

      final result = skill.execute(context: context);
      expect(result.success, true);
      expect(result.promptForAI, contains('选中文本'));
    });
  });
}
