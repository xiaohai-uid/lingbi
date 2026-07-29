/// 引导流程定义 — 数据驱动的引导步骤描述
///
/// 从 YAML/JSON 文件加载，不硬编码步骤。
/// 每个题材 Skill 提供自己的 GuidedFlowDefinition。
library;

/// 流程类型：长篇 / 短篇
enum GuidedFlowType {
  long,
  short;

  static GuidedFlowType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'short':
        return GuidedFlowType.short;
      default:
        return GuidedFlowType.long;
    }
  }

  String get value => name;
}

/// 单个引导步骤定义
class GuidedFlowStep {
  const GuidedFlowStep({
    required this.id,
    required this.name,
    required this.prompt,
    this.constraints = const [],
    this.completionCriteria = '',
    this.outputs = const [],
  });

  factory GuidedFlowStep.fromJson(Map<String, dynamic> json) {
    return GuidedFlowStep(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      constraints: (json['constraints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completionCriteria: json['completionCriteria'] as String? ?? '',
      outputs: (json['outputs'] as List<dynamic>?)
              ?.map((e) => StepOutput.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// 步骤唯一标识
  final String id;

  /// 步骤显示名称（如"世界观构建"）
  final String name;

  /// AI 主动提问的 prompt 模板
  final String prompt;

  /// 约束条件（如"必须包含修炼体系"）
  final List<String> constraints;

  /// AI 判定完成的标准描述
  final String completionCriteria;

  /// 步骤完成时的产出物定义
  final List<StepOutput> outputs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'prompt': prompt,
        'constraints': constraints,
        'completionCriteria': completionCriteria,
        'outputs': outputs.map((o) => o.toJson()).toList(),
      };
}

/// 步骤产出物定义 — 描述完成后写入什么文件
class StepOutput {
  const StepOutput({
    required this.targetFile,
    required this.extractPrompt,
  });

  factory StepOutput.fromJson(Map<String, dynamic> json) {
    return StepOutput(
      targetFile: json['targetFile'] as String? ?? '',
      extractPrompt: json['extractPrompt'] as String? ?? '',
    );
  }

  /// 写入的目标文件名（如 "worldbuilding.json"）
  final String targetFile;

  /// 从对话中提取结构化数据的 AI prompt
  final String extractPrompt;

  Map<String, dynamic> toJson() => {
        'targetFile': targetFile,
        'extractPrompt': extractPrompt,
      };
}

/// 完整的引导流程定义
class GuidedFlowDefinition {
  const GuidedFlowDefinition({
    required this.id,
    required this.genre,
    required this.type,
    required this.steps,
  });

  factory GuidedFlowDefinition.fromJson(Map<String, dynamic> json) {
    return GuidedFlowDefinition(
      id: json['id'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      type: GuidedFlowType.fromString(json['type'] as String? ?? 'long'),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => GuidedFlowStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// 流程唯一标识（如 "xuanhuan-long"）
  final String id;

  /// 题材（如 "玄幻"）
  final String genre;

  /// 流程类型（长篇/短篇）
  final GuidedFlowType type;

  /// 引导步骤列表（有序）
  final List<GuidedFlowStep> steps;

  /// 步骤总数
  int get stepCount => steps.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'genre': genre,
        'type': type.value,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}
