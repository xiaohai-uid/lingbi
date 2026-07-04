import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/database_service.dart';
import 'package:document/document.dart';
import 'package:document/main.dart';

/// Handles requests for /:id
/// GET    - Get a single document
/// PUT    - Update a document
/// DELETE - Delete a document
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

/// GET /:id - Gets a single document by ID.
Response _handleGet(RequestContext context, String id) {
  final document = databaseService.getById(id);

  if (document == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Document not found'}),
    );
  }

  return Response(
    body: jsonEncode(document.toJson()),
  );
}

/// PUT /:id - Updates a document.
Future<Response> _handlePut(RequestContext context, String id) async {
  final existing = databaseService.getById(id);
  if (existing == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Document not found'}),
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final title = body['title'] as String?;
  final content = body['content'] as String?;
  final projectId = body['project_id'] as String?;

  if (title != null && title.trim().isEmpty) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'Title cannot be empty'}),
    );
  }

  final updated = databaseService.update(
    id,
    title: title?.trim(),
    content: content,
    projectId: projectId,
  );

  if (updated == null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Document not found'}),
    );
  }

  return Response(
    body: jsonEncode(updated.toJson()),
  );
}

/// DELETE /:id - Deletes a document.
Response _handleDelete(RequestContext context, String id) {
  final deleted = databaseService.delete(id);

  if (!deleted) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Document not found'}),
    );
  }

  return Response(
    statusCode: 200,
    body: jsonEncode({'message': 'Document deleted successfully'}),
  );
}