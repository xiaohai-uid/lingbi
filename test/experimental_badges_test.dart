import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/ui_v2/components/project_tabs.dart';
import 'package:lingbi/ui_v2/components/toolbox_page.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

void main() {
  setUp(() {
    ServiceLocator.failed();
  });

  testWidgets('toolbox marks experimental tools', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: const Scaffold(body: ToolboxPage()),
      ),
    );
    await tester.pump();

    const experimentalTools = [
      '一键成剧',
      '平行世界',
      '流程审批',
      '六维审稿',
      '清晰度检测',
      '反幻觉监督',
      '参考书',
      '向量知识',
      '网络搜索',
      '风格蒸馏',
      '市场情报',
      '去AI味',
      '叙事线编织',
    ];

    for (final label in experimentalTools) {
      final textFinder = find.text(label);
      await tester.scrollUntilVisible(
        textFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(textFinder, findsOneWidget, reason: 'missing $label');
      final itemFinder = find.ancestor(
        of: textFinder,
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: itemFinder, matching: find.text('Experimental')),
        findsWidgets,
        reason: '$label should be marked Experimental',
      );
    }
  });

  testWidgets('project navigation marks experimental tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: Scaffold(
          body: ProjectNavigationBar(
            currentTab: ProjectTab.overview,
            onTabChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('EXP'), findsNWidgets(3));
    expect(find.text('总览'), findsOneWidget);
    expect(find.text('写作'), findsOneWidget);
  });
}
