import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI assistant split contract', () {
    test('public entry stays a facade', () {
      final lines = File(
        'lib/ui_v2/components/ai_assistant.dart',
      ).readAsLinesSync();

      expect(lines.length, lessThan(50));
    });

    test('expected AI assistant files exist', () {
      const files = [
        'ai_assistant/chat_message.dart',
        'ai_assistant/ai_assistant_panel.dart',
        'ai_assistant/message_builders.dart',
        'ai_assistant/chat_input_bar.dart',
      ];

      for (final name in files) {
        final path = 'lib/ui_v2/components/$name';
        expect(File(path).existsSync(), isTrue, reason: 'missing $path');
      }
    });
  });
}
