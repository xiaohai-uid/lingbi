import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/novel/layer3_generator.dart';
import 'package:lingbi/services/prompt_service.dart';

void main() {
  group('Layer3Generator', () {
    test('default constructor creates instance with defaults', () {
      final generator = Layer3Generator();
      expect(generator, isA<Layer3Generator>());
    });

    test('accepts dependency injection', () {
      final generator = Layer3Generator(
        promptService: PromptService(),
      );
      expect(generator, isA<Layer3Generator>());
    });

    test('sets provider name', () {
      final generator = Layer3Generator();
      generator.providerName = 'claude';
      // No crash means success
    });
  });
}
