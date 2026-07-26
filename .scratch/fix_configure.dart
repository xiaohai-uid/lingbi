import 'dart:io';

void main() {
  var file = File('lib/services/ai_service.dart');
  var content = file.readAsStringSync();
  
  // Replace configureApiKey to auto-create endpoint if not found
  final old = '''  @override void configureApiKey(String provider, String key) {
    final idx = _endpoints.indexWhere((e) => e.id == provider);
    if (idx >= 0) {
      _endpoints[idx] = _endpoints[idx].copyWith(apiKey: key.isEmpty ? null : key);
      _providerCache.remove(provider);
    }
  }''';
  
  final replacement = '''  @override void configureApiKey(String provider, String key) {
    final idx = _endpoints.indexWhere((e) => e.id == provider);
    if (idx >= 0) {
      _endpoints[idx] = _endpoints[idx].copyWith(apiKey: key.isEmpty ? null : key);
      _providerCache.remove(provider);
    } else if (key.isNotEmpty && provider != 'free') {
      // Auto-create endpoint for known providers (backward compatibility)
      final protocol = (provider == 'claude') ? Protocol.anthropic : Protocol.openai;
      addEndpoint(EndpointConfig(
        id: provider,
        name: provider,
        baseUrl: 'https://api.\${provider}.com',
        apiKey: key,
        protocol: protocol,
        modelId: provider == 'openai' ? 'gpt-4o' : 
                 provider == 'claude' ? 'claude-sonnet-4-20250514' :
                 provider == 'deepseek' ? 'deepseek-chat' :
                 provider == 'sensenova' ? 'sensenova-6.7-flash-lite' : 'gpt-4o',
      ));
    }
  }''';
  
  content = content.replaceFirst(old, replacement);
  file.writeAsStringSync(content);
  print('Fixed configureApiKey');
}
