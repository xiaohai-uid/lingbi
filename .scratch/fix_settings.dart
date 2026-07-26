import 'dart:io';

void main() {
  var file = File('lib/services/settings_service.dart');
  var content = file.readAsStringSync();
  
  // Remove the old CustomEndpointConfig class (now renamed to EndpointConfig)
  // It starts at "/// 自定义端点配置数据类" and ends at "}"
  final start = content.indexOf("/// 自定义端点配置数据类");
  if (start >= 0) {
    // Find the closing } of the class
    var depth = 0;
    var end = start;
    var found = false;
    for (var i = start; i < content.length; i++) {
      if (content[i] == '{') depth++;
      if (content[i] == '}') {
        depth--;
        if (depth == 0) {
          end = i + 1;
          found = true;
          break;
        }
      }
    }
    if (found) {
      // Remove the class definition and the blank line after it
      var after = end;
      while (after < content.length && (content[after] == '\n' || content[after] == '\r')) after++;
      content = content.substring(0, start) + content.substring(after);
    }
  }
  
  // Fix unaddEndpoint -> removeEndpoint
  content = content.replaceAll('unaddEndpoint', 'removeEndpoint');
  
  // Fix customEndpoints -> endpoints (already done by sed)
  // Fix _customEndpoints -> _endpoints (already done by sed)
  
  // Add import for EndpointConfig if not present
  if (!content.contains("import '../core/ai/models/endpoint_config.dart'") &&
      !content.contains('import "../core/ai/models/endpoint_config.dart"')) {
    // Add after the last import
    final lastImport = content.lastIndexOf("import ");
    final endOfLine = content.indexOf('\n', lastImport);
    content = content.substring(0, endOfLine + 1) + 
      "import '../core/ai/models/endpoint_config.dart';\n" + 
      content.substring(endOfLine + 1);
  }
  
  file.writeAsStringSync(content);
  print('Fixed settings_service.dart');
}
