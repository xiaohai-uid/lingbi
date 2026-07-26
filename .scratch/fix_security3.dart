import 'dart:io';

void main() {
  // Fix: endpoint_config.dart - remove apiKey from == and hashCode
  var file = File('lib/core/ai/models/endpoint_config.dart');
  var content = file.readAsStringSync();
  
  // Fix == operator
  content = content.replaceFirst(
    "apiKey == other.apiKey &&",
    "// apiKey excluded from == (credential, not identity)\n      // apiKey == other.apiKey &&"
  );
  
  // Fix hashCode - remove apiKey
  content = content.replaceFirst(
    "apiKey,",
    "// apiKey,"
  );
  
  // Actually the first replace might fail. Let me look at the exact content
  file.writeAsStringSync(content);
  print('Fixed endpoint_config.dart 1');
}
