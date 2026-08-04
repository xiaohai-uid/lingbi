/// Fusion P1 routing prototype (throwaway).
///
/// Run: `dart run tool/prototype/fusion_p1_route_proto.dart`
library;

import 'dart:io';

class NodeSpec {
  const NodeSpec({
    required this.nodeId,
    required this.nodeType,
    required this.inputs,
    required this.outputs,
    this.maxRounds = 1,
  });

  final String nodeId;
  final String nodeType;
  final List<String> inputs;
  final List<String> outputs;
  final int maxRounds;
}

class WorkflowEntry {
  const WorkflowEntry({
    required this.entryId,
    required this.displayName,
    required this.nodes,
    this.contextKeys = const [],
    this.requiresTools = const [],
  });

  final String entryId;
  final String displayName;
  final List<NodeSpec> nodes;
  final List<String> contextKeys;
  final List<String> requiresTools;
}

class RouteRule {
  const RouteRule({
    required this.entryId,
    required this.displayName,
    required this.sceneKeywords,
    required this.intentKeywords,
    required this.requiresSelection,
    required this.nodes,
  });

  final String entryId;
  final String displayName;
  final List<String> sceneKeywords;
  final List<String> intentKeywords;
  final bool requiresSelection;
  final List<NodeSpec> nodes;
}

class RouteResult {
  const RouteResult.success(this.entry) : missReason = null;
  const RouteResult.miss(this.missReason) : entry = null;

  final WorkflowEntry? entry;
  final String? missReason;
}

class RouteEngine {
  const RouteEngine(this.rules);

  static const threshold = 0.6;
  static const sceneWeight = 0.5;
  static const intentWeight = 0.3;
  static const inputWeight = 0.2;

  final List<RouteRule> rules;

  RouteResult route({
    required String message,
    required bool hasSelection,
  }) {
    RouteRule? best;
    double bestScore = 0;

    for (final rule in rules) {
      final sceneScore =
          _anyHit(message, rule.sceneKeywords) ? 1.0 : 0.0;
      final intentScore =
          _anyHit(message, rule.intentKeywords) ? 1.0 : 0.0;
      final inputScore =
          rule.requiresSelection ? (hasSelection ? 1.0 : 0.0) : 1.0;
      final score = sceneScore * sceneWeight +
          intentScore * intentWeight +
          inputScore * inputWeight;
      if (score >= threshold && score > bestScore) {
        best = rule;
        bestScore = score;
      }
    }

    if (best == null) {
      return const RouteResult.miss('未命中，保持普通对话');
    }
    return RouteResult.success(WorkflowEntry(
      entryId: best.entryId,
      displayName: best.displayName,
      nodes: best.nodes,
    ));
  }

  bool _anyHit(String message, List<String> keywords) {
    for (final keyword in keywords) {
      if (message.contains(keyword)) return true;
    }
    return false;
  }
}

List<RouteRule> defaultRules() => [
      const RouteRule(
        entryId: 'smart-continuation',
        displayName: '智能续写',
        sceneKeywords: ['续写', '下一章'],
        intentKeywords: ['续写', '继续'],
        requiresSelection: false,
        nodes: [
          NodeSpec(
            nodeId: 'context_assembly',
            nodeType: 'agent',
            inputs: ['chapter_draft', 'world_state'],
            outputs: ['assembled_context'],
          ),
          NodeSpec(
            nodeId: 'draft',
            nodeType: 'agent',
            inputs: ['assembled_context'],
            outputs: ['chapter_draft'],
            maxRounds: 2,
          ),
          NodeSpec(
            nodeId: 'validate',
            nodeType: 'gate',
            inputs: ['chapter_draft'],
            outputs: ['validated_draft'],
          ),
          NodeSpec(
            nodeId: 'candidate',
            nodeType: 'candidate',
            inputs: ['validated_draft'],
            outputs: ['candidate'],
          ),
        ],
      ),
      const RouteRule(
        entryId: 'dialogue-polish',
        displayName: '文本润色',
        sceneKeywords: ['润色'],
        intentKeywords: ['润色', '改写', '优化'],
        requiresSelection: true,
        nodes: [
          NodeSpec(
            nodeId: 'draft',
            nodeType: 'agent',
            inputs: ['selected_text'],
            outputs: ['polished_text'],
            maxRounds: 2,
          ),
          NodeSpec(
            nodeId: 'validate',
            nodeType: 'gate',
            inputs: ['polished_text'],
            outputs: ['validated_text'],
          ),
          NodeSpec(
            nodeId: 'candidate',
            nodeType: 'candidate',
            inputs: ['validated_text'],
            outputs: ['candidate'],
          ),
        ],
      ),
      const RouteRule(
        entryId: 'deai-polisher',
        displayName: '降低AI痕迹',
        sceneKeywords: ['去AI味', '降低AI痕迹'],
        intentKeywords: ['去AI', '自然', '痕迹'],
        requiresSelection: true,
        nodes: [
          NodeSpec(
            nodeId: 'draft',
            nodeType: 'agent',
            inputs: ['selected_text'],
            outputs: ['deai_text'],
            maxRounds: 2,
          ),
          NodeSpec(
            nodeId: 'validate',
            nodeType: 'gate',
            inputs: ['deai_text'],
            outputs: ['validated_text'],
          ),
          NodeSpec(
            nodeId: 'candidate',
            nodeType: 'candidate',
            inputs: ['validated_text'],
            outputs: ['candidate'],
          ),
        ],
      ),
    ];

void main() {
  final engine = RouteEngine(defaultRules());
  final cases = [
    ('帮我续写下一章', false),
    ('润色这段', true),
    ('降低AI痕迹', true),
    ('今天天气怎么样', false),
  ];

  for (final (message, hasSelection) in cases) {
    final result = engine.route(message: message, hasSelection: hasSelection);
    stdout.writeln('输入: $message | 选中: $hasSelection');
    final entry = result.entry;
    if (entry == null) {
      stdout.writeln('结果: ${result.missReason}');
    } else {
      stdout.writeln('结果: ${entry.entryId} (${entry.displayName})');
      stdout.writeln(
        '节点: ${entry.nodes.map((node) => node.nodeId).join(' -> ')}',
      );
    }
    stdout.writeln();
  }
}
