import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:storage/lib/vector_store.dart';

RequestHandler vectorSearch(Request request) async {
  try {
    final body = await request.json();
    final vector = body['vector'];
    final namespace = body['namespace'] ?? 'default';
    final limit = body['limit'] ?? 5;

    if (vector == null) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'vector is required'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Validate vector is a list of doubles
    if (!(vector is List) || vector.any((v) => v is! num)) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'vector must be a list of numbers'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final vectorList = vector.cast<double>();

    final results = await vectorStore.search(vectorList, 
        limit: limit as int, namespace: namespace as String);

    return Response(
      body: jsonEncode({'results': results}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}