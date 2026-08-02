/// Provider conformance suite — reusable test group for AIProvider contract.
///
/// Any AIProvider implementation must pass these tests. Call
/// [runProviderConformanceSuite] with a factory that produces a fresh provider.
///
/// Task C1: test(provider): add deterministic conformance suite for AIProvider contract
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

/// Runs the full conformance suite against a provider produced by [factory].
///
/// Usage in a test file:
/// ```dart
/// void main() {
///   runProviderConformanceSuite(() => MyProvider(...));
/// }
/// ```
void runProviderConformanceSuite(AIProvider Function() factory) {
  group('AIProvider conformance', () {
    late AIProvider provider;

    setUp(() {
      provider = factory();
    });

    tearDown(() async {
      await provider.dispose();
    });

    group('identity', () {
      test('name is non-empty', () {
        expect(provider.name, isNotEmpty);
      });

      test('displayName is non-empty', () {
        expect(provider.displayName, isNotEmpty);
      });

      test('isAvailable returns a bool', () {
        expect(provider.isAvailable, isA<bool>());
      });
    });

    group('chatSync', () {
      test('returns non-null string for simple message', () async {
        final result = await provider.chatSync(
          messages: [const ChatMessage(role: 'user', content: 'hello')],
        );
        expect(result, isA<String>());
      });

      test('accepts system + user messages', () async {
        final result = await provider.chatSync(
          messages: [
            const ChatMessage(role: 'system', content: 'You are helpful.'),
            const ChatMessage(role: 'user', content: 'test'),
          ],
        );
        expect(result, isA<String>());
      });

      test('respects temperature and maxTokens parameters', () async {
        final result = await provider.chatSync(
          messages: [const ChatMessage(role: 'user', content: 'hi')],
          temperature: 0.1,
          maxTokens: 100,
        );
        expect(result, isA<String>());
      });
    });

    group('chat (streaming)', () {
      test('emits at least one chunk', () async {
        final chunks = await provider
            .chat(
              messages: [const ChatMessage(role: 'user', content: 'hello')],
            )
            .toList();
        expect(chunks, isNotEmpty);
      });

      test('concatenated chunks form non-empty string', () async {
        final chunks = await provider
            .chat(
              messages: [const ChatMessage(role: 'user', content: 'hello')],
            )
            .toList();
        final full = chunks.join();
        expect(full.trim(), isNotEmpty);
      });
    });

    group('supportsTools', () {
      test('returns a bool', () {
        expect(provider.supportsTools, isA<bool>());
      });

      test('chatWithTools throws UnsupportedError when not supported', () async {
        if (provider.supportsTools) return; // skip if supported
        expect(
          () => provider.chatWithTools(
            messages: [const ChatMessage(role: 'user', content: 'hi')],
            tools: const [],
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('chatWithTools (when supported)', () {
      test('returns ToolTurn with finishReason', () async {
        if (!provider.supportsTools) return; // skip if not supported
        final turn = await provider.chatWithTools(
          messages: [const ChatMessage(role: 'user', content: 'hi')],
          tools: const [
            ToolSpec(
              name: 'test_tool',
              description: 'A test tool',
              parameters: {'type': 'object', 'properties': {}},
            ),
          ],
        );
        expect(turn, isA<ToolTurn>());
        expect(turn.finishReason, isA<String>());
      });
    });

    group('embed', () {
      test('returns list of doubles', () async {
        final embedding = await provider.embed('test text');
        expect(embedding, isA<List<double>>());
      });

      test('same input produces same output (deterministic)', () async {
        final e1 = await provider.embed('hello world');
        final e2 = await provider.embed('hello world');
        expect(e1, equals(e2));
      });
    });
  });
}
