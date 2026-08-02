/// 意图确认服务 — 由技能参数定义驱动
///
/// 不使用统一的"目标+长度+情绪"规则。
/// 由当前 SkillAction 的参数定义决定是否需要确认。
/// 参数已经充分时直接执行；参数不足时显示确认卡。
library;

import 'package:lingbi/features/skill/data/skill_action_service.dart';

/// 参数充分性评估结果
class IntentAssessment {
  const IntentAssessment({
    required this.isSufficient,
    this.missingParameters = const [],
    this.quickOptions = const [],
  });

  /// 参数是否充分（充分则直接执行）
  final bool isSufficient;

  /// 缺失的必填参数
  final List<SkillParameter> missingParameters;

  /// 快速选项（用于确认卡）
  final List<QuickOption> quickOptions;
}

/// 快速选项
class QuickOption {
  const QuickOption({
    required this.label,
    required this.paramName,
    required this.value,
  });

  final String label;
  final String paramName;
  final String value;
}

/// 确认卡数据
class ConfirmationCard {
  const ConfirmationCard({
    required this.skillName,
    required this.question,
    this.parameters = const [],
    this.quickOptions = const [],
    this.allowFreeInput = true,
    this.showDirectGenerate = true,
    this.showRememberOption = true,
  });

  /// 技能名称
  final String skillName;

  /// 确认问题
  final String question;

  /// 需要补充的参数
  final List<SkillParameter> parameters;

  /// 快速选项
  final List<QuickOption> quickOptions;

  /// 是否允许自由输入
  final bool allowFreeInput;

  /// 是否显示"直接生成"按钮
  final bool showDirectGenerate;

  /// 是否显示"本次记住"选项
  final bool showRememberOption;
}

/// 意图确认服务
class IntentConfirmationService {
  IntentConfirmationService();

  /// 本次会话记住的参数（skillId → params）
  final Map<String, Map<String, String>> _sessionMemory = {};

  /// 用户是否全局跳过确认
  bool skipAll = false;

  /// 评估技能的参数充分性
  ///
  /// 由 SkillAction 的参数定义驱动，不使用固定规则。
  IntentAssessment assessIntent(
    SkillAction skill, {
    Map<String, String> userParams = const {},
  }) {
    // 全局跳过
    if (skipAll) {
      return const IntentAssessment(isSufficient: true);
    }

    // 合并会话记忆中的参数
    final remembered = _sessionMemory[skill.id] ?? {};
    final mergedParams = {...remembered, ...userParams};

    // 由技能自身判断参数是否充分
    if (skill.areParametersSatisfied(mergedParams)) {
      return const IntentAssessment(isSufficient: true);
    }

    // 获取缺失参数
    final missing = skill.getMissingParameters(mergedParams);

    // 生成快速选项
    final quickOptions = _generateQuickOptions(missing);

    return IntentAssessment(
      isSufficient: false,
      missingParameters: missing,
      quickOptions: quickOptions,
    );
  }

  /// 根据评估结果生成确认卡
  ConfirmationCard? buildConfirmationCard(
    SkillAction skill,
    IntentAssessment assessment,
  ) {
    if (assessment.isSufficient) return null;

    final question = assessment.missingParameters.length == 1
        ? '请补充「${assessment.missingParameters.first.label}」'
        : '请补充以下参数以执行「${skill.name}」';

    return ConfirmationCard(
      skillName: skill.name,
      question: question,
      parameters: assessment.missingParameters,
      quickOptions: assessment.quickOptions,
    );
  }

  /// 记住本次会话的参数选择
  void rememberForSession(String skillId, Map<String, String> params) {
    _sessionMemory[skillId] = {
      ...(_sessionMemory[skillId] ?? {}),
      ...params,
    };
  }

  /// 清除会话记忆
  void clearSessionMemory() {
    _sessionMemory.clear();
  }

  /// 为缺失参数生成快速选项
  List<QuickOption> _generateQuickOptions(List<SkillParameter> missing) {
    final options = <QuickOption>[];
    for (final param in missing) {
      if (param.options != null && param.options!.isNotEmpty) {
        // 取前 3 个选项
        for (final opt in param.options!.take(3)) {
          options.add(QuickOption(
            label: opt,
            paramName: param.name,
            value: opt,
          ));
        }
      } else if (param.defaultValue.isNotEmpty) {
        options.add(QuickOption(
          label: '默认: ${param.defaultValue}',
          paramName: param.name,
          value: param.defaultValue,
        ));
      }
    }
    return options;
  }
}
