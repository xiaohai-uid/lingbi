/// 本地模型配置注册表
///
/// 为每个 AI 平台定义可用的模型列表、基础 URL 和认证信息。
/// 使用纯 Dart 代码实现，不依赖外部库。
library;

/// 模型信息
///
/// 描述单个 AI 模型的基本属性。
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.name,
    this.category = '',
    this.recommended = false,
    this.deprecated = false,
  });

  /// JSON 反序列化
  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        recommended: json['recommended'] as bool? ?? false,
        deprecated: json['deprecated'] as bool? ?? false,
      );

  /// 模型唯一标识（如 'gpt-4o'）
  final String id;

  /// 模型显示名称
  final String name;

  /// 模型类别（如 '主力'、'轻量'、'推理'、'代码'）
  final String category;

  /// 是否推荐作为默认选择
  final bool recommended;

  /// 是否已废弃
  final bool deprecated;

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'recommended': recommended,
        'deprecated': deprecated,
      };
}

/// 平台模型配置
///
/// 描述一个 AI 平台的完整配置信息，包含模型列表、API 端点和认证方式。
class PlatformModelConfig {
  const PlatformModelConfig({
    required this.id,
    required this.name,
    required this.models,
    required this.baseUrl,
    this.authHeader = 'authorization',
  });

  /// JSON 反序列化
  factory PlatformModelConfig.fromJson(Map<String, dynamic> json) {
    return PlatformModelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      authHeader: json['authHeader'] as String? ?? 'authorization',
      models: (json['models'] as List<dynamic>)
          .map((m) => ModelInfo.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 平台唯一标识（如 'openai'）
  final String id;

  /// 平台显示名称
  final String name;

  /// 可用模型列表
  final List<ModelInfo> models;

  /// API 基础 URL
  final String baseUrl;

  /// 认证请求头名称（默认为 'authorization'）
  final String authHeader;

  /// 推荐模型（推荐度最高的模型，通常为第一个 recommended 模型）
  ModelInfo? get recommendedModel {
    for (final model in models) {
      if (model.recommended) return model;
    }
    return null;
  }

  /// 可用模型列表（排除已废弃的模型）
  List<ModelInfo> get availableModels {
    return models.where((m) => !m.deprecated).toList();
  }

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'models': models.map((m) => m.toJson()).toList(),
        'baseUrl': baseUrl,
        'authHeader': authHeader,
      };
}

/// 模型注册表
///
/// 静态持有所有 AI 平台的配置信息，提供统一的查询接口。
class ModelRegistry {
  /// 所有平台配置（按 provider id 索引）
  static const Map<String, PlatformModelConfig> _platforms = {
    'openai': PlatformModelConfig(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      models: [
        ModelInfo(
          id: 'gpt-4o',
          name: 'GPT-4o',
          category: '主力',
          recommended: true,
        ),
        ModelInfo(
          id: 'gpt-4o-mini',
          name: 'GPT-4o Mini',
          category: '轻量',
        ),
        ModelInfo(
          id: 'gpt-3.5-turbo',
          name: 'GPT-3.5 Turbo',
          category: '经典',
        ),
        ModelInfo(
          id: 'o1',
          name: 'O1',
          category: '推理',
        ),
        ModelInfo(
          id: 'o1-mini',
          name: 'O1 Mini',
          category: '推理轻量',
        ),
      ],
    ),
    'claude': PlatformModelConfig(
      id: 'claude',
      name: 'Claude',
      baseUrl: 'https://api.anthropic.com',
      authHeader: 'x-api-key',
      models: [
        ModelInfo(
          id: 'claude-sonnet-4-20250514',
          name: 'Claude Sonnet 4',
          category: '主力',
          recommended: true,
        ),
        ModelInfo(
          id: 'claude-3-5-sonnet-20241022',
          name: 'Claude 3.5 Sonnet',
          category: '稳定',
        ),
        ModelInfo(
          id: 'claude-3-5-haiku-20241022',
          name: 'Claude 3.5 Haiku',
          category: '轻量',
        ),
        ModelInfo(
          id: 'claude-3-opus-20240229',
          name: 'Claude 3 Opus',
          category: '旗舰',
        ),
      ],
    ),
    'deepseek': PlatformModelConfig(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      models: [
        ModelInfo(
          id: 'deepseek-chat',
          name: 'DeepSeek Chat',
          category: '主力',
          recommended: true,
        ),
        ModelInfo(
          id: 'deepseek-coder',
          name: 'DeepSeek Coder',
          category: '代码',
        ),
        ModelInfo(
          id: 'deepseek-reasoner',
          name: 'DeepSeek Reasoner',
          category: '推理',
        ),
      ],
    ),
    'sensenova': PlatformModelConfig(
      id: 'sensenova',
      name: 'SenseNova (商汤)',
      baseUrl: 'https://token.sensenova.cn/v1',
      models: [
        ModelInfo(
          id: 'sensenova-6.7-flash-lite',
          name: 'SenseNova 6.7 Flash Lite',
          category: '轻量',
          recommended: true,
        ),
        ModelInfo(
          id: 'sensenova-6.7-flash',
          name: 'SenseNova 6.7 Flash',
          category: '主力',
        ),
      ],
    ),
  };

  /// 获取所有平台配置（只读快照）
  static Map<String, PlatformModelConfig> get allPlatforms =>
      Map.unmodifiable(_platforms);

  /// 获取所有 Provider ID 列表
  static List<String> get allProviderIds => List.unmodifiable(_platforms.keys);

  /// 根据 Provider ID 获取平台配置
  ///
  /// 如果 provider 不存在，抛出 ArgumentError。
  static PlatformModelConfig getConfig(String providerId) {
    final config = _platforms[providerId];
    if (config == null) {
      throw ArgumentError(
        'Unknown provider: $providerId. '
        'Available providers: ${_platforms.keys.join(', ')}',
      );
    }
    return config;
  }
}
