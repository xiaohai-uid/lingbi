import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/shared/models/canon_entry.dart';

/// 向导维度（两屏共 8 个）
enum WizardDimension {
  // 第一屏：快速选择（全必选）
  genre,
  wordCount,
  platform,
  // 第二屏：深度填写
  title,
  protagonist,
  worldview,
  creativeDirection,
  firstChapterGoal,
}

/// 第一屏包含的维度
const screenOneDimensions = [
  WizardDimension.genre,
  WizardDimension.wordCount,
  WizardDimension.platform,
];

/// 第二屏包含的维度
const screenTwoDimensions = [
  WizardDimension.title,
  WizardDimension.protagonist,
  WizardDimension.worldview,
  WizardDimension.creativeDirection,
  WizardDimension.firstChapterGoal,
];

/// 每个维度的多选上限（null = 单选或纯文本）
const multiSelectCaps = <WizardDimension, int>{
  WizardDimension.genre: 3,
  WizardDimension.creativeDirection: 3,
};

/// 可跳过的维度及其默认值
const skippableDefaults = <WizardDimension, String>{
  WizardDimension.title: '未命名作品',
  WizardDimension.worldview: '',
  WizardDimension.creativeDirection: '通用',
};

/// 单个维度的用户输入值（支持多选 + 自定义共存）
class WizardStepValue {
  const WizardStepValue({this.selected = const [], this.customText});

  /// 卡片选中的选项列表（单选时长度为 1）
  final List<String> selected;

  /// 自定义输入文本（与卡片选择共存）
  final String? customText;

  /// 是否为空（无选择且无自定义文本）
  bool get isEmpty => selected.isEmpty && (customText == null || customText!.trim().isEmpty);

  /// 是否非空
  bool get isNotEmpty => !isEmpty;

  /// 合并所有值为展示字符串（用于 buildOutput）
  String get combined {
    final parts = [...selected];
    if (customText != null && customText!.trim().isNotEmpty) {
      parts.add(customText!.trim());
    }
    return parts.join('、');
  }

  Map<String, dynamic> toJson() => {
        'selected': selected,
        if (customText != null) 'customText': customText,
      };

