import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/schema_processor.dart';

void main() {
  late SchemaProcessor processor;

  setUp(() {
    processor = SchemaProcessor();
  });

  group('extractJsonBlock', () {
    test('extracts JSON from code block', () {
      const input = 'Some text\n```json\n{"key": "value"}\n```\nMore text';
      final result = processor.extractJsonBlock(input);
      expect(result, isNotNull);
      expect(result!['key'], 'value');
    });

    test('extracts JSON without language tag', () {
      const input = '```\n{"key": "value"}\n```';
      final result = processor.extractJsonBlock(input);
      expect(result, isNotNull);
      expect(result!['key'], 'value');
    });

    test('returns null when no JSON block found', () {
      const input = 'Just plain text without any JSON';
      expect(processor.extractJsonBlock(input), isNull);
    });

    test('handles nested JSON', () {
      const input = '```json\n{"outer": {"inner": [1, 2, 3]}}\n```';
      final result = processor.extractJsonBlock(input);
      expect(result, isNotNull);
      expect((result!['outer'] as Map)['inner'], [1, 2, 3]);
    });

    test('handles multiple code blocks - returns first valid JSON', () {
      const input =
          '```json\n{"first": true}\n```\n```json\n{"second": true}\n```';
      final result = processor.extractJsonBlock(input);
      expect(result, isNotNull);
      expect(result!['first'], true);
    });
  });

  group('extractStructured', () {
    test('extracts and parses structured data with parser', () {
      const input =
          'Some text\n```json\n{"name": "Test", "count": 42}\n```\nEnd';
      final result = processor.extractStructured<Map<String, dynamic>>(
        input,
        (json) => json,
      );
      expect(result, isNotNull);
      expect(result!['name'], 'Test');
      expect(result['count'], 42);
    });

    test('returns null when no JSON found', () {
      const input = 'No JSON here';
      final result = processor.extractStructured<String>(
        input,
        (json) => json['result'] as String,
      );
      expect(result, isNull);
    });

    test('transforms parsed data using fromJson function', () {
      const input = '```json\n{"result": "hello"}\n```';
      final result = processor.extractStructured<String>(
        input,
        (json) => (json['result'] as String).toUpperCase(),
      );
      expect(result, 'HELLO');
    });
  });

  group('extractAllJsonBlocks', () {
    test('extracts all JSON blocks from text', () {
      const input = '```json\n{"a": 1}\n```\nText\n```json\n{"b": 2}\n```';
      final results = processor.extractAllJsonBlocks(input);
      expect(results.length, 2);
      expect(results[0]['a'], 1);
      expect(results[1]['b'], 2);
    });

    test('returns empty list when no JSON blocks', () {
      expect(processor.extractAllJsonBlocks('No JSON'), isEmpty);
    });
  });
}
