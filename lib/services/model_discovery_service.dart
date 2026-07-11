/// ModelDiscoveryService — 免费模型发现客户端
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final String type;
  final bool isFree;
  final String description;
  final String endpoint;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    this.type = 'chat',
    this.isFree = true,
    this.description = '',
    this.endpoint = '',
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    provider: json['provider'] as String? ?? '',
    type: json['type'] as String? ?? 'chat',
    isFree: json['is_free'] as bool? ?? true,
    description: json['description'] as String? ?? '',
    endpoint: json['endpoint'] as String? ?? '',
  );
}

class TestResult {
  final String modelId;
  final bool success;
  final int latencyMs;
  final String? error;

  const TestResult({
    required this.modelId,
    required this.success,
    this.latencyMs = 0,
    this.error,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
    modelId: json['model_id'] as String? ?? '',
    success: json['success'] as bool? ?? false,
    latencyMs: json['latency_ms'] as int? ?? 0,
    error: json['error'] as String?,
  );
}

class ModelDiscoveryService {
  ModelDiscoveryService({this.baseUrl = 'http://localhost:8099'});

  final String baseUrl;
  final http.Client _client = http.Client();

  /// 获取免费模型列表
  Future<List<ModelInfo>> listFreeModels() async {
    final resp = await _client.get(Uri.parse('$baseUrl/api/v1/models/free'));
    if (resp.statusCode != 200) throw StateError('Failed to list models');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['models'] as List).map((m) => ModelInfo.fromJson(m)).toList();
  }

  /// 测试模型连接
  Future<TestResult> testConnection({
    required String endpoint,
    required String model,
    String? apiKey,
  }) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/v1/models/test'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'endpoint': endpoint,
        'model': model,
        'api_key': apiKey ?? '',
      }),
    );
    if (resp.statusCode != 200) throw StateError('Test failed');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return TestResult.fromJson(body['test_result']);
  }

  /// 推荐模型
  Future<List<ModelInfo>> recommend({
    String need = 'writing',
    bool needApiKey = false,
  }) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/v1/models/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'need': need, 'need_api_key': needApiKey}),
    );
    if (resp.statusCode != 200) throw StateError('Recommendation failed');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['recommendations'] as List)
        .map((m) => ModelInfo.fromJson(m))
        .toList();
  }
}
