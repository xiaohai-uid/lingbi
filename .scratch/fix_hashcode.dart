import 'dart:io';

void main() {
  var file = File('lib/core/ai/models/endpoint_config.dart');
  var content = file.readAsStringSync();
  
  // Remove apiKey from Object.hash call
  content = content.replaceFirst(
    "        apiKey,\n        protocol,",
    "        protocol,"
  );
  
  file.writeAsStringSync(content);
  print('Fixed hashCode - removed apiKey');
}
