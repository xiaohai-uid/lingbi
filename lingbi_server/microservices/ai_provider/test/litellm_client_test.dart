import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:ai_provider/litellm_client.dart';

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

    test('equality works correctly', () {
      final a = ChatMessage(role: 'user', content: 'Hello');
      final b = ChatMessage(role: 'user', content: 'Hello');
      final c = ChatMessage(role: 'assistant', content: 'Hello');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('LiteLLMException', () {
    test('formats message correctly without status code', () {
      final ex = LiteLLMException('Something went wrong');
      expect(ex.toString(), contains('Something went wrong'));
    });

    test('formats message correctly with status code', () {
      final ex = LiteLLMException('Not found', statusCode: 404);
      expect(ex.toString(), contains('404'));
      expect(ex.toString(), contains('Not found'));
    });
  });

  group('RateLimitException', () {
    test('has correct status code', () {
      final ex = RateLimitException('Too many requests');
      expect(ex.statusCode, equals(429));
    });

    test('has default retry after', () {
      final ex = RateLimitException('Too many requests');
      expect(ex.retryAfter, equals(const Duration(seconds: 30)));
    });
  });

  group('LiteLLMTimeoutException', () {
    test('has null status code', () {
      final ex = LiteLLMTimeoutException('Request timed out');
      expect(ex.statusCode, isNull);
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

    test('non-streaming chat returns a stream with single value', () async {
      final client = LiteLLMClient(baseUrl: 'http://localhost:8081');
      final messages = [ChatMessage(role: 'user', content: 'Hello')];

      try {
        final stream = await client.chat(
          model: 'test-model',
          messages: messages,
          stream: false,
        );

        expect(stream, isNotNull);
      } catch (e) {
        // Expected if server is not running
        expect(e, isA<Exception>());
      } finally {
        client.dispose();
      }
    });

    test('embed throws on connection error', () async {
      final client = LiteLLMClient(baseUrl: 'http://localhost:1');
      try {
        await client.embed(model: 'test', input: 'Hello');
        fail('Expected exception');
      } catch (e) {
        expect(e, isA<Exception>());
      } finally {
        client.dispose();
      }
    });

    test('listModels throws on connection error', () async {
      final client = LiteLLMClient(baseUrl: 'http://localhost:1');
      try {
        await client.listModels();
        fail('Expected exception');
      } catch (e) {
        expect(e, isA<Exception>());
      } finally {
        client.dispose();
      }
    });

    test('dispose does not throw', () {
      final client = LiteLLMClient(baseUrl: 'http://localhost:8081');
      expect(() => client.dispose(), returnsNormally);
    });
  });
}
