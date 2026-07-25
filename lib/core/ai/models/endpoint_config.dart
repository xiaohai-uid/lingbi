/// AI 通信协议枚举
///
/// 定义支持的 API 协议格式。
enum Protocol {
  /// OpenAI 兼容协议（/v1/chat/completions）
  openai,

  /// Anthropic 协议（/v1/messages）
  anthropic,
}

/// 端点配置 — 供应商统一抽象
///
/// 所有 AI 提供商（内置或自定义）均使用此模型描述。
/// 官方预置与用户自定义走相同路径，无内置/自定义区分。
class EndpointConfig {
  /// 创建端点配置
  const EndpointConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKey,
    required this.protocol,
    required this.modelId,
    this.authStrategy,
    this.isReasoningModel = false,
  });

  /// 从 JSON 反序列化
  factory EndpointConfig.fromJson(Map<String, dynamic> json) {
    return EndpointConfig(
      id: json['id'] as String? ?? (json['name'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String?,
      protocol: Protocol.values.firstWhere(
        (p) => p.name == json['protocol'],
        orElse: () => Protocol.openai,
      ),
      modelId: json['modelId'] as String? ?? '',
      authStrategy: json['authStrategy'] as String?,
      isReasoningModel: json['isReasoningModel'] as bool? ?? false,
    );
  }

  /// 唯一标识
  final String id;

  /// 显示名称
  final String name;

  /// API 基础 URL（不含路径后缀）
  final String baseUrl;

  /// API Key（可选，环境变量优先级更高）
  final String? apiKey;

  /// 通信协议
  final Protocol protocol;

  /// 默认模型 ID
  final String modelId;

  /// 认证策略（如 'bearer'、'x-api-key' 等），null 表示使用协议默认
  final String? authStrategy;

  /// 是否为思考模型（推理模型）
  final bool isReasoningModel;

  /// 获取完整的聊天完成 URL
  String get chatEndpoint {
    return switch (protocol) {
      Protocol.openai => '${baseUrl.replaceAll('/v1', '')}/v1/chat/completions',
      Protocol.anthropic => '${baseUrl.replaceAll('/v1', '')}/v1/messages',
    };
  }

  /// 获取模型列表 URL
  String get modelsEndpoint {
    if (protocol == Protocol.anthropic) return '';
    return '${baseUrl.replaceAll('/v1', '')}/v1/models';
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        if (apiKey != null) 'apiKey': apiKey,
        'protocol': protocol.name,
        'modelId': modelId,
        if (authStrategy != null) 'authStrategy': authStrategy,
        'isReasoningModel': isReasoningModel,
      };

  /// 创建副本（可选字段覆盖）
  EndpointConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    Protocol? protocol,
    String? modelId,
    String? authStrategy,
    bool? isReasoningModel,
  }) {
    return EndpointConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      protocol: protocol ?? this.protocol,
      modelId: modelId ?? this.modelId,
      authStrategy: authStrategy ?? this.authStrategy,
      isReasoningModel: isReasoningModel ?? this.isReasoningModel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndpointConfig &&
          id == other.id &&
          name == other.name &&
          baseUrl == other.baseUrl &&
          // apiKey excluded from == (credential, not identity)
      // apiKey == other.apiKey &&
          protocol == other.protocol &&
          modelId == other.modelId &&
          authStrategy == other.authStrategy &&
          isReasoningModel == other.isReasoningModel;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        baseUrl,
        protocol,
        modelId,
        authStrategy,
        isReasoningModel,
      );

  @override
  String toString() =>
      'EndpointConfig(id: $id, name: $name, protocol: ${protocol.name}, modelId: $modelId)';
}
