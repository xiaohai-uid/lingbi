/// Provider Registry — 供应商管理核心模块
///
/// 管理用户自定义的 AI 供应商配置，包括模型发现和参数保存。
library provider_registry;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 模型默认参数
class DefaultParams {
  const DefaultParams({
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.topP = 1.0,
  });

  factory DefaultParams.fromJson(Map<String, dynamic> json) => DefaultParams(
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        maxTokens: json['maxTokens'] as int? ?? 2048,
        topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      );
  final double temperature;
  final int maxTokens;
  final double topP;

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'maxTokens': maxTokens,
        'topP': topP,
      };
}

/// 模型信息
class ModelInfo {
  const ModelInfo({required this.id, this.ownedBy = 'unknown'});

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String? ?? '',
        ownedBy: json['owned_by'] as String? ??
            json['ownedBy'] as String? ??
            'unknown',
      );
  final String id;
  final String ownedBy;

  Map<String, dynamic> toJson() => {
        'id': id,
        'owned_by': ownedBy,
      };
}

/// 供应商配置
class ProviderConfig {
  ProviderConfig({
    String? id,
    required this.name,
    required this.baseUrl,
    this.apiKey = '',
    this.selectedModel,
    this.models = const [],
    this.defaultParams = const DefaultParams(),
  }) : id = id ?? _uuid.v4();

  factory ProviderConfig.fromJson(Map<String, dynamic> json) => ProviderConfig(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        selectedModel: json['selectedModel'] as String?,
        models: (json['models'] as List?)
                ?.map((m) => ModelInfo.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        defaultParams: json['defaultParams'] != null
            ? DefaultParams.fromJson(
                json['defaultParams'] as Map<String, dynamic>)
            : const DefaultParams(),
      );
  final String id;
  String name;
  String baseUrl;
  String apiKey;
  String? selectedModel;
  List<ModelInfo> models;
  DefaultParams defaultParams;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        if (selectedModel != null) 'selectedModel': selectedModel,
        'models': models.map((m) => m.toJson()).toList(),
        'defaultParams': defaultParams.toJson(),
      };
}

/// 供应商注册表
class ProviderRegistry {
  ProviderRegistry();

  factory ProviderRegistry.fromJson(Map<String, dynamic> json) {
    final registry = ProviderRegistry();
    if (json['providers'] is List) {
      for (final p in json['providers'] as List) {
        registry.add(ProviderConfig.fromJson(p as Map<String, dynamic>));
      }
    }
    return registry;
  }

  final List<ProviderConfig> _providers = [];

  List<ProviderConfig> getAll() => List.unmodifiable(_providers);

  ProviderConfig? get(String id) {
    try {
      return _providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProviderConfig? getActiveProvider() =>
      _providers.isEmpty ? null : _providers.first;

  void add(ProviderConfig config) => _providers.add(config);

  void remove(String id) => _providers.removeWhere((p) => p.id == id);

  /// 将指定供应商设为活动（移到列表首位）
  void setActiveProvider(String id) {
    final idx = _providers.indexWhere((p) => p.id == id);
    if (idx > 0) {
      final provider = _providers.removeAt(idx);
      _providers.insert(0, provider);
    }
  }

  void update(String id,
      {String? name,
      String? baseUrl,
      String? apiKey,
      String? selectedModel,
      DefaultParams? defaultParams}) {
    final idx = _providers.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final p = _providers[idx];
    if (name != null) p.name = name;
    if (baseUrl != null) p.baseUrl = baseUrl;
    if (apiKey != null) p.apiKey = apiKey;
    if (selectedModel != null) p.selectedModel = selectedModel;
    if (defaultParams != null) p.defaultParams = defaultParams;
  }

  /// 调用供应商 API 的 /v1/models 接口发现可用模型
  static Future<List<ModelInfo>> getModels(
    String baseUrl, {
    String apiKey = '',
    http.Client? client,
  }) async {
    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/models';
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $apiKey';

    try {
      final c = client ?? http.Client();
      final response = await c.get(Uri.parse(url), headers: headers);
      if (client == null) c.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        items = decoded['data'] as List;
      } else {
        throw Exception('Unexpected response format from /v1/models');
      }

      return items.map((m) {
        if (m is Map) {
          return ModelInfo(
            id: m['id'] as String? ?? '',
            ownedBy: m['owned_by'] as String? ?? m['ownedBy'] as String? ?? 'unknown',
          );
        }
        return ModelInfo(id: m.toString());
      }).toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to discover models: $e');
    }
  }

  Map<String, dynamic> toJson() => {
        'providers': _providers.map((p) => p.toJson()).toList(),
      };
}
