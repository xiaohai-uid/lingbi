import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/shared/models/canon_entry.dart';

/// 引导型向导的 5 个步骤
enum GuidedWizardStep {
  title,
  genre,
  protagonist,
  worldview,
  firstChapterGoal,
}

/// 每步跳过时填充的默认值
const _defaultValues = <GuidedWizardStep, String>{
  GuidedWizardStep.title: '未命名作品',
  GuidedWizardStep.genre: '通用',
  GuidedWizardStep.protagonist: '主角',
  GuidedWizardStep.worldview: '',
  GuidedWizardStep.firstChapterGoal: '开篇引入，建立世界观和主角',
};

/// 向导完成后的产出物
class WizardOutput {
  const WizardOutput({
    required this.brief,
    required this.initialCanon,
    required this.firstChapterInstruction,
  });

  /// 项目简报（所有字段非空）
  final ProjectBrief brief;

  /// 初始正典条目（至少一条角色 + 一条设定）
  final List<CanonEntry> initialCanon;

  /// 第一章生成指令
  final String firstChapterInstruction;
}

/// 引导型向导的纯数据状态（可序列化、可恢复）
class GuidedWizardState {
  const GuidedWizardState({
    required this.currentStep,
    required this.lastStep,
    required this.stepData,
    required this.skippedSteps,
    required this.isCompleted,
  });

  /// 初始状态：从第一步开始
  const GuidedWizardState.initial()
      : currentStep = GuidedWizardStep.title,
        lastStep = 0,
        stepData = const {},
        skippedSteps = const {},
        isCompleted = false;

  factory GuidedWizardState.fromJson(Map<String, dynamic> json) {
    final rawStepData = json['stepData'] as Map<String, dynamic>? ?? {};
    final rawSkipped = json['skippedSteps'] as List<dynamic>? ?? [];
    return GuidedWizardState(
      currentStep: GuidedWizardStep.values.byName(
        json['currentStep'] as String? ?? 'title',
      ),
      lastStep: json['lastStep'] as int? ?? 0,
      stepData: {
        for (final entry in rawStepData.entries)
          GuidedWizardStep.values.byName(entry.key): entry.value as String,
      },
      skippedSteps: {
        for (final name in rawSkipped)
          GuidedWizardStep.values.byName(name as String),
      },
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// 当前所在步骤
  final GuidedWizardStep currentStep;

  /// 已完成的步骤数（用于中断恢复）
  final int lastStep;

  /// 每步的用户输入或默认值
  final Map<GuidedWizardStep, String> stepData;

  /// 被跳过的步骤集合
  final Set<GuidedWizardStep> skippedSteps;

  /// 是否已完成全部步骤
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
        'currentStep': currentStep.name,
        'lastStep': lastStep,
        'stepData': {
          for (final entry in stepData.entries) entry.key.name: entry.value,
        },
        'skippedSteps': skippedSteps.map((s) => s.name).toList(),
        'isCompleted': isCompleted,
      };

  GuidedWizardState copyWith({
    GuidedWizardStep? currentStep,
    int? lastStep,
    Map<GuidedWizardStep, String>? stepData,
    Set<GuidedWizardStep>? skippedSteps,
    bool? isCompleted,
  }) =>
      GuidedWizardState(
        currentStep: currentStep ?? this.currentStep,
        lastStep: lastStep ?? this.lastStep,
        stepData: stepData ?? this.stepData,
        skippedSteps: skippedSteps ?? this.skippedSteps,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuidedWizardState &&
          currentStep == other.currentStep &&
          lastStep == other.lastStep &&
          _mapEquals(stepData, other.stepData) &&
          _setEquals(skippedSteps, other.skippedSteps) &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        currentStep,
        lastStep,
        Object.hashAllUnordered(stepData.entries),
        Object.hashAllUnordered(skippedSteps),
        isCompleted,
      );
}

/// 引导型向导状态机（纯逻辑，无 IO）
///
/// 管理 5 步流转、跳过默认值填充、中断恢复。
/// 完成时通过 [buildOutput] 产出 ProjectBrief + 初始正典 + 第一章指令。
class GuidedWizardStateMachine {
  GuidedWizardStateMachine() : _state = const GuidedWizardState.initial();

