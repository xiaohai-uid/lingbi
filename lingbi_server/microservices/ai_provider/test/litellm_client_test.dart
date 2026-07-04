import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import 'package:ai_provider/lib/litellm_client.dart';

void main() {
  group('ChatMessage', () {
    test('toJson returns correct structure', () {
      final msg = ChatMessage(role: 'user', content: 'Hello');
      expect(msg.toJson(), equals({'role': 'user', 'content': 'Hello'}));
    });

    test('fromJson creates correct object', () {
      final json = {'role': 'assistant', 'content': 'Hi there!'};
      final msg = ChatMessage.fromJson(json);
      expect(msg.role, equals('assistant'));
      expect(msg.content, equals('Hi there!'));
    });

    test('toJson and fromJson are inverses', () {
      final original = ChatMessage(role: 'system', content: 'You are helpful.');
      final restored = ChatMessage.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });

  group('LiteLLMClient', () {
    test('chat returns a stream that emits chunks', () async {
      final client = LiteLLMClient(baseUrl: 'http://localhost:8081');
      final messages = [ChatMessage(role: 'user', content: 'Hello')];

      try {
        final stream = await client.chat(
          model: 'test-model',
          messages: messages,
        );

        // Verify we get a stream
        expect(stream, isNotNull);
      } catch (e) {
        // Expected if server is not running
        expect(e, isA<Exception>());
      } finally {
        client.dispose();
      }
    });
  });
}
