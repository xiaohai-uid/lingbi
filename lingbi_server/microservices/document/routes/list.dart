import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/database_service.dart';
import 'package:document/document.dart';
import 'package:document/main.dart';

/// Handles GET /list - Lists all documents.
Response onRequest(RequestContext context) async {
  try {
    final projectId = context.request.uri.queryParameters['project_id'];
    final documents = databaseService.list(projectId: projectId);

    return Response(
      body: jsonEncode({
        'documents': documents.map((d) => d.toJson()).toList(),
        'count': documents.length,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
