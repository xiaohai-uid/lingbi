/// 写作上下文包数据模型
///
/// 借鉴 OpenWrite GenerationContext 设计思想，用 Dart 重新实现。
/// 每次 AI 生成章节时由 ContextAssembler 组装，作为 AI 的完整输入。
library;

/// 伏笔状态快照
class ForeshadowingState {
  const ForeshadowingState({
    this.pending = const [],
    this.planted = const [],
    this.resolved = const [],
  });

  /// 待回收伏笔
  final List<ForeshadowingItem> pending;

  /// 已埋下伏笔
  final List<ForeshadowingItem> planted;

  /// 已回收伏笔
  final List<ForeshadowingItem> resolved;

  /// 生成伏笔上下文文本
  String toContextText({int maxChars = 0}) {
    final parts = <String>[];
    if (pending.isNotEmpty) {
      parts.add('【待回收伏笔 (${pending.length})】');
      for (final item in pending.take(5)) {
        parts.add('  - ${item.id}: ${item.description}');
      }
    }
    if (planted.isNotEmpty) {
      parts.add('【已埋下伏笔 (${planted.length})】');
      for (final item in planted.take(5)) {
        parts.add('  - ${item.id}: ${item.description}');
      }
    }
    var text = parts.join('\n');
    if (maxChars > 0 && text.length > maxChars) {
      text = '${text.substring(0, maxChars)}…';
    }
    return text;
  }

  Map<String, dynamic> toJson() => {
        'pending': pending.map((e) => e.toJson()).toList(),
        'planted': planted.map((e) => e.toJson()).toList(),
        'resolved': resolved.map((e) => e.toJson()).toList(),
      };

