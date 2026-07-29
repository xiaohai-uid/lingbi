import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/settings/data/settings_service.dart';

void main() {
  group('OnboardingState', () {
    test('全新配置需要进入向导', () {
      const state = OnboardingState.initial();
      expect(state.completed, false);
      expect(state.needsOnboarding, true);
    });

    test('完成向导后不再弹出', () {
      final state = OnboardingState(
        completed: true,
        schemaVersion: currentOnboardingSchemaVersion,
        completedAt: DateTime(2026),
        selectedProviderId: 'sensenova',
        selectedModelId: 'sensenova-6.7-flash-lite',
        lastStep: 7,
      );
      expect(state.needsOnboarding, false);
    });

    test('本地模式也算完成', () {
      final state = OnboardingState(
        completed: true,
        schemaVersion: currentOnboardingSchemaVersion,
        completedAt: DateTime(2026),
        localOnlyMode: true,
        lastStep: 1,
      );
      expect(state.needsOnboarding, false);
      expect(state.localOnlyMode, true);
    });

    test('中途退出后保留 lastStep 用于恢复', () {
      const state = OnboardingState(
        completed: false,
        schemaVersion: currentOnboardingSchemaVersion,
        lastStep: 3,
      );
      expect(state.needsOnboarding, true);
      expect(state.lastStep, 3);
    });

    test('schemaVersion 不匹配时重新展示向导', () {
      final state = OnboardingState(
        completed: true,
        schemaVersion: currentOnboardingSchemaVersion - 1,
        completedAt: DateTime(2026),
        selectedProviderId: 'openai',
        selectedModelId: 'gpt-4o',
        lastStep: 7,
      );
      expect(state.needsOnboarding, true);
    });

    test('toJson/fromJson 往返一致', () {
      final original = OnboardingState(
        completed: true,
        schemaVersion: currentOnboardingSchemaVersion,
        completedAt: DateTime(2026, 7, 24, 10, 30),
        selectedProviderId: 'deepseek',
        selectedModelId: 'deepseek-chat',
        lastStep: 7,
      );
      final json = original.toJson();
      final restored = OnboardingState.fromJson(json);
      expect(restored.completed, original.completed);
      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.completedAt, original.completedAt);
      expect(restored.selectedProviderId, original.selectedProviderId);
      expect(restored.selectedModelId, original.selectedModelId);
      expect(restored.localOnlyMode, original.localOnlyMode);
      expect(restored.lastStep, original.lastStep);
    });

    test('fromJson 处理缺失字段', () {
      final state = OnboardingState.fromJson({});
      expect(state.completed, false);
      expect(state.schemaVersion, 0);
      expect(state.completedAt, isNull);
      expect(state.selectedProviderId, isNull);
      expect(state.selectedModelId, isNull);
      expect(state.localOnlyMode, false);
      expect(state.lastStep, 0);
    });

    test('copyWith 创建修改副本', () {
      const original = OnboardingState.initial();
      final modified = original.copyWith(
        completed: true,
        lastStep: 5,
        selectedProviderId: 'claude',
      );
      expect(modified.completed, true);
      expect(modified.lastStep, 5);
      expect(modified.selectedProviderId, 'claude');
      expect(modified.schemaVersion, currentOnboardingSchemaVersion);
    });

    test('resetOnboarding 返回初始状态但保留 schema 版本', () {
      final completed = OnboardingState(
        completed: true,
        schemaVersion: currentOnboardingSchemaVersion,
        completedAt: DateTime(2026),
        selectedProviderId: 'openai',
        selectedModelId: 'gpt-4o',
        lastStep: 7,
      );
      final reset = completed.reset();
      expect(reset.completed, false);
      expect(reset.lastStep, 0);
      expect(reset.schemaVersion, currentOnboardingSchemaVersion);
      expect(reset.needsOnboarding, true);
    });
  });
}
