import 'dart:io';

void main() {
  var file = File('lib/core/ai/models/endpoint_config.dart');
  var content = file.readAsStringSync();
  
  // Fix the broken constructor parameter
  content = content.replaceFirst(
    "this.// apiKey,",
    "this.apiKey,"
  );
  
  // Fix hashCode: remove apiKey from Object.hash
  // Replace the comment back to apiKey in hashCode, then properly exclude it
  content = content.replaceFirst(
    "        // apiKey,",
    "        // apiKey,"
  );
  
  // Actually, the hashCode is broken. Let me replace the whole Object.hash call
  content = content.replaceFirst(
    "  int get hashCode => Object.hash(\n        id,\n        name,\n        baseUrl,\n        // apiKey,\n        protocol,\n        modelId,\n        authStrategy,\n        isReasoningModel,\n      );",
    "  int get hashCode => Object.hash(\n        id,\n        name,\n        baseUrl,\n        protocol,\n        modelId,\n        authStrategy,\n        isReasoningModel,\n      );"
  );
  
  file.writeAsStringSync(content);
  print('Fixed endpoint_config.dart');
}
