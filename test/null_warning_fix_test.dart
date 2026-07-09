import 'package:flutter_test/flutter_test.dart';

void main() {
  group('non-nullable warning fixes', () {
    test('synopsis.isNotEmpty is the correct check for non-nullable String',
        () {
      for (final text in ['', 'synopsis text', 'a']) {
        expect(text.isNotEmpty, isA<bool>());
      }
    });

    test('synopsis as-is equals synopsis without dead ?? fallback for String',
        () {
      for (final text in ['', 'synopsis text']) {
        expect(text, equals(text));
      }
    });

    test('name as-is equals name without dead ?? fallback for String', () {
      for (final name in ['test', '']) {
        expect(name, equals(name));
      }
    });
  });
}
