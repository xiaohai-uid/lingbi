import 'dart:io';

void main() {
  var file = File('lib/services/ai_service.dart');
  var content = file.readAsStringSync();
  
  // Make setProvider accept any name, just store it
  content = content.replaceFirst(
    '  @override void setProvider(String name) {',
    '  @override void setProvider(String name) {'
  );
  content = content.replaceFirst(
    "    if (name == 'free' || _endpoints.any((e) => e.id == name)) _currentProvider = name;",
    "    _currentProvider = name;"
  );
  
  file.writeAsStringSync(content);
  print('Fixed setProvider');
}
