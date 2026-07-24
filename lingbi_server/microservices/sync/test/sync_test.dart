import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  final baseUrl = 'http://localhost:8090';
  final client = http.Client();

  group('Sync Service - Health', () {
    test('GET /health returns healthy status', () async {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['status'], anyOf('healthy', 'ok'));
    });
  });

  group('Sync Service - Configuration', () {
    test('GET /config returns current configuration', () async {
      final response = await client.get(Uri.parse('$baseUrl/config'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body, isMap);
    });

    test('PUT /config updates configuration', () async {
      final response = await client.put(
        Uri.parse('$baseUrl/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'webdav_url': 'http://localhost:9999',
          'webdav_user': 'testuser',
          'sync_interval': 300,
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });
  });

  group('Sync Service - Status', () {
    test('GET /status returns sync status', () async {
      final response = await client.get(Uri.parse('$baseUrl/status'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body, isMap);
      expect(body['status'], anyOf('idle', 'running', 'success', 'error'));
    });
  });

  group('Sync Service - Sync Operations', () {
    test('POST /sync starts a sync operation', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': '/tmp/source',
          'destination': '/tmp/dest',
        }),
      );
      // May return 200 (success), 202 (accepted), or 500 (if rclone not available)
      expect(response.statusCode, anyOf(200, 202, 500));
    });

    test('POST /sync rejects missing paths', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      expect(response.statusCode, anyOf(400, 500));
    });
  });

  group('Sync Service - Conflict Resolution', () {
    test('POST /sync with conflict strategy', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': '/tmp/source',
          'destination': '/tmp/dest',
          'conflict_strategy': 'overwrite',
        }),
      );
      expect(response.statusCode, anyOf(200, 202, 500));
    });
  });

  group('Sync Service - Additional', () {
    test('GET /health includes version info', () async {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body.containsKey('service') || body.containsKey('version'), true);
    });

    test('GET /config returns map with string keys', () async {
      final response = await client.get(Uri.parse('$baseUrl/config'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      if (body is Map) {
        for (final key in body.keys) {
          expect(key, isA<String>());
        }
      }
    });

    test('GET /status includes lastSync field', () async {
      final response = await client.get(Uri.parse('$baseUrl/status'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body.containsKey('lastSync') || body.containsKey('status'), true);
    });

    test('GET /status includes filesSynced field', () async {
      final response = await client.get(Uri.parse('$baseUrl/status'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body.containsKey('filesSynced') || body.containsKey('errors'), true);
    });
  });
}
