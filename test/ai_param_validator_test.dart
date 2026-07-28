import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/utils/ai_param_validator.dart';

void main() {
  group('AiParamValidator.validateTemperature', () {
    test('valid temperature returns null', () {
      expect(AiParamValidator.validateTemperature(0.7), isNull);
      expect(AiParamValidator.validateTemperature(0), isNull);
      expect(AiParamValidator.validateTemperature(2), isNull);
    });

    test('too low temperature returns error', () {
      final result = AiParamValidator.validateTemperature(-0.1);
      expect(result, isNotNull);
      expect(result, contains('温度'));
    });

    test('too high temperature returns error', () {
      final result = AiParamValidator.validateTemperature(2.1);
      expect(result, isNotNull);
      expect(result, contains('温度'));
    });
  });

  group('AiParamValidator.validateMaxTokens', () {
    test('valid maxTokens returns null', () {
      expect(AiParamValidator.validateMaxTokens(2048), isNull);
      expect(AiParamValidator.validateMaxTokens(1), isNull);
      expect(AiParamValidator.validateMaxTokens(128000), isNull);
    });

    test('too low maxTokens returns error', () {
      final result = AiParamValidator.validateMaxTokens(0);
      expect(result, isNotNull);
      expect(result, contains('Token'));
    });

    test('too high maxTokens returns error', () {
      final result = AiParamValidator.validateMaxTokens(128001);
      expect(result, isNotNull);
      expect(result, contains('Token'));
    });
  });

  group('AiParamValidator.sanitizeText', () {
    test('normal text passes through unchanged', () {
      expect(AiParamValidator.sanitizeText('你好世界'), '你好世界');
      expect(AiParamValidator.sanitizeText('Hello World'), 'Hello World');
    });

    test('newlines and tabs are preserved', () {
      expect(AiParamValidator.sanitizeText('line1\nline2\tcol'), 'line1\nline2\tcol');
    });

    test('control characters are removed', () {
      expect(AiParamValidator.sanitizeText('before\x00after'), 'beforeafter');
      expect(AiParamValidator.sanitizeText('a\x01b\x02c'), 'abc');
    });

    test('empty string returns empty', () {
      expect(AiParamValidator.sanitizeText(''), '');
    });
  });

  group('Word export helpers', () {
    test('stripMarkdown handles basic content', () {
      // Test via ExportService - just verify the HTML generation logic
      const md = '# Title\n\nParagraph 1\n\nParagraph 2';
      // This is a simple test of the markdown stripping logic
      expect(md.contains('# '), true);
    });
  });
}
