/// 模型注册表 — 管理已知模型的元数据
///
/// 模型选择支持：
/// 1. 供应商内置模型
/// 2. 可选调用 `/v1/models`
/// 3. 用户手工输入 modelId
///
/// 不得假设所有兼容端点都支持 `/v1/models`。
/// 不得从模型列表猜测价格和上下文窗口。
library;

/// 元数据来源
enum MetadataSource {
  /// 内置已知模型（有完整元数据）
  builtin,

  /// 从 /v1/models API 获取（仅有 ID，无价格/窗口信息）
  remote,

  /// 用户手工输入（仅有 ID）
  manual,
}

/// 模型能力标记
class ModelCapabilities {
  const ModelCapabilities({
    this.supportsStreaming = true,
    this.supportsJson = false,
    this.supportsReasoning = false,
    this.supportsVision = false,
    this.supportsTools = false,
  });

  final bool supportsStreaming;
  final bool supportsJson;
  final bool supportsReasoning;
  final bool supportsVision;
  final bool supportsTools;

  static const defaultCapabilities = ModelCapabilities();
}

/// 模型价格信息（每百万 token，单位：人民币元）
class ModelPricing {
  const ModelPricing({
    this.inputPerMillion = 0,
    this.outputPerMillion = 0,
    this.currency = 'CNY',
  });

  final double inputPerMillion;
  final double outputPerMillion;
  final String currency;

  /// 价格是否已知
  bool get isKnown => inputPerMillion > 0 || outputPerMillion > 0;

  double estimateCost({required int inputTokens, required int outputTokens}) {
    return (inputTokens / 1000000 * inputPerMillion) +
        (outputTokens / 1000000 * outputPerMillion);
  }

  /// 格式化费用显示
  String formatCost({required int inputTokens, required int outputTokens}) {
    if (!isKnown) return '费用未知';
    final cost = estimateCost(
        inputTokens: inputTokens, outputTokens: outputTokens);
    if (cost < 0.01) return '< ¥0.01';
    return '¥${cost.toStringAsFixed(2)}';
  }
}

/// 单个模型的完整元数据
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.providerId,
    this.contextWindow,
    this.maxOutputTokens,
    this.capabilities = ModelCapabilities.defaultCapabilities,
    this.pricing = const ModelPricing(),
    this.description = '',
    this.metadataSource = MetadataSource.builtin,
    this.category = '',
    this.recommended = false,
    this.deprecated = false,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String? ?? '',
        displayName: json['display_name'] as String? ?? json['id'] as String? ?? '',
        providerId: json['provider_id'] as String? ?? '',
        contextWindow: json['context_window'] as int?,
        maxOutputTokens: json['max_output_tokens'] as int?,
        metadataSource: MetadataSource.values.firstWhere(
          (s) => s.name == json['metadata_source'],
          orElse: () => MetadataSource.manual,
        ),
        category: json['category'] as String? ?? '',
        recommended: json['recommended'] as bool? ?? false,
      );

  /// 模型 ID（API 调用时使用）
  final String id;

  /// 显示名称
  final String displayName;

  /// 所属供应商 ID
  final String providerId;

  /// 上下文窗口大小（token），null 表示未知
  final int? contextWindow;

  /// 最大输出 token 数，null 表示未知
  final int? maxOutputTokens;

  /// 能力标记
  final ModelCapabilities capabilities;

  /// 价格信息
  final ModelPricing pricing;

  /// 简短描述
  final String description;

  /// 元数据来源
  final MetadataSource metadataSource;

  /// 模型类别（如 '主力'、'轻量'、'推理'）
  final String category;

  /// 是否推荐
  final bool recommended;

  /// 是否已废弃
  final bool deprecated;

  /// 上下文窗口是否已知
  bool get isContextWindowKnown => contextWindow != null;

  /// 格式化上下文窗口显示
  String get contextWindowLabel {
    final w = contextWindow;
    if (w == null) return '未知';
    if (w >= 1000000) return '${w ~/ 1000000}M';
    if (w >= 1000) return '${w ~/ 1000}K';
    return '$w';
  }

  /// 格式化输出上限显示
  String get maxOutputLabel {
    final t = maxOutputTokens;
    if (t == null) return '未知';
    if (t >= 1000) return '${t ~/ 1000}K';
    return '$t';
  }

  /// 元数据来源标签
  String get metadataSourceLabel {
    return switch (metadataSource) {
      MetadataSource.builtin => '内置',
      MetadataSource.remote => 'API获取',
      MetadataSource.manual => '手动配置',
    };
  }

  ModelInfo copyWith({
    String? id,
    String? displayName,
    String? providerId,
    int? contextWindow,
    int? maxOutputTokens,
    ModelCapabilities? capabilities,
    ModelPricing? pricing,
    String? description,
    MetadataSource? metadataSource,
    String? category,
    bool? recommended,
    bool? deprecated,
  }) {
    return ModelInfo(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      providerId: providerId ?? this.providerId,
      contextWindow: contextWindow ?? this.contextWindow,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      capabilities: capabilities ?? this.capabilities,
      pricing: pricing ?? this.pricing,
      description: description ?? this.description,
      metadataSource: metadataSource ?? this.metadataSource,
      category: category ?? this.category,
      recommended: recommended ?? this.recommended,
      deprecated: deprecated ?? this.deprecated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'provider_id': providerId,
        if (contextWindow != null) 'context_window': contextWindow,
        if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
        'metadata_source': metadataSource.name,
        'category': category,
        'recommended': recommended,
      };
}

