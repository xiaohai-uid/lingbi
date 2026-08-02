/// DynamicPromptSkill — 将 SKILL.md 适配为 SkillAction 子类的桥接类
///
/// 从 SkillManifest 数据类构建，自动映射所有 SkillAction 接口属性，
/// 并在 buildPrompt 中完成模板占位符替换。
library;

import 'package:lingbi/features/skill/data/skill/skill_manifest.dart';
import 'package:lingbi/features/skill/data/skill/skill_permission.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

/// 动态 Prompt 技能 — 桥接 SkillManifest → SkillAction
class DynamicPromptSkill extends SkillAction {
  DynamicPromptSkill({required this.manifest, this.permissions});

  /// 技能清单数据
  final SkillManifest manifest;

  /// 权限集（可选）
  final PermissionSet? permissions;

  // ==================== SkillAction getter 映射 ====================

  @override
  String get id => manifest.id;

  @override
  String get name => manifest.name;

  @override
  String get description => manifest.description;

  @override
  String get icon {
    // 按 category 映射默认图标，无 category 时用 'auto_awesome'
    if (manifest.category == null) return 'auto_awesome';
    return switch (manifest.category) {
      'writing' => 'edit_note',
      'editing' => 'auto_fix_high',
      'analysis' => 'analytics',
      'dialogue' => 'chat',
      _ => 'auto_awesome',
    };
  }

  @override
  InputScope get inputScope => InputScope.selectionOrDocument;

  @override
  OutputMode get outputMode => OutputMode.candidate;

  @override
  MutationPolicy get mutationPolicy => MutationPolicy.insertAtCursor;

  // ==================== buildPrompt 模板替换 ====================

  @override
  String buildPrompt({
    required SkillContext context,
    Map<String, String> params = const {},
  }) {
    final template = manifest.promptTemplate;

    // 构建占位符映射表
    final placeholders = <String, String>{
      'input': context.effectiveInput(inputScope),
      'canon_summary': context.canonSummary,
      'selected_text': context.selectedText,
      'project_name': context.projectName,
      ...params,
    };

    // 检测模板是否包含任何占位符（使用单词边界匹配）
    final hasAnyPlaceholder = placeholders.keys.any((key) {
      final pattern = RegExp('\\b${RegExp.escape(key)}\\b');
      return pattern.hasMatch(template);
    });

    // 无占位符时直接返回整篇模板
    if (!hasAnyPlaceholder) return template;

    // 逐一替换占位符（单词边界安全）
    var result = template;
    for (final entry in placeholders.entries) {
      final pattern = RegExp('\\b${RegExp.escape(entry.key)}\\b');
      result = result.replaceAll(pattern, entry.value);
    }

    return result;
  }
}
