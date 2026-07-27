/// 短篇写作支持
///
/// 专门的短篇引导流程 + 拆文分析 + 扫榜：
/// - 短篇 GuidedFlow：情绪设计→反转构思→精修出稿
/// - 短篇拆文：故事核/结构/情感线/反转/共鸣
/// - 短篇扫榜：知乎盐言/番茄短篇风口趋势
/// - 长篇/短篇模式切换
library;

import 'dart:convert';

import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

// ─── 数据模型 ───

/// 项目写作模式
enum WritingMode {
  longForm,
  shortForm;

  String get label => switch (this) {
        WritingMode.longForm => '长篇',
        WritingMode.shortForm => '短篇',
      };

  static WritingMode fromString(String s) {
    return WritingMode.values.firstWhere(
      (e) => e.name == s,
      orElse: () => WritingMode.longForm,
    );
  }
}

/// 短篇引导步骤
enum ShortStoryStep {
  emotionDesign,
  reversalDesign,
  polishOutput;

  String get label => switch (this) {
        ShortStoryStep.emotionDesign => '情绪设计',
        ShortStoryStep.reversalDesign => '反转构思',
        ShortStoryStep.polishOutput => '精修出稿',
      };

  String get description => switch (this) {
        ShortStoryStep.emotionDesign => '设计故事的情绪曲线：开篇吸引→情绪积累→高潮爆发→余韵收束',
        ShortStoryStep.reversalDesign => '构思核心反转：铺垫→误导→揭示→回味',
        ShortStoryStep.polishOutput => '精修文稿：节奏调整/金句打磨/结尾升华',
      };

  int get order => index;
}

/// 情绪曲线节点
class EmotionPoint {
  const EmotionPoint({
    required this.position,
    required this.emotion,
    required this.intensity,
    this.description = '',
  });

  factory EmotionPoint.fromJson(Map<String, dynamic> json) {
    return EmotionPoint(
      position: json['position'] as String? ?? '',
      emotion: json['emotion'] as String? ?? '',
      intensity: json['intensity'] as int? ?? 5,
      description: json['description'] as String? ?? '',
    );
  }

  /// 位置（开篇/发展/高潮/结尾）
  final String position;

  /// 情绪类型
  final String emotion;

  /// 强度 1-10
  final int intensity;

  final String description;

  Map<String, dynamic> toJson() => {
        'position': position,
        'emotion': emotion,
        'intensity': intensity,
        'description': description,
      };
}

/// 短篇拆文分析结果
class ShortStoryAnalysis {
  const ShortStoryAnalysis({
    this.storyCore = '',
    this.structure = '',
    this.emotionLine = const [],
    this.reversalDesign = '',
    this.resonancePoints = const [],
    this.wordCount = 0,
    this.error = '',
  });

