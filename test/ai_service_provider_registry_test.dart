import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/quota_service.dart';
import 'package:lingbi/services/provider_registry.dart';

void main() {
  group('AIService + ProviderRegistry', () {
    test('uses active provider config from ProviderRegistry for name', () {
      final registry = ProviderRegistry();
      registry.add(ProviderConfig(
        name: 'My Proxy',
        baseUrl: 'https://my-proxy.com/v1',
        apiKey: 'sk-test',
        selectedModel: 'gpt-4o',
      ));
      final ai = AIService(quotaService: QuotaService(), providerRegistry: registry);
      expect(ai.currentProviderName, 'My Proxy');
    });

    test('availableProviders includes custom providers', () {
      final registry = ProviderRegistry();
      registry.add(ProviderConfig(
        name: 'My Proxy',
        baseUrl: 'https://my-proxy.com/v1',
        selectedModel: 'gpt-4o',
      ));
      final ai = AIService(quotaService: QuotaService(), providerRegistry: registry);
      expect(ai.availableProviders, contains('My Proxy'));
      expect(ai.availableProviders, contains('free'));
    });

    test('falls back to LLMFactory when ProviderRegistry is empty', () {
      final registry = ProviderRegistry();
      final ai = AIService(quotaService: QuotaService(), providerRegistry: registry);
      expect(ai.currentProviderName, 'free');
      expect(ai.availableProviders, contains('free'));
    });

    test('fallback works when ProviderRegistry is null', () {
      final ai = AIService(quotaService: QuotaService());
      expect(ai.currentProviderName, 'free');
      expect(ai.availableProviders, contains('free'));
    });

    test('chat does not throw when using custom provider from registry', () {
      final registry = ProviderRegistry();
      registry.add(ProviderConfig(
        name: 'My Proxy',
        baseUrl: 'https://my-proxy.com/v1',
        apiKey: 'sk-test',
        selectedModel: 'gpt-4o',
      ));
      final ai = AIService(quotaService: QuotaService(), providerRegistry: registry);
      expect(() => ai.chat(message: 'test'), returnsNormally);
    });

    test('setActiveProvider switches when multiple providers exist', () {
      final registry = ProviderRegistry();
      final p1 = ProviderConfig(name: 'A', baseUrl: 'https://a.com/v1', selectedModel: 'm1');
      final p2 = ProviderConfig(name: 'B', baseUrl: 'https://b.com/v1', selectedModel: 'm2');
      registry.add(p1);
      registry.add(p2);
      expect(registry.getActiveProvider()?.name, 'A');

      registry.setActiveProvider(p2.id);
      expect(registry.getActiveProvider()?.name, 'B');
    });

    test('defaultParams from active provider is accessible', () {
      final registry = ProviderRegistry();
      registry.add(ProviderConfig(
        name: 'My Proxy',
        baseUrl: 'https://my-proxy.com/v1',
        selectedModel: 'gpt-4o',
        defaultParams: const DefaultParams(temperature: 0.3, maxTokens: 4096, topP: 0.8),
      ));
      final active = registry.getActiveProvider()!;
      expect(active.defaultParams.temperature, 0.3);
      expect(active.defaultParams.maxTokens, 4096);
      expect(active.defaultParams.topP, 0.8);
    });
  });
}