import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';
import 'package:project/main.dart';

/// Handles GET /health - Health check endpoint.
Response onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  try {
    final projectCount = projectService.listProjects().length;

    return Response(
      body: jsonEncode({
        'status': 'ok',
        'service': 'project',
        'project_count': projectCount,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 503,
      body: jsonEncode({
        'status': 'error',
        'service': 'project',
        'error': e.toString(),
      }),
    );
  }
}