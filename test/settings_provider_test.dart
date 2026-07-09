import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/settings_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/quota_service.dart';
import 'package:lingbi/services/provider_registry.dart';

void main() {
  group('SettingsService provider registry', () {
    test('starts with empty provider registry', () {
      final ai = AIService(quotaService: QuotaService());
      final settings = SettingsService(aiService: ai);
      expect(settings.providerRegistry.getAll(), isEmpty);
    });

    test('addProvider stores a provider config', () {
      final ai = AIService(quotaService: QuotaService());
      final settings = SettingsService(aiService: ai);
      final config =
          ProviderConfig(name: 'Test', baseUrl: 'https://test.com/v1');
      settings.addProvider(config);
      expect(settings.providerRegistry.getAll().length, 1);
      expect(settings.providerRegistry.getAll()[0].name, 'Test');
    });
  });
}
