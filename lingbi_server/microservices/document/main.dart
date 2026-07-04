import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/lib/database_service.dart';
import 'package:document/lib/document.dart';

/// Global database service, initialized on startup.
late DatabaseService databaseService;

void main() async {
  // Initialize database service
  databaseService = DatabaseService();
  await databaseService.init();

  // Start the server on port 8083
  DartFrog.debugMode = true;
  await serve(serve, port: 8083);
}
