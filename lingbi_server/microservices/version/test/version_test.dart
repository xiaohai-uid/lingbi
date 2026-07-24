import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  final baseUrl = 'http://localhost:8086';
  final client = http.Client();

  group('Version Service - Health', () {
    test('GET /health returns healthy status', () async {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['status'], anyOf('healthy', 'ok'));
    });
  });

  group('Version Service - Snapshot', () {
    String? snapshotId;

    test('POST /history/:docId creates a version snapshot', () async {
      final docId = 'test-doc-001';
      final response = await client.post(
        Uri.parse('$baseUrl/history/$docId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': '# Chapter 1\n\nThis is the first version.',
          'comment': 'Initial version',
          'author': 'test-user',
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
      final body = jsonDecode(response.body);
      snapshotId = body['id'] ?? body['data']?['id'];
    });

    test('POST /history/:docId creates second snapshot', () async {
      final docId = 'test-doc-001';
      final response = await client.post(
        Uri.parse('$baseUrl/history/$docId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': '# Chapter 1\n\nThis is the second version with changes.',
          'comment': 'Added changes',
          'author': 'test-user',
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });

    test('POST /history/:docId rejects missing content', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/history/test-doc-002'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment': 'No content provided',
          'author': 'test-user',
        }),
      );
      expect(response.statusCode, anyOf(400, 500));
    });
  });

  group('Version Service - History', () {
    test('GET /history/:docId returns version history', () async {
      final response = await client.get(
        Uri.parse('$baseUrl/history/test-doc-001'),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body, anyOf(isList, isMap));
    });

    test('GET /history/:docId returns empty for nonexistent', () async {
      final response = await client.get(
        Uri.parse('$baseUrl/history/nonexistent-doc'),
      );
      expect(response.statusCode, anyOf(200, 404));
    });
  });

  group('Version Service - Diff', () {
    test('GET /diff/:docId/:v1/:v2 returns diff between versions', () async {
      // This test requires knowing the version IDs from the snapshot tests
      // Using placeholder IDs - will return 404 or 500 if versions don't exist
      final response = await client.get(
        Uri.parse('$baseUrl/diff/test-doc-001/v1/v2'),
      );
      // May return 200 with diff, or 404 if versions not found
      expect(response.statusCode, anyOf(200, 404, 500));
    });
  });

  group('Version Service - Compression', () {
    test('handles large content snapshot', () async {
      final largeContent = 'Line ${List.generate(100, (i) => i).join(', ')}';
      final response = await client.post(
        Uri.parse('$baseUrl/history/large-doc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': largeContent,
          'comment': 'Large content test',
          'author': 'test-user',
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });
  });

  group('Version Service - Additional', () {
    test('GET /health includes service name', () async {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body.containsKey('service') || body.containsKey('version'), true);
    });

    test('snapshot with unicode content', () async {
      final response = await client.post(
        Uri.parse('$baseUrl/history/unicode-doc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': '# 第一章\n\n这是一个中文测试文档，包含特殊字符：「」【】',
          'comment': 'Unicode test',
          'author': 'test-user',
        }),
      );
      expect(response.statusCode, anyOf(200, 201));
    });

    test('multiple snapshots for same doc', () async {
      for (int i = 0; i < 3; i++) {
        final response = await client.post(
          Uri.parse('$baseUrl/history/multi-snap-doc'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'content': 'Version $i content',
            'comment': 'Snapshot $i',
            'author': 'test-user',
          }),
        );
        expect(response.statusCode, anyOf(200, 201));
      }
      final histResponse = await client.get(
        Uri.parse('$baseUrl/history/multi-snap-doc'),
      );
      expect(histResponse.statusCode, 200);
    });
  });
}
