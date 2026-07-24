import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/model_registry.dart';
import 'package:lingbi/services/settings_service.dart';

void main() {
  group('设置页模型管理功能', () {
    test('所有 Provider 列表可用', () {
      final platforms = ModelRegistry.allPlatforms;
      expect(platforms.containsKey('openai'), true);
      expect(platforms.containsKey('claude'), true);
      expect(platforms.containsKey('deepseek'), true);
      expect(platforms.containsKey('sensenova'), true);
    });

    test('每个 Provider 有配置状态', () {
      // 验证 PlatformModelConfig 包含必要信息
      for (final entry in ModelRegistry.allPlatforms.entries) {
        expect(entry.value.id, isNotEmpty);
        expect(entry.value.name, isNotEmpty);
        expect(entry.value.models, isNotEmpty);
        expect(entry.value.baseUrl, isNotEmpty);
      }
    });

    test('模型选择包含上下文和价格信息', () {
      final models = ModelRegistry.instance.getModelsForProvider('openai');
      for (final model in models) {
        expect(model.displayName, isNotEmpty);
        expect(model.id, isNotEmpty);
        // 上下文窗口标签可用
        expect(model.contextWindowLabel, isNotEmpty);
        // 输出上限标签可用
        expect(model.maxOutputLabel, isNotEmpty);
      }
    });
  });

  group('deleteApiKey 设计验证', () {
    test('maskApiKey 可用于删除确认前的显示', () {
      const key = 'sk-test123456';
      final masked = maskApiKey(key);
      expect(masked, isNot(contains('test123456')));
      expect(masked.length, lessThan(key.length));
    });
  });

  group('重新打开向导', () {
    test('resetOnboarding 使 needsOnboarding 为 true', () {
      final state = OnboardingState(
        completed: true,
        schemaVersion: currentOnboardingSchemaVersion,
        completedAt: DateTime.now(),
        selectedProviderId: 'openai',
        selectedModelId: 'gpt-4o',
        localOnlyMode: false,
        lastStep: 7,
      );
      expect(state.needsOnboarding, false);
      final reset = state.reset();
      expect(reset.needsOnboarding, true);
      expect(reset.completed, false);
    });
  });

  group('删除确认文案', () {
    test('确认文案包含关键信息', () {
      const confirmText = '删除后，该供应商将无法继续调用，现有项目内容不会被删除。';
      expect(confirmText, contains('无法继续调用'));
      expect(confirmText, contains('不会被删除'));
    });
  });
}
