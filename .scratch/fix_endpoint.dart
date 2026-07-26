import 'dart:io';

void main() {
  final file = File('lib/core/ai/models/endpoint_config.dart');
  var content = file.readAsStringSync();

  // Fix 1: modelsEndpoint for anthropic should return empty string
  content = content.replaceFirst(
    "    return '\${baseUrl.replaceAll('/v1', '')}/v1/models';",
    "    if (protocol == Protocol.anthropic) return '';\n    return '\${baseUrl.replaceAll('/v1', '')}/v1/models';"
  );

  // Fix 2: fromJson id fallback
  content = content.replaceFirst(
    "id: json['id'] as String? ?? '',",
    "id: json['id'] as String? ?? (json['name'] as String? ?? ''),"
  );

  file.writeAsStringSync(content);
  print('Fixed endpoint_config.dart');
}
