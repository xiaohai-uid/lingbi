/// 测试: MemoryStorageClient — Qdrant 向量存储
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lingbi/services/memory_storage_client.dart';
import 'package:lingbi/services/interfaces/i_memory_storage.dart';

void main() {
  group('MemoryStorageClient', () {
    test('upsertVector 发送正确请求', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/storage/upsert');
        expect(request.method, 'POST');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['collection'], 'memory_summaries');
        expect(body['id'], 'test-1');
        expect(body['vector'], [0.1, 0.2, 0.3]);

        return http.Response(jsonEncode({'status': 'ok', 'id': 'test-1'}), 200);
      });

      final client = MemoryStorageClient(client: mockClient);
      await client.upsertVector(
        id: 'test-1',
        vector: [0.1, 0.2, 0.3],
        payload: {'worldId': 'w1'},
      );
      // 不抛异常即成功
    });

    test('searchVectors 返回结果', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'results': [
            {'id': 'r1', 'score': 0.95, 'payload': {'worldId': 'w1', 'summary': 'test'}},
            {'id': 'r2', 'score': 0.85, 'payload': {'worldId': 'w2', 'summary': 'test2'}},
          ],
        }), 200);
      });

      final client = MemoryStorageClient(client: mockClient);
      final results = await client.searchVectors(vector: [0.1, 0.2, 0.3]);

      expect(results.length, 2);
      expect(results[0].id, 'r1');
      expect(results[0].score, 0.95);
      expect(results[0].payload['worldId'], 'w1');
      expect(results[1].id, 'r2');
    });

    test('searchVectors 无结果时返回空列表', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final client = MemoryStorageClient(client: mockClient);
      final results = await client.searchVectors(vector: [0.1, 0.2]);

      expect(results, isEmpty);
    });

    test('deleteVector 发送正确请求', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/storage/delete');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['collection'], 'memory_summaries');
        expect(body['id'], 'test-1');
        return http.Response(jsonEncode({'status': 'deleted', 'id': 'test-1'}), 200);
      });

      final client = MemoryStorageClient(client: mockClient);
      await client.deleteVector('test-1');
    });
  });
}
