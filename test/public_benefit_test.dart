/// 套餐/公益模型 — 单元测试
///
/// 覆盖：配额检测/自动切换/降级提示
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/public_benefit_service.dart';

void main() {
  group('BenefitQuota 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      const quota = BenefitQuota(
        dailyUsed: 10,
        monthlyUsed: 100,
        lastResetDay: '2026-7-25',
        lastResetMonth: '2026-7',
      );

      final json = quota.toJson();
      final restored = BenefitQuota.fromJson(json);

      expect(restored.dailyLimit, 30);
      expect(restored.monthlyLimit, 500);
      expect(restored.dailyUsed, 10);
      expect(restored.monthlyUsed, 100);
    });

    test('剩余量计算', () {
      const quota = BenefitQuota(
        dailyUsed: 25,
        monthlyUsed: 480,
      );

      expect(quota.dailyRemaining, 5);
      expect(quota.monthlyRemaining, 20);
      expect(quota.isDailyExhausted, isFalse);
      expect(quota.isMonthlyExhausted, isFalse);
    });

    test('超限判断', () {
      const quota = BenefitQuota(
        dailyUsed: 30,
      );
      expect(quota.isDailyExhausted, isTrue);
      expect(quota.isExhausted, isTrue);
      expect(quota.dailyRemaining, 0);
    });
  });

  group('PublicBenefitService 配额管理', () {
    late PublicBenefitService service;

    setUp(() {
      service = PublicBenefitService();
    });

    test('初始状态有配额', () {
      expect(service.quota.isExhausted, isFalse);
      expect(service.quota.dailyRemaining, 30);
    });

    test('tryConsume 正常消费', () {
      final result = service.tryConsume();
      expect(result, isNull); // 成功
      expect(service.quota.dailyUsed, 1);
    });

    test('tryConsume 日限耗尽返回提示', () {
      // 设置已用完
      service.loadQuota(BenefitQuota(
        dailyLimit: 3,
        dailyUsed: 3,
        lastResetDay: _today(),
        lastResetMonth: _thisMonth(),
      ));

      final result = service.tryConsume();
      expect(result, isNotNull);
      expect(result, contains('额度已用完'));
      expect(result, contains('API Key'));
    });

    test('tryConsume 月限耗尽返回提示', () {
      service.loadQuota(BenefitQuota(
        monthlyLimit: 10,
        monthlyUsed: 10,
        lastResetDay: _today(),
        lastResetMonth: _thisMonth(),
      ));

      final result = service.tryConsume();
      expect(result, isNotNull);
      expect(result, contains('本月'));
    });

    test('配额提示文本', () {
      expect(service.quotaHint, contains('0/30'));

      // 消费到接近上限
      for (var i = 0; i < 26; i++) {
        service.tryConsume();
      }
      expect(service.quotaHint, contains('剩余'));
    });

    test('能力提示包含上下文信息', () {
      expect(service.capabilityHint, contains('能力有限'));
      expect(service.capabilityHint, contains('API Key'));
    });
  });

  group('自动切换', () {
    late PublicBenefitService service;

    setUp(() {
      service = PublicBenefitService();
    });

    test('初始使用公益模型', () {
      expect(service.isUsingBenefitModel, isTrue);
      expect(service.hasOwnApiKey, isFalse);
    });

    test('配置 API Key 后自动切换', () {
      final shouldSwitch =
          service.notifyOwnApiKeyConfigured('deepseek');
      expect(shouldSwitch, isTrue);
      expect(service.isUsingBenefitModel, isFalse);
      expect(service.hasOwnApiKey, isTrue);
    });

    test('已切换后再次通知不重复切换', () {
      service.notifyOwnApiKeyConfigured('deepseek');
      final shouldSwitch =
          service.notifyOwnApiKeyConfigured('openai');
      expect(shouldSwitch, isFalse);
    });

    test('手动切回公益模型', () {
      service.notifyOwnApiKeyConfigured('deepseek');
      service.switchToBenefitModel();
      expect(service.isUsingBenefitModel, isTrue);
    });

    test('切换建议文本', () {
      expect(service.switchSuggestion, isEmpty);

      service.notifyOwnApiKeyConfigured('deepseek');
      service.switchToBenefitModel(); // 切回
      expect(service.switchSuggestion, contains('建议切换'));
    });
  });

  group('模型列表', () {
    test('默认提供公益模型', () {
      final service = PublicBenefitService();
      expect(service.availableModels, isNotEmpty);
      expect(service.recommendedModel, isNotNull);
      expect(service.recommendedModel!.displayName, contains('免费'));
    });

    test('自定义模型列表', () {
      final service = PublicBenefitService(
        models: const [
          BenefitModelInfo(
            id: 'custom',
            displayName: '自定义公益',
            endpoint: 'https://custom.api/v1',
            contextWindow: 8192,
          ),
        ],
      );
      expect(service.availableModels.length, 1);
      expect(service.recommendedModel!.id, 'custom');
    });
  });

  group('配额重置', () {
    test('跨天重置日配额', () {
      final service = PublicBenefitService();
      // 模拟昨天用了很多
      service.loadQuota(BenefitQuota(
        dailyUsed: 29,
        monthlyUsed: 100,
        lastResetDay: '2020-1-1', // 过期
        lastResetMonth: _thisMonth(),
      ));

      // tryConsume 触发重置
      final result = service.tryConsume();
      expect(result, isNull); // 重置后应该成功
      expect(service.quota.dailyUsed, 1); // 重置为0后+1
    });
  });
}

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

String _thisMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month}';
}
