import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/lib/project_service.dart';

/// Global project service instance, initialized on startup.
late ProjectService projectService;

void main() async {
  // Initialize the project service with SQLite database
  projectService = ProjectService();
  await projectService.initialize();

  // Start the server on port 8082
  DartFrog.debugMode = true;
  await serve(serve, port: 8082);
}