  factory ShortStoryAnalysis.fromJson(Map<String, dynamic> json) {
    return ShortStoryAnalysis(
      storyCore: json['story_core'] as String? ?? '',
      structure: json['structure'] as String? ?? '',
      emotionLine: (json['emotion_line'] as List<dynamic>?)
              ?.map((e) => EmotionPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reversalDesign: json['reversal_design'] as String? ?? '',
      resonancePoints: (json['resonance_points'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      wordCount: json['word_count'] as int? ?? 0,
    );
  }

  /// 故事核（一句话概括）
  final String storyCore;

  /// 结构分析
  final String structure;

  /// 情感线
  final List<EmotionPoint> emotionLine;

  /// 反转设计
  final String reversalDesign;

  /// 共鸣点
  final List<String> resonancePoints;

  final int wordCount;
  final String error;

  bool get isSuccess => error.isEmpty;

  Map<String, dynamic> toJson() => {
        'story_core': storyCore,
        'structure': structure,
        'emotion_line': emotionLine.map((e) => e.toJson()).toList(),
        'reversal_design': reversalDesign,
        'resonance_points': resonancePoints,
        'word_count': wordCount,
      };
}

/// 扫榜条目
class TrendingEntry {
  const TrendingEntry({
    required this.title,
    required this.platform,
    this.author = '',
    this.heat = 0,
    this.tags = const [],
    this.summary = '',
  });

  factory TrendingEntry.fromJson(Map<String, dynamic> json) {
    return TrendingEntry(
      title: json['title'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      author: json['author'] as String? ?? '',
      heat: json['heat'] as int? ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      summary: json['summary'] as String? ?? '',
    );
  }

  final String title;
  final String platform;
  final String author;
  final int heat;
  final List<String> tags;
  final String summary;

  Map<String, dynamic> toJson() => {
        'title': title,
        'platform': platform,
        'author': author,
        'heat': heat,
        'tags': tags,
        'summary': summary,
      };
}

/// 扫榜平台
enum TrendingPlatform {
  zhihuYanyan,
  fanqieShort;

  String get label => switch (this) {
        TrendingPlatform.zhihuYanyan => '知乎盐言',
        TrendingPlatform.fanqieShort => '番茄短篇',
      };
}

/// 趋势分析报告
class TrendAnalysisReport {
  const TrendAnalysisReport({
    this.hotTopics = const [],
    this.structurePatterns = const [],
    this.emotionTrends = '',
    this.suggestions = const [],
    this.rawEntries = const [],
  });

  final List<String> hotTopics;
  final List<String> structurePatterns;
  final String emotionTrends;
  final List<String> suggestions;
  final List<TrendingEntry> rawEntries;
}

/// 短篇引导状态
class ShortStoryFlowState {
  const ShortStoryFlowState({
    this.currentStep = ShortStoryStep.emotionDesign,
    this.emotionCurve = const [],
    this.reversalIdea = '',
    this.draft = '',
    this.isComplete = false,
  });

  factory ShortStoryFlowState.fromJson(Map<String, dynamic> json) {
    return ShortStoryFlowState(
      currentStep: ShortStoryStep.values.firstWhere(
        (e) => e.name == (json['current_step'] as String? ?? ''),
        orElse: () => ShortStoryStep.emotionDesign,
      ),
      emotionCurve: (json['emotion_curve'] as List<dynamic>?)
              ?.map((e) => EmotionPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reversalIdea: json['reversal_idea'] as String? ?? '',
      draft: json['draft'] as String? ?? '',
      isComplete: json['is_complete'] as bool? ?? false,
    );
  }

  final ShortStoryStep currentStep;
  final List<EmotionPoint> emotionCurve;
  final String reversalIdea;
  final String draft;
  final bool isComplete;

  Map<String, dynamic> toJson() => {
        'current_step': currentStep.name,
        'emotion_curve': emotionCurve.map((e) => e.toJson()).toList(),
        'reversal_idea': reversalIdea,
        'draft': draft,
        'is_complete': isComplete,
      };

  ShortStoryFlowState copyWith({
    ShortStoryStep? currentStep,
    List<EmotionPoint>? emotionCurve,
    String? reversalIdea,
    String? draft,
    bool? isComplete,
  }) {
    return ShortStoryFlowState(
      currentStep: currentStep ?? this.currentStep,
      emotionCurve: emotionCurve ?? this.emotionCurve,
      reversalIdea: reversalIdea ?? this.reversalIdea,
      draft: draft ?? this.draft,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

// ─── 服务 ───

/// 短篇写作支持服务
class ShortStoryService {
  ShortStoryService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  set aiProvider(AIProvider provider) => _aiProvider = provider;

  static const _flowKey = 'short_story_flow';
  static const _modeKey = 'writing_mode';

  // ─── 1. 模式管理 ───

  /// 设置项目写作模式
  Future<void> setWritingMode(String projectId, WritingMode mode) async {
    await _metaRepository.write(projectId, _modeKey, {'mode': mode.name});
  }

  /// 获取项目写作模式
  Future<WritingMode> getWritingMode(String projectId) async {
    final data = await _metaRepository.read(projectId, _modeKey);
    if (data == null) return WritingMode.longForm;
    return WritingMode.fromString(data['mode'] as String? ?? '');
  }

  /// 短篇引导步骤列表
  List<ShortStoryStep> get flowSteps => ShortStoryStep.values.toList();

  // ─── 2. 短篇引导流程 ───

  /// 加载引导状态
  Future<ShortStoryFlowState> loadFlowState(String projectId) async {
    final data = await _metaRepository.read(projectId, _flowKey);
    if (data == null) return const ShortStoryFlowState();
    return ShortStoryFlowState.fromJson(data);
  }

  /// 保存引导状态
  Future<void> saveFlowState(
      String projectId, ShortStoryFlowState state) async {
    await _metaRepository.write(projectId, _flowKey, state.toJson());
  }

  /// 完成情绪设计步骤
  Future<ShortStoryFlowState> completeEmotionDesign(
    String projectId,
    List<EmotionPoint> curve,
  ) async {
    final state = await loadFlowState(projectId);
    final updated = state.copyWith(
      emotionCurve: curve,
      currentStep: ShortStoryStep.reversalDesign,
    );
    await saveFlowState(projectId, updated);
    return updated;
  }

  /// 完成反转构思步骤
  Future<ShortStoryFlowState> completeReversalDesign(
    String projectId,
    String reversalIdea,
  ) async {
    final state = await loadFlowState(projectId);
    final updated = state.copyWith(
      reversalIdea: reversalIdea,
      currentStep: ShortStoryStep.polishOutput,
    );
    await saveFlowState(projectId, updated);
    return updated;
  }

  /// 完成精修出稿
  Future<ShortStoryFlowState> completePolish(
    String projectId,
    String finalDraft,
  ) async {
    final state = await loadFlowState(projectId);
    final updated = state.copyWith(
      draft: finalDraft,
      isComplete: true,
    );
    await saveFlowState(projectId, updated);
    return updated;
  }

  /// AI 辅助生成情绪曲线建议
  Future<List<EmotionPoint>> suggestEmotionCurve({
    required String storyIdea,
    String genre = '',
  }) async {
    try {
      final response = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
            role: 'system',
            content: '你是短篇小说情绪设计专家。为给定的故事创意设计情绪曲线。'
                '输出 JSON 数组，每项含 position/emotion/intensity(1-10)/description。',
          ),
          ChatMessage(
            role: 'user',
            content:
                '故事创意: $storyIdea${genre.isNotEmpty ? '\n题材: $genre' : ''}',
          ),
        ],
      );

      final list = jsonDecode(_cleanJson(response)) as List<dynamic>;
      return list
          .map((e) => EmotionPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── 3. 短篇拆文 ───

  /// 分析短篇文本
  Future<ShortStoryAnalysis> analyzeShortStory(String text) async {
    if (text.trim().isEmpty) {
      return const ShortStoryAnalysis(error: '文本为空');
    }

    try {
      final response = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
            role: 'system',
            content: '你是短篇小说分析专家。对给定短篇进行五维拆解分析。'
                '输出 JSON，含 story_core/structure/emotion_line/reversal_design/'
                'resonance_points/word_count 字段。'
                'emotion_line 为数组，每项含 position/emotion/intensity/description。',
          ),
          ChatMessage(role: 'user', content: '拆解分析:\n\n$text'),
        ],
        maxTokens: 4096,
      );

      final json = jsonDecode(_cleanJson(response)) as Map<String, dynamic>;
      return ShortStoryAnalysis.fromJson(json);
    } catch (e) {
      return ShortStoryAnalysis(error: '分析失败: $e');
    }
  }

  // ─── 4. 短篇扫榜 ───

  /// 扫榜趋势分析（AI 基于提供的数据分析）
  Future<TrendAnalysisReport> analyzeTrends({
    required List<TrendingEntry> entries,
    TrendingPlatform platform = TrendingPlatform.zhihuYanyan,
  }) async {
    if (entries.isEmpty) {
      return const TrendAnalysisReport();
    }

    try {
      final entryText = entries
          .map((e) =>
              '- ${e.title} (${e.platform}) 热度:${e.heat} 标签:${e.tags.join(",")}')
          .join('\n');

      final response = await _aiProvider.chatSync(
        messages: [
          ChatMessage(
            role: 'system',
            content: '你是网文市场分析师。分析${platform.label}短篇热门趋势。'
                '输出 JSON，含 hot_topics/structure_patterns/emotion_trends/suggestions 字段。',
          ),
          ChatMessage(role: 'user', content: '热门数据:\n$entryText'),
        ],
      );

      final json = jsonDecode(_cleanJson(response)) as Map<String, dynamic>;
      return TrendAnalysisReport(
        hotTopics: (json['hot_topics'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        structurePatterns: (json['structure_patterns'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        emotionTrends: json['emotion_trends'] as String? ?? '',
        suggestions: (json['suggestions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        rawEntries: entries,
      );
    } catch (_) {
      return TrendAnalysisReport(rawEntries: entries);
    }
  }

  // ─── 辅助 ───

  String _cleanJson(String output) {
    var cleaned = output.trim();
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) cleaned = cleaned.substring(firstNewline + 1);
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }
    return cleaned;
  }
}
