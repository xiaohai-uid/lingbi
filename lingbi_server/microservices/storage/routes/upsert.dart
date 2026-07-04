import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:storage/lib/vector_store.dart';

RequestHandler upsert(Request request) async {
  try {
    final body = await request.json();
    final id = body['id'];
    final vector = body['vector'];
    final namespace = body['namespace'] ?? 'default';
    final payload = body['payload'];

    if (id == null || vector == null) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'id and vector are required'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // Validate vector is a list of numbers
    if (!(vector is List) || vector.any((v) => v is! num)) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'vector must be a list of numbers'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final vectorList = vector.cast<double>();

    await vectorStore.upsert(id, vectorList, 
        namespace: namespace as String, payload: payload);

    return Response(
      body: jsonEncode({'success': true, 'id': id}),
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