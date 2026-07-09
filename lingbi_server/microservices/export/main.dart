import 'package:dart_frog/dart_frog.dart';
import 'lib/export_service.dart';

/// Global export service instance
late ExportService exportService;

void main() async {
  // Initialize export service
  exportService = ExportService();

  // Start the server on port 8085
  DartFrog.debugMode = true;
  await serve(serve, port: 8085);
}
