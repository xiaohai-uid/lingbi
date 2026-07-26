import 'dart:io';

void main() {
  final file = File('lib/core/ai/providers/openai_compatible_provider.dart');
  var content = file.readAsStringSync();

  // Fix 1: Add isAvailable check to listModels
  content = content.replaceFirst(
    "  Future<List<String>> listModels() async {",
    "  Future<List<String>> listModels() async {\n    if (!isAvailable) return [];"
  );

  // Fix 2: Add isAvailable check to embed
  content = content.replaceFirst(
    "  Future<List<double>> embed(String text) async {",
    "  Future<List<double>> embed(String text) async {\n    if (!isAvailable) return List.filled(768, 0);"
  );

  // Fix 3: Guard _authHeaders when apiKey is null
  content = content.replaceFirst(
    "  Map<String, String> get _authHeaders {",
    "  Map<String, String> get _authHeaders {\n    if (_config.apiKey == null) return {};"
  );

  file.writeAsStringSync(content);
  print('Fixed openai_compatible_provider.dart');
}
