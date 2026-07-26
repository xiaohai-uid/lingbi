import 'dart:io';

void main() {
  var file = File('lib/services/settings_service.dart');
  var content = file.readAsStringSync();
  
  // Fix load order: register endpoints BEFORE applying API keys
  // Move the "将 API keys 应用到 AI 服务" block AFTER the "将自定义端点注册到 AI 服务" block
  
  // Find the two blocks
  final apiKeysBlock = "    // 6. 将 API keys 应用到 AI 服务";
  final endpointsBlock = "    // 7. 将自定义端点注册到 AI 服务";
  
  // Extract the API keys block
  final apiKeysStart = content.indexOf(apiKeysBlock);
  if (apiKeysStart < 0) { print("ERROR: apiKeys block not found"); return; }
  final apiKeysEnd = content.indexOf("\n    // 7.", apiKeysStart);
  if (apiKeysEnd < 0) { print("ERROR: endpoints block not found after apiKeys"); return; }
  final apiKeysCode = content.substring(apiKeysStart, apiKeysEnd);
  
  // Extract the endpoints block
  final endpointsStart = content.indexOf(endpointsBlock);
  if (endpointsStart < 0) { print("ERROR: endpoints block not found"); return; }
  var endpointsEnd = content.indexOf("\n    // 8.", endpointsStart);
  if (endpointsEnd < 0) {
    // Try "  }" or similar end marker
    endpointsEnd = content.indexOf("\n  }\n\n", endpointsStart);
    if (endpointsEnd < 0) {
      // Last block before method end
      endpointsEnd = content.indexOf("\n    }\n\n    // 8.", endpointsStart);
      if (endpointsEnd < 0) {
        endpointsEnd = content.indexOf("\n  }\n\n  ThemeMode", endpointsStart);
      }
    }
  }
  if (endpointsEnd < 0) { print("ERROR: cannot find end of endpoints block"); return; }
  final endpointsCode = content.substring(endpointsStart, endpointsEnd);
  
  // Swap: first endpoints, then apiKeys
  content = content.substring(0, apiKeysStart) + 
    endpointsCode + "\n" +
    apiKeysCode + 
    content.substring(apiKeysEnd);
  
  // Remove the old endpoints block (now duplicated)
  final oldEndpointsStart = content.indexOf(endpointsBlock, apiKeysEnd + 50);
  final oldEndpointsEnd = content.indexOf("\n    }\n\n    // 8.", oldEndpointsStart);
  if (oldEndpointsStart > 0 && oldEndpointsEnd > 0) {
    content = content.substring(0, oldEndpointsStart) + content.substring(oldEndpointsEnd);
  }
  
  file.writeAsStringSync(content);
  print('Fixed load order');
}
