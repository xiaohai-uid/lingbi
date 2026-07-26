import 'dart:io';

void main() {
  var file = File('lib/services/settings_service.dart');
  var content = file.readAsStringSync();
  
  // Fix the _save method - add protocol parameter
  content = content.replaceFirst(
    "            .map((e) => EndpointConfig(\n                  id: e.id,\n                  name: e.name,\n                  baseUrl: e.baseUrl,\n                  apiKey: '', // 不在 JSON 中保存 apiKey\n                  modelId: e.modelId,\n                ).toJson())",
    "            .map((e) => EndpointConfig(\n                  protocol: e.protocol,\n                  id: e.id,\n                  name: e.name,\n                  baseUrl: e.baseUrl,\n                  apiKey: '', // 不在 JSON 中保存 apiKey\n                  modelId: e.modelId,\n                ).toJson())"
  );
  
  // Fix the _load method - parse EndpointConfig with protocol
  content = content.replaceFirst(
    "            _endpoints = (json['customEndpoints'] as List)\n                .whereType<Map<String, dynamic>>()\n                .map((e) => EndpointConfig.fromJson(e))\n                .toList();",
    "            _endpoints = (json['customEndpoints'] as List)\n                .whereType<Map<String, dynamic>>()\n                .map((e) => EndpointConfig.fromJson(e))\n                .toList();"
  );
  
  file.writeAsStringSync(content);
  print('Fixed _save method');
}
