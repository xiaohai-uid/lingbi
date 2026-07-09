import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/llm_factory.dart';
import 'package:lingbi/core/ai/base_client.dart';
import 'package:lingbi/core/ai/llm_models.dart';

class _MockClient extends BaseLLMClient {
  _MockClient({String name = 'mock'}) : super(providerName: name);

  @override
  String get displayName => 'Mock';

  @override
  bool get isAvailable => true;

  @override
  Future<List<double>> embed(String text) async => [];

  @override
  Future<String> generateText(LLMRequest request) async => 'mock response';

  @override
  Stream<String> streamText(LLMRequest request) async* {
    yield 'mock stream';
  }

  @override
  Future<T> generateStructured<T>(
    LLMRequest request,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    return fromJson({'result': 'mock'});
  }
}

void main() {
  setUp(() {
    LLMFactory.reset();
  });

  group('LLMFactory', () {
    test('registers and creates a provider', () {
      LLMFactory.register('mock', () => _MockClient());
      final client = LLMFactory.create('mock');
      expect(client, isA<BaseLLMClient>());
      expect(client.providerName, 'mock');
    });

    test('throws on unknown provider', () {
      expect(
        () => LLMFactory.create('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('availableProviders returns registered names', () {
      LLMFactory.register('mock1', () => _MockClient(name: 'mock1'));
      LLMFactory.register('mock2', () => _MockClient(name: 'mock2'));
      final available = LLMFactory.availableProviders;
      expect(available, containsAll(['mock1', 'mock2']));
    });

    test('overrides existing registration', () {
      LLMFactory.register('mock', () => _MockClient(name: 'original'));
      LLMFactory.register('mock', () => _MockClient(name: 'override'));
      final client = LLMFactory.create('mock');
      expect(client.providerName, 'override');
    });

    test('reset clears all registrations', () {
      LLMFactory.register('mock', () => _MockClient());
      LLMFactory.reset();
      expect(LLMFactory.availableProviders, isEmpty);
    });

    test('registers built-in providers initially', () async {
      // initBuiltins 应在测试前被调用，或自动初始化
      LLMFactory.initBuiltins();
      final available = LLMFactory.availableProviders;
      expect(available, contains('free'));
      expect(available, contains('openai'));
      expect(available, contains('claude'));
      expect(available, contains('deepseek'));
    });
  });
}
