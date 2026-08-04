/// Fusion P1 路由引擎单元测试。
///
/// 覆盖 RouteEngine 默认规则、SkillActionService 路由执行、
/// AIService system prompt 注入和 SkillMarketPage 路由元数据映射。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/routing/default_rules.dart';
import 'package:lingbi/features/routing/route_engine.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';

void main() {
  group('RouteEngine 默认规则', () {
    final engine = RouteEngine(rules: defaultRouteRules());

    test('“帮我续写下一章”路由到智能续写 WorkflowEntry', () {
      final result = engine.route(userMessage: '帮我续写下一章');

      expect(result, isNotNull);
      expect(result!.skillId, 'smart-continuation');
      expect(result.entry.displayName, '智能续写');
      expect(result.score, greaterThanOrEqualTo(0.6));
      expect(result.entry.nodes, isNotEmpty);
      expect(result.matchedKeys, isNotEmpty);
    });

    test('“润色这段”且有选区时路由到文本润色', () {
      final result = engine.route(
        userMessage: '润色这段',
        selection: '这是需要润色的文本。',
      );

      expect(result, isNotNull);
      expect(result!.skillId, 'dialogue-polish');
      expect(result.score, greaterThanOrEqualTo(0.6));
    });

    test('“降低AI痕迹”且有选区时路由到 deai-polisher', () {
      final result = engine.route(
        userMessage: '降低AI痕迹',
        selection: '这是一段足够长、明显带有 AI 写作痕迹的候选文本。',
      );

      expect(result, isNotNull);
      expect(result!.skillId, 'deai-polisher');
    });

    test('“今天天气怎么样”不命中任何规则', () {
      final result = engine.route(userMessage: '今天天气怎么样');
      expect(result, isNull);
    });

    test('selection-only 规则在没有选区时不命中', () {
      final result = engine.route(userMessage: '润色这段');
      expect(result, isNull);
    });

    test('WorkflowEntry 包含节点链', () {
      final entry = defaultRouteRuleFor('smart-continuation')!.entry;
      final nodeIds = entry.nodes.map((node) => node.nodeId).toList();

      expect(nodeIds,
          containsAll(['context_assembly', 'draft', 'gate', 'candidate']));
      expect(entry.nodes.first.nodeType, NodeType.agent);
      expect(entry.nodes.last.maxRounds, greaterThanOrEqualTo(1));
    });
  });

  group('SkillActionService 路由', () {
    test('内置技能初始化前路由返回 null', () {
      final service = SkillActionService();
      expect(service.routeTask(userMessage: '帮我续写下一章'), isNull);
    });

    test('routeTask 只返回已注册技能', () {
      final service = SkillActionService()..initializeBuiltinSkills();
      final result = service.routeTask(userMessage: '帮我续写下一章');

      expect(result, isNotNull);
      expect(result!.skillId, 'smart-continuation');
    });

    test('executeRouted 自动执行命中的技能并保留手动入口', () {
      final service = SkillActionService()..initializeBuiltinSkills();
      final routed = service.executeRouted(
        userMessage: '帮我续写下一章',
        context: const SkillContext(
          fullDocument: '这是一段足够长的前文内容，用于测试智能续写是否正常工作。',
        ),
      );
      final manual = service.executeSkill(
        skillId: 'dialogue-polish',
        context: const SkillContext(selectedText: '这是需要润色的文本。'),
      );

      expect(routed.success, true);
      expect(routed.promptForAI, contains('续写'));
      expect(manual.success, true);
    });
  });

  group('AIService system prompt 注入', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService(quotaService: QuotaService());
    });

    test('续写消息注入 Available Skills', () {
      final prompt = aiService.systemPromptFor(userMessage: '帮我续写下一章');

      expect(prompt, contains('Available Skills'));
      expect(prompt, contains('smart-continuation'));
      expect(prompt, contains('智能续写'));
    });

    test('润色消息带选区时注入 dialogue-polish', () {
      final prompt = aiService.systemPromptFor(
        userMessage: '润色这段',
        selection: '需要润色的文本。',
      );

      expect(prompt, contains('dialogue-polish'));
    });

    test('无路由消息不注入技能元数据', () {
      final prompt = aiService.systemPromptFor(userMessage: '今天天气怎么样');
      expect(prompt, isNot(contains('smart-continuation')));
    });
  });

  group('RouteRule 元数据映射', () {
    test('内置技能映射到默认路由规则', () {
      expect(defaultRouteRuleFor('smart-continuation'), isNotNull);
      expect(defaultRouteRuleFor('dialogue-polish'), isNotNull);
      expect(defaultRouteRuleFor('deai-polisher'), isNotNull);
    });

    test('未知技能返回 null', () {
      expect(defaultRouteRuleFor('not-a-skill'), isNull);
    });
  });
}
