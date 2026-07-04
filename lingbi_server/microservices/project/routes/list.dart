import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';
import 'package:project/main.dart';

/// Handles GET /list - Lists all projects.
Response onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final projects = projectService.listProjects();

    return Response(
      body: jsonEncode({
        'projects': projects.map((p) => p.toJson()).toList(),
        'count': projects.length,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}