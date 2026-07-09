import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/novel/layer2_generator.dart';
import 'package:lingbi/services/prompt_service.dart';
import 'package:lingbi/core/ai/retry_handler.dart';

void main() {
  group('Layer2Generator', () {
    test('default constructor creates instance with defaults', () {
      final generator = Layer2Generator();
      expect(generator, isA<Layer2Generator>());
    });

    test('accepts dependency injection', () {
      final generator = Layer2Generator(
        promptService: PromptService(),
        retryHandler: const RetryHandler(),
      );
      expect(generator, isA<Layer2Generator>());
    });

    test('sets provider name', () {
      final generator = Layer2Generator();
      generator.providerName = 'deepseek';
      // No crash means success
    });
  });
}
