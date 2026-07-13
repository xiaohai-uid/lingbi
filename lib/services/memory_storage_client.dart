/// MemoryStorageClient — 调用 Storage Service 操作 Qdrant 向量
///
/// HTTP POST http://localhost:8100/api/v1/storage/{upsert|search|delete}
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'interfaces/i_memory_storage.dart';

class MemoryStorageClient implements IMemoryStorage {
  MemoryStorageClient({
    this.baseUrl = 'http://localhost:8100',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<void> upsertVector({
    required String id,
    required List<double> vector,
    required Map<String, dynamic> payload,
    String collection = 'memory_summaries',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/storage/upsert');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': collection,
        'id': id,
        'vector': vector,
        'payload': payload,
      }),
    );

    if (response.statusCode != 200) {
      throw StateError('Upsert failed: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<List<StorageSearchResult>> searchVectors({
    required List<double> vector,
    int limit = 10,
    String collection = 'memory_summaries',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/storage/search');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': collection,
        'vector': vector,
        'limit': limit,
      }),
    );

    if (response.statusCode != 200) {
      throw StateError('Search failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>?) ?? [];
    return results.map((r) => StorageSearchResult(
      id: r['id'] as String,
      score: (r['score'] as num).toDouble(),
      payload: (r['payload'] as Map<String, dynamic>?) ?? {},
    )).toList();
  }

  @override
  Future<void> deleteVector(String id, {String collection = 'memory_summaries'}) async {
    final uri = Uri.parse('$baseUrl/api/v1/storage/delete');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': collection,
        'id': id,
      }),
    );

    if (response.statusCode != 200) {
      throw StateError('Delete failed: ${response.statusCode} ${response.body}');
    }
  }
}
