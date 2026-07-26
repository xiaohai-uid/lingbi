import 'dart:io';

void main() {
  final sb = StringBuffer();
  sb.writeln("import 'dart:async';");
  sb.writeln();
  sb.writeln("import 'package:lingbi/services/interfaces/i_ai_service.dart';");
  sb.writeln("import '../core/ai/ai_provider.dart';");
  sb.writeln("import '../core/ai/ai_response_normalizer.dart';");
  sb.writeln("import '../core/ai/free_provider.dart';");
  sb.writeln("import '../core/ai/model_registry.dart';");
  sb.writeln("import '../core/ai/models/endpoint_config.dart';");
  sb.writeln("import '../core/ai/provider_factory.dart';");
  sb.writeln("import '../core/errors/ai_error.dart';");
  sb.writeln("import 'quota_service.dart';");
  // ... rest of file
  File('lib/services/ai_service.dart').writeAsStringSync(sb.toString());
  print('Written ${sb.toString().length} bytes');
}
