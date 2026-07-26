import 'dart:io';

void main() {
  final file = File('lib/core/ai/providers/anthropic_provider.dart');
  var content = file.readAsStringSync();

  // Fix: Simplify _convertMessages - remove unnecessary ternary since system messages are filtered out before calling
  content = content.replaceFirst(
    "      'role': m.role == 'system' ? 'user' : m.role,",
    "      'role': m.role,"
  );

  // Fix: Add isAvailable check to listModels
  content = content.replaceFirst(
    "  Future<List<String>> listModels() async {",
    "  Future<List<String>> listModels() async {\n    if (!isAvailable) return [];"
  );

  file.writeAsStringSync(content);
  print('Fixed anthropic_provider.dart');
}
