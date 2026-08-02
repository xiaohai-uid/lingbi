import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/models/endpoint_config.dart';
import 'package:lingbi/shared/ai/provider_factory.dart';
import 'package:lingbi/shared/ai/providers/openai_compatible_provider.dart';
import 'package:lingbi/shared/ai/providers/anthropic_provider.dart';

void main() {
  group('Protocol', () {
    test('openai has correct name', () {
      expect(Protocol.openai.name, 'openai');
    });

    test('anthropic has correct name', () {
      expect(Protocol.anthropic.name, 'anthropic');
    });

    test('values contains both protocols', () {
      expect(Protocol.values, containsAll([Protocol.openai, Protocol.anthropic]));
    });
  });

  group('EndpointConfig', () {
    const openaiConfig = EndpointConfig(
      id: 'test-openai',
      name: 'Test OpenAI',
      baseUrl: 'https://api.test.com/v1',
      apiKey: 'sk-test-key',
      protocol: Protocol.openai,
      modelId: 'gpt-4o',
      authStrategy: 'bearer',
    );

    const anthropicConfig = EndpointConfig(
      id: 'test-anthropic',
      name: 'Test Anthropic',
      baseUrl: 'https://api.anthropic-test.com',
      apiKey: 'sk-ant-test',
      protocol: Protocol.anthropic,
      modelId: 'claude-sonnet-4',
      isReasoningModel: true,
    );

    test('creates with all fields', () {
      expect(openaiConfig.id, 'test-openai');
      expect(openaiConfig.name, 'Test OpenAI');
      expect(openaiConfig.baseUrl, 'https://api.test.com/v1');
      expect(openaiConfig.apiKey, 'sk-test-key');
      expect(openaiConfig.protocol, Protocol.openai);
      expect(openaiConfig.modelId, 'gpt-4o');
      expect(openaiConfig.authStrategy, 'bearer');
      expect(openaiConfig.isReasoningModel, false);
    });

    test('creates with default values', () {
      const config = EndpointConfig(
        id: 'minimal',
        name: 'Minimal',
        baseUrl: 'https://api.test.com',
        protocol: Protocol.openai,
        modelId: 'gpt-4o-mini',
      );
      expect(config.isReasoningModel, false);
      expect(config.apiKey, isNull);
      expect(config.authStrategy, isNull);
    });

    test('chatEndpoint for openai protocol', () {
      expect(openaiConfig.chatEndpoint, 'https://api.test.com/v1/chat/completions');
    });

    test('chatEndpoint for anthropic protocol', () {
      expect(anthropicConfig.chatEndpoint, 'https://api.anthropic-test.com/v1/messages');
    });

    test('modelsEndpoint for openai protocol', () {
      expect(openaiConfig.modelsEndpoint, 'https://api.test.com/v1/models');
    });

    test('serializes to JSON', () {
      final json = openaiConfig.toJson();
      expect(json['id'], 'test-openai');
      expect(json['name'], 'Test OpenAI');
      expect(json['baseUrl'], 'https://api.test.com/v1');
      expect(json['apiKey'], 'sk-test-key');
      expect(json['protocol'], 'openai');
      expect(json['modelId'], 'gpt-4o');
      expect(json['authStrategy'], 'bearer');
      expect(json['isReasoningModel'], false);
    });

    test('serializes to JSON (minimal, no apiKey)', () {
      const config = EndpointConfig(
        id: 'no-key',
        name: 'No Key',
        baseUrl: 'https://api.test.com',
        protocol: Protocol.anthropic,
        modelId: 'claude-3',
      );
      final json = config.toJson();
      expect(json['apiKey'], isNull);
      expect(json['authStrategy'], isNull);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 'test-openai',
        'name': 'Test OpenAI',
        'baseUrl': 'https://api.test.com/v1',
        'apiKey': 'sk-test-key',
        'protocol': 'openai',
        'modelId': 'gpt-4o',
        'authStrategy': 'bearer',
        'isReasoningModel': false,
      };
      final config = EndpointConfig.fromJson(json);
      expect(config.id, 'test-openai');
      expect(config.name, 'Test OpenAI');
      expect(config.baseUrl, 'https://api.test.com/v1');
      expect(config.apiKey, 'sk-test-key');
      expect(config.protocol, Protocol.openai);
      expect(config.modelId, 'gpt-4o');
      expect(config.authStrategy, 'bearer');
      expect(config.isReasoningModel, false);
    });

    test('deserializes from JSON (minimal)', () {
      final json = {
        'id': 'minimal',
        'name': 'Minimal',
        'baseUrl': 'https://api.test.com',
        'protocol': 'anthropic',
        'modelId': 'claude-3',
      };
      final config = EndpointConfig.fromJson(json);
      expect(config.id, 'minimal');
      expect(config.protocol, Protocol.anthropic);
      expect(config.apiKey, isNull);
      expect(config.isReasoningModel, false);
    });

    test('deserializes with invalid protocol falls back to openai', () {
      final json = {
        'id': 'bad-proto',
        'name': 'Bad',
        'baseUrl': 'https://api.test.com',
        'protocol': 'unknown',
        'modelId': 'gpt-4o',
      };
      final config = EndpointConfig.fromJson(json);
      expect(config.protocol, Protocol.openai);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = openaiConfig.copyWith(modelId: 'gpt-4o-mini');
      expect(updated.id, 'test-openai');
      expect(updated.name, 'Test OpenAI');
      expect(updated.modelId, 'gpt-4o-mini');
      expect(updated.protocol, Protocol.openai);
    });

    test('copyWith with null fields keeps original', () {
      final updated = openaiConfig.copyWith();
      expect(updated.id, 'test-openai');
      expect(updated.modelId, 'gpt-4o');
    });

    test('equality', () {
      const same = EndpointConfig(
        id: 'test-openai',
        name: 'Test OpenAI',
        baseUrl: 'https://api.test.com/v1',
        apiKey: 'sk-test-key',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
        authStrategy: 'bearer',
      );
      expect(openaiConfig == same, isTrue);
      expect(openaiConfig == anthropicConfig, isFalse);
    });

    test('hashCode consistent with equality', () {
      const same = EndpointConfig(
        id: 'test-openai',
        name: 'Test OpenAI',
        baseUrl: 'https://api.test.com/v1',
        apiKey: 'sk-test-key',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
        authStrategy: 'bearer',
      );
      expect(openaiConfig.hashCode, same.hashCode);
    });

    test('toString includes key fields', () {
      final str = openaiConfig.toString();
      expect(str, contains('test-openai'));
      expect(str, contains('openai'));
      expect(str, contains('gpt-4o'));
    });
  });

  group('ProviderFactory', () {
    test('create returns OpenAICompatibleProvider for openai protocol', () {
      const config = EndpointConfig(
        id: 'test',
        name: 'Test',
        baseUrl: 'https://api.test.com',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
      );
      final provider = ProviderFactory.create(config);
      expect(provider, isA<OpenAICompatibleProvider>());
      expect(provider.name, 'test');
      expect(provider.displayName, 'Test');
    });

    test('create returns AnthropicProvider for anthropic protocol', () {
      const config = EndpointConfig(
        id: 'test-claude',
        name: 'Test Claude',
        baseUrl: 'https://api.anthropic.com',
        protocol: Protocol.anthropic,
        modelId: 'claude-sonnet-4',
      );
      final provider = ProviderFactory.create(config);
      expect(provider, isA<AnthropicProvider>());
      expect(provider.name, 'test-claude');
      expect(provider.displayName, 'Test Claude');
    });
  });
  group('ProviderFactory edge cases', () {
    test('discoverModels returns empty list for anthropic protocol', () async {
      const config = EndpointConfig(
        id: 'test-claude',
        name: 'Test Claude',
        baseUrl: 'https://api.anthropic.com',
        protocol: Protocol.anthropic,
        modelId: 'claude-sonnet-4',
      );
      final models = await ProviderFactory.discoverModels(config);
      expect(models, isEmpty);
    });

    test('discoverModels returns empty list for openai with no apiKey', () async {
      const config = EndpointConfig(
        id: 'test-no-key',
        name: 'Test No Key',
        baseUrl: 'https://api.test.com',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
      );
      final models = await ProviderFactory.discoverModels(config);
      // Without apiKey, discovery should return empty (not crash)
      expect(models, isEmpty);
    });

    test('testConnection handles provider with no apiKey gracefully', () async {
      const config = EndpointConfig(
        id: 'test-no-key',
        name: 'Test No Key',
        baseUrl: 'https://api.test.com',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
      );
      final result = await ProviderFactory.testConnection(config);
      // Without apiKey, chatSync returns error string, not throw
      // ProviderFactory.testConnection returns a result
      expect(result, isNotNull);
    });
  });

}
