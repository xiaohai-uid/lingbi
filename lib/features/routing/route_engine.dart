/// Fusion P1 路由引擎。
///
/// 路由结果从“单个技能”升级为 [WorkflowEntry]，后续节点执行、
/// Token 账本和输出门可以在同一入口上继续扩展。
library;

import 'tool_bootstrap.dart';

/// 路由维度类型。
enum RouteDimensionId {
  scene,
  intent,
  inputScope,
}

/// 路由维度 — 一条规则由多个维度加权打分。
class RouteDimension {
  const RouteDimension({
    required this.id,
    required this.value,
    required this.keywords,
    required this.weight,
    this.requiresSelection = false,
  });

  final RouteDimensionId id;
  final String value;
  final List<String> keywords;
  final double weight;

  /// 该维度要求调用方提供非空选区。
  final bool requiresSelection;
}

/// 流程节点类型。
enum NodeType {
  agent,
  script,
  approval,
  gate,
}

/// 流程节点规格。
class NodeSpec {
  const NodeSpec({
    required this.nodeId,
    this.nodeType = NodeType.agent,
    this.inputs = const [],
    this.outputs = const [],
    this.maxRounds = 1,
  });

  final String nodeId;
  final NodeType nodeType;
  final List<String> inputs;
  final List<String> outputs;
  final int maxRounds;
}

/// 流程入口 — 路由命中后返回的执行链。
class WorkflowEntry {
  const WorkflowEntry({
    required this.entryId,
    required this.displayName,
    this.nodes = const [],
    this.contextKeys = const [],
    this.requiresTools = const [],
  });

  final String entryId;
  final String displayName;
  final List<NodeSpec> nodes;
  final List<String> contextKeys;
  final List<ToolRequirement> requiresTools;
}

/// 路由规则 — 一组维度条件和一个流程入口。
class RouteRule {
  const RouteRule({
    required this.entry,
    required this.dimensions,
    this.minScore = 0.6,
    this.fallbackPrompt = '',
  });

  final WorkflowEntry entry;
  final List<RouteDimension> dimensions;
  final double minScore;
  final String fallbackPrompt;

  bool get requiresSelection =>
      dimensions.any((dimension) => dimension.requiresSelection);
}

/// 路由结果 — 包含命中规则、得分和可解释的关键词证据。
class RouteResult {
  const RouteResult({
    required this.rule,
    required this.score,
    this.matchedKeys = const [],
  });

  final RouteRule rule;
  final double score;
  final List<String> matchedKeys;

  WorkflowEntry get entry => rule.entry;
  String get skillId => rule.entry.entryId;
}

/// 路由引擎 — 对用户消息、选区、当前场景做加权匹配。
class RouteEngine {
  RouteEngine({required List<RouteRule> rules})
      : _rules = List.unmodifiable(rules);

  final List<RouteRule> _rules;

  /// 路由用户任务。
  ///
  /// 未命中或选区不足时返回 `null`，不强行执行任何技能。
  RouteResult? route({
    required String userMessage,
    String? selection,
    String currentScene = '',
  }) {
    final normalizedMessage = userMessage.toLowerCase();
    final scored = <(RouteRule, double, List<String>)>[];

    for (final rule in _rules) {
      if (rule.requiresSelection &&
          (selection == null || selection.trim().isEmpty)) {
        continue;
      }

      var totalWeight = 0.0;
      var matchedWeight = 0.0;
      final matchedKeys = <String>[];
      for (final dimension in rule.dimensions) {
        totalWeight += dimension.weight;
        final keys = _matchedKeys(
          dimension,
          normalizedMessage,
          selection,
          currentScene,
        );
        if (keys.isNotEmpty) {
          matchedWeight += dimension.weight;
          matchedKeys.addAll(keys);
        }
      }
      if (totalWeight == 0) continue;

      final score = matchedWeight / totalWeight;
      if (score >= rule.minScore) {
        scored.add((rule, score, matchedKeys));
      }
    }

    if (scored.isEmpty) return null;
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final best = scored.first;
    return RouteResult(
      rule: best.$1,
      score: best.$2,
      matchedKeys: List.unmodifiable(best.$3),
    );
  }

  List<String> _matchedKeys(
    RouteDimension dimension,
    String normalizedMessage,
    String? selection,
    String currentScene,
  ) {
    final keys = <String>[];
    if (dimension.requiresSelection) {
      if (selection == null || selection.trim().isEmpty) return keys;
      keys.add('${dimension.id.name}:selection');
    }
    if (currentScene.isNotEmpty && dimension.value == currentScene) {
      keys.add('${dimension.id.name}:scene');
    }
    for (final keyword in dimension.keywords) {
      if (normalizedMessage.contains(keyword.toLowerCase())) {
        keys.add('${dimension.id.name}:$keyword');
      }
    }
    return keys;
  }
}
