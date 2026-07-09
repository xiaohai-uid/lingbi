import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:codex/lib/codex_store.dart';
import 'package:codex/main.dart';

/// Handles GET /search - Search codex entries by text
Response search(RequestContext context) async {
  try {
    final body = await context.request.jsonDecode();
    final query = body['query'] as String?;

    if (query == null || query.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Query parameter is required'}),
      );
    }

    final type = body['type'] as String?;
    final limit = (body['limit'] as int?) ?? 10;

    // Get all entries and filter by query text
    final allEntries = await codexStore.list(type: type);
    final results = <Map<String, dynamic>>[];

    for (final entry in allEntries) {
      final name = (entry['name'] as String?).toLowerCase() ?? '';
      final description = (entry['description'] as String?).toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      if (name.contains(searchQuery) || description.contains(searchQuery)) {
        results.add(entry);
      }
    }

    return Response(
      body: jsonEncode({
        'results': results.take(limit).toList(),
        'count': results.length,
        'query': query,
      }),
    );
  } on Exception catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.message}),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Unexpected error: $e'}),
    );
  }
}
