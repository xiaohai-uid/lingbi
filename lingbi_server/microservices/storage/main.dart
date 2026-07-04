import 'package:dart_frog/dart_frog.dart';
import 'package:storage/lib/vector_store.dart';

/// Global vector store instance
late VectorStore vectorStore;

void main() async {
  // Initialize vector store with SQLite database
  vectorStore = await VectorStore.initialize('data/storage.db');

  // Start the server on port 8089
  DartFrog.debugMode = true;
  await serve(serve, port: 8089);
}