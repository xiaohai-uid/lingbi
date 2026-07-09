import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';

/// Global project service instance, initialized on startup.
late ProjectService projectService;

void main() async {
  // Initialize the project service with JSON file persistence
  projectService = ProjectService();
  await projectService.initialize();

  // Start the server on port 8082
  DartFrog.debugMode = true;
  await serve(serve, port: 8082);
}
