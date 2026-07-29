import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/modules/pipeline/novel_application_service.dart';
import 'package:lingbi/ui_v2/components/chapter_settlement_panel.dart';

void main() {
  SettlementProposal proposal() => SettlementProposal(
        id: 'stl-3',
        chapterId: '第3章',
        candidateId: 'candidate-3',
        items: const [
          SettlementItem(
            category: 'new_character',
            entityName: '陆离',
            description: '陆离首次登场。',
          ),
          SettlementItem(
            category: 'item_change',
            entityName: '铜牌',
            description: '铜牌交到沈砚手中。',
          ),
        ],
      );

  testWidgets('lets the author select facts before confirming', (tester) async {
    Set<int>? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChapterSettlementPanel(
            proposal: proposal(),
            onConfirm: (selected) async => confirmed = selected,
            onSkip: () async {},
          ),
        ),
      ),
    );

    expect(find.text('章节状态结算'), findsOneWidget);
    expect(find.text('陆离首次登场。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settlement-item-0')));
    await tester.tap(find.byKey(const ValueKey('confirm-settlement')));
    await tester.pumpAndSettle();

    expect(confirmed, {1});
  });

  testWidgets('supports explicitly skipping a settlement', (tester) async {
    var skipped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChapterSettlementPanel(
            proposal: proposal(),
            onConfirm: (_) async {},
            onSkip: () async => skipped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('skip-settlement')));
    await tester.pumpAndSettle();

    expect(skipped, isTrue);
  });
}
