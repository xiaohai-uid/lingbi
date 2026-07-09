import 'package:dart_frog/dart_frog.dart';
import 'lib/sync_service.dart';

/// Global sync service instance
late SyncService syncService;

void main() async {
  // Initialize sync service
  syncService = SyncService();
  await syncService.initialize();

  // Start the server on port 8090
  DartFrog.debugMode = true;
  await serve(serve, port: 8090);
}
