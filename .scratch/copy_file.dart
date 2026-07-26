import 'dart:io';

void main() {
  final src = File('/tmp/ai_service_complete.dart');
  final dst = File('lib/services/ai_service.dart');
  if (!src.existsSync()) {
    print('Source file not found at /tmp/ai_service_complete.dart');
    exit(1);
  }
  final content = src.readAsStringSync();
  dst.writeAsStringSync(content);
  print('Copied ${content.length} bytes, ${content.split('\n').length} lines');
}
