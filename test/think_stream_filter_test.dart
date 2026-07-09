import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/think_stream_filter.dart';

void main() {
  group('ThinkStreamFilter', () {
    late ThinkStreamFilter filter;

    setUp(() {
      filter = ThinkStreamFilter();
    });

    test('passes through normal text unchanged', () {
      expect(filter.feed('Hello world'), 'Hello world');
      expect(filter.finish(), '');
    });

    test('filters single-chunk think block', () {
      const input = 'Before  thinking\nSome reasoning\nMore thinking\nAfter';
      final result = filter.feed(input);
      expect(result, 'Before After');
    });

    test('filters cross-chunk think block', () {
      // Chunk 1: opening tag
      final r1 = filter.feed('Start');
      expect(r1, 'Start');

      // Chunk 2: think tag opens across chunks
      final r2 = filter.feed(' thinking');
      expect(r2, ''); // Buffered

      // Chunk 3: content inside think
      final r3 = filter.feed('Some reasoning here');
      expect(r3, ''); // Still inside

      // Chunk 4: closing tag
      final r4 = filter.feed('End');
      // Might still be buffered
      expect(r4, '');

      // Chunk 5: text after
      final r5 = filter.feed('After');
      expect(r5, 'After');
    });

    test('handles multiple think blocks', () {
      const input = 'A  thinking\nB\nC\nD\nE';
      final result = filter.feed(input);
      // Three think blocks: first and last empty, middle has B\nC
      // Between them: A, D, E
      expect(result, 'A D E');
    });

    test('finish returns buffered non-think text', () {
      filter.feed('Hello  thinking');
      final remaining = filter.finish();
      expect(remaining, '');
    });

    test('returns buffered text when no open think tag', () {
      filter.feed('He');
      final remaining = filter.finish();
      expect(remaining, 'He');
    });

    test('handles empty input', () {
      expect(filter.feed(''), '');
      expect(filter.finish(), '');
    });

    test('filters JSON code block with think wrap', () {
      const input =
          'Some text  thinking\n{\n  "key": "value"\n}\n\ntest\nAfter';
      final result = filter.feed(input);
      expect(result, contains('After'));
      expect(result, isNot(contains('  thinking')));
    });
  });
}
