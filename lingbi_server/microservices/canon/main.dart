import 'package:dart_frog/dart_frog.dart';
import 'package:canon/lib/canon_store.dart';

/// Global canon store instance
late CanonStore canonStore;

void main() async {
  // Initialize canon store with SQLite database
  canonStore = await CanonStore.initialize('data/canon.db');

  // Start the server on port 8084
  DartFrog.debugMode = true;
  await serve(serve, port: 8084);
}
