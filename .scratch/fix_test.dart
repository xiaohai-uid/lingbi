import 'dart:io';

void main() {
  final file = File('test/endpoint_config_test.dart');
  var content = file.readAsStringSync();

  // Add tests for discoverModels and testConnection before the last closing brace of main()
  final newTests = '''
  group('ProviderFactory edge cases', () {
    test('discoverModels returns empty list for anthropic protocol', () async {
      final config = EndpointConfig(
        id: 'test-claude',
        name: 'Test Claude',
        baseUrl: 'https://api.anthropic.com',
        protocol: Protocol.anthropic,
        modelId: 'claude-sonnet-4',
      );
      final models = await ProviderFactory.discoverModels(config);
      expect(models, isEmpty);
    });

    test('discoverModels returns empty list for openai with no apiKey', () async {
      final config = EndpointConfig(
        id: 'test-no-key',
        name: 'Test No Key',
        baseUrl: 'https://api.test.com',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
      );
      final models = await ProviderFactory.discoverModels(config);
      // Without apiKey, discovery should return empty (not crash)
      expect(models, isEmpty);
    });

    test('testConnection returns failure for provider with no apiKey', () async {
      final config = EndpointConfig(
        id: 'test-no-key',
        name: 'Test No Key',
        baseUrl: 'https://api.test.com',
        protocol: Protocol.openai,
        modelId: 'gpt-4o',
      );
      final result = await ProviderFactory.testConnection(config);
      expect(result.success, false);
    });
  });
''';

  // Insert before the last '}'
  final lastBrace = content.lastIndexOf('}');
  content = content.substring(0, lastBrace) + newTests + '\n}';
  file.writeAsStringSync(content);
  print('Added 3 new tests');
}
