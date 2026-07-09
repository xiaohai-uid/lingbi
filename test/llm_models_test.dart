import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/llm_models.dart';

void main() {
  group('LLMRequest', () {
    test('creates with default values', () {
      const request = LLMRequest(
        messages: [LLMMessage(role: 'user', content: 'Hello')],
      );
      expect(request.messages.length, 1);
      expect(request.temperature, isNull);
      expect(request.maxTokens, isNull);
      expect(request.systemPrompt, isNull);
    });

    test('creates with all parameters', () {
      const request = LLMRequest(
        messages: [
          LLMMessage(role: 'system', content: 'You are a helper'),
          LLMMessage(role: 'user', content: 'Help me'),
        ],
        systemPrompt: 'You are a writing assistant',
        temperature: 0.8,
        maxTokens: 4096,
        topP: 0.9,
        presencePenalty: 0.1,
        frequencyPenalty: 0.1,
        stop: ['###'],
        responseSchema: {'type': 'object', 'properties': {}},
      );
      expect(request.messages.length, 2);
      expect(request.temperature, 0.8);
      expect(request.maxTokens, 4096);
      expect(request.topP, 0.9);
    });

    test('toJson includes all fields', () {
      const request = LLMRequest(
        messages: [LLMMessage(role: 'user', content: 'Hi')],
        temperature: 0.5,
        maxTokens: 1024,
      );
      final json = request.toJson();
      expect(json['temperature'], 0.5);
      expect(json['max_tokens'], 1024);
      expect(json['messages'].length, 1);
    });
  });

  group('LLMResponse', () {
    test('creates with content', () {
      const response = LLMResponse(content: 'Hello world');
      expect(response.content, 'Hello world');
      expect(response.usage, isNull);
      expect(response.finishReason, isNull);
    });

    test('creates with usage info', () {
      const usage =
          TokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30);
      const response = LLMResponse(
        content: 'Result',
        usage: usage,
        finishReason: 'stop',
      );
      expect(response.usage!.totalTokens, 30);
      expect(response.finishReason, 'stop');
    });
  });

  group('TokenUsage', () {
    test('calculates total from prompt + completion', () {
      const usage = TokenUsage(promptTokens: 50, completionTokens: 100);
      expect(usage.totalTokens, 150);
    });

    test('explicit total overrides calculation', () {
      const usage =
          TokenUsage(promptTokens: 50, completionTokens: 100, totalTokens: 200);
      expect(usage.totalTokens, 200);
    });
  });

  group('LLMMessage', () {
    test('creates with role and content', () {
      const msg = LLMMessage(role: 'user', content: 'Test');
      expect(msg.role, 'user');
      expect(msg.content, 'Test');
    });

    test('toJson returns correct map', () {
      const msg = LLMMessage(role: 'assistant', content: 'Response');
      final json = msg.toJson();
      expect(json['role'], 'assistant');
      expect(json['content'], 'Response');
    });

    test('fromJson restores object', () {
      final json = {'role': 'system', 'content': 'Be helpful'};
      final msg = LLMMessage.fromJson(json);
      expect(msg.role, 'system');
      expect(msg.content, 'Be helpful');
    });
  });
}
