import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Microservices Integration Tests', () {
    late HttpClient httpClient;
    final String gatewayHost = 'localhost';
    final int gatewayPort = 8080;

    setUp(() {
      httpClient = HttpClient();
      httpClient.connectionTimeout = Duration(seconds: 5);
    });

    tearDown(() {
      httpClient.close();
    });

    test('API Gateway health check', () async {
      final request = await httpClient
          .getUrl(Uri.parse('http://$gatewayHost:$gatewayPort/health'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body);
      expect(result['status'], 'healthy');
    });

    test('API Gateway routes to AI Provider', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/ai/models'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final models = jsonDecode(body) as List;
      expect(models.isNotEmpty, true,
          reason: 'AI Provider should return at least one model');
    });

    test('AI Provider chat streaming endpoint', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/ai/chat'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': 'Hello, world!'}
        ],
        'temperature': 0.7,
        'max_tokens': 100,
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      // Stream should be readable
      await response.transform(utf8.decoder).join();
    });

    test('AI Provider style analysis endpoint', () async {
      final request = await httpClient.postUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/ai/style/analyze'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'text': 'This is a sample text for style analysis.',
        'model': 'gpt-3.5-turbo',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('AI Provider novel analysis endpoint', () async {
      final request = await httpClient.postUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/ai/novel/analyze'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'text': 'The knight drew his sword...',
        'model': 'gpt-3.5-turbo',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('AI Provider continue writing endpoint', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/ai/continue'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'text': 'It was a dark and stormy night...',
        'model': 'gpt-3.5-turbo',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('AI Provider embedding endpoint', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/ai/embedding'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({'text': 'Test text for embedding'});
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      final responseBody = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseBody);
      expect(result['embedding'], isNotNull);
    });

    test('Project Service - create project', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/project/'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'id': 'test-project-001',
        'name': 'Test Project',
        'description': 'A test project for integration',
        'directoryPath': '/test/path',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 201);
      final responseBody = await response.transform(utf8.decoder).join();
      final project = jsonDecode(responseBody);
      expect(project['name'], 'Test Project');
    });

    test('Project Service - list projects', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/project/list'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final projects = jsonDecode(body) as List;
      expect(projects, isList);
    });

    test('Document Service - create document', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/document/'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'id': 'test-doc-001',
        'projectId': 'test-project-001',
        'title': 'Test Document',
        'content': '# Hello World',
        'wordCount': 2,
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 201);
      final responseBody = await response.transform(utf8.decoder).join();
      final doc = jsonDecode(responseBody);
      expect(doc['title'], 'Test Document');
    });

    test('Document Service - list documents', () async {
      final request = await httpClient.getUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/document/list?projectId=test-project-001'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final docs = jsonDecode(body) as List;
      expect(docs, isList);
    });

    test('Settings Service - get settings', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/settings/'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final settings = jsonDecode(body);
      expect(settings, isA<Map>());
    });

    test('Settings Service - update settings', () async {
      final request = await httpClient.putUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/settings/'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'theme': 'dark',
        'language': 'en',
        'model': 'gpt-3.5-turbo',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('Quota Service - check status', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/quota/status'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final status = jsonDecode(body);
      expect(status['remaining'], isA<int>());
    });

    test('Quota Service - consume token', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/quota/consume'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({'userId': 'test-user'});
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      final responseBody = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseBody);
      expect(result['success'], true);
    });

    test('Quota Service - reset quota', () async {
      final request = await httpClient.putUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/quota/reset'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({'userId': 'test-user'});
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('Storage Service - health check', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/storage/health'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body);
      expect(result['status'], 'healthy');
    });

    test('Storage Service - upsert vector', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/storage/upsert'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'id': 'test-vector-001',
        'vector': [0.1, 0.2, 0.3, 0.4, 0.5],
        'payload': {'text': 'test vector'},
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('Storage Service - vector search', () async {
      final request = await httpClient.postUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/storage/vector-search'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'query': [0.1, 0.2, 0.3, 0.4, 0.5],
        'limit': 5,
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      final responseBody = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseBody);
      expect(result['results'], isList);
    });

    test('Export Service - get supported formats', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/export/formats'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final formats = jsonDecode(body) as List;
      expect(formats, contains('markdown'));
      expect(formats, contains('pdf'));
    });

    test('Export Service - export to markdown', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/export/'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'content': '# Hello World\n\nThis is a test document.',
        'format': 'markdown',
        'title': 'Test Document',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      final responseBody = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseBody);
      expect(result['success'], true);
      expect(result['format'], 'markdown');
    });

    test('Export Service - export to txt', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/export/'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'content': '# Hello World\n\nThis is a test document.',
        'format': 'txt',
        'title': 'Test Document',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      final responseBody = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseBody);
      expect(result['success'], true);
      expect(result['format'], 'txt');
    });

    test('Version History Service - get history', () async {
      final request = await httpClient.getUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/version/history/test-doc-001'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final history = jsonDecode(body) as List;
      expect(history, isList);
    });

    test('Version History Service - create snapshot', () async {
      final request = await httpClient.postUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/version/snapshot/test-doc-001'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'content': '# Updated Content',
        'author': 'test-user',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 201);
    });

    test('Version History Service - get diff', () async {
      final request = await httpClient.getUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/version/diff/test-doc-001/1/2'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final diff = jsonDecode(body);
      expect(diff['changes'], isList);
    });

    test('Sync Service - health check', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/sync/health'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body);
      expect(result['status'], 'healthy');
    });

    test('Sync Service - get status', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/sync/status'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final status = jsonDecode(body);
      expect(status['syncing'], isA<bool>());
    });

    test('Sync Service - sync files', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/sync/sync'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'sourcePath': '/local/path',
        'destPath': '/remote/path',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      final responseBody = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseBody);
      expect(result['success'], true);
    });

    test('Sync Service - update config', () async {
      final request = await httpClient.putUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/sync/config'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'provider': 'webdav',
        'endpoint': 'https://example.com/webdav',
        'username': 'test',
        'password': 'test',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('Canvas Service - health check', () async {
      final request = await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/canvas/health'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body);
      expect(result['status'], 'healthy');
    });

    test('Canvas Service - create canvas', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/canvas/'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'title': 'Test Canvas',
        'projectId': 'test-project-001',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 201);
      final responseBody = await response.transform(utf8.decoder).join();
      final canvas = jsonDecode(responseBody);
      expect(canvas['title'], 'Test Canvas');
    });

    test('Canvas Service - get canvas', () async {
      final request = await httpClient.getUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/canvas/test-canvas-001'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final canvas = jsonDecode(body);
      expect(canvas['nodes'], isList);
      expect(canvas['edges'], isList);
    });

    test('Canvas Service - update canvas with layout', () async {
      final request = await httpClient.putUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/canvas/test-canvas-001'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'nodes': [
          {'id': 'node-1', 'x': 100, 'y': 100, 'type': 'story'},
          {'id': 'node-2', 'x': 200, 'y': 150, 'type': 'character'},
        ],
        'edges': [
          {'from': 'node-1', 'to': 'node-2'},
        ],
        'applyLayout': true,
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
    });

    test('Canvas Service - delete canvas', () async {
      final request = await httpClient.deleteUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/canvas/test-canvas-001'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body);
      expect(result['success'], true);
    });

    test('Canvas Service - get templates', () async {
      final request = await httpClient.getUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/canvas/templates'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final templates = jsonDecode(body) as List;
      expect(templates, isList);
      expect(templates.isNotEmpty, true);
    });

    test('Codex Service - list codex entries', () async {
      final request = await httpClient.getUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/codex/list?projectId=test-project-001&type=character'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final entries = jsonDecode(body) as List;
      expect(entries, isList);
    });

    test('Codex Service - create codex entry', () async {
      final request = await httpClient
          .postUrl(Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/codex/'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'id': 'test-character-001',
        'type': 'character',
        'name': 'Test Character',
        'description': 'A test character for the story.',
        'projectId': 'test-project-001',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 201);
      final responseBody = await response.transform(utf8.decoder).join();
      final entry = jsonDecode(responseBody);
      expect(entry['name'], 'Test Character');
    });

    test('Codex Service - search codex entries', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/codex/search'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'query': 'character',
        'projectId': 'test-project-001',
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 200);
      final responseBody = await response.transform(utf8.decoder).join();
      final results = jsonDecode(responseBody) as List;
      expect(results, isList);
    });

    test('AI Provider - add custom model', () async {
      final request = await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/ai/models'));
      request.headers.contentType = ContentType.json;
      final body = jsonEncode({
        'id': 'custom-ollama',
        'name': 'Custom Ollama Model',
        'type': 'openai_compatible',
        'baseUrl': 'http://localhost:11434/v1',
        'apiKey': '',
        'model': 'qwen2.5:7b',
        'enabled': true,
      });
      await request.add(utf8.encode(body));
      final response = await request.close();
      expect(response.statusCode, 201);
      final responseBody = await response.transform(utf8.decoder).join();
      final model = jsonDecode(responseBody);
      expect(model['name'], 'Custom Ollama Model');
    });

    test('AI Provider - set active model', () async {
      final request = await httpClient.putUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/ai/active/gpt-3.5-turbo'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body);
      expect(result['success'], true);
      expect(result['activeModel'], 'gpt-3.5-turbo');
    });

    test('AI Provider - delete custom model', () async {
      final request = await httpClient.deleteUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/ai/models/custom-ollama'));
      final response = await request.close();
      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      final result = jsonDecode(body);
      expect(result['success'], true);
    });

    // Integration test: Full workflow
    test('Full workflow integration test', () async {
      // 1. Create project
      await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/project/'))
        ..add(jsonEncode({
          'id': 'workflow-project',
          'name': 'Workflow Test',
          'description': 'Full workflow test',
          'directoryPath': '/workflow'
        }));

      // 2. Create document
      await httpClient.postUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/document/'))
        ..add(jsonEncode({
          'id': 'workflow-doc',
          'projectId': 'workflow-project',
          'title': 'Workflow Doc',
          'content': '# Test',
          'wordCount': 1
        }));

      // 3. Create codex entry
      await httpClient
          .postUrl(Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/codex/'))
        ..add(jsonEncode({
          'id': 'workflow-char',
          'type': 'character',
          'name': 'Workflow Character',
          'description': 'Test character',
          'projectId': 'workflow-project'
        }));

      // 4. AI chat
      await httpClient
          .postUrl(Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/ai/chat'))
        ..add(jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': 'Hello'}
          ]
        }));

      // 5. Export
      await httpClient
          .postUrl(Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/export/'))
        ..add(jsonEncode(
            {'content': '# Test', 'format': 'markdown', 'title': 'Test'}));

      // 6. Version snapshot
      await httpClient.postUrl(Uri.parse(
          'http://$gatewayHost:$gatewayPort/api/v1/version/snapshot/workflow-doc'))
        ..add(jsonEncode({'content': '# Updated', 'author': 'test'}));

      // 7. Quota check
      await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/quota/status'));

      // 8. Storage health
      await httpClient.getUrl(
          Uri.parse('http://$gatewayHost:$gatewayPort/api/v1/storage/health'));

      // All steps completed without exception
    });
  });
}
