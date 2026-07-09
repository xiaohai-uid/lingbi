import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';

import 'package:document/database_service.dart';
import 'package:document/document.dart';
import 'package:document/main.dart';

/// Handles POST / - Creates a new document.
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
    final title = (body['title'] as String?)?.trim() ?? '';
    final content = (body['content'] as String?) ?? '';
    final projectId = body['project_id'] as String? ?? 'default';

    if (title.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Title is required'}),
      );
    }

    final now = DateTime.now();
    final wordCount = Document.calculateWordCount(content);
    final document = Document(
      id: const Uuid().v4(),
      projectId: projectId,
      title: title,
      content: content,
      wordCount: wordCount,
      createdAt: now,
      updatedAt: now,
    );

    final created = databaseService.create(document);

    return Response(
      statusCode: 201,
      body: jsonEncode(created.toJson()),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