  factory ForeshadowingState.fromJson(Map<String, dynamic> json) =>
      ForeshadowingState(
        pending: (json['pending'] as List? ?? [])
            .map((e) => ForeshadowingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        planted: (json['planted'] as List? ?? [])
            .map((e) => ForeshadowingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        resolved: (json['resolved'] as List? ?? [])
            .map((e) => ForeshadowingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 单个伏笔条目
class ForeshadowingItem {
  const ForeshadowingItem({
    required this.id,
    required this.description,
    this.weight = 5,
    this.layer = '支线',
    this.targetChapter,
  });

  final String id;
  final String description;
  final int weight;
  final String layer;
  final String? targetChapter;

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'weight': weight,
        'layer': layer,
        if (targetChapter != null) 'target_chapter': targetChapter,
      };

  factory ForeshadowingItem.fromJson(Map<String, dynamic> json) =>
      ForeshadowingItem(
        id: json['id'] as String? ?? '',
        description: json['description'] as String? ?? '',
        weight: json['weight'] as int? ?? 5,
        layer: json['layer'] as String? ?? '支线',
        targetChapter: json['target_chapter'] as String?,
      );
}

/// 世界观规则
class WorldRules {
  const WorldRules({
    this.constraints = const [],
    this.entities = const [],
    this.relations = const [],
  });

  /// 世界观约束/设定
  final List<String> constraints;

  /// 相关实体
  final List<WorldEntity> entities;

  /// 实体关系
  final List<String> relations;

  /// 生成世界观上下文文本
  String toContextText({int maxChars = 0}) {
    final parts = <String>[];
    if (constraints.isNotEmpty) {
      parts.add('【世界观约束】');
      for (final c in constraints.take(10)) {
        parts.add('  - $c');
      }
    }
    if (entities.isNotEmpty) {
      parts.add('【相关实体 (${entities.length})】');
      for (final e in entities.take(5)) {
        parts.add('  - ${e.name}');
      }
    }
    var text = parts.join('\n');
    if (maxChars > 0 && text.length > maxChars) {
      text = '${text.substring(0, maxChars)}…';
    }
    return text;
  }

  Map<String, dynamic> toJson() => {
        'constraints': constraints,
        'entities': entities.map((e) => e.toJson()).toList(),
        'relations': relations,
      };

  factory WorldRules.fromJson(Map<String, dynamic> json) => WorldRules(
        constraints:
            (json['constraints'] as List? ?? []).cast<String>(),
        entities: (json['entities'] as List? ?? [])
            .map((e) => WorldEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        relations: (json['relations'] as List? ?? []).cast<String>(),
      );
}

/// 世界实体
class WorldEntity {
  const WorldEntity({required this.name, this.description = ''});

  final String name;
  final String description;

  Map<String, dynamic> toJson() => {'name': name, 'description': description};

  factory WorldEntity.fromJson(Map<String, dynamic> json) => WorldEntity(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

/// 角色卡片（上下文用）
class CharacterCard {
  const CharacterCard({
    required this.name,
    this.role = '',
    this.currentState = '',
    this.personality = '',
    this.relationships = const [],
  });

  final String name;
  final String role;
  final String currentState;
  final String personality;
  final List<String> relationships;

  /// 生成角色上下文文本
  String toContextText({int maxChars = 200}) {
    final parts = <String>['- $name'];
    if (role.isNotEmpty) parts.add('  身份: $role');
    if (currentState.isNotEmpty) parts.add('  当前状态: $currentState');
    if (personality.isNotEmpty) parts.add('  性格: $personality');
    if (relationships.isNotEmpty) {
      parts.add('  关系: ${relationships.join("、")}');
    }
    var text = parts.join('\n');
    if (maxChars > 0 && text.length > maxChars) {
      text = '${text.substring(0, maxChars)}…';
    }
    return text;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'current_state': currentState,
        'personality': personality,
        'relationships': relationships,
      };

  factory CharacterCard.fromJson(Map<String, dynamic> json) => CharacterCard(
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        currentState: json['current_state'] as String? ?? '',
        personality: json['personality'] as String? ?? '',
        relationships:
            (json['relationships'] as List? ?? []).cast<String>(),
      );
}

/// 戏剧位置信息
class DramaticContext {
  const DramaticContext({
    this.arcStructure = '',
    this.arcEmotionalArc = '',
    this.sectionStructure = '',
    this.sectionEmotionalArc = '',
    this.sectionTension = '',
    this.dramaticPosition = '',
    this.contentFocus = '',
  });

  /// 篇弧线结构
  final String arcStructure;

  /// 篇情感走向
  final String arcEmotionalArc;

  /// 节戏剧结构
  final String sectionStructure;

  /// 节情感弧线
  final String sectionEmotionalArc;

  /// 节张力走向
  final String sectionTension;

  /// 本章戏剧位置
  final String dramaticPosition;

  /// 本章内容焦点
  final String contentFocus;

  bool get isEmpty =>
      arcStructure.isEmpty &&
      dramaticPosition.isEmpty &&
      contentFocus.isEmpty;

  Map<String, dynamic> toJson() => {
        if (arcStructure.isNotEmpty) 'arc_structure': arcStructure,
        if (arcEmotionalArc.isNotEmpty)
          'arc_emotional_arc': arcEmotionalArc,
        if (sectionStructure.isNotEmpty)
          'section_structure': sectionStructure,
        if (sectionEmotionalArc.isNotEmpty)
          'section_emotional_arc': sectionEmotionalArc,
        if (sectionTension.isNotEmpty) 'section_tension': sectionTension,
        if (dramaticPosition.isNotEmpty)
          'dramatic_position': dramaticPosition,
        if (contentFocus.isNotEmpty) 'content_focus': contentFocus,
      };

  factory DramaticContext.fromJson(Map<String, dynamic> json) =>
      DramaticContext(
        arcStructure: json['arc_structure'] as String? ?? '',
        arcEmotionalArc: json['arc_emotional_arc'] as String? ?? '',
        sectionStructure: json['section_structure'] as String? ?? '',
        sectionEmotionalArc:
            json['section_emotional_arc'] as String? ?? '',
        sectionTension: json['section_tension'] as String? ?? '',
        dramaticPosition: json['dramatic_position'] as String? ?? '',
        contentFocus: json['content_focus'] as String? ?? '',
      );
}

/// 写作 AI 的完整上下文包
///
/// 每次生成章节时由 ContextAssembler 组装。
/// 借鉴 OpenWrite GenerationContext 设计，适配灵笔 Dart 生态。
class GenerationContext {
  const GenerationContext({
    this.novelId = '',
    this.chapterId = '',
    this.authorIntent = '',
    this.creativeFocus = '',
    this.chapterGoals = const [],
    this.targetWords = 6000,
    this.emotionArc = '',
    this.dramaticContext = const DramaticContext(),
    this.outlineWindow = const [],
    this.currentChapterSummary = '',
    this.activeCharacters = const [],
    this.foreshadowing = const ForeshadowingState(),
    this.styleProfile = '',
    this.worldRules = const WorldRules(),
    this.recentText = '',
    this.currentState = '',
    this.ledger = '',
    this.relationships = '',
    this.chapterSummaries = '',
    this.userInstruction = '',
    this.spoilerBlacklist = const [],
    this.tokenBudget = 8000,
  });

  // ─── 基础信息 ───
  final String novelId;
  final String chapterId;

  /// 整本书长期不变的作者意图（永不截断）
  final String authorIntent;

  /// 当前阶段创作罗盘与硬约束（永不截断）
  final String creativeFocus;

  /// 本章写作目标
  final List<String> chapterGoals;

  /// 目标字数
  final int targetWords;

  /// 章内微观情绪变化
  final String emotionArc;

  // ─── 戏剧位置 ───
  final DramaticContext dramaticContext;

  // ─── 大纲 ───
  /// 大纲窗口（ OutlineNode 摘要列表）
  final List<String> outlineWindow;

  /// 当前章节摘要
  final String currentChapterSummary;

  // ─── 角色 ───
  final List<CharacterCard> activeCharacters;

  // ─── 伏笔 ───
  final ForeshadowingState foreshadowing;

  // ─── 风格 ───
  final String styleProfile;

  // ─── 世界观 ───
  final WorldRules worldRules;

  // ─── 真相文件（运行态） ───

  /// 最近章节文本（用于连贯性）
  final String recentText;

  /// 世界当前状态
  final String currentState;

  /// 资源账本
  final String ledger;

  /// 角色关系与动态状态
  final String relationships;

  /// 章节摘要列表
  final String chapterSummaries;

  // ─── 用户控制 ───

  /// 用户临时指令
  final String userInstruction;

  /// 禁止泄露内容
  final List<String> spoilerBlacklist;

  /// Token 预算
  final int tokenBudget;

  /// 粗略估算总 token 数（中文约 1.5 字/token）
  int estimateTokens() {
    var totalChars = 0;
    for (final section in toPromptSections().values) {
      totalChars += section.length;
    }
    return (totalChars / 1.5).round();
  }

  /// 转为有序的 prompt 段落
  Map<String, String> toPromptSections() {
    final sections = <String, String>{};

    if (authorIntent.isNotEmpty) {
      sections['作者意图'] = authorIntent;
    }
    if (creativeFocus.isNotEmpty) {
      sections['创作罗盘（当前最高优先级）'] = creativeFocus;
    }
    if (recentText.isNotEmpty) {
      sections['上文'] = recentText;
    }
    if (chapterSummaries.isNotEmpty) {
      sections['历史章节记忆'] = chapterSummaries;
    }
    if (outlineWindow.isNotEmpty) {
      sections['大纲窗口'] = outlineWindow.map((o) => '- $o').join('\n');
    }
    if (currentChapterSummary.isNotEmpty) {
      sections['当前章节'] = currentChapterSummary;
    }
    if (activeCharacters.isNotEmpty) {
      sections['出场角色'] = activeCharacters
          .map((c) => c.toContextText(maxChars: 200))
          .join('\n');
    }
    if (foreshadowing.pending.isNotEmpty ||
        foreshadowing.planted.isNotEmpty) {
      sections['伏笔'] = foreshadowing.toContextText(maxChars: 500);
    }
    if (styleProfile.isNotEmpty) {
      sections['风格指南'] = styleProfile.length > 500
          ? '${styleProfile.substring(0, 500)}…'
          : styleProfile;
    }
    if (worldRules.constraints.isNotEmpty ||
        worldRules.entities.isNotEmpty) {
      sections['世界观'] = worldRules.toContextText(maxChars: 300);
    }
    if (currentState.isNotEmpty) {
      sections['世界当前状态'] = currentState;
    }
    if (ledger.isNotEmpty) {
      sections['资源账本'] = ledger;
    }
    if (relationships.isNotEmpty) {
      sections['角色关系'] = relationships;
    }
    if (chapterGoals.isNotEmpty) {
      sections['本章目标'] =
          chapterGoals.map((g) => '- $g').join('\n');
    }

    // 戏剧位置
    if (!dramaticContext.isEmpty) {
      final dc = dramaticContext;
      final parts = <String>[];
      if (dc.arcStructure.isNotEmpty) {
        parts.add('篇弧线结构: ${dc.arcStructure}');
      }
      if (dc.arcEmotionalArc.isNotEmpty) {
        parts.add('篇情感走向: ${dc.arcEmotionalArc}');
      }
      if (dc.sectionStructure.isNotEmpty) {
        parts.add('节戏剧结构: ${dc.sectionStructure}');
      }
      if (dc.sectionTension.isNotEmpty) {
        parts.add('节张力走向: ${dc.sectionTension}');
      }
      if (dc.dramaticPosition.isNotEmpty) {
        parts.add('▶ 本章位于: ${dc.dramaticPosition}');
      }
      if (dc.contentFocus.isNotEmpty) {
        parts.add('▶ 本章焦点: ${dc.contentFocus}');
      }
      if (parts.isNotEmpty) {
        sections['戏剧位置'] = parts.join('\n');
      }
    }

    if (emotionArc.isNotEmpty) {
      sections['章内情绪变化'] = emotionArc;
    }
    if (userInstruction.isNotEmpty) {
      sections['用户指令'] = userInstruction;
    }
    if (spoilerBlacklist.isNotEmpty) {
      sections['禁止泄露'] = spoilerBlacklist.join('、');
    }

    return sections;
  }

  /// 生成完整的 prompt 上下文文本
  String toPromptContext() {
    final parts = <String>[];
    for (final entry in toPromptSections().entries) {
      parts.add('## ${entry.key}\n\n${entry.value}');
    }
    return parts.join('\n\n');
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'novel_id': novelId,
        'chapter_id': chapterId,
        'author_intent': authorIntent,
        'creative_focus': creativeFocus,
        'chapter_goals': chapterGoals,
        'target_words': targetWords,
        'emotion_arc': emotionArc,
        'dramatic_context': dramaticContext.toJson(),
        'outline_window': outlineWindow,
        'current_chapter_summary': currentChapterSummary,
        'active_characters':
            activeCharacters.map((c) => c.toJson()).toList(),
        'foreshadowing': foreshadowing.toJson(),
        'style_profile': styleProfile,
        'world_rules': worldRules.toJson(),
        'recent_text': recentText,
        'current_state': currentState,
        'ledger': ledger,
        'relationships': relationships,
        'chapter_summaries': chapterSummaries,
        'user_instruction': userInstruction,
        'spoiler_blacklist': spoilerBlacklist,
        'token_budget': tokenBudget,
      };
}
