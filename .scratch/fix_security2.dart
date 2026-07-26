import 'dart:io';

void main() {
  // Fix 1: OpenAICompatibleProvider
  var file = File('lib/core/ai/providers/openai_compatible_provider.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "yield '\${_config.name} API 错误: \$e';",
    "yield '\${_config.name} API 错误: 请求失败，请检查网络和配置';"
  );
  content = content.replaceAll(
    "return '\${_config.name} API 错误: \$e';",
    "return '\${_config.name} API 错误: 请求失败，请检查网络和配置';"
  );
  
  file.writeAsStringSync(content);
  print('Fixed openai_compatible_provider.dart');

  // Fix 2: AnthropicProvider
  file = File('lib/core/ai/providers/anthropic_provider.dart');
  content = file.readAsStringSync();
  
  content = content.replaceAll(
    "yield '\${_config.name} API 错误: \$e';",
    "yield '\${_config.name} API 错误: 请求失败，请检查网络和配置';"
  );
  content = content.replaceAll(
    "_ => '\${_config.name} API 错误: \$statusCode \$body',",
    "_ => '\${_config.name} API 错误: \$statusCode',"
  );
  
  file.writeAsStringSync(content);
  print('Fixed anthropic_provider.dart');
}
