import 'dart:io';

void main() {
  // Fix 1: interface - remove unused import
  var file = File('lib/services/interfaces/i_project_meta_repository.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst("import '../../core/models/canon_entry.dart';\n", "");
  file.writeAsStringSync(content);
  print('Fixed interface');

  // Fix 2: implementation - fix sep undefined in read() and unused variable
  file = File('lib/services/project_meta_repository.dart');
  content = file.readAsStringSync();
  
  // Fix sep in read method - use Platform.pathSeparator directly
  content = content.replaceFirst(
    "final file = File('\${dir.path}\$sep\$fileName');",
    "final file = File('\${dir.path}\${Platform.pathSeparator}\$fileName');"
  );
  
  // Remove unused variable and fix delete method
  content = content.replaceFirst(
    "final indexEntries = entries.where((e) => e.name == indexName).toList();\n    // Also check other types\n    for (final type in CanonEntryType.values) {",
    "// Also check all types\n    for (final type in CanonEntryType.values) {"
  );
  
  file.writeAsStringSync(content);
  print('Fixed implementation');
}
