import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lingbi/services/provider_registry.dart';

class _MockClient extends http.BaseClient {
  final int statusCode;
  final String body;
  final bool throwError;
  _MockClient({this.statusCode = 200, this.body = '', this.throwError = false});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (throwError) throw Exception('Network error');
    final response = http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
    return Future.value(response);
  }
}

void main() {
  group('DefaultParams', () {
    test('creates with default values', () {
      const params = DefaultParams();
      expect(params.temperature, 0.7);
      expect(params.maxTokens, 2048);
      expect(params.topP, 1.0);
    });

    test('serializes to/from JSON', () {
      const params =
          DefaultParams(temperature: 0.5, maxTokens: 4096, topP: 0.9);
      final json = params.toJson();
      final restored = DefaultParams.fromJson(json);
      expect(restored.temperature, 0.5);
      expect(restored.maxTokens, 4096);
      expect(restored.topP, 0.9);
    });
  });

  group('ModelInfo', () {
    test('creates with id and owner', () {
      const model = ModelInfo(id: 'gpt-4o', ownedBy: 'openai');
      expect(model.id, 'gpt-4o');
      expect(model.ownedBy, 'openai');
    });

    test('serializes to/from JSON', () {
      const model = ModelInfo(id: 'gpt-4o-mini', ownedBy: 'openai');
      final json = model.toJson();
      final restored = ModelInfo.fromJson(json);
      expect(restored.id, 'gpt-4o-mini');
      expect(restored.ownedBy, 'openai');
    });
  });

  group('ProviderConfig', () {
    test('creates with required fields', () {
      final config =
          ProviderConfig(name: '我的中转站', baseUrl: 'https://api.example.com/v1');
      expect(config.name, '我的中转站');
      expect(config.baseUrl, 'https://api.example.com/v1');
      expect(config.apiKey, '');
      expect(config.selectedModel, null);
      expect(config.models, isEmpty);
      expect(config.defaultParams.temperature, 0.7);
      expect(config.id.isNotEmpty, true);
    });

    test('serializes to/from JSON', () {
      final config = ProviderConfig(
        id: 'test-id',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'sk-test',
        selectedModel: 'gpt-4o',
        models: [const ModelInfo(id: 'gpt-4o', ownedBy: 'openai')],
        defaultParams:
            const DefaultParams(temperature: 0.3, maxTokens: 1024, topP: 0.8),
      );
      final json = config.toJson();
      final restored = ProviderConfig.fromJson(json);
      expect(restored.id, 'test-id');
      expect(restored.name, 'OpenAI');
      expect(restored.baseUrl, 'https://api.openai.com/v1');
      expect(restored.apiKey, 'sk-test');
      expect(restored.selectedModel, 'gpt-4o');
      expect(restored.models.length, 1);
      expect(restored.models[0].id, 'gpt-4o');
      expect(restored.defaultParams.temperature, 0.3);
      expect(restored.defaultParams.maxTokens, 1024);
    });
  });

  group('ProviderRegistry', () {
    test('starts empty', () {
      final registry = ProviderRegistry();
      expect(registry.getAll(), isEmpty);
      expect(registry.getActiveProvider(), isNull);
    });

    test('adds a provider', () {
      final registry = ProviderRegistry();
      final config =
          ProviderConfig(name: 'Test', baseUrl: 'https://test.com/v1');
      registry.add(config);
      expect(registry.getAll(), [config]);
    });

    test('removes a provider by id', () {
      final registry = ProviderRegistry();
      final config =
          ProviderConfig(name: 'Test', baseUrl: 'https://test.com/v1');
      registry.add(config);
      registry.remove(config.id);
      expect(registry.getAll(), isEmpty);
    });

    test('updates a provider', () {
      final registry = ProviderRegistry();
      final config =
          ProviderConfig(name: 'Test', baseUrl: 'https://test.com/v1');
      registry.add(config);
      registry.update(config.id, name: 'Updated');
      expect(registry.get(config.id)?.name, 'Updated');
    });

    test(
        'getActiveProvider returns the first provider when none explicitly set',
        () {
      final registry = ProviderRegistry();
      final config =
          ProviderConfig(name: 'Test', baseUrl: 'https://test.com/v1');
      registry.add(config);
      expect(registry.getActiveProvider(), config);
    });

    test('toJson/fromJson round-trips full registry state', () {
      final registry = ProviderRegistry();
      registry.add(ProviderConfig(name: 'A', baseUrl: 'https://a.com/v1'));
      registry.add(ProviderConfig(name: 'B', baseUrl: 'https://b.com/v1'));
      final json = registry.toJson();
      final restored = ProviderRegistry.fromJson(json);
      expect(restored.getAll().length, 2);
      expect(restored.getAll()[0].name, 'A');
      expect(restored.getAll()[1].name, 'B');
    });

    test('silently ignores removing unknown id', () {
      final registry = ProviderRegistry();
      registry.remove('non-existent');
      // No crash is the test
    });

    test('silently ignores updating unknown id', () {
      final registry = ProviderRegistry();
      registry.update('non-existent', name: 'X');
      expect(registry.getAll(), isEmpty);
    });
  });

  group('getModels', () {
    test('parses OpenAI-compatible response format', () async {
      final client = _MockClient(
        body: '{"data": [{"id": "gpt-4o", "owned_by": "openai"}, {"id": "gpt-4o-mini", "owned_by": "openai"}]}',
      );
      final models = await ProviderRegistry.getModels(
        'https://test.com/v1', apiKey: 'sk-test', client: client,
      );
      expect(models.length, 2);
      expect(models[0].id, 'gpt-4o');
      expect(models[1].id, 'gpt-4o-mini');
    });

    test('parses plain array fallback', () async {
      final client = _MockClient(
        body: '[{"id": "deepseek-chat", "owned_by": "deepseek"}, {"id": "deepseek-coder", "owned_by": "deepseek"}]',
      );
      final models = await ProviderRegistry.getModels(
        'https://test.com/v1', apiKey: 'sk-test', client: client,
      );
      expect(models.length, 2);
      expect(models[0].id, 'deepseek-chat');
    });

    test('handles empty model list', () async {
      final client = _MockClient(body: '{"data": []}');
      final models = await ProviderRegistry.getModels(
        'https://test.com/v1', apiKey: 'sk-test', client: client,
      );
      expect(models, isEmpty);
    });

    test('throws on HTTP 401', () async {
      final client = _MockClient(statusCode: 401, body: 'Unauthorized');
      expect(
        () => ProviderRegistry.getModels('https://test.com/v1', apiKey: 'bad', client: client),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on HTTP 404', () async {
      final client = _MockClient(statusCode: 404, body: 'Not Found');
      expect(
        () => ProviderRegistry.getModels('https://test.com/v1', apiKey: 'sk-test', client: client),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on network error', () async {
      final client = _MockClient(throwError: true);
      expect(
        () => ProviderRegistry.getModels('https://test.com/v1', apiKey: 'sk-test', client: client),
        throwsA(isA<Exception>()),
      );
    });

    test('strips trailing slash from baseUrl', () async {
      final client = _MockClient(body: '{"data": []}');
      await ProviderRegistry.getModels('https://test.com/v1/', apiKey: 'sk-test', client: client);
      // No crash = test passes
    });
  });
}
