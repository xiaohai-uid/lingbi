import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';
import 'package:project/main.dart';

/// Handles requests for /:id
/// GET    - Get a single project
/// PUT    - Update a project
/// DELETE - Delete a project
Response onRequest(RequestContext context) async {
  final id = context.params['id']!;
  final method = context.request.method;

  if (method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  try {
    switch (method) {
      case HttpMethod.get:
        return _handleGet(context, id);
      case HttpMethod.put:
        return _handlePut(context, id);
      case HttpMethod.delete:
        return _handleDelete(context, id);
      default:
        return Response(
          statusCode: 405,
          body: jsonEncode({'error': 'Method not allowed'}),
        );
    }
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}

/// GET /:id - Gets a single project by ID.
Response _handleGet(RequestContext context, String id) {
  final project = projectService.getProjectById(id);

  if (project == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Project not found'}),
    );
  }

  return Response(
    body: jsonEncode(project.toJson()),
  );
}

/// PUT /:id - Updates a project.
Future<Response> _handlePut(RequestContext context, String id) async {
  final existing = projectService.getProjectById(id);
  if (existing == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Project not found'}),
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final name = body['name'] as String?;
  final description = body['description'] as String?;

  if (name != null && name.trim().isEmpty) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'Project name cannot be empty'}),
    );
  }

  final updated = projectService.updateProject(
    id,
    name: name?.trim(),
    description: description?.trim(),
  );

  if (updated == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Project not found'}),
    );
  }

  return Response(
    body: jsonEncode(updated.toJson()),
  );
}

/// DELETE /:id - Deletes a project.
Response _handleDelete(RequestContext context, String id) {
  final deleted = projectService.deleteProject(id);

  if (!deleted) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Project not found'}),
    );
  }

  return Response(
    statusCode: 200,
    body: jsonEncode({'message': 'Project deleted successfully'}),
  );
}
