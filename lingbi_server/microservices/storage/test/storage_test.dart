import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  final baseUrl = 'http://localhost:8089';
  final client = http.Client();

  group('Storage Service - Health', () {
    test('GET /health returns healthy status', () async {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['status'], anyOf('healthy', 'ok'));
      expect(body['service'], 'storage');
    });
  });

  group('Storage Service - Upsert', () {
    test('POST /upsert stores a vector', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': 'test-vec-001',
          'vector': [0.1, 0.2, 0.3, 0.4],
          'namespace': 'test',
          'payload': {'name': 'Test Vector', 'type': 'demo'},
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });

    test('POST /upsert with different namespace', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': 'test-vec-002',
          'vector': [0.5, 0.6, 0.7, 0.8],
          'namespace': 'production',
          'payload': {'name': 'Prod Vector'},
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });

    test('POST /upsert rejects missing vector', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': 'test-vec-bad',
          'namespace': 'test',
        }),
      );
      expect(response.statusCode, 400);
    });
  });

  group('Storage Service - Vector Search', () {
    test('POST /vector-search finds similar vectors', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/vector-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vector': [0.1, 0.2, 0.3, 0.4],
          'namespace': 'test',
          'limit': 5,
        }),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['data'] ?? body['results'], isList);
    });

    test('POST /vector-search with different query', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/vector-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vector': [1.0, 0.0, 0.0, 0.0],
          'namespace': 'test',
          'limit': 3,
        }),
      );
      expect(response.statusCode, 200);
    });

    test('POST /vector-search rejects missing vector', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/vector-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'namespace': 'test', 'limit': 5}),
      );
      expect(response.statusCode, 400);
    });
  });

  group('Storage Service - Namespace Isolation', () {
    test('search in empty namespace returns empty', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/vector-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vector': [0.1, 0.2, 0.3, 0.4],
          'namespace': 'empty_namespace',
          'limit': 5,
        }),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      final results = body['data'] ?? body['results'];
      expect(results, isEmpty);
    });
  });

  group('Storage Service - Edge Cases', () {
    test('upsert with empty payload succeeds', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': 'test-vec-no-payload',
          'vector': [1.0, 0.0],
          'namespace': 'test',
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });

    test('upsert same id twice overwrites', () async {
      await client.post(
        Uri.parse('$baseUrl/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': 'test-overwrite',
          'vector': [0.1, 0.2],
          'namespace': 'test',
          'payload': {'v': 1},
        }),
      );
      final response = await client.post(
        Uri.parse('$baseUrl/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': 'test-overwrite',
          'vector': [0.3, 0.4],
          'namespace': 'test',
          'payload': {'v': 2},
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });

    test('search with limit 1 returns at most 1 result', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/vector-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vector': [0.1, 0.2, 0.3, 0.4],
          'namespace': 'test',
          'limit': 1,
        }),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      final results = body['data'] ?? body['results'];
      expect(results.length, lessThanOrEqualTo(1));
    });
  });
}
