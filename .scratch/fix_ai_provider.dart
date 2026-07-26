import 'dart:io';

void main() {
  var file = File('lib/core/ai/ai_provider.dart');
  var content = file.readAsStringSync();
  
  // Fix _classifyConnectionError to use generic message instead of raw exception
  content = content.replaceFirst(
    "return '连接失败: \$e';",
    "return '连接失败，请检查网络和配置';"
  );
  
  file.writeAsStringSync(content);
  print('Fixed ai_provider.dart');
}
