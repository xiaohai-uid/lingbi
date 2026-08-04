/// 技能动作服务 — 统一管理可执行技能
///
/// 首轮只实现：智能续写、文本/对话润色、降低 AI 痕迹。
/// 入口：斜杠命令 + AI 工具栏 + 自动路由。右键菜单后续接入同一服务。
library;

import 'package:flutter/foundation.dart';
import 'package:lingbi/features/routing/default_rules.dart';
import 'package:lingbi/features/routing/route_engine.dart';
import 'package:lingbi/shared/models/canon_entry.dart';

/// 参数类型
enum SkillParameterType {
  text,
  number,
  select,
  boolean,
}

/// 技能参数定义
class SkillParameter {
  const SkillParameter({
    required this.name,
    required this.label,
    this.type = SkillParameterType.text,
    this.defaultValue = '',
    this.required = false,
    this.placeholder = '',
    this.options,
  });

  final String name;
  final String label;
  final SkillParameterType type;
  final String defaultValue;
  final bool required;
  final String placeholder;
  final List<String>? options;
}

/// 输入范围
enum InputScope {
  /// 使用选中文本
  selection,

  /// 使用全文
  fullDocument,

  /// 选中文本优先，无选中则全文
  selectionOrDocument,

  /// 无需文本输入
  none,
}

/// 输出模式
enum OutputMode {
  /// 输出为候选正文（可采纳到编辑器）
  candidate,

  /// 输出为分析/信息（不可采纳）
  analysis,
}

/// 变更策略
enum MutationPolicy {
  /// 插入到光标处
  insertAtCursor,

  /// 替换选区
  replaceSelection,

  /// 追加到末尾
  appendToEnd,

  /// 不修改文档（仅分析）
  readOnly,
}

/// 上下文需求
class ContextRequirements {
  const ContextRequirements({
    this.needsFullDocument = false,
    this.needsCanonSummary = false,
    this.needsPreviousChapter = false,
    this.minInputLength = 0,
  });

  final bool needsFullDocument;
  final bool needsCanonSummary;
  final bool needsPreviousChapter;
  final int minInputLength;
}

/// 技能执行上下文
class SkillContext {
  const SkillContext({
    this.selectedText = '',
    this.fullDocument = '',
    this.projectId = '',
    this.projectName = '',
    this.documentTitle = '',
    this.canonSummary = '',
    this.chapterId = '',
    this.sourcePath = '',
  });

  final String selectedText;
  final String fullDocument;
  final String projectId;
  final String projectName;
  final String documentTitle;
  final String canonSummary;
  final String chapterId;
  final String sourcePath;

  /// 根据 InputScope 获取有效输入文本
  String effectiveInput(InputScope scope) {
    return switch (scope) {
      InputScope.selection => selectedText,
      InputScope.fullDocument => fullDocument,
      InputScope.selectionOrDocument =>
        selectedText.isNotEmpty ? selectedText : fullDocument,
      InputScope.none => '',
    };
  }
}

/// 技能执行结果
class SkillResult {
  const SkillResult({
    required this.success,
    this.output = '',
    this.candidateText,
    this.error,
    this.promptForAI = '',
    this.canonEntries = const [],
  });

  final bool success;
  final String output;
  final String? candidateText;
  final String? error;

  /// 构建好的 AI prompt（由 AIService 执行）
  final String promptForAI;

  /// 重量 Skill 通过声明式 API 返回的正典条目列表
  final List<CanonEntry> canonEntries;
}

/// 技能动作抽象基类
abstract class SkillAction {
  /// 技能唯一标识
  String get id;

  /// 显示名称
  String get name;

  /// 简短描述
  String get description;

  /// 图标（Material Icon 名称）
  String get icon;

  /// 输入范围
  InputScope get inputScope;

  /// 必填参数
  List<SkillParameter> get requiredParameters => [];

  /// 可选参数
  List<SkillParameter> get optionalParameters => [];

  /// 所有参数
  List<SkillParameter> get parameters => [
        ...requiredParameters,
        ...optionalParameters,
      ];

  /// 上下文需求
  ContextRequirements get contextRequirements => const ContextRequirements();

  /// 输出模式
  OutputMode get outputMode;

  /// 变更策略
  MutationPolicy get mutationPolicy;

  /// 是否支持撤销
  bool get canUndo => true;

  /// 检查参数是否充分（参数驱动，非固定规则）
  bool areParametersSatisfied(Map<String, String> params) {
    for (final p in requiredParameters) {
      final value = params[p.name] ?? '';
      if (value.isEmpty && p.defaultValue.isEmpty) return false;
    }
    return true;
  }

  /// 获取缺失的必填参数
  List<SkillParameter> getMissingParameters(Map<String, String> params) {
    return requiredParameters.where((p) {
      final value = params[p.name] ?? '';
      return value.isEmpty && p.defaultValue.isEmpty;
    }).toList();
  }

