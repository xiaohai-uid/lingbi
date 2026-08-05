import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:lingbi/features/onboarding/ui/onboarding_gate.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch opens the two-screen wizard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final locator = await ServiceLocator.init();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: OnboardingGate(
          isDarkMode: false,
          onToggleTheme: (_) {},
          settingsService: locator.settingsService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('快速选择'), findsOneWidget);
    expect(find.text('题材'), findsWidgets);
  });

  testWidgets('screen one completion opens deep fill with model config',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final locator = await ServiceLocator.init();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [LingBiColors.light]),
        home: OnboardingGate(
          isDarkMode: false,
          onToggleTheme: (_) {},
          settingsService: locator.settingsService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('玄幻'));
    await tester.tap(find.text('长篇'));
    await tester.tap(find.text('起点'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    expect(find.text('深度填写'), findsOneWidget);
    expect(find.text('模型配置'), findsOneWidget);
    expect(find.text('免费模型'), findsOneWidget);
  });
}
