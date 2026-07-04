import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/database_service.dart';
import 'package:document/main.dart';

/// Handles GET /search - Full-text search across documents.
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
    final query = context.request.uri.queryParameters['q'] ?? '';
    final projectId = context.request.uri.queryParameters['project_id'];
    final limitStr = context.request.uri.queryParameters['limit'];
    final limit = limitStr != null ? int.tryParse(limitStr) : null;

    if (query.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Query parameter "q" is required'}),
      );
    }

    final results = databaseService.search(
      query,
      projectId: projectId,
      limit: limit,
    );

    return Response(
      body: jsonEncode({
        'results': results.map((r) => {
          ...r.document.toJson(),
          'rank': r.rank,
        }).toList(),
        'count': results.length,
        'query': query,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}