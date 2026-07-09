import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:project/project_service.dart';
import 'package:project/main.dart';

/// Handles requests for /:id/tree
/// GET  - Get the project's document tree
/// PUT  - Update the project's document tree
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

/// GET /:id/tree - Gets the project's document tree.
Response _handleGet(RequestContext context, String id) {
  final tree = projectService.getTree(id);

  if (tree == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Project not found'}),
    );
  }

  return Response(
    body: jsonEncode({
      'project_id': id,
      'tree': tree.map((k, v) => MapEntry(k, v)),
    }),
  );
}

/// PUT /:id/tree - Updates the project's document tree.
Future<Response> _handlePut(RequestContext context, String id) async {
  final existing = projectService.getProjectById(id);
  if (existing == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Project not found'}),
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final treeData = body['tree'] as Map<String, dynamic>?;

  if (treeData == null) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'tree field is required'}),
    );
  }

  final tree =
      treeData.map((k, v) => MapEntry(k, List<String>.from(v as List)));

  final success = projectService.updateTree(id, tree);
  if (!success) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Project not found'}),
    );
  }

  return Response(
    body: jsonEncode({
      'message': 'Tree updated successfully',
      'project_id': id,
      'tree': tree.map((k, v) => MapEntry(k, v)),
    }),
  );
}
