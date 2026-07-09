import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';
import 'package:project/main.dart';

/// Handles POST / - Creates a new project.
/// Also handles OPTIONS for CORS preflight.
Response onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  return _handlePost(context);
}

Future<Response> _handlePost(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final name = (body['name'] as String?)?.trim() ?? '';
    final description = (body['description'] as String?)?.trim() ?? '';

    if (name.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Project name is required'}),
      );
    }

    final project = projectService.createProject(
      name: name,
      description: description,
    );

    return Response(
      statusCode: 201,
      body: jsonEncode(project.toJson()),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
