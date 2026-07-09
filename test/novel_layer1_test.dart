import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/novel/layer1_generator.dart';
import 'package:lingbi/core/models/novel_structure.dart';
import 'package:lingbi/services/prompt_service.dart';
import 'package:lingbi/core/ai/retry_handler.dart';

void main() {
  group('Layer1Generator', () {
    test('default constructor creates instance with defaults', () {
      final generator = Layer1Generator();
      expect(generator, isA<Layer1Generator>());
    });

    test('sets provider name', () {
      final generator = Layer1Generator();
      generator.providerName = 'openai';
      expect(generator.providerName, 'openai');
    });

    test('empty idea returns empty structure', () async {
      final generator = Layer1Generator();
      final result = await generator.generate(userIdea: '');
      expect(result, isA<SynopsisAndCharacters>());
      expect(result.synopsis, isEmpty);
      expect(result.characters, isEmpty);
    });

    test('accepts dependency injection', () {
      final generator = Layer1Generator(
        promptService: PromptService(),
        retryHandler: const RetryHandler(),
      );
      expect(generator, isA<Layer1Generator>());
    });
  });
}
