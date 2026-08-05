import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/features/routing/tool_bootstrap.dart';
import 'package:lingbi/features/routing/route_engine.dart';
import 'package:lingbi/features/skill/data/skill/skill_manifest.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

void main() {
  test('missing tool returns unavailable with install hint', () async {
    final bootstrap = ToolBootstrap(
      probe: (kind) async => kind == ToolKind.git
          ? const ToolStatus(
              available: false,
              detail: 'git not found',
              installHint: '请安装 git 后重试',
            )
          : const ToolStatus(available: true),
    );

    final status = await bootstrap.check(
      const ToolRequirement(
        kind: ToolKind.git,
        label: 'git',
        installHint: '请安装 git 后重试',
      ),
    );

    expect(status.available, isFalse);
    expect(status.installHint, contains('安装 git'));
  });

  test('checkAll reports missing tools without crashing', () async {
    final bootstrap = ToolBootstrap(
      probe: (kind) async => ToolStatus(available: kind != ToolKind.crawl4ai),
    );
    final results = await bootstrap.checkAll(const [
      ToolRequirement(kind: ToolKind.git, label: 'git'),
      ToolRequirement(kind: ToolKind.crawl4ai, label: 'crawl4ai'),
    ]);

    expect(results[ToolKind.git]?.available, isTrue);
    expect(results[ToolKind.crawl4ai]?.available, isFalse);
  });

  test('WorkflowEntry carries requiresTools', () {
    const entry = WorkflowEntry(
      entryId: 'entry',
      displayName: 'Entry',
      requiresTools: [
        ToolRequirement(kind: ToolKind.python, label: 'python'),
      ],
    );

    expect(entry.requiresTools.single.kind, ToolKind.python);
  });

  test('SkillManifest parser reads requires_tools', () {
    final manifest = SkillManifestParser.parse('''
---
name: test-skill
description: test
requires_tools: git, python
---
# Test
Body
''', 'test-skill');

    expect(
      manifest.requiresTools.map((r) => r.kind),
      containsAll([ToolKind.git, ToolKind.python]),
    );
  });

  test('executeRoutedAsync refuses missing workflow tools', () async {
    const rule = RouteRule(
      entry: WorkflowEntry(
        entryId: 'smart-continuation',
        displayName: '智能续写',
        requiresTools: [
          ToolRequirement(kind: ToolKind.git, label: 'git'),
        ],
      ),
      dimensions: [
        RouteDimension(
          id: RouteDimensionId.intent,
          value: 'create',
          keywords: ['续写'],
          weight: 1,
        ),
      ],
    );
    final service = SkillActionService(
      routeEngine: RouteEngine(rules: [rule]),
      toolBootstrap: ToolBootstrap(
        probe: (_) async => const ToolStatus(available: false),
      ),
    )..initializeBuiltinSkills();

    final result = await service.executeRoutedAsync(
      userMessage: '帮我续写下一章',
      context: const SkillContext(
        fullDocument: '这是一段足够长的前文内容，用于测试智能续写是否正常工作。',
      ),
      currentScene: 'novel_continuation',
    );

    expect(result.success, isFalse);
    expect(result.error, contains('缺少工具'));
  });

  test('settings capability panel is wired', () {
    expect(
      File('lib/features/settings/ui/sections/capability_settings_section.dart')
          .existsSync(),
      isTrue,
    );
    final page = File(
      'lib/features/settings/ui/settings_page.dart',
    ).readAsLinesSync().join('\n');
    expect(page, contains("'能力'"));
    expect(page, contains('CapabilitySettingsSection'));
  });
}
