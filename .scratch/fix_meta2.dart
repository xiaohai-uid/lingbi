import 'dart:io';

void main() {
  var file = File('lib/services/project_meta_repository.dart');
  var content = file.readAsStringSync();
  
  // Remove unused entries variable
  content = content.replaceFirst(
    "final entries = await _canonService.list(projectId, CanonEntryType.lore);\n    ",
    ""
  );
  
  file.writeAsStringSync(content);
  print('Fixed unused variable');
}
