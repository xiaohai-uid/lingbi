import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('onboarding wizard contract', () {
    test('wizard UI files exist', () {
      expect(
        File('lib/features/onboarding/ui/guided_wizard_page.dart').existsSync(),
        isTrue,
      );
      expect(
        File('lib/features/onboarding/ui/wizard_card_selector.dart')
            .existsSync(),
        isTrue,
      );
    });

    test('gate routes new users to wizard instead of auto-completing', () {
      final gate = File(
        'lib/features/onboarding/ui/onboarding_gate.dart',
      ).readAsLinesSync().join('\n');

      expect(gate, contains('GuidedWizardPage'));
      expect(gate, isNot(contains('markOnboardingComplete')));
    });

    test('wizard embeds model configuration', () {
      final page = File(
        'lib/features/onboarding/ui/guided_wizard_page.dart',
      ).readAsLinesSync().join('\n');

      expect(page, contains('_buildModelConfig'));
      expect(page, contains('ModelSelector'));
    });
  });
}
