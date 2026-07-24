import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/model_registry.dart';

void main() {
  group('ModelInfo', () {
    test('creates with all fields', () {
      const info = ModelInfo(
        id: 'gpt-4o',
        displayName: 'GPT-4o',
        providerId: 'openai',
        contextWindow: 128000,
        maxOutputTokens: 16384,
        category: '主力',
        recommended: true,
        deprecated: false,
      );
      expect(info.id, 'gpt-4o');
      expect(info.displayName, 'GPT-4o');
      expect(info.providerId, 'openai');
      expect(info.contextWindow, 128000);
      expect(info.category, '主力');
      expect(info.recommended, true);
      expect(info.deprecated, false);
    });

    test('defaults recommended to false and deprecated to false', () {
      const info = ModelInfo(id: 'test', displayName: 'Test', providerId: 'x');
      expect(info.recommended, false);
      expect(info.deprecated, false);
    });

    test('contextWindowLabel formats correctly', () {
      const m1 = ModelInfo(id: 'a', displayName: 'A', providerId: 'p', contextWindow: 128000);
      const m2 = ModelInfo(id: 'b', displayName: 'B', providerId: 'p', contextWindow: 1000000);
      const m3 = ModelInfo(id: 'c', displayName: 'C', providerId: 'p');
      expect(m1.contextWindowLabel, '128K');
      expect(m2.contextWindowLabel, '1M');
      expect(m3.contextWindowLabel, '未知');
    });

    test('metadataSourceLabel', () {
      const m1 = ModelInfo(id: 'a', displayName: 'A', providerId: 'p');
      expect(m1.metadataSourceLabel, '内置');
      const m2 = ModelInfo(id: 'b', displayName: 'B', providerId: 'p', metadataSource: MetadataSource.remote);
      expect(m2.metadataSourceLabel, 'API获取');
    });

    test('toJson contains expected fields', () {
      const info = ModelInfo(
        id: 'gpt-4o-mini',
        displayName: 'GPT-4o Mini',
        providerId: 'openai',
        contextWindow: 128000,
        category: '轻量',
        recommended: false,
      );
      final json = info.toJson();
      expect(json['id'], 'gpt-4o-mini');
      expect(json['display_name'], 'GPT-4o Mini');
      expect(json['provider_id'], 'openai');
      expect(json['context_window'], 128000);
      expect(json['category'], '轻量');
      expect(json['recommended'], false);
    });

    test('fromJson reconstructs fields', () {
      final json = {
        'id': 'claude-sonnet-4-20250514',
        'display_name': 'Claude Sonnet 4',
        'provider_id': 'claude',
        'context_window': 200000,
        'category': '主力',
        'recommended': true,
        'metadata_source': 'builtin',
      };
      final info = ModelInfo.fromJson(json);
      expect(info.id, 'claude-sonnet-4-20250514');
      expect(info.displayName, 'Claude Sonnet 4');
      expect(info.providerId, 'claude');
      expect(info.contextWindow, 200000);
      expect(info.recommended, true);
      expect(info.metadataSource, MetadataSource.builtin);
    });

    test('toJson/fromJson round-trip', () {
      const original = ModelInfo(
        id: 'deepseek-reasoner',
        displayName: 'DeepSeek R1',
        providerId: 'deepseek',
        contextWindow: 65536,
        maxOutputTokens: 8192,
        category: '推理',
        recommended: false,
        metadataSource: MetadataSource.builtin,
      );
      final restored = ModelInfo.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.providerId, original.providerId);
      expect(restored.contextWindow, original.contextWindow);
      expect(restored.category, original.category);
    });

    test('copyWith creates modified copy', () {
      const original = ModelInfo(id: 'test', displayName: 'Test', providerId: 'p', contextWindow: 1000);
      final copy = original.copyWith(displayName: 'Modified', contextWindow: 2000);
      expect(copy.id, 'test');
      expect(copy.displayName, 'Modified');
      expect(copy.contextWindow, 2000);
    });
  });

  group('PlatformModelConfig', () {
    test('creates with all fields', () {
      const config = PlatformModelConfig(
        id: 'openai',
        name: 'OpenAI',
        models: [
          ModelInfo(id: 'gpt-4o', displayName: 'GPT-4o', providerId: 'openai', recommended: true),
          ModelInfo(id: 'gpt-4o-mini', displayName: 'GPT-4o Mini', providerId: 'openai'),
        ],
        baseUrl: 'https://api.openai.com/v1',
        authHeader: 'authorization',
      );
      expect(config.id, 'openai');
      expect(config.name, 'OpenAI');
      expect(config.models.length, 2);
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.authHeader, 'authorization');
    });

    test('defaults authHeader to authorization', () {
      const config = PlatformModelConfig(id: 'test', name: 'Test', models: [], baseUrl: 'https://example.com');
      expect(config.authHeader, 'authorization');
    });

    test('recommendedModel returns the recommended model', () {
      const config = PlatformModelConfig(
        id: 'openai',
        name: 'OpenAI',
        models: [
          ModelInfo(id: 'gpt-4o-mini', displayName: 'Mini', providerId: 'openai'),
          ModelInfo(id: 'gpt-4o', displayName: 'GPT-4o', providerId: 'openai', recommended: true),
        ],
        baseUrl: 'https://api.openai.com/v1',
      );
      expect(config.recommendedModel?.id, 'gpt-4o');
    });

    test('recommendedModel returns first when none recommended', () {
      const config = PlatformModelConfig(
        id: 'test',
        name: 'Test',
        models: [
          ModelInfo(id: 'model-a', displayName: 'A', providerId: 'test'),
          ModelInfo(id: 'model-b', displayName: 'B', providerId: 'test'),
        ],
        baseUrl: 'https://example.com',
      );
      expect(config.recommendedModel?.id, 'model-a');
    });

    test('availableModels excludes deprecated models', () {
      const config = PlatformModelConfig(
        id: 'test',
        name: 'Test',
        models: [
          ModelInfo(id: 'active-1', displayName: 'Active 1', providerId: 'test'),
          ModelInfo(id: 'old', displayName: 'Old', providerId: 'test', deprecated: true),
        ],
        baseUrl: 'https://example.com',
      );
      expect(config.availableModels.length, 1);
      expect(config.availableModels[0].id, 'active-1');
    });
  });

  group('ModelRegistry', () {
    test('allProviderIds returns all 4 provider IDs', () {
      final ids = ModelRegistry.allProviderIds;
      expect(ids, contains('openai'));
      expect(ids, contains('claude'));
      expect(ids, contains('deepseek'));
      expect(ids, contains('sensenova'));
      expect(ids.length, 4);
    });

    test('allPlatforms returns map with 4 entries', () {
      final platforms = ModelRegistry.allPlatforms;
      expect(platforms.length, 4);
    });

    test('getConfig returns correct config for openai', () {
      final config = ModelRegistry.getConfig('openai');
      expect(config, isNotNull);
      expect(config!.id, 'openai');
      expect(config.name, 'OpenAI');
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.authHeader, 'authorization');
    });

    test('getConfig returns correct config for claude', () {
      final config = ModelRegistry.getConfig('claude');
      expect(config, isNotNull);
      expect(config!.id, 'claude');
      expect(config.baseUrl, 'https://api.anthropic.com');
      expect(config.authHeader, 'x-api-key');
    });

    test('getConfig returns correct config for deepseek', () {
      final config = ModelRegistry.getConfig('deepseek');
      expect(config, isNotNull);
      expect(config!.id, 'deepseek');
      expect(config.baseUrl, 'https://api.deepseek.com/v1');
    });

    test('getConfig returns correct config for sensenova', () {
      final config = ModelRegistry.getConfig('sensenova');
      expect(config, isNotNull);
      expect(config!.name, 'SenseNova (商汤)');
      expect(config.baseUrl, 'https://token.sensenova.cn/v1');
    });

    test('getConfig returns null for unknown provider', () {
      expect(ModelRegistry.getConfig('unknown'), isNull);
    });

    test('openai has correct model list', () {
      final config = ModelRegistry.getConfig('openai')!;
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, ['gpt-4o', 'gpt-4o-mini']);
    });

    test('claude has correct model list', () {
      final config = ModelRegistry.getConfig('claude')!;
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, ['claude-sonnet-4-20250514', 'claude-3-5-haiku-20241022']);
    });

    test('deepseek has correct model list', () {
      final config = ModelRegistry.getConfig('deepseek')!;
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, ['deepseek-chat', 'deepseek-reasoner']);
    });

    test('sensenova has correct model list', () {
      final config = ModelRegistry.getConfig('sensenova')!;
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, ['sensenova-6.7-flash-lite', 'sensenova-6.7-flash']);
    });

    test('recommendedModel for each platform', () {
      expect(ModelRegistry.getConfig('openai')!.recommendedModel?.id, 'gpt-4o');
      expect(ModelRegistry.getConfig('claude')!.recommendedModel?.id, 'claude-sonnet-4-20250514');
      expect(ModelRegistry.getConfig('deepseek')!.recommendedModel?.id, 'deepseek-chat');
      expect(ModelRegistry.getConfig('sensenova')!.recommendedModel?.id, 'sensenova-6.7-flash-lite');
    });

    test('getConfig and allPlatforms consistent', () {
      for (final id in ModelRegistry.allProviderIds) {
        expect(ModelRegistry.getConfig(id)!.id, id);
        expect(ModelRegistry.allPlatforms[id]?.id, id);
      }
    });

    test('instance.getModelsForProvider returns builtin models', () {
      final models = ModelRegistry.instance.getModelsForProvider('openai');
      expect(models.length, 2);
      expect(models.first.id, 'gpt-4o');
    });

    test('instance.findModel finds builtin model', () {
      final model = ModelRegistry.instance.findModel('deepseek-chat');
      expect(model, isNotNull);
      expect(model!.displayName, 'DeepSeek V3');
      expect(model.providerId, 'deepseek');
    });

    test('instance.findModel returns null for unknown', () {
      expect(ModelRegistry.instance.findModel('nonexistent'), isNull);
    });

    test('instance.getDefaultModel returns recommended', () {
      final model = ModelRegistry.instance.getDefaultModel('openai');
      expect(model?.id, 'gpt-4o');
    });

    test('registerRemoteModels adds models with remote source', () {
      final registry = ModelRegistry.instance;
      registry.registerRemoteModels('openai', ['gpt-5-turbo', 'gpt-4o']);
      final models = registry.getModelsForProvider('openai');
      final remote = models.where((m) => m.id == 'gpt-5-turbo').toList();
      expect(remote.length, 1);
      expect(remote.first.metadataSource, MetadataSource.remote);
      expect(remote.first.contextWindow, isNull);
    });

    test('estimateTokens estimates Chinese text', () {
      final tokens = ModelRegistry.estimateTokens('这是一段中文测试文本');
      expect(tokens, greaterThan(0));
    });

    test('estimateTokens returns 0 for empty', () {
      expect(ModelRegistry.estimateTokens(''), 0);
    });
  });

  group('ModelPricing', () {
    test('isKnown returns false for default pricing', () {
      const pricing = ModelPricing();
      expect(pricing.isKnown, false);
    });

    test('isKnown returns true when prices set', () {
      const pricing = ModelPricing(inputPerMillion: 1.0, outputPerMillion: 2.0);
      expect(pricing.isKnown, true);
    });

    test('formatCost returns unknown for default pricing', () {
      const pricing = ModelPricing();
      expect(pricing.formatCost(inputTokens: 1000, outputTokens: 500), '费用未知');
    });

    test('formatCost calculates cost', () {
      const pricing = ModelPricing(inputPerMillion: 10.0, outputPerMillion: 30.0);
      final cost = pricing.formatCost(inputTokens: 1000000, outputTokens: 1000000);
      expect(cost.isNotEmpty, true);
      expect(cost, isNot(equals('费用未知')));
    });
  });
}
