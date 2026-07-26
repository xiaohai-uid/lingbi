import 'dart:io';

void main() {
  // Fix 1: OpenAICompatibleProvider - sanitize exception messages
  var file = File('lib/core/ai/providers/openai_compatible_provider.dart');
  var content = file.readAsStringSync();
  
  // Replace raw exception interpolation with sanitized version
  content = content.replaceAll(
    "yield '$_config.name API 错误: $e';",
    "yield '\${_config.name} API 错误: 请求失败，请检查网络和配置';"
  );
  content = content.replaceAll(
    "return '$_config.name API 错误: $e';",
    "return '\${_config.name} API 错误: 请求失败，请检查网络和配置';"
  );
  
  file.writeAsStringSync(content);
  print('Fixed openai_compatible_provider.dart');

  // Fix 2: AnthropicProvider - sanitize exception and body
  file = File('lib/core/ai/providers/anthropic_provider.dart');
  content = file.readAsStringSync();
  
  content = content.replaceAll(
    "yield '$_config.name API 错误: $e';",
    "yield '\${_config.name} API 错误: 请求失败，请检查网络和配置';"
  );
  content = content.replaceAll(
    "_ => '$_config.name API 错误: $statusCode $body',",
    "_ => '\${_config.name} API 错误: \$statusCode',"
  );
  
  file.writeAsStringSync(content);
  print('Fixed anthropic_provider.dart');

  // Fix 3: endpoint_config.dart - remove apiKey from hashCode/==
  file = File('lib/core/ai/models/endpoint_config.dart');
  content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "apiKey == other.apiKey &&",
    "// apiKey intentionally excluded from == (credential, not identity)\n      // apiKey == other.apiKey &&"
  );
  content = content.replaceFirst(
    "apiKey,",
    "// apiKey,"
  );
  
  file.writeAsStringSync(content);
  print('Fixed endpoint_config.dart');
}
