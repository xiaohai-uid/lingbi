import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/domain/runtime/node_recovery.dart';
import 'package:lingbi/features/routing/gate/output_gate.dart';
import 'package:lingbi/features/routing/ledger/token_ledger.dart';
import 'package:lingbi/features/routing/miss/route_miss_aggregator.dart';
import 'package:lingbi/features/routing/tool_bootstrap.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

void main() {
  test('three misses in one scene emit a suggestion', () {
    final aggregator = RouteMissAggregator();

    expect(aggregator.suggestions(), isEmpty);
    aggregator.recordMiss(scene: 'weather', userMessage: '今天天气怎么样');
    aggregator.recordMiss(scene: 'weather', userMessage: '明天会下雨吗');
    aggregator.recordMiss(scene: 'weather', userMessage: '天气查询');

    final suggestions = aggregator.suggestions();
    expect(suggestions, hasLength(1));
    expect(suggestions.single.scene, 'weather');
    expect(suggestions.single.count, 3);
    expect(suggestions.single.suggestedSkillId, 'skill:weather');
  });

  test('SkillActionService records misses and exposes suggestions', () {
    final aggregator = RouteMissAggregator();
    final service = SkillActionService(missAggregator: aggregator);

    service.routeTask(userMessage: '今天天气怎么样', currentScene: 'weather');
    service.routeTask(userMessage: '明天会下雨吗', currentScene: 'weather');
    service.routeTask(userMessage: '天气查询', currentScene: 'weather');

    expect(service.suggestions, hasLength(1));
  });

  test('miss suggestion panel is wired into toolbox', () {
    expect(
      File('lib/features/routing/ui/route_miss_suggestions_panel.dart')
          .existsSync(),
      isTrue,
    );
    final toolbox = File(
      'lib/ui_v2/components/toolbox_page.dart',
    ).readAsLinesSync().join('\n');
    expect(toolbox, contains('新技能建议'));
    expect(toolbox, contains('RouteMissSuggestionsPanel'));
  });

  test('Fusion P1-P7 acceptance pieces work together', () async {
    final aggregator = RouteMissAggregator();
    final service = SkillActionService(
      missAggregator: aggregator,
      toolBootstrap: ToolBootstrap(
        probe: (_) async => const ToolStatus(available: true),
      ),
    )..initializeBuiltinSkills();

    final route = service.routeTask(
      userMessage: '帮我续写下一章',
      currentScene: 'novel_continuation',
    );
    expect(route, isNotNull);

    final ledgerDir = Directory.systemTemp.createTempSync('lingbi_p7_ledger_');
    addTearDown(() => ledgerDir.deleteSync(recursive: true));
    final ledger = TokenLedger(basePath: ledgerDir.path);
    ledger.append(const TokenLedgerEntry(
      runId: 'run-1',
      nodeId: 'draft',
      attempt: 0,
      promptTokens: 10,
      completionTokens: 20,
      providerId: 'free',
    ));
    final usage = await ledger.summarize('run-1');
    expect(usage.totalTokens, 30);

    const gate = StructureGate(requiredFields: ['title']);
    final repaired = await gate.repair(
      output: '{}',
      repair: (_, __) async => '{"title":"ok"}',
    );
    expect(repaired.passed, isTrue);

    final recovery = NodeRecoveryState(
      runId: 'run-1',
      workflowVersion: 1,
      nodeIds: const ['context', 'draft'],
      completedNodeIds: const {'context'},
    );
    expect(recovery.nextNodeId, 'draft');

    service.routeTask(userMessage: '天气', currentScene: 'weather');
    service.routeTask(userMessage: '天气2', currentScene: 'weather');
    service.routeTask(userMessage: '天气3', currentScene: 'weather');
    expect(service.suggestions, isNotEmpty);
  });
}
