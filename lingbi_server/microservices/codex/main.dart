import 'package:dart_frog/dart_frog.dart';
import 'package:codex/lib/codex_store.dart';

/// Global codex store instance
late CodexStore codexStore;

void main() async {
  // Initialize codex store with SQLite database
  codexStore = await CodexStore.initialize('data/codex.db');

  // Start the server on port 8084
  DartFrog.debugMode = true;
  await serve(serve, port: 8084);
}
