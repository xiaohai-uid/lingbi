/// 测试: EmbeddingService — AI Provider 向量生成
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lingbi/services/embedding_service.dart';

void main() {
  group('EmbeddingService', () {
    test('embed 返回向量', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/ai/embed');
        expect(request.method, 'POST');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['text'], 'test text');

        return http.Response(jsonEncode({
          'embedding': [0.1, 0.2, 0.3, -0.4],
          'model': 'text-embedding-3-small',
          'dimensions': 4,
        }), 200);
      });

      final service = EmbeddingService(client: mockClient);
      final result = await service.embed('test text');

      expect(result, [0.1, 0.2, 0.3, -0.4]);
    });

    test('embed 失败时抛异常', () async {
      final mockClient = MockClient((request) async {
        return http.Response('error', 500);
      });

      final service = EmbeddingService(client: mockClient);
      expect(() => service.embed('test'), throwsA(isA<StateError>()));
    });

    test('embedBatch 返回多个向量', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode({
          'embedding': [0.1 * callCount, 0.2 * callCount],
        }), 200);
      });

      final service = EmbeddingService(client: mockClient);
      final results = await service.embedBatch(['hello', 'world']);

      expect(results.length, 2);
      expect(callCount, 2);
    });
  });
}
