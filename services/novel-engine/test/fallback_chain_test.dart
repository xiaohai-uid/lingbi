import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lingbi_novel_engine/fallback_chain.dart';
import 'package:lingbi_novel_engine/llm_client.dart';

class MockLLMClient extends Mock implements LLMClient {}

void main() {
  late MockLLMClient client;
  const messages = [
    {'role': 'user', 'content': 'test'}
  ];

  setUp(() {
    client = MockLLMClient();
    registerFallbackValue(<Map<String, String>>[]);
  });

  test('uses primary model when it succeeds', () async {
    when(() => client.chat(
          messages: any(named: 'messages'),
          model: any(named: 'model'),
          temperature: any(named: 'temperature'),
          maxTokens: any(named: 'maxTokens'),
        )).thenAnswer((_) async => 'primary-ok');

    final chain = FallbackChain(
      client: client,
      models: ['primary', 'backup'],
    );
    final result = await chain.chatWithFallback(messages: messages);

    expect(result.content, 'primary-ok');
    expect(result.model, 'primary');
    expect(result.attempts, 1);
    verify(() => client.chat(
          messages: any(named: 'messages'),
          model: 'primary',
          temperature: any(named: 'temperature'),
          maxTokens: any(named: 'maxTokens'),
        )).called(1);
  });

  test('falls back to secondary when primary fails', () async {
    var calls = 0;
    when(() => client.chat(
          messages: any(named: 'messages'),
          model: any(named: 'model'),
          temperature: any(named: 'temperature'),
          maxTokens: any(named: 'maxTokens'),
        )).thenAnswer((invocation) async {
      calls++;
      final model = invocation.namedArguments[#model] as String;
      if (model == 'primary') throw Exception('primary down');
      return 'backup-ok';
    });

    final chain = FallbackChain(
      client: client,
      models: ['primary', 'backup'],
    );
    final result = await chain.chatWithFallback(messages: messages);

    expect(result.content, 'backup-ok');
    expect(result.model, 'backup');
    expect(result.attempts, 2);
    expect(calls, 2);
  });

  test('throws FallbackExhaustedException when all fail', () async {
    when(() => client.chat(
          messages: any(named: 'messages'),
          model: any(named: 'model'),
          temperature: any(named: 'temperature'),
          maxTokens: any(named: 'maxTokens'),
        )).thenThrow(Exception('boom'));

    final chain = FallbackChain(
      client: client,
      models: ['primary', 'backup'],
    );

    expect(
      () => chain.chatWithFallback(messages: messages),
      throwsA(isA<FallbackExhaustedException>()),
    );
  });

  test('throws when no models configured', () async {
    final chain = FallbackChain(client: client, models: const []);
    expect(
      () => chain.chatWithFallback(messages: messages),
      throwsA(isA<FallbackExhaustedException>()),
    );
  });
}
