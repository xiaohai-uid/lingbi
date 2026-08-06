import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/free_provider.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/errors/ai_error.dart';

/// Phase 2 测试：免费模型零配置
///
/// 验证：
/// 1. FreeProvider 不依赖环境变量即可 isAvailable = true
/// 2. displayName 包含"免费"字样
/// 3. currentModelId 非空
/// 4. supportsTools = true（支持 Agent 工具循环）
void main() {
  group('FreeProvider 零配置', () {
    test('默认不声明匿名能力，避免错误文本成为生成内容', () {
      final provider = FreeProvider();
      expect(provider.isAvailable, isFalse);
      expect(provider.supportsTools, isFalse);
    });

    test('显式 anonymousCapability 时才可用', () {
      final provider = FreeProvider(anonymousCapability: true);
      expect(provider.isAvailable, isTrue);
      expect(provider.supportsTools, isTrue);
    });

    test('displayName 包含免费标识', () {
      final provider = FreeProvider();
      expect(provider.displayName, contains('免费'));
    });

    test('currentModelId 非空', () {
      final provider = FreeProvider();
      expect(provider.currentModelId, isNotEmpty);
    });

    test('name 为 free', () {
      final provider = FreeProvider();
      expect(provider.name, 'free');
    });

    test('未配置时 chat 抛出 typed noApiKey 错误', () async {
      final provider = FreeProvider();
      await expectLater(
        provider.chat(
          messages: const [ChatMessage(role: 'user', content: '测试')],
        ).toList(),
        throwsA(isA<AIException>()
            .having((error) => error.type, 'type', AIExceptionType.noApiKey)),
      );
    });
  });
}
