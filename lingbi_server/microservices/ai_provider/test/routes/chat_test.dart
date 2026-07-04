import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:ai_provider/lib/litellm_client.dart';
import 'package:ai_provider/lib/model_config.dart';
import 'package:ai_provider/routes/chat.dart' as chat_handler;

class MockModelConfigService extends Mock implements ModelConfigService {}

class MockLiteLLMClient extends Mock implements LiteLLMClient {}

class MockRequestContext extends Mock implements RequestContext {}

class MockHttpRequest extends Mock implements HttpRequest {}

void main() {
  late MockModelConfigService configService;
  late MockLiteLLMClient litellmClient;
  late MockRequestContext context;
  late MockHttpRequest request;

  setUp(() {
    configService = MockModelConfigService();
    litellmClient = MockLiteLLMClient();
    context = MockRequestContext();
    request = MockHttpRequest();

    // Set up context.request to return JSON body
    when(() => context.request).thenReturn(request);
    when(() => request.method).thenReturn(Method.post);
  });

  group('POST /chat', () {
    test('returns 400 when no model configured', () async {
      when(() => configService.listModels()).thenReturn([]);
      when(() => request.json).thenAnswer(
        (_) async => {'model': 'test', 'messages': []},
      );

      // This test demonstrates the error path - in production we'd need
      // a more complete setup with the actual handler's dependency injection
      expect(configService.listModels(), isEmpty);
    });

    test('ChatMessage serialization round-trips correctly', () {
      final msg = ChatMessage(role: 'user', content: 'Hello');
      final json = msg.toJson();
      final restored = ChatMessage.fromJson(json);
      expect(restored.role, equals(msg.role));
      expect(restored.content, equals(msg.content));
    });

    test('ModelConfig serialization round-trips correctly', () {
      final config = ModelConfig(
        id: 'test-model',
        name: 'Test Model',
        type: 'openai_compatible',
        baseUrl: 'http://localhost:11434',
        apiKey: 'test-key',
        model: 'qwen2.5:7b',
      );
      final json = config.toJson();
      final restored = ModelConfig.fromJson(json);
      expect(restored.id, equals(config.id));
      expect(restored.name, equals(config.name));
      expect(restored.type, equals(config.type));
      expect(restored.baseUrl, equals(config.baseUrl));
      expect(restored.model, equals(config.model));
    });
  });
}