  /// 构建 AI prompt（由具体技能实现）
  String buildPrompt({
    required SkillContext context,
    Map<String, String> params = const {},
  });

  /// 执行技能（验证 + 构建 prompt）
  SkillResult execute({
    required SkillContext context,
    Map<String, String> params = const {},
  }) {
    // 验证输入
    final input = context.effectiveInput(inputScope);
    if (contextRequirements.minInputLength > 0 &&
        input.length < contextRequirements.minInputLength) {
      return SkillResult(
        success: false,
        error: '输入文本不足（至少需要 ${contextRequirements.minInputLength} 字）',
      );
    }

    // 构建 prompt
    final prompt = buildPrompt(context: context, params: params);
    return SkillResult(
      success: true,
      promptForAI: prompt,
      output: outputMode == OutputMode.candidate ? '' : prompt,
    );
  }
}

/// 技能动作服务
class SkillActionService extends ChangeNotifier {
  SkillActionService({RouteEngine? routeEngine})
      : _routeEngine = routeEngine ?? RouteEngine(rules: defaultRouteRules());

  final RouteEngine _routeEngine;
  final Map<String, SkillAction> _registeredSkills = {};

  /// 获取所有已注册的技能
  List<SkillAction> get registeredSkills => _registeredSkills.values.toList();

  /// 注册技能
  void registerSkill(SkillAction skill) {
    _registeredSkills[skill.id] = skill;
    notifyListeners();
  }

  /// 注销技能（卸载时使用）
  void unregisterSkill(String skillId) {
    if (_registeredSkills.remove(skillId) != null) {
      notifyListeners();
    }
  }

  /// 根据 ID 获取技能
  SkillAction? getSkill(String skillId) => _registeredSkills[skillId];

  /// 执行技能
  SkillResult executeSkill({
    required String skillId,
    required SkillContext context,
    Map<String, String> params = const {},
  }) {
    final skill = _registeredSkills[skillId];
    if (skill == null) {
      return const SkillResult(success: false, error: '技能不存在');
    }
    return skill.execute(context: context, params: params);
  }

  /// 先路由后执行用户任务。
  ///
  /// 未命中或命中技能未注册时返回 `null`，不硬塞技能。
  RouteResult? routeTask({
    required String userMessage,
    String? selection,
    String currentScene = '',
  }) {
    final result = _routeEngine.route(
      userMessage: userMessage,
      selection: selection,
      currentScene: currentScene,
    );
    if (result == null || !_registeredSkills.containsKey(result.skillId)) {
      return null;
    }
    return result;
  }

  /// 自动路由并执行命中的技能；手动入口仍走 [executeSkill]。
  SkillResult executeRouted({
    required String userMessage,
    required SkillContext context,
    String? selection,
    String currentScene = '',
    Map<String, String> params = const {},
  }) {
    final effectiveSelection = selection ??
        (context.selectedText.isNotEmpty ? context.selectedText : null);
    final route = routeTask(
      userMessage: userMessage,
      selection: effectiveSelection,
      currentScene: currentScene,
    );
    if (route == null) {
      return const SkillResult(success: false, error: '未命中可用技能');
    }
    return executeSkill(
      skillId: route.skillId,
      context: context,
      params: params,
    );
  }

