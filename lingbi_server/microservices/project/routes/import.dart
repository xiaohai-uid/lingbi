import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';
import 'package:project/main.dart';

/// Handles POST /import - Imports projects from Markdown files.
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
    final filePaths = (body['file_paths'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    if (filePaths.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'file_paths must be a non-empty list'}),
      );
    }

    final createdIds = projectService.importFromMarkdown(filePaths);

    return Response(
      statusCode: 201,
      body: jsonEncode({
        'message': 'Imported ${createdIds.length} project(s)',
        'project_ids': createdIds,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}