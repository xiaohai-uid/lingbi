/// EmbeddingService — 调用 AI Provider 生成文本向量
///
/// HTTP POST http://localhost:8081/api/v1/ai/embed
/// 返回 1536 维向量 (text-embedding-3-small)
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'interfaces/i_embedding_service.dart';

class EmbeddingService implements IEmbeddingService {
  EmbeddingService({
    this.baseUrl = 'http://localhost:8081',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<double>> embed(String text) async {
    final uri = Uri.parse('$baseUrl/api/v1/ai/embed');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode != 200) {
      throw StateError('Embedding failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final embedding = body['embedding'] as List<dynamic>;
    return embedding.cast<double>();
  }

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    final results = <List<double>>[];
    for (final text in texts) {
      results.add(await embed(text));
    }
    return results;
  }
}
