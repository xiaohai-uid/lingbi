import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/database_service.dart';
import 'package:document/main.dart';

/// Handles GET /health - Health check endpoint.
Response onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  try {
    // Verify database is accessible by checking if it can query
    final docCount = databaseService.list().length;

    return Response(
      body: jsonEncode({
        'status': 'ok',
        'service': 'document',
        'document_count': docCount,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 503,
      body: jsonEncode({
        'status': 'error',
        'service': 'document',
        'error': e.toString(),
      }),
    );
  }
}
