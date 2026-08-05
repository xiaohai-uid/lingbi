/// Fusion P1 默认路由规则。
///
/// 首版覆盖智能续写、文本润色和降低 AI 痕迹三个内置技能。
library;

import 'package:lingbi/features/routing/route_engine.dart';

/// 返回默认路由规则。
List<RouteRule> defaultRouteRules() => [
      RouteRule(
        entry: WorkflowEntry(
          entryId: 'smart-continuation',
          displayName: '智能续写',
          nodes: _nodesFor('smart-continuation'),
          contextKeys: const ['canon_summary', 'document', 'candidate'],
        ),
        dimensions: const [
          RouteDimension(
            id: RouteDimensionId.scene,
            value: 'novel_continuation',
            keywords: ['续写', '接着写', '继续', '下一段', '下一章', '往下写', '延伸'],
            weight: 0.5,
          ),
          RouteDimension(
            id: RouteDimensionId.intent,
            value: 'create',
            keywords: ['生成', '创作', '续写', '写'],
            weight: 0.3,
          ),
          RouteDimension(
            id: RouteDimensionId.inputScope,
            value: 'selectionOrDocument',
            keywords: ['续写', '下一章', '继续', '前文', '全文'],
            weight: 0.2,
          ),
        ],
        fallbackPrompt: '请选择一段前文后再续写。',
      ),
      RouteRule(
        entry: WorkflowEntry(
          entryId: 'dialogue-polish',
          displayName: '文本润色',
          nodes: _nodesFor('dialogue-polish'),
          contextKeys: const ['selection', 'candidate'],
        ),
        dimensions: const [
          RouteDimension(
            id: RouteDimensionId.scene,
            value: 'polish',
            keywords: ['润色', '改一下', '优化', '通顺', '修改', '改写'],
            weight: 0.5,
          ),
          RouteDimension(
            id: RouteDimensionId.intent,
            value: 'edit',
            keywords: ['润色', '修改', '改进', '优化', '改写', '调整'],
            weight: 0.3,
          ),
          RouteDimension(
            id: RouteDimensionId.inputScope,
            value: 'selection',
            keywords: [],
            weight: 0.2,
            requiresSelection: true,
          ),
        ],
        fallbackPrompt: '请选中需要润色的文本。',
      ),
      RouteRule(
        entry: WorkflowEntry(
          entryId: 'deai-polisher',
          displayName: '降低AI痕迹',
          nodes: _nodesFor('deai-polisher'),
          contextKeys: const ['selection', 'candidate'],
        ),
        dimensions: const [
          RouteDimension(
            id: RouteDimensionId.scene,
            value: 'deai',
            keywords: ['降低AI痕迹', '像人写', '去AI味', '少AI味', 'AI味'],
            weight: 0.5,
          ),
          RouteDimension(
            id: RouteDimensionId.intent,
            value: 'edit',
            keywords: ['修改', '改写', '优化', '降低', '消除'],
            weight: 0.3,
          ),
          RouteDimension(
            id: RouteDimensionId.inputScope,
            value: 'selection',
            keywords: [],
            weight: 0.2,
            requiresSelection: true,
          ),
        ],
        fallbackPrompt: '请选中需要降低 AI 痕迹的文本。',
      ),
    ];

/// 根据技能 ID 查找默认路由规则。
RouteRule? defaultRouteRuleFor(String skillId) {
  for (final rule in defaultRouteRules()) {
    if (rule.entry.entryId == skillId) return rule;
  }
  return null;
}

List<NodeSpec> _nodesFor(String entryId) {
  switch (entryId) {
    case 'smart-continuation':
    case 'dialogue-polish':
    case 'deai-polisher':
      return const [
        NodeSpec(
          nodeId: 'context_assembly',
          inputs: ['canon_summary', 'document'],
          outputs: ['generation_context'],
        ),
        NodeSpec(
          nodeId: 'draft',
          inputs: ['generation_context'],
          outputs: ['candidate_text'],
          maxRounds: 2,
        ),
        NodeSpec(
          nodeId: 'gate',
          nodeType: NodeType.gate,
          inputs: ['candidate_text'],
          outputs: ['validated_text'],
        ),
        NodeSpec(
          nodeId: 'candidate',
          nodeType: NodeType.approval,
          inputs: ['validated_text'],
          outputs: ['candidate'],
        ),
      ];
    default:
      return const [
        NodeSpec(
          nodeId: 'agent',
          outputs: ['candidate'],
        ),
      ];
  }
}
