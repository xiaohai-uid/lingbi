import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/free_provider.dart';

/// Phase 2 测试：免费模型零配置
///
/// 验证：
/// 1. FreeProvider 不依赖环境变量即可 isAvailable = true
/// 2. displayName 包含"免费"字样
/// 3. currentModelId 非空
/// 4. supportsTools = true（支持 Agent 工具循环）
void main() {
  group('FreeProvider 零配置', () {
    test('isAvailable 始终为 true（不依赖环境变量）', () {
      final provider = FreeProvider();
      expect(provider.isAvailable, isTrue);
    });

    test('displayName 包含免费标识', () {
      final provider = FreeProvider();
      expect(provider.displayName, contains('免费'));
    });

    test('currentModelId 非空', () {
      final provider = FreeProvider();
      expect(provider.currentModelId, isNotEmpty);
    });

    test('supportsTools 为 true', () {
      final provider = FreeProvider();
      expect(provider.supportsTools, isTrue);
    });

    test('name 为 free', () {
      final provider = FreeProvider();
      expect(provider.name, 'free');
    });
  });
}