/// 平台模型配置（供应商级别）
class PlatformModelConfig {
  const PlatformModelConfig({
    required this.id,
    required this.name,
    required this.models,
    required this.baseUrl,
    this.authHeader = 'authorization',
  });

  final String id;
  final String name;
  final List<ModelInfo> models;
  final String baseUrl;
  final String authHeader;

  ModelInfo? get recommendedModel {
    for (final model in models) {
      if (model.recommended) return model;
    }
    return models.isNotEmpty ? models.first : null;
  }

  List<ModelInfo> get availableModels =>
      models.where((m) => !m.deprecated).toList();
}

/// 模型注册表 — 集中管理所有已知模型
class ModelRegistry {
  ModelRegistry._();
  static final ModelRegistry instance = ModelRegistry._();

  /// 内置平台配置
  static const Map<String, PlatformModelConfig> _platforms = {
    'openai': PlatformModelConfig(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      models: [
        ModelInfo(
          id: 'gpt-4o',
          displayName: 'GPT-4o',
          providerId: 'openai',
          contextWindow: 128000,
          maxOutputTokens: 16384,
          capabilities: ModelCapabilities(
              supportsJson: true, supportsVision: true, supportsTools: true),
          pricing: ModelPricing(inputPerMillion: 17.5, outputPerMillion: 70),
          category: '主力',
          recommended: true,
          description: 'OpenAI 旗舰多模态模型',
        ),
        ModelInfo(
          id: 'gpt-4o-mini',
          displayName: 'GPT-4o Mini',
          providerId: 'openai',
          contextWindow: 128000,
          maxOutputTokens: 16384,
          capabilities: ModelCapabilities(
              supportsJson: true, supportsVision: true, supportsTools: true),
          pricing: ModelPricing(inputPerMillion: 1.05, outputPerMillion: 4.2),
          category: '轻量',
          description: 'OpenAI 轻量高性价比模型',
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
          displayName: 'Claude Sonnet 4',
          providerId: 'claude',
          contextWindow: 200000,
          maxOutputTokens: 8192,
          capabilities: ModelCapabilities(
              supportsJson: true, supportsVision: true, supportsTools: true),
          pricing: ModelPricing(inputPerMillion: 21, outputPerMillion: 105),
          category: '主力',
          recommended: true,
          description: 'Anthropic Claude Sonnet 4',
        ),
        ModelInfo(
          id: 'claude-3-5-haiku-20241022',
          displayName: 'Claude 3.5 Haiku',
          providerId: 'claude',
          contextWindow: 200000,
          maxOutputTokens: 8192,
          capabilities: ModelCapabilities(
              supportsJson: true, supportsVision: true, supportsTools: true),
          pricing: ModelPricing(inputPerMillion: 5.6, outputPerMillion: 28),
          category: '轻量',
          description: 'Anthropic 轻量模型',
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
          displayName: 'DeepSeek V3',
          providerId: 'deepseek',
          contextWindow: 65536,
          maxOutputTokens: 8192,
          capabilities: ModelCapabilities(supportsJson: true, supportsTools: true),
          pricing: ModelPricing(inputPerMillion: 1, outputPerMillion: 2),
          category: '主力',
          recommended: true,
          description: 'DeepSeek V3 通用对话模型',
        ),
        ModelInfo(
          id: 'deepseek-reasoner',
          displayName: 'DeepSeek R1',
          providerId: 'deepseek',
          contextWindow: 65536,
          maxOutputTokens: 8192,
          capabilities: ModelCapabilities(
              supportsJson: true, supportsReasoning: true, supportsTools: true),
          pricing: ModelPricing(inputPerMillion: 4, outputPerMillion: 16),
          category: '推理',
          description: 'DeepSeek R1 推理模型',
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
          displayName: 'SenseNova 6.7 Flash Lite',
          providerId: 'sensenova',
          contextWindow: 32768,
          maxOutputTokens: 4096,
          pricing: ModelPricing(inputPerMillion: 0.5, outputPerMillion: 1.5),
          category: '轻量',
          recommended: true,
          description: '商汤轻量模型',
        ),
        ModelInfo(
          id: 'sensenova-6.7-flash',
          displayName: 'SenseNova 6.7 Flash',
          providerId: 'sensenova',
          contextWindow: 32768,
          maxOutputTokens: 4096,
          pricing: ModelPricing(inputPerMillion: 2, outputPerMillion: 6),
          category: '主力',
          description: '商汤大语言模型，中文能力强',
        ),
      ],
    ),
  };

