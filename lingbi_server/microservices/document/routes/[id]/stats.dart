import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/database_service.dart';
import 'package:document/main.dart';

/// Handles GET /:id/stats - Returns document statistics.
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
    final id = context.params['id']!;

    // Check document exists
    if (databaseService.getById(id) == null) {
      return Response(
        statusCode: 404,
        body: jsonEncode({'error': 'Document not found'}),
      );
    }

    final stats = databaseService.getStats(id);

    return Response(
      body: jsonEncode(stats.toJson()),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
