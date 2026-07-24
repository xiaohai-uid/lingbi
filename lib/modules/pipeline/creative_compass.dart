/// 创作罗盘 (Creative Compass)
///
/// 借鉴 OpenWrite author_intent + current_focus 设计思想。
/// 为 AI 提供始终不变的创作方向和当前阶段焦点。
///
/// - AuthorIntent: 整本书的核心意图，永不截断
/// - CurrentFocus: 当前阶段的硬约束和创作方向
library;

import 'dart:convert';
import 'dart:io';

/// 作者意图（全书级别，极少修改）
class AuthorIntent {
  const AuthorIntent({
    this.coreTheme = '',
    this.genre = '',
    this.targetAudience = '',
    this.tone = '',
    this.coreConflict = '',
    this.endingVision = '',
    this.taboos = const [],
    this.mustHaves = const [],
  });

  /// 核心主题（一句话）
  final String coreTheme;

  /// 类型/题材
  final String genre;

  /// 目标读者
  final String targetAudience;

  /// 整体基调
  final String tone;

  /// 核心冲突
  final String coreConflict;

  /// 结局愿景
  final String endingVision;

  /// 禁忌（绝不能出现的内容）
  final List<String> taboos;

  /// 必须包含的元素
  final List<String> mustHaves;

  bool get isEmpty => coreTheme.isEmpty && genre.isEmpty;

  /// 生成 prompt 文本（永不截断）
  String toPromptText() {
    final parts = <String>[];
    if (coreTheme.isNotEmpty) parts.add('核心主题: $coreTheme');
    if (genre.isNotEmpty) parts.add('类型: $genre');
    if (targetAudience.isNotEmpty) parts.add('目标读者: $targetAudience');
    if (tone.isNotEmpty) parts.add('基调: $tone');
    if (coreConflict.isNotEmpty) parts.add('核心冲突: $coreConflict');
    if (endingVision.isNotEmpty) parts.add('结局愿景: $endingVision');
    if (taboos.isNotEmpty) parts.add('禁忌: ${taboos.join("、")}');
    if (mustHaves.isNotEmpty) parts.add('必须包含: ${mustHaves.join("、")}');
    return parts.join('\n');
  }

  Map<String, dynamic> toJson() => {
        'core_theme': coreTheme,
        'genre': genre,
        'target_audience': targetAudience,
        'tone': tone,
        'core_conflict': coreConflict,
        'ending_vision': endingVision,
        'taboos': taboos,
        'must_haves': mustHaves,
      };

  factory AuthorIntent.fromJson(Map<String, dynamic> json) => AuthorIntent(
        coreTheme: json['core_theme'] as String? ?? '',
        genre: json['genre'] as String? ?? '',
        targetAudience: json['target_audience'] as String? ?? '',
        tone: json['tone'] as String? ?? '',
        coreConflict: json['core_conflict'] as String? ?? '',
        endingVision: json['ending_vision'] as String? ?? '',
        taboos: (json['taboos'] as List? ?? []).cast<String>(),
        mustHaves: (json['must_haves'] as List? ?? []).cast<String>(),
      );
}

/// 当前焦点（阶段级别，随写作进度更新）
class CurrentFocus {
  const CurrentFocus({
    this.arcGoal = '',
    this.arcPhase = '',
    this.emotionalTarget = '',
    this.pacingDirective = '',
    this.hardConstraints = const [],
    this.priorityQueue = const [],
    this.updatedAt,
  });

  /// 当前篇章目标
  final String arcGoal;

  /// 当前篇章阶段（如"铺垫期"、"高潮期"、"收束期"）
  final String arcPhase;

  /// 情感目标（读者应感受到什么）
  final String emotionalTarget;

  /// 节奏指令（如"加快"、"舒缓"、"张弛交替"）
  final String pacingDirective;

  /// 硬约束（不可违反的规则）
  final List<String> hardConstraints;

  /// 优先级队列（当前最重要的事项）
  final List<String> priorityQueue;

  /// 最后更新时间
  final DateTime? updatedAt;

  bool get isEmpty => arcGoal.isEmpty && arcPhase.isEmpty;

