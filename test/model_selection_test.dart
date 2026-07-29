import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/model_registry.dart';
import 'package:lingbi/shared/models/model_snapshot.dart';

void main() {
  group('ModelRegistry.replaceRemoteModels', () {
    test('替换 remote 模型不影响 builtin', () {
      final registry = ModelRegistry.instance;
      // openai 有 builtin 模型 gpt-4o, gpt-4o-mini
      registry.replaceRemoteModels('openai', ['gpt-4o', 'custom-model-1']);
      final models = registry.getModelsForProvider('openai');
      // builtin 模型仍在
      expect(models.any((m) => m.id == 'gpt-4o'), true);
      expect(models.any((m) => m.id == 'gpt-4o-mini'), true);
      // 新 remote 模型已添加（排除与 builtin 重复的）
      expect(models.any((m) => m.id == 'custom-model-1'), true);
      // custom-model-1 标记为 remote
      final custom = models.firstWhere((m) => m.id == 'custom-model-1');
      expect(custom.metadataSource, MetadataSource.remote);
    });

    test('再次替换时旧 remote 被移除', () {
      final registry = ModelRegistry.instance;
      registry.replaceRemoteModels('deepseek', ['remote-a', 'remote-b']);
      var models = registry.getModelsForProvider('deepseek');
      expect(models.any((m) => m.id == 'remote-a'), true);
      expect(models.any((m) => m.id == 'remote-b'), true);

      // 第二次替换
      registry.replaceRemoteModels('deepseek', ['remote-c']);
      models = registry.getModelsForProvider('deepseek');
      expect(models.any((m) => m.id == 'remote-a'), false);
      expect(models.any((m) => m.id == 'remote-b'), false);
      expect(models.any((m) => m.id == 'remote-c'), true);
      // builtin 不受影响
      expect(models.any((m) => m.id == 'deepseek-chat'), true);
    });

    test('不覆盖 manual 模型', () {
      final registry = ModelRegistry.instance;
      registry.addCustomModel(const ModelInfo(
        id: 'my-custom-model',
        displayName: 'My Custom',
        providerId: 'claude',
        metadataSource: MetadataSource.manual,
      ));
      registry.replaceRemoteModels('claude', ['remote-x']);
      final models = registry.getModelsForProvider('claude');
      // manual 模型保留
      expect(models.any((m) => m.id == 'my-custom-model'), true);
      // remote 模型已替换
      expect(models.any((m) => m.id == 'remote-x'), true);
    });
  });

  group('ModelSnapshot', () {
    test('fromModelInfo 捕获完整快照', () {
      const info = ModelInfo(
        id: 'gpt-4o',
        displayName: 'GPT-4o',
        providerId: 'openai',
        contextWindow: 128000,
        maxOutputTokens: 16384,
        pricing: ModelPricing(inputPerMillion: 17.5, outputPerMillion: 70),
      );
      final snapshot = ModelSnapshot.fromModelInfo(info);
      expect(snapshot.providerId, 'openai');
      expect(snapshot.modelId, 'gpt-4o');
      expect(snapshot.displayName, 'GPT-4o');
      expect(snapshot.contextWindow, 128000);
      expect(snapshot.maxOutputTokens, 16384);
      expect(snapshot.pricing.inputPerMillion, 17.5);
      expect(snapshot.metadataSource, MetadataSource.builtin);
      expect(snapshot.capturedAt, isNotNull);
    });

    test('toJson/fromJson 往返一致', () {
      final original = ModelSnapshot(
        providerId: 'deepseek',
        modelId: 'deepseek-chat',
        displayName: 'DeepSeek V3',
        contextWindow: 65536,
        maxOutputTokens: 8192,
        pricing: const ModelPricing(inputPerMillion: 1, outputPerMillion: 2),
        capturedAt: DateTime(2026, 7, 24, 10, 30),
      );
      final json = original.toJson();
      final restored = ModelSnapshot.fromJson(json);
      expect(restored.providerId, original.providerId);
      expect(restored.modelId, original.modelId);
      expect(restored.displayName, original.displayName);
      expect(restored.contextWindow, original.contextWindow);
      expect(restored.maxOutputTokens, original.maxOutputTokens);
      expect(restored.pricing.inputPerMillion, original.pricing.inputPerMillion);
      expect(restored.pricing.outputPerMillion, original.pricing.outputPerMillion);
      expect(restored.metadataSource, original.metadataSource);
      expect(restored.capturedAt, original.capturedAt);
    });

    test('contextWindowLabel 格式化', () {
      final snapshot = ModelSnapshot(
        providerId: 'test',
        modelId: 'test',
        displayName: 'Test',
        contextWindow: 128000,
        capturedAt: DateTime.now(),
      );
      expect(snapshot.contextWindowLabel, '128K');

      final unknown = ModelSnapshot(
        providerId: 'test',
        modelId: 'test',
        displayName: 'Test',
        capturedAt: DateTime.now(),
      );
      expect(unknown.contextWindowLabel, '未知');
    });

    test('pricingLabel 显示', () {
      final withPricing = ModelSnapshot(
        providerId: 'test',
        modelId: 'test',
        displayName: 'Test',
        pricing: const ModelPricing(inputPerMillion: 1, outputPerMillion: 2),
        capturedAt: DateTime.now(),
      );
      expect(withPricing.pricingLabel, contains('¥'));

      final noPricing = ModelSnapshot(
        providerId: 'test',
        modelId: 'test',
        displayName: 'Test',
        capturedAt: DateTime.now(),
      );
      expect(noPricing.pricingLabel, '费用未知');
    });

    test('summary 包含关键信息', () {
      final snapshot = ModelSnapshot(
        providerId: 'openai',
        modelId: 'gpt-4o',
        displayName: 'GPT-4o',
        contextWindow: 128000,
        pricing: const ModelPricing(inputPerMillion: 17.5, outputPerMillion: 70),
        capturedAt: DateTime.now(),
      );
      expect(snapshot.summary, contains('GPT-4o'));
      expect(snapshot.summary, contains('gpt-4o'));
      expect(snapshot.summary, contains('128K'));
    });
  });

  group('模型选项透明显示', () {
    test('builtin 模型有完整元数据', () {
      final models = ModelRegistry.instance.getModelsForProvider('openai');
      final gpt4o = models.firstWhere((m) => m.id == 'gpt-4o');
      expect(gpt4o.displayName, 'GPT-4o');
      expect(gpt4o.contextWindow, isNotNull);
      expect(gpt4o.maxOutputTokens, isNotNull);
      expect(gpt4o.pricing.isKnown, true);
      expect(gpt4o.metadataSource, MetadataSource.builtin);
      expect(gpt4o.metadataSourceLabel, '内置');
    });

    test('remote 模型标记为 API 获取', () {
      final registry = ModelRegistry.instance;
      registry.replaceRemoteModels('sensenova', ['remote-test-model']);
      final models = registry.getModelsForProvider('sensenova');
      final remote = models.firstWhere((m) => m.id == 'remote-test-model');
      expect(remote.metadataSource, MetadataSource.remote);
      expect(remote.metadataSourceLabel, 'API获取');
      expect(remote.contextWindow, isNull);
      expect(remote.contextWindowLabel, '未知');
      expect(remote.pricing.isKnown, false);
    });
  });
}
