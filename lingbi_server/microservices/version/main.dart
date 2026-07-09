import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:version/lib/version_service.dart';

/// Global version service, initialized on startup.
late VersionService versionService;

void main() async {
  // Initialize version service
  versionService = VersionService();
  await versionService.init();

  // Start the server on port 8086
  DartFrog.debugMode = true;
  await serve(serve, port: 8086);
}
