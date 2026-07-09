import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/base_client.dart';
import 'package:lingbi/core/ai/llm_models.dart';
import 'package:lingbi/core/ai/llm_errors.dart';

/// 测试用的最小实现
class TestClient extends BaseLLMClient {
  TestClient({String name = 'test'}) : super(providerName: name);

  @override
  String get displayName => 'Test';

  @override
  bool get isAvailable => true;

  @override
  Future<List<double>> embed(String text) async => [];

  @override
  Future<String> generateText(LLMRequest request) async {
    if (request.messages.isEmpty) {
      throw LLMResponseException(
        message: 'No messages',
        provider: providerName,
        statusCode: 400,
      );
    }
    return 'Generated: ${request.messages.last.content}';
  }

  @override
  Stream<String> streamText(LLMRequest request) async* {
    yield 'Streaming: ';
    yield request.messages.last.content;
  }

  @override
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final text = await generateText(request);
    // 模拟 JSON 提取
    final json = <String, dynamic>{'result': text};
    return fromJson(json);
  }
}

void main() {
  group('BaseLLMClient', () {
    late TestClient client;

    setUp(() {
      client = TestClient(name: 'test-client');
    });

    test('providerName is set correctly', () {
      expect(client.providerName, 'test-client');
    });

    test('generateText returns generated text', () async {
      const request = LLMRequest(
        messages: [LLMMessage(role: 'user', content: 'Hello')],
      );
      final result = await client.generateText(request);
      expect(result, 'Generated: Hello');
    });

    test('generateText throws on empty messages', () async {
      const request = LLMRequest(messages: []);
      expect(
        () => client.generateText(request),
        throwsA(isA<LLMResponseException>()),
      );
    });

    test('streamText returns stream of chunks', () async {
      const request = LLMRequest(
        messages: [LLMMessage(role: 'user', content: 'Test')],
      );
      final chunks = <String>[];
      // ignore: prefer_foreach
      await for (final chunk in client.streamText(request)) {
        chunks.add(chunk);
      }
      expect(chunks.length, 2);
      expect(chunks[0], 'Streaming: ');
      expect(chunks[1], 'Test');
    });

    test('generateStructured returns parsed result', () async {
      const request = LLMRequest(
        messages: [LLMMessage(role: 'user', content: 'Parse this')],
      );
      final result = await client.generateStructured<Map<String, dynamic>>(
        request,
        (json) => json,
      );
      expect(result['result'], contains('Generated'));
    });
  });
}
