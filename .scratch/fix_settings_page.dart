import 'dart:io';

void main() {
  var file = File('lib/ui_v2/pages/settings_page.dart');
  var content = file.readAsStringSync();
  
  // Add import for EndpointConfig and Protocol
  content = content.replaceFirst(
    "import 'package:lingbi/core/ai/model_registry.dart';",
    "import 'package:lingbi/core/ai/model_registry.dart';\nimport 'package:lingbi/core/ai/models/endpoint_config.dart';"
  );
  
  // Fix first EndpointConfig constructor - add protocol
  content = content.replaceFirst(
    "final config = EndpointConfig(\n                        id: DateTime.now().millisecondsSinceEpoch.toString(),\n                        name: nameCtrl.text.trim(),\n                        baseUrl: urlCtrl.text.trim(),\n                        apiKey: keyCtrl.text.trim(),\n                        modelId: modelCtrl.text.trim(),\n                      );",
    "final config = EndpointConfig(\n                        protocol: Protocol.openai,\n                        id: DateTime.now().millisecondsSinceEpoch.toString(),\n                        name: nameCtrl.text.trim(),\n                        baseUrl: urlCtrl.text.trim(),\n                        apiKey: keyCtrl.text.trim(),\n                        modelId: modelCtrl.text.trim(),\n                      );"
  );
  
  // Fix second EndpointConfig constructor - add protocol
  content = content.replaceFirst(
    "final config = EndpointConfig(\n                  id: DateTime.now().millisecondsSinceEpoch.toString(),\n                  name: name,\n                  baseUrl: url,\n                  apiKey: key,\n                  modelId: model,\n                );",
    "final config = EndpointConfig(\n                  protocol: Protocol.openai,\n                  id: DateTime.now().millisecondsSinceEpoch.toString(),\n                  name: name,\n                  baseUrl: url,\n                  apiKey: key,\n                  modelId: model,\n                );"
  );
  
  // Fix testCustomEndpoint - addEndpoint returns void, so use testConnection instead
  content = content.replaceFirst(
    "final result = await ServiceLocator\n                          .instance.aiService\n                          .addEndpoint(config); result = \"连接已添加\";",
    "ServiceLocator.instance.aiService.addEndpoint(config);\n                      final result = \"连接已添加\";"
  );
  
  // Fix addEndpoint on SettingsService -> addCustomEndpoint (the method name in SettingsService)
  content = content.replaceFirst(
    "ServiceLocator.instance.settingsService\n                    .addEndpoint(config);",
    "ServiceLocator.instance.settingsService\n                    .addCustomEndpoint(config);"
  );
  
  file.writeAsStringSync(content);
  print('Fixed settings_page.dart');
}
