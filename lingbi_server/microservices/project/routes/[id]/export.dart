import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';
import 'package:project/main.dart';

/// Handles GET /:id/export - Exports a project as Markdown directory structure.
Response onRequest(RequestContext context) async {
  final id = context.params['id']!;
  final method = context.request.method;

  if (method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (method != HttpMethod.get) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final outputDir = projectService.exportToMarkdown(id);

    if (outputDir == null) {
      return Response(
        statusCode: 404,
        body: jsonEncode({'error': 'Project not found'}),
      );
    }

    return Response(
      body: jsonEncode({
        'message': 'Project exported successfully',
        'project_id': id,
        'output_directory': outputDir,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
