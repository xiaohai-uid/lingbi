import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/data/context/context_compiler.dart';

void main() {
  group('CompilerConfig.forModel（p6 动态上下文预算）', () {
    test('未知窗口回退默认 8000', () {
      final cfg = CompilerConfig.forModel(contextWindow: null);
      expect(cfg.tokenBudget, 8000);
    });

    test('大窗口显著放大预算（远超旧的固定 8000）', () {
      final cfg = CompilerConfig.forModel(
        contextWindow: 128000,
        maxOutputTokens: 16384,
      );
      expect(cfg.tokenBudget, greaterThan(50000));
      expect(cfg.tokenBudget, lessThan(128000));
    });

    test('小窗口被夹在安全下限 4000', () {
      final cfg = CompilerConfig.forModel(
        contextWindow: 4096,
        maxOutputTokens: 2048,
      );
      expect(cfg.tokenBudget, 4000);
    });

    test('超大窗口被夹在安全上限 200000', () {
      final cfg = CompilerConfig.forModel(
        contextWindow: 1000000,
        maxOutputTokens: 32000,
      );
      expect(cfg.tokenBudget, 200000);
    });
  });
}