  factory WizardStepValue.fromJson(Map<String, dynamic> json) =>
      WizardStepValue(
        selected: (json['selected'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        customText: json['customText'] as String?,
      );

  WizardStepValue copyWith({List<String>? selected, String? customText}) =>
      WizardStepValue(
        selected: selected ?? this.selected,
        customText: customText ?? this.customText,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WizardStepValue &&
          _listEquals(selected, other.selected) &&
          customText == other.customText;

  @override
  int get hashCode => Object.hash(Object.hashAll(selected), customText);
}

/// 向导完成后的产出物
class WizardOutput {
  const WizardOutput({
    required this.brief,
    required this.initialCanon,
    required this.firstChapterInstruction,
    required this.genres,
    required this.wordCount,
    required this.platform,
    required this.creativeDirection,
  });

  /// 项目简报（所有字段非空）
  final ProjectBrief brief;

  /// 初始正典条目（至少一条角色 + 一条设定）
  final List<CanonEntry> initialCanon;

  /// 第一章生成指令
  final String firstChapterInstruction;

  /// 多选题材列表
  final List<String> genres;

  /// 字数目标
  final String wordCount;

  /// 发布平台
  final String platform;

  /// 创意方向（多选）
  final String creativeDirection;
}

/// 引导型向导的纯数据状态（可序列化、可恢复）
class GuidedWizardState {
  const GuidedWizardState({
    required this.dimensionData,
    required this.skippedDimensions,
    required this.isCompleted,
  });

  /// 初始状态：所有维度为空
  const GuidedWizardState.initial()
      : dimensionData = const {},
        skippedDimensions = const {},
        isCompleted = false;

  factory GuidedWizardState.fromJson(Map<String, dynamic> json) {
    final rawData = json['dimensionData'] as Map<String, dynamic>? ?? {};
    final rawSkipped = json['skippedDimensions'] as List<dynamic>? ?? [];
    return GuidedWizardState(
      dimensionData: {
        for (final entry in rawData.entries)
          WizardDimension.values.byName(entry.key):
              WizardStepValue.fromJson(entry.value as Map<String, dynamic>),
      },
      skippedDimensions: {
        for (final name in rawSkipped)
          WizardDimension.values.byName(name as String),
      },
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// 每个维度的用户输入
  final Map<WizardDimension, WizardStepValue> dimensionData;

  /// 被跳过的维度集合
  final Set<WizardDimension> skippedDimensions;

  /// 是否已完成全部步骤
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
        'dimensionData': {
          for (final entry in dimensionData.entries)
            entry.key.name: entry.value.toJson(),
        },
        'skippedDimensions': skippedDimensions.map((d) => d.name).toList(),
        'isCompleted': isCompleted,
      };

  GuidedWizardState copyWith({
    Map<WizardDimension, WizardStepValue>? dimensionData,
    Set<WizardDimension>? skippedDimensions,
    bool? isCompleted,
  }) =>
      GuidedWizardState(
        dimensionData: dimensionData ?? this.dimensionData,
        skippedDimensions: skippedDimensions ?? this.skippedDimensions,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuidedWizardState &&
          _mapEquals(dimensionData, other.dimensionData) &&
          _setEquals(skippedDimensions, other.skippedDimensions) &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(dimensionData.entries),
        Object.hashAllUnordered(skippedDimensions),
        isCompleted,
      );
}

/// 引导型向导状态机（纯逻辑，无 IO）
///
/// 管理 8 个维度的数据、校验规则、跳过默认值填充。
/// 完成时通过 [buildOutput] 产出 ProjectBrief + 初始正典 + 第一章指令。
/// UI 层负责屏导航；状态机只管数据和规则。
class GuidedWizardStateMachine {
  GuidedWizardStateMachine() : _state = const GuidedWizardState.initial();

  GuidedWizardStateMachine.fromState(GuidedWizardState state)
      : _state = state;

  GuidedWizardState _state;

  GuidedWizardState get state => _state;

  /// 设置某个维度的值
  void setDimension(WizardDimension dimension, WizardStepValue value) {
    if (_state.isCompleted) return;
    final data = Map<WizardDimension, WizardStepValue>.from(_state.dimensionData)
      ..[dimension] = value;
    // 如果之前被跳过但现在有值了，移除跳过标记
    final skipped = Set<WizardDimension>.from(_state.skippedDimensions)
      ..remove(dimension);
    _state = _state.copyWith(dimensionData: data, skippedDimensions: skipped);
  }

  /// 跳过某个维度（填充默认值）
  ///
  /// 仅允许可跳过的维度（title, worldview, creativeDirection）
  void skip(WizardDimension dimension) {
    if (_state.isCompleted) return;
    final defaultValue = skippableDefaults[dimension];
    if (defaultValue == null) return; // 不可跳过
    final data = Map<WizardDimension, WizardStepValue>.from(_state.dimensionData)
      ..[dimension] = WizardStepValue(selected: [defaultValue]);
    final skipped = Set<WizardDimension>.from(_state.skippedDimensions)
      ..add(dimension);
    _state = _state.copyWith(dimensionData: data, skippedDimensions: skipped);
  }

  /// 校验某个维度是否满足多选上限
  ///
  /// 返回 true 表示可以添加，false 表示已达上限
  bool canAddSelection(WizardDimension dimension, int currentCount) {
    final cap = multiSelectCaps[dimension];
    if (cap == null) return true; // 单选或纯文本，无上限概念
    return currentCount < cap;
  }

  /// 校验第一屏是否全部填写完成
  bool isScreenOneComplete() {
    for (final dim in screenOneDimensions) {
      final value = _state.dimensionData[dim];
      if (value == null || value.isEmpty) return false;
    }
    return true;
  }

  /// 校验第二屏是否全部填写完成（可跳过维度用默认值也算完成）
  bool isScreenTwoComplete() {
    for (final dim in screenTwoDimensions) {
      final value = _state.dimensionData[dim];
      if (value == null || value.isEmpty) {
        // 可跳过维度允许为空（完成时自动填充默认值）
        if (!skippableDefaults.containsKey(dim)) return false;
      }
    }
    return true;
  }

  /// 标记向导完成
  ///
  /// 前置条件：两屏校验均通过。自动为可跳过维度填充默认值。
  void markCompleted() {
    if (!isScreenOneComplete() || !isScreenTwoComplete()) {
      throw StateError('向导校验未通过，不能标记完成');
    }
    // 为可跳过维度填充默认值
    final data = Map<WizardDimension, WizardStepValue>.from(_state.dimensionData);
    for (final entry in skippableDefaults.entries) {
      final existing = data[entry.key];
      if (existing == null || existing.isEmpty) {
        data[entry.key] = WizardStepValue(selected: [entry.value]);
      }
    }
    _state = _state.copyWith(dimensionData: data, isCompleted: true);
  }

  /// 构建向导产出物
  ///
  /// 前置条件：向导必须已完成（[GuidedWizardState.isCompleted] == true）。
  WizardOutput buildOutput(String projectId) {
    if (!_state.isCompleted) {
      throw StateError('向导未完成，不能构建产出物');
    }

    final data = _state.dimensionData;
    final title = _valueOr(data[WizardDimension.title], '未命名作品');
    final genres = data[WizardDimension.genre]?.selected ?? ['通用'];
    final wordCount = _valueOr(data[WizardDimension.wordCount], '长篇(50万+)');
    final platform = _valueOr(data[WizardDimension.platform], '自由发布');
    final protagonist = _valueOr(data[WizardDimension.protagonist], '主角');
    final worldview = data[WizardDimension.worldview]?.combined ?? '';
    final creativeDirection =
        _valueOr(data[WizardDimension.creativeDirection], '通用');
    final goal = _valueOr(
        data[WizardDimension.firstChapterGoal], '开篇引入，建立世界观和主角');

    final brief = ProjectBrief(
      title: title,
      genreId: genres.join('+'),
      templateId: 'genre:${genres.first}',
    );

    final canon = <CanonEntry>[
      // 角色条目（始终存在）
      CanonEntry(
        projectId: projectId,
        type: CanonEntryType.character,
        name: protagonist,
        description: protagonist,
      ),
      // 题材设定条目（始终存在）
      CanonEntry(
        projectId: projectId,
        type: CanonEntryType.lore,
        name: '题材类型',
        description: genres.join('、'),
      ),
    ];

    // 世界规则：仅在用户实际填写时注入
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
      genres: genres,
      wordCount: wordCount,
      platform: platform,
      creativeDirection: creativeDirection,
    );
  }
}

/// 空值合并：值为空时返回 fallback
String _valueOr(WizardStepValue? value, String fallback) {
  if (value == null || value.isEmpty) return fallback;
  return value.combined;
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals(Map<WizardDimension, WizardStepValue> a,
    Map<WizardDimension, WizardStepValue> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}

bool _setEquals(Set<WizardDimension> a, Set<WizardDimension> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