  /// 模糊搜索技能（斜杠命令用）
  List<SkillAction> searchSkills(String query) {
    if (query.isEmpty) return registeredSkills;
    final q = query.toLowerCase();
    return registeredSkills
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.id.toLowerCase().contains(q))
        .toList();
  }

  /// 根据输入范围过滤可用技能
  List<SkillAction> skillsForInput({required bool hasSelection}) {
    return registeredSkills.where((skill) {
      if (skill.inputScope == InputScope.selection && !hasSelection) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 初始化内置技能（首轮 3 个）
  void initializeBuiltinSkills() {
    registerSkill(SmartContinuationSkill());
    registerSkill(TextPolishSkill());
    registerSkill(DeaiPolisherSkill());
    notifyListeners();
  }
}

// ==================== 内置技能实现 ====================

/// 智能续写
class SmartContinuationSkill extends SkillAction {
  @override
  String get id => 'smart-continuation';
  @override
  String get name => '智能续写';
  @override
  String get description => '根据前文语境和风格自动续写下一段落';
  @override
  String get icon => 'edit_note';
  @override
  InputScope get inputScope => InputScope.selectionOrDocument;
  @override
  OutputMode get outputMode => OutputMode.candidate;
  @override
  MutationPolicy get mutationPolicy => MutationPolicy.insertAtCursor;
  @override
  bool get canUndo => true;

  @override
  ContextRequirements get contextRequirements => const ContextRequirements(
        needsFullDocument: true,
        needsCanonSummary: true,
        minInputLength: 10,
      );

  @override
  List<SkillParameter> get optionalParameters => [
        const SkillParameter(
          name: 'length',
          label: '续写长度',
          type: SkillParameterType.select,
          defaultValue: '300',
          options: ['100', '300', '500', '1000'],
        ),
        const SkillParameter(
          name: 'mood',
          label: '情绪基调',
          type: SkillParameterType.select,
          defaultValue: '延续前文',
          options: ['延续前文', '紧张', '舒缓', '悲伤', '欢快', '悬疑'],
        ),
      ];

  @override
  String buildPrompt({
    required SkillContext context,
    Map<String, String> params = const {},
  }) {
    final length = params['length'] ?? '300';
    final mood = params['mood'] ?? '延续前文';
    final input = context.effectiveInput(inputScope);

    final sb = StringBuffer();
    sb.writeln('你是一位专业小说作家。请根据以下前文续写约$length字的内容。');
    if (mood != '延续前文') sb.writeln('情绪基调：$mood');
    if (context.canonSummary.isNotEmpty) {
      sb.writeln('\n【世界观参考】\n${context.canonSummary}');
    }
    sb.writeln('\n【前文】\n$input');
    sb.writeln('\n请直接输出续写正文，不要添加标题或说明。');
    return sb.toString();
  }
}

/// 文本/对话润色
class TextPolishSkill extends SkillAction {
  @override
  String get id => 'dialogue-polish';
  @override
  String get name => '文本润色';
  @override
  String get description => '润色选中的文本或对话，保持原意提升质量';
  @override
  String get icon => 'auto_fix_high';
  @override
  InputScope get inputScope => InputScope.selection;
  @override
  OutputMode get outputMode => OutputMode.candidate;
  @override
  MutationPolicy get mutationPolicy => MutationPolicy.replaceSelection;
  @override
  bool get canUndo => true;

  @override
  ContextRequirements get contextRequirements => const ContextRequirements(
        minInputLength: 5,
      );

  @override
  List<SkillParameter> get optionalParameters => [
        const SkillParameter(
          name: 'style',
          label: '润色方向',
          type: SkillParameterType.select,
          defaultValue: '保持原风格',
          options: ['保持原风格', '更文学', '更口语', '更紧凑', '更细腻'],
        ),
      ];

  @override
  String buildPrompt({
    required SkillContext context,
    Map<String, String> params = const {},
  }) {
    final style = params['style'] ?? '保持原风格';
    final input = context.effectiveInput(inputScope);

    final sb = StringBuffer();
    sb.writeln('你是一位专业小说编辑。请润色以下文本，方向：$style。');
    sb.writeln('要求：保持原意，不改变情节走向，不添加新内容。');
    sb.writeln('\n【待润色文本】\n$input');
    sb.writeln('\n请直接输出润色后的正文，不要添加说明。');
    return sb.toString();
  }
}

/// 降低 AI 痕迹
class DeaiPolisherSkill extends SkillAction {
  @override
  String get id => 'deai-polisher';
  @override
  String get name => '降低AI痕迹';
  @override
  String get description => '检测并改写 AI 生成痕迹明显的段落';
  @override
  String get icon => 'auto_fix_normal';
  @override
  InputScope get inputScope => InputScope.selection;
  @override
  OutputMode get outputMode => OutputMode.candidate;
  @override
  MutationPolicy get mutationPolicy => MutationPolicy.replaceSelection;
  @override
  bool get canUndo => true;

  @override
  ContextRequirements get contextRequirements => const ContextRequirements(
        minInputLength: 20,
      );

  @override
  List<SkillParameter> get optionalParameters => [
        const SkillParameter(
          name: 'intensity',
          label: '改写强度',
          type: SkillParameterType.select,
          defaultValue: '适中',
          options: ['轻微', '适中', '大幅'],
        ),
      ];

  @override
  String buildPrompt({
    required SkillContext context,
    Map<String, String> params = const {},
  }) {
    final intensity = params['intensity'] ?? '适中';
    final input = context.effectiveInput(inputScope);

    final sb = StringBuffer();
    sb.writeln('你是一位资深文学编辑，擅长消除 AI 写作痕迹。');
    sb.writeln('请以$intensity强度改写以下文本，消除典型 AI 写作特征：');
    sb.writeln('- 去除"值得注意的是""总而言之"等套话');
    sb.writeln('- 打破过于均匀的段落长度');
    sb.writeln('- 减少排比和对仗的机械使用');
    sb.writeln('- 增加口语化表达和个性化用词');
    sb.writeln('- 保持原意不变');
    sb.writeln('\n【待改写文本】\n$input');
    sb.writeln('\n请直接输出改写后的正文，不要添加说明。');
    return sb.toString();
  }
}
