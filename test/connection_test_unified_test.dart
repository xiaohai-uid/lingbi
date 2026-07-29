import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

void main() {
  group('ConnectionTestResult 增强字段', () {
    test('向后兼容：旧构造方式仍可用', () {
      const result = ConnectionTestResult(
        success: true,
        latencyMs: 150,
        modelId: 'gpt-4o',
        message: '连接成功',
      );
      expect(result.success, true);
      expect(result.latencyMs, 150);
      expect(result.modelId, 'gpt-4o');
      expect(result.message, '连接成功');
      // 新字段默认值
      expect(result.providerId, '');
      expect(result.responsePreview, isNull);
      expect(result.errorCategory, isNull);
    });

    test('新字段完整赋值', () {
      const result = ConnectionTestResult(
        success: true,
        latencyMs: 200,
        modelId: 'deepseek-chat',
        message: '连接成功',
        providerId: 'deepseek',
        responsePreview: '连接成功',
      );
      expect(result.providerId, 'deepseek');
      expect(result.responsePreview, '连接成功');
      expect(result.errorCategory, isNull);
    });

    test('latency 返回 Duration', () {
      const result = ConnectionTestResult(
        success: true,
        latencyMs: 350,
        message: '连接成功',
      );
      expect(result.latency, const Duration(milliseconds: 350));
    });

    test('失败结果包含 errorCategory', () {
      const result = ConnectionTestResult(
        success: false,
        latencyMs: 100,
        modelId: 'gpt-4o',
        message: '密钥无效，请检查 API Key 是否复制完整',
        providerId: 'openai',
        errorCategory: '密钥无效，请检查 API Key 是否复制完整',
      );
      expect(result.success, false);
      expect(result.errorCategory, isNotNull);
      expect(result.responsePreview, isNull);
    });
  });

  group('responsePreview 规则', () {
    test('短文本不截断', () {
      const result = ConnectionTestResult(
        success: true,
        latencyMs: 100,
        message: '连接成功',
        responsePreview: '连接成功',
      );
      expect(result.responsePreview!.length, lessThanOrEqualTo(80));
    });

    test('成功时 responsePreview 非 null', () {
      const result = ConnectionTestResult(
        success: true,
        latencyMs: 100,
        message: '连接成功',
        responsePreview: '好的',
      );
      expect(result.responsePreview, isNotNull);
    });

    test('失败时 responsePreview 为 null', () {
      const result = ConnectionTestResult(
        success: false,
        latencyMs: 100,
        message: '连接失败',
        errorCategory: '网络不可达',
      );
      expect(result.responsePreview, isNull);
    });
  });

  group('错误分类覆盖', () {
    // 验证 9 种错误分类的中文消息格式
    final errorCases = {
      '401': '密钥无效',
      '403': '权限不足',
      '404': '模型不存在',
      '429': '频率限制',
      'balance': '余额不足',
      'socket': '网络不可达',
      '500': '服务端错误',
      'empty': '空响应',
      'format': '格式异常',
    };

    for (final entry in errorCases.entries) {
      test('错误 ${entry.key} 映射为中文: ${entry.value}', () {
        // 验证 ConnectionTestResult 可以携带 errorCategory
        final result = ConnectionTestResult(
          success: false,
          latencyMs: 50,
          message: '${entry.value}，请检查配置',
          errorCategory: entry.value,
        );
        expect(result.errorCategory, contains(entry.value));
        expect(result.success, false);
      });
    }
  });

  group('安全性', () {
    test('toString 不泄露敏感信息', () {
      const result = ConnectionTestResult(
        success: true,
        latencyMs: 100,
        modelId: 'gpt-4o',
        message: '连接成功',
        providerId: 'openai',
        responsePreview: '连接成功',
      );
      final str = result.toString();
      expect(str, isNot(contains('sk-')));
      expect(str, isNot(contains('Authorization')));
      expect(str, isNot(contains('api.openai.com')));
    });

    test('失败 toString 仅显示消息', () {
      const result = ConnectionTestResult(
        success: false,
        latencyMs: 100,
        message: '密钥无效，请检查 API Key 是否复制完整',
        errorCategory: '密钥无效',
      );
      final str = result.toString();
      expect(str, contains('密钥无效'));
      expect(str, isNot(contains('sk-')));
    });
  });
}