  /// 用户自定义/远程获取的模型
  final Map<String, List<ModelInfo>> _customModels = {};

  /// 获取所有平台配置
  static Map<String, PlatformModelConfig> get allPlatforms =>
      Map.unmodifiable(_platforms);

  /// 获取所有 Provider ID 列表
  static List<String> get allProviderIds =>
      List.unmodifiable(_platforms.keys);

  /// 获取指定供应商的所有可用模型
  List<ModelInfo> getModelsForProvider(String providerId) {
    final builtin =
        _platforms[providerId]?.availableModels ?? [];
    final custom = _customModels[providerId] ?? [];
    return [...builtin, ...custom];
  }

  /// 根据模型 ID 查找模型信息
  ModelInfo? findModel(String modelId, {String? providerId}) {
    // 先查内置
    for (final platform in _platforms.values) {
      for (final m in platform.models) {
        if (m.id == modelId &&
            (providerId == null || m.providerId == providerId)) {
          return m;
        }
      }
    }
    // 再查自定义
    for (final models in _customModels.values) {
      for (final m in models) {
        if (m.id == modelId) return m;
      }
    }
    return null;
  }

  /// 获取供应商的默认模型
  ModelInfo? getDefaultModel(String providerId) {
    final config = _platforms[providerId];
    return config?.recommendedModel;
  }

  /// 查询模型是否支持 function-calling（工具调用）。
  ///
  /// 内置模型返回其 [ModelCapabilities.supportsTools]；
  /// 非内置（remote/manual）模型能力未知，返回 null，由调用方决定
  /// 是否乐观尝试（OpenAI 兼容端点通常支持）。
  bool? supportsToolsFor(String modelId, {String? providerId}) {
    final info = findModel(modelId, providerId: providerId);
    if (info == null || info.metadataSource != MetadataSource.builtin) {
      return null;
    }
    return info.capabilities.supportsTools;
  }

  /// 获取平台配置
  static PlatformModelConfig? getConfig(String providerId) =>
      _platforms[providerId];

  /// 注册从 /v1/models 获取的模型列表
  ///
  /// 不猜测价格和上下文窗口，标记为 remote 来源。
  void registerRemoteModels(String providerId, List<String> modelIds) {
    final existing =
        getModelsForProvider(providerId).map((m) => m.id).toSet();
    final newModels = modelIds
        .where((id) => !existing.contains(id))
        .map((id) => ModelInfo(
              id: id,
              displayName: id,
              providerId: providerId,
              // 不从模型列表猜测价格和上下文窗口
              metadataSource: MetadataSource.remote,
              description: '从 API 获取的模型',
            ))
        .toList();
    if (newModels.isNotEmpty) {
      _customModels[providerId] = [
        ...(_customModels[providerId] ?? []),
        ...newModels,
      ];
    }
  }

  /// 替换指定供应商的 remote 模型列表
  ///
  /// 新 remote 结果替换同一 Provider 旧 remote。
  /// 不覆盖 builtin / 不覆盖 manual。
  void replaceRemoteModels(String providerId, List<String> modelIds) {
    final current = _customModels[providerId] ?? [];
    // 保留 manual 模型
    final manualModels =
        current.where((m) => m.metadataSource == MetadataSource.manual).toList();
    // 用新列表替换所有 remote 模型
    final builtinIds =
        _platforms[providerId]?.models.map((m) => m.id).toSet() ?? {};
    final newRemoteModels = modelIds
        .where((id) => !builtinIds.contains(id))
        .map((id) => ModelInfo(
              id: id,
              displayName: id,
              providerId: providerId,
              metadataSource: MetadataSource.remote,
              description: '从 API 获取的模型',
            ))
        .toList();
    _customModels[providerId] = [...manualModels, ...newRemoteModels];
  }

  /// 添加用户手动配置的模型
  void addCustomModel(ModelInfo model) {
    final withSource = model.copyWith(metadataSource: MetadataSource.manual);
    _customModels[model.providerId] = [
      ...(_customModels[model.providerId] ?? []),
      withSource,
    ];
  }

  /// 估算 token 数（中文约 1.5 字/token，英文约 4 字符/token）
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    var chineseChars = 0;
    var otherChars = 0;
    for (final rune in text.runes) {
      if (rune >= 0x4E00 && rune <= 0x9FFF) {
        chineseChars++;
      } else {
        otherChars++;
      }
    }
    return (chineseChars / 1.5).ceil() + (otherChars / 4).ceil();
  }
}
