/// 蝴蝶效应分析器
///
/// 分析时间线事件变更对角色权重和剧情走向的影响。
library butterfly_analyzer;

import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/data/repositories/timeline_repository.dart';
import 'package:lingbi/core/ai/llm_factory.dart';
import 'package:lingbi/core/ai/llm_models.dart';
import 'package:lingbi/core/ai/retry_handler.dart';
import 'package:lingbi/services/prompt_service.dart';

/// 蝴蝶效应分析器
class ButterflyAnalyzer {
  ButterflyAnalyzer({
    required this.timelineRepo,
    PromptService? promptService,
    RetryHandler? retryHandler,
  })  : promptService = promptService ?? PromptService(),
        retryHandler = retryHandler ?? const RetryHandler();
  final TimelineRepository timelineRepo;
  final PromptService promptService;
  final RetryHandler retryHandler;
  final String _providerName = 'deepseek';

  /// 分析事件变更的蝴蝶效应
  Future<ButterflyAnalysisResult> analyze({
    required String worldId,
    required String eventId,
    required String changeDescription,
  }) async {
    // 1. 获取事件信息
    final events = await timelineRepo.getEvents(worldId);
    final event = events.firstWhere(
      (TimelineEvent e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );

    // 2. 获取相关角色（从时间线事件和作品结构推断）
    // TODO: 从实际数据源获取角色列表
    const characterContext = '当前事件涉及的主要角色';

    // 3. 调用 LLM 分析
    final analysis = await _llmAnalyze(
      eventTitle: event.title,
      eventDescription: event.description,
      changeDescription: changeDescription,
      characterContext: characterContext,
    );

    // 4. 保存分析结果
    // TODO: 保存到数据库（需要传递 impacts 数据）

    return analysis;
  }

  /// LLM 分析蝴蝶效应
  Future<ButterflyAnalysisResult> _llmAnalyze({
    required String eventTitle,
    required String eventDescription,
    required String changeDescription,
    required String characterContext,
  }) async {
    final prompt = promptService.renderPrompt('butterfly_effect', {
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'changeDescription': changeDescription,
      'characterContext': characterContext,
    });

    final request = LLMRequest(
      messages: [LLMMessage(role: 'system', content: prompt)],
      temperature: 0.7,
      maxTokens: 2048,
    );

    final result = await retryHandler.execute(() =>
        LLMFactory.create(_providerName)
            .generateStructured<ButterflyAnalysisResult>(
          request,
          ButterflyAnalysisResult.fromJson,
        ));

    return result;
  }
}

/// 蝴蝶效应分析结果
class ButterflyAnalysisResult {
  // 预估费用

  const ButterflyAnalysisResult({
    required this.predictedDirection,
    required this.impacts,
    this.tokenCost = 0,
    this.estimatedCost = 0.0,
  });

  factory ButterflyAnalysisResult.fromJson(Map<String, dynamic> json) =>
      ButterflyAnalysisResult(
        predictedDirection: json['predictedDirection'] as String? ?? '',
        impacts: (json['impacts'] as List?)
                ?.map(
                    (i) => CharacterImpact.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        tokenCost: json['tokenCost'] as int? ?? 0,
        estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      );
  final String predictedDirection; // 剧情走向预测
  final List<CharacterImpact> impacts; // 角色影响列表
  final int tokenCost; // 消耗 token 数
  final double estimatedCost;

  Map<String, dynamic> toJson() => {
        'predictedDirection': predictedDirection,
        'impacts': impacts.map((i) => i.toJson()).toList(),
        'tokenCost': tokenCost,
        'estimatedCost': estimatedCost,
      };
}

/// 角色影响数据
class CharacterImpact {
  // positive / negative / neutral

  const CharacterImpact({
    required this.characterId,
    required this.characterName,
    required this.weightDelta,
    required this.reason,
    this.direction = 'neutral',
  });

  factory CharacterImpact.fromJson(Map<String, dynamic> json) =>
      CharacterImpact(
        characterId: json['characterId'] as String? ?? '',
        characterName: json['characterName'] as String? ?? '',
        weightDelta: json['weightDelta'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        direction: json['direction'] as String? ?? 'neutral',
      );
  final String characterId;
  final String characterName;
  final int weightDelta; // 权重变化 -100 ~ +100
  final String reason; // 影响原因
  final String direction;

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'characterName': characterName,
        'weightDelta': weightDelta,
        'reason': reason,
        'direction': direction,
      };
}