  GuidedWizardStateMachine.fromState(GuidedWizardState state)
      : _state = state;

  GuidedWizardState _state;

  GuidedWizardState get state => _state;

  /// 完成当前步骤并前进到下一步
  void advance(String input) {
    if (_state.isCompleted) return;

    final step = _state.currentStep;
    final stepData = Map<GuidedWizardStep, String>.from(_state.stepData)
      ..[step] = input;
    final nextIndex = step.index + 1;
    final completed = nextIndex >= GuidedWizardStep.values.length;

    _state = _state.copyWith(
      currentStep: completed
          ? step
          : GuidedWizardStep.values[nextIndex],
      lastStep: nextIndex,
      stepData: stepData,
      isCompleted: completed,
    );
  }

  /// 跳过当前步骤（填充默认值）并前进到下一步
  void skip() {
    if (_state.isCompleted) return;

    final step = _state.currentStep;
    final stepData = Map<GuidedWizardStep, String>.from(_state.stepData)
      ..[step] = _defaultValues[step]!;
    final skippedSteps = Set<GuidedWizardStep>.from(_state.skippedSteps)
      ..add(step);
    final nextIndex = step.index + 1;
    final completed = nextIndex >= GuidedWizardStep.values.length;

    _state = _state.copyWith(
      currentStep: completed
          ? step
          : GuidedWizardStep.values[nextIndex],
      lastStep: nextIndex,
      stepData: stepData,
      skippedSteps: skippedSteps,
      isCompleted: completed,
    );
  }

  /// 构建向导产出物
  ///
  /// 前置条件：向导必须已完成（[GuidedWizardState.isCompleted] == true）。
  /// 不变量：ProjectBrief 所有字段非空，正典至少一条角色 + 一条设定。
  WizardOutput buildOutput(String projectId) {
    if (!_state.isCompleted) {
      throw StateError('向导未完成，不能构建产出物');
    }

    final data = _state.stepData;
    final title = _nonEmpty(data[GuidedWizardStep.title], '未命名作品');
    final genre = _nonEmpty(data[GuidedWizardStep.genre], '通用');
    final protagonist = _nonEmpty(data[GuidedWizardStep.protagonist], '主角');
    final worldview = data[GuidedWizardStep.worldview]?.trim() ?? '';
    final goal = _nonEmpty(
        data[GuidedWizardStep.firstChapterGoal], '开篇引入，建立世界观和主角');

    final brief = ProjectBrief(
      title: title,
      genreId: genre,
      templateId: 'genre:$genre',
    );

    final canon = <CanonEntry>[
      // 角色条目（始终存在）
      CanonEntry(
        projectId: projectId,
        type: CanonEntryType.character,
        name: protagonist,
        description: _state.skippedSteps.contains(GuidedWizardStep.protagonist)
            ? ''
            : protagonist,
      ),
      // 题材设定条目（始终存在，满足"至少一条设定"不变量）
      CanonEntry(
        projectId: projectId,
        type: CanonEntryType.lore,
        name: '题材类型',
        description: genre,
      ),
    ];

    // 世界规则：仅在用户实际填写时注入（跳过时空字符串不注入）
    if (worldview.isNotEmpty) {
      canon.add(CanonEntry(
        projectId: projectId,
        type: CanonEntryType.lore,
        name: '世界规则',
        description: worldview,
      ));
    }

    return WizardOutput(
      brief: brief,
      initialCanon: canon,
      firstChapterInstruction: goal,
    );
  }
}

/// 空值合并：null 或空白字符串时返回 fallback
String _nonEmpty(String? value, String fallback) =>
    (value == null || value.trim().isEmpty) ? fallback : value;

bool _mapEquals(Map<GuidedWizardStep, String> a, Map<GuidedWizardStep, String> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}

bool _setEquals(Set<GuidedWizardStep> a, Set<GuidedWizardStep> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
