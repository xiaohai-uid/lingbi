import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/model_registry.dart';

void main() {
  group('ModelInfo', () {
    test('creates with all fields', () {
      const info = ModelInfo(
        id: 'gpt-4o',
        name: 'GPT-4o',
        category: '主力',
        recommended: true,
      );
      expect(info.id, 'gpt-4o');
      expect(info.name, 'GPT-4o');
      expect(info.category, '主力');
      expect(info.recommended, true);
      expect(info.deprecated, false);
    });

    test('defaults recommended to false and deprecated to false', () {
      const info = ModelInfo(id: 'test', name: 'Test');
      expect(info.recommended, false);
      expect(info.deprecated, false);
    });

    test('toJson contains all fields', () {
      const info = ModelInfo(
        id: 'gpt-4o-mini',
        name: 'GPT-4o Mini',
        category: '轻量',
      );
      final json = info.toJson();
      expect(json['id'], 'gpt-4o-mini');
      expect(json['name'], 'GPT-4o Mini');
      expect(json['category'], '轻量');
      expect(json['recommended'], false);
      expect(json['deprecated'], false);
    });

    test('fromJson reconstructs all fields', () {
      final json = {
        'id': 'claude-3-5-sonnet-20241022',
        'name': 'Claude 3.5 Sonnet',
        'category': '稳定',
        'recommended': false,
        'deprecated': false,
      };
      final info = ModelInfo.fromJson(json);
      expect(info.id, 'claude-3-5-sonnet-20241022');
      expect(info.name, 'Claude 3.5 Sonnet');
      expect(info.category, '稳定');
      expect(info.recommended, false);
      expect(info.deprecated, false);
    });

    test('toJson/fromJson round-trip', () {
      const original = ModelInfo(
        id: 'deepseek-reasoner',
        name: 'DeepSeek Reasoner',
        category: '推理',
        deprecated: true,
      );
      final restored = ModelInfo.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.recommended, original.recommended);
      expect(restored.deprecated, original.deprecated);
    });

    test('toJson/fromJson round-trip with defaults', () {
      const original = ModelInfo(
          id: 'sensenova-6.7-flash',
          name: 'SenseNova 6.7 Flash',
          category: '主力');
      final restored = ModelInfo.fromJson(original.toJson());
      expect(restored.recommended, false);
      expect(restored.deprecated, false);
    });
  });

  group('PlatformModelConfig', () {
    test('creates with all fields', () {
      const config = PlatformModelConfig(
        id: 'openai',
        name: 'OpenAI',
        models: [
          ModelInfo(
              id: 'gpt-4o', name: 'GPT-4o', category: '主力', recommended: true),
          ModelInfo(id: 'gpt-4o-mini', name: 'GPT-4o Mini', category: '轻量'),
        ],
        baseUrl: 'https://api.openai.com/v1',
      );
      expect(config.id, 'openai');
      expect(config.name, 'OpenAI');
      expect(config.models.length, 2);
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.authHeader, 'authorization');
    });

    test('defaults authHeader to authorization', () {
      const config = PlatformModelConfig(
        id: 'test',
        name: 'Test',
        models: [],
        baseUrl: 'https://example.com',
      );
      expect(config.authHeader, 'authorization');
    });

    test('toJson contains all fields', () {
      const config = PlatformModelConfig(
        id: 'claude',
        name: 'Claude',
        models: [
          ModelInfo(
              id: 'claude-sonnet-4-20250514',
              name: 'Claude Sonnet 4',
              category: '主力',
              recommended: true),
        ],
        baseUrl: 'https://api.anthropic.com',
        authHeader: 'x-api-key',
      );
      final json = config.toJson();
      expect(json['id'], 'claude');
      expect(json['name'], 'Claude');
      expect(json['baseUrl'], 'https://api.anthropic.com');
      expect(json['authHeader'], 'x-api-key');
      expect((json['models'] as List).length, 1);
      expect((json['models'] as List)[0]['id'], 'claude-sonnet-4-20250514');
    });

    test('fromJson reconstructs all fields', () {
      final json = {
        'id': 'deepseek',
        'name': 'DeepSeek',
        'baseUrl': 'https://api.deepseek.com/v1',
        'authHeader': 'authorization',
        'models': [
          {
            'id': 'deepseek-chat',
            'name': 'DeepSeek Chat',
            'category': '主力',
            'recommended': true,
            'deprecated': false
          },
          {
            'id': 'deepseek-coder',
            'name': 'DeepSeek Coder',
            'category': '代码',
            'recommended': false,
            'deprecated': false
          },
        ],
      };
      final config = PlatformModelConfig.fromJson(json);
      expect(config.id, 'deepseek');
      expect(config.name, 'DeepSeek');
      expect(config.baseUrl, 'https://api.deepseek.com/v1');
      expect(config.authHeader, 'authorization');
      expect(config.models.length, 2);
      expect(config.models[0].id, 'deepseek-chat');
      expect(config.models[1].id, 'deepseek-coder');
    });

    test('toJson/fromJson round-trip', () {
      const original = PlatformModelConfig(
        id: 'sensenova',
        name: 'SenseNova (商汤)',
        models: [
          ModelInfo(
              id: 'sensenova-6.7-flash-lite',
              name: 'SenseNova 6.7 Flash Lite',
              category: '轻量',
              recommended: true),
          ModelInfo(
              id: 'sensenova-6.7-flash',
              name: 'SenseNova 6.7 Flash',
              category: '主力'),
        ],
        baseUrl: 'https://token.sensenova.cn/v1',
      );
      final restored = PlatformModelConfig.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.baseUrl, original.baseUrl);
      expect(restored.authHeader, original.authHeader);
      expect(restored.models.length, original.models.length);
      for (var i = 0; i < original.models.length; i++) {
        expect(restored.models[i].id, original.models[i].id);
        expect(restored.models[i].recommended, original.models[i].recommended);
      }
    });

    test('recommendedModel returns the recommended model', () {
      const config = PlatformModelConfig(
        id: 'openai',
        name: 'OpenAI',
        models: [
          ModelInfo(id: 'gpt-3.5-turbo', name: 'GPT-3.5 Turbo', category: '经典'),
          ModelInfo(
              id: 'gpt-4o', name: 'GPT-4o', category: '主力', recommended: true),
          ModelInfo(id: 'gpt-4o-mini', name: 'GPT-4o Mini', category: '轻量'),
        ],
        baseUrl: 'https://api.openai.com/v1',
      );
      expect(config.recommendedModel?.id, 'gpt-4o');
    });

    test('recommendedModel returns null when no recommended model', () {
      const config = PlatformModelConfig(
        id: 'test',
        name: 'Test',
        models: [
          ModelInfo(id: 'model-a', name: 'Model A'),
          ModelInfo(id: 'model-b', name: 'Model B'),
        ],
        baseUrl: 'https://example.com',
      );
      expect(config.recommendedModel, isNull);
    });

    test('availableModels excludes deprecated models', () {
      const config = PlatformModelConfig(
        id: 'test',
        name: 'Test',
        models: [
          ModelInfo(
              id: 'active-1',
              name: 'Active 1',
              category: '主力',
              recommended: true),
          ModelInfo(id: 'active-2', name: 'Active 2', category: '轻量'),
          ModelInfo(
              id: 'deprecated-1',
              name: 'Deprecated 1',
              category: '经典',
              deprecated: true),
        ],
        baseUrl: 'https://example.com',
      );
      final available = config.availableModels;
      expect(available.length, 2);
      expect(available[0].id, 'active-1');
      expect(available[1].id, 'active-2');
    });

    test('availableModels returns all when none deprecated', () {
      const config = PlatformModelConfig(
        id: 'test',
        name: 'Test',
        models: [
          ModelInfo(id: 'a', name: 'A'),
          ModelInfo(id: 'b', name: 'B'),
        ],
        baseUrl: 'https://example.com',
      );
      expect(config.availableModels.length, 2);
    });

    test('availableModels returns empty when all deprecated', () {
      const config = PlatformModelConfig(
        id: 'test',
        name: 'Test',
        models: [
          ModelInfo(id: 'old', name: 'Old', deprecated: true),
        ],
        baseUrl: 'https://example.com',
      );
      expect(config.availableModels.length, 0);
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
      expect(platforms.keys.contains('openai'), true);
      expect(platforms.keys.contains('claude'), true);
      expect(platforms.keys.contains('deepseek'), true);
      expect(platforms.keys.contains('sensenova'), true);
    });

    test('getConfig returns correct PlatformModelConfig for openai', () {
      final config = ModelRegistry.getConfig('openai');
      expect(config.id, 'openai');
      expect(config.name, 'OpenAI');
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.authHeader, 'authorization');
    });

    test('getConfig returns correct PlatformModelConfig for claude', () {
      final config = ModelRegistry.getConfig('claude');
      expect(config.id, 'claude');
      expect(config.name, 'Claude');
      expect(config.baseUrl, 'https://api.anthropic.com');
      expect(config.authHeader, 'x-api-key');
    });

    test('getConfig returns correct PlatformModelConfig for deepseek', () {
      final config = ModelRegistry.getConfig('deepseek');
      expect(config.id, 'deepseek');
      expect(config.name, 'DeepSeek');
      expect(config.baseUrl, 'https://api.deepseek.com/v1');
      expect(config.authHeader, 'authorization');
    });

    test('getConfig returns correct PlatformModelConfig for sensenova', () {
      final config = ModelRegistry.getConfig('sensenova');
      expect(config.id, 'sensenova');
      expect(config.name, 'SenseNova (商汤)');
      expect(config.baseUrl, 'https://token.sensenova.cn/v1');
      expect(config.authHeader, 'authorization');
    });

    test('getConfig throws ArgumentError for unknown provider', () {
      expect(
        () => ModelRegistry.getConfig('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('openai has correct model list', () {
      final config = ModelRegistry.getConfig('openai');
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, [
        'gpt-4o',
        'gpt-4o-mini',
        'gpt-3.5-turbo',
        'o1',
        'o1-mini',
      ]);
    });

    test('claude has correct model list', () {
      final config = ModelRegistry.getConfig('claude');
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, [
        'claude-sonnet-4-20250514',
        'claude-3-5-sonnet-20241022',
        'claude-3-5-haiku-20241022',
        'claude-3-opus-20240229',
      ]);
    });

    test('deepseek has correct model list', () {
      final config = ModelRegistry.getConfig('deepseek');
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, [
        'deepseek-chat',
        'deepseek-coder',
        'deepseek-reasoner',
      ]);
    });

    test('sensenova has correct model list', () {
      final config = ModelRegistry.getConfig('sensenova');
      final modelIds = config.models.map((m) => m.id).toList();
      expect(modelIds, [
        'sensenova-6.7-flash-lite',
        'sensenova-6.7-flash',
      ]);
    });

    test('recommendedModel returns recommended model for each platform', () {
      expect(ModelRegistry.getConfig('openai').recommendedModel?.id, 'gpt-4o');
      expect(ModelRegistry.getConfig('claude').recommendedModel?.id,
          'claude-sonnet-4-20250514');
      expect(ModelRegistry.getConfig('deepseek').recommendedModel?.id,
          'deepseek-chat');
      expect(ModelRegistry.getConfig('sensenova').recommendedModel?.id,
          'sensenova-6.7-flash-lite');
    });

    test('availableModels returns only non-deprecated models for each platform',
        () {
      for (final id in ModelRegistry.allProviderIds) {
        final config = ModelRegistry.getConfig(id);
        expect(config.availableModels.length, config.models.length);
      }
    });

    test('getConfig and allPlatforms return consistent data', () {
      for (final id in ModelRegistry.allProviderIds) {
        expect(ModelRegistry.getConfig(id).id, id);
        expect(ModelRegistry.allPlatforms[id]?.id, id);
      }
    });
  });
}
