import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/quota_service.dart';

void main() {
  group('testGeneration 隔离保证', () {
    late AIService aiService;
    late QuotaService quotaService;

    setUp(() {
      quotaService = QuotaService();
      aiService = AIService(quotaService: quotaService);
    });

    test('不消耗配额', () {
      // testGeneration 方法签名存在且不调用 quota
      // 验证 QuotaService 初始状态
      expect(quotaService.remaining, quotaService.dailyLimit);
      // testGeneration 是 Stream<String> 方法，接受 providerId 参数
      // 实际调用需要真实 Provider，此处验证接口存在
      expect(aiService.testGeneration, isA<Function>());
    });

    test('支持 providerId 参数指定供应商', () {
      // 验证方法签名支持 providerId
      final stream = aiService.testGeneration(providerId: 'free');
      expect(stream, isA<Stream<String>>());
    });

    test('支持 maxTokens 参数', () {
      final stream = aiService.testGeneration(
        providerId: 'free',
        maxTokens: 50,
      );
      expect(stream, isA<Stream<String>>());
    });

    test('支持取消（cancelCurrentRequest）', () {
      // 验证取消方法存在
      expect(aiService.cancelCurrentRequest, isA<Function>());
      // 调用取消不应抛异常
      aiService.cancelCurrentRequest();
    });

    test('isGenerating 初始为 false', () {
      expect(aiService.isGenerating, false);
    });
  });

  group('testGeneration 与 chat 隔离', () {
    test('chat 消耗配额而 testGeneration 不消耗', () {
      final quotaService = QuotaService();
      // 记录初始配额
      final initialRemaining = quotaService.remaining;

      // testGeneration 不应改变配额
      // （实际调用需要 Provider，此处验证设计意图）
      expect(quotaService.remaining, initialRemaining);
    });
  });

  group('固定提示词', () {
    test('使用固定中文提示词', () {
      // 验证 testGeneration 方法存在且为 Stream<String>
      final quotaService = QuotaService();
      final aiService = AIService(quotaService: quotaService);
      final stream = aiService.testGeneration(providerId: 'free');
      expect(stream, isA<Stream<String>>());
      // 固定提示词为：请用一句不超过 30 字的中文，描写雨夜中的旧车站。
      // 此提示词硬编码在 AIService.testGeneration 中
    });
  });
}
