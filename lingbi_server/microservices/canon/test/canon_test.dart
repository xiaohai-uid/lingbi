import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  final baseUrl = 'http://localhost:8084';
  final client = http.Client();

  group('Canon Service - Health', () {
    test('GET /health returns healthy status', () async {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['status'], 'healthy');
      expect(body['service'], 'canon');
    });
  });

  group('Canon Service - CRUD', () {
    String? createdId;

    test('POST / creates a character entry', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'character',
          'name': 'Test Character',
          'description': 'A test character',
          'tags': ['hero', 'main'],
        }),
      );
      expect(response.statusCode, 201);
      final body = jsonDecode(response.body);
      expect(body['data']['name'], 'Test Character');
      expect(body['data']['type'], 'character');
      createdId = body['data']['id'];
    });

    test('POST / creates a location entry', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'location',
          'name': 'Test City',
          'description': 'A fictional city',
        }),
      );
      expect(response.statusCode, 201);
      final body = jsonDecode(response.body);
      expect(body['data']['type'], 'location');
    });

    test('POST / rejects invalid entry type', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'invalid_type',
          'name': 'Bad Entry',
        }),
      );
      expect(response.statusCode, 400);
    });

    test('POST / rejects missing required fields', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': 'missing type and name'}),
      );
      expect(response.statusCode, 400);
    });

    test('GET / lists all entries', () async {
      final response = await client.get(Uri.parse('$baseUrl/'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['data'], isList);
      expect(body['count'], greaterThanOrEqualTo(0));
    });

    test('GET /?type=character filters by type', () async {
      final response = await client.get(Uri.parse('$baseUrl/?type=character'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['data'], isList);
      for (final entry in body['data']) {
        expect(entry['type'], 'character');
      }
    });

    test('GET /:id returns specific entry', () async {
      if (createdId == null) return;
      final response = await client.get(Uri.parse('$baseUrl/$createdId'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['data']['id'], createdId);
    });

    test('GET /:id returns 404 for nonexistent', () async {
      final response = await client.get(Uri.parse('$baseUrl/nonexistent-id'));
      expect(response.statusCode, 404);
    });

    test('POST /search searches entries', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': 'Test',
          'limit': 5,
        }),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['data'], isList);
    });

    test('POST /search rejects missing query', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'limit': 5}),
      );
      expect(response.statusCode, 400);
    });

    test('DELETE /:id deletes entry', () async {
      if (createdId == null) return;
      final response = await client.delete(Uri.parse('$baseUrl/$createdId'));
      expect(response.statusCode, anyOf(200, 204));
    });
  });

  group('Canon Service - Boundary', () {
    test('handles empty name gracefully', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': 'character', 'name': ''}),
      );
      // Should either accept or reject, but not crash
      expect(response.statusCode, anyOf(201, 400));
    });

    test('handles very long description', () async {
      final longDesc = 'A' * 10000;
      final response = await client.post(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'lore',
          'name': 'Long Description Test',
          'description': longDesc,
        }),
      );
      expect(response.statusCode, anyOf(201, 400));
    });
  });
}