  /// 生成 prompt 文本（永不截断）
  String toPromptText() {
    final parts = <String>[];
    if (arcGoal.isNotEmpty) parts.add('当前篇章目标: $arcGoal');
    if (arcPhase.isNotEmpty) parts.add('篇章阶段: $arcPhase');
    if (emotionalTarget.isNotEmpty) parts.add('情感目标: $emotionalTarget');
    if (pacingDirective.isNotEmpty) parts.add('节奏: $pacingDirective');
    if (hardConstraints.isNotEmpty) {
      parts.add('硬约束:\n${hardConstraints.map((c) => "  - $c").join("\n")}');
    }
    if (priorityQueue.isNotEmpty) {
      parts.add(
          '优先级:\n${priorityQueue.asMap().entries.map((e) => "  ${e.key + 1}. ${e.value}").join("\n")}');
    }
    return parts.join('\n');
  }

  Map<String, dynamic> toJson() => {
        'arc_goal': arcGoal,
        'arc_phase': arcPhase,
        'emotional_target': emotionalTarget,
        'pacing_directive': pacingDirective,
        'hard_constraints': hardConstraints,
        'priority_queue': priorityQueue,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  factory CurrentFocus.fromJson(Map<String, dynamic> json) => CurrentFocus(
        arcGoal: json['arc_goal'] as String? ?? '',
        arcPhase: json['arc_phase'] as String? ?? '',
        emotionalTarget: json['emotional_target'] as String? ?? '',
        pacingDirective: json['pacing_directive'] as String? ?? '',
        hardConstraints:
            (json['hard_constraints'] as List? ?? []).cast<String>(),
        priorityQueue:
            (json['priority_queue'] as List? ?? []).cast<String>(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}

/// 创作罗盘（组合 AuthorIntent + CurrentFocus）
class CreativeCompass {
  const CreativeCompass({
    this.authorIntent = const AuthorIntent(),
    this.currentFocus = const CurrentFocus(),
  });

  final AuthorIntent authorIntent;
  final CurrentFocus currentFocus;

  /// 生成完整的创作罗盘 prompt（永不截断）
  String toPromptText() {
    final parts = <String>[];
    if (!authorIntent.isEmpty) {
      parts.add('【作者意图（全书不变）】\n${authorIntent.toPromptText()}');
    }
    if (!currentFocus.isEmpty) {
      parts.add('【当前焦点（阶段更新）】\n${currentFocus.toPromptText()}');
    }
    return parts.join('\n\n');
  }

  Map<String, dynamic> toJson() => {
        'author_intent': authorIntent.toJson(),
        'current_focus': currentFocus.toJson(),
      };

  factory CreativeCompass.fromJson(Map<String, dynamic> json) =>
      CreativeCompass(
        authorIntent: AuthorIntent.fromJson(
            json['author_intent'] as Map<String, dynamic>? ?? {}),
        currentFocus: CurrentFocus.fromJson(
            json['current_focus'] as Map<String, dynamic>? ?? {}),
      );
}

/// 创作罗盘存储服务
///
/// 持久化到 {projectDir}/.lingbi/runtime/creative_compass.json
class CreativeCompassStore {
  CreativeCompassStore({required String projectDir})
      : _file =
            File('$projectDir/.lingbi/runtime/creative_compass.json');

  final File _file;

  /// 加载或创建空罗盘
  CreativeCompass loadOrCreate() {
    if (_file.existsSync()) {
      try {
        final json = jsonDecode(_file.readAsStringSync())
            as Map<String, dynamic>;
        return CreativeCompass.fromJson(json);
      } catch (_) {
        // 文件损坏
      }
    }
    return const CreativeCompass();
  }

  /// 保存罗盘
  void save(CreativeCompass compass) {
    _file.parent.createSync(recursive: true);
    _file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(compass.toJson()),
    );
  }

  /// 更新当前焦点（保留作者意图不变）
  void updateFocus(CurrentFocus focus) {
    final compass = loadOrCreate();
    save(CreativeCompass(
      authorIntent: compass.authorIntent,
      currentFocus: CurrentFocus(
        arcGoal: focus.arcGoal,
        arcPhase: focus.arcPhase,
        emotionalTarget: focus.emotionalTarget,
        pacingDirective: focus.pacingDirective,
        hardConstraints: focus.hardConstraints,
        priorityQueue: focus.priorityQueue,
        updatedAt: DateTime.now(),
      ),
    ));
  }

  /// 更新作者意图（保留当前焦点不变）
  void updateIntent(AuthorIntent intent) {
    final compass = loadOrCreate();
    save(CreativeCompass(
      authorIntent: intent,
      currentFocus: compass.currentFocus,
    ));
  }
}
