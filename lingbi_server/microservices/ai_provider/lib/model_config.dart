import 'dart:convert';
import 'dart:io';

/// Configuration for an AI model provider.
class ModelConfig {
  final String id;
  final String name;
  final String type; // openai_compatible, deepseek, claude, qwen, zhipu, etc.
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool enabled;
  final Map<String, dynamic> config;

  const ModelConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.enabled = true,
    this.config = const {},
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String,
      enabled: json['enabled'] as bool? ?? true,
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'enabled': enabled,
      'config': config,
    };
  }

  /// Returns HTTP headers for API requests, including Authorization if apiKey is set.
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

  /// Creates a copy of this config with updated fields.
  ModelConfig copyWith({
    String? id,
    String? name,
    String? type,
    String? baseUrl,
    String? apiKey,
    String? model,
    bool? enabled,
    Map<String, dynamic>? config,
  }) {
    return ModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      enabled: enabled ?? this.enabled,
      config: config ?? this.config,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Service for managing AI model configurations.
///
/// Supports loading and saving configurations from/to JSON files,
/// and provides CRUD operations for model configurations.
/// All mutations auto-persist to the configured file path.
class ModelConfigService {
  final List<ModelConfig> _models = [];

  /// Path to the persistent configuration file.
  String? _configFilePath;

  /// The currently active model ID.
  String? activeModelId;

  /// Loads model configurations from a JSON file.
  ///
  /// The file should contain a JSON array of model configuration objects.
  /// If the file doesn't exist, this method does nothing.
  /// Returns the number of models loaded.
  Future<int> loadConfigs(String filePath) async {
    _configFilePath = filePath;
    final file = File(filePath);
    if (!await file.exists()) {
      return 0;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);

      if (json is List) {
        _models.clear();
        _models.addAll(
          json.map((m) => ModelConfig.fromJson(m as Map<String, dynamic>)).toList(),
        );
      }
      return _models.length;
    } catch (e) {
      // If the file is malformed, start with empty config
      _models.clear();
      return 0;
    }
  }

  /// Saves current model configurations to the configured file path.
  ///
  /// Creates parent directories if they don't exist.
  /// Throws if no config file path has been set.
  Future<void> saveConfigs() async {
    final filePath = _configFilePath;
    if (filePath == null) {
      throw const LiteLLMConfigException('No config file path configured');
    }
    await saveConfigsTo(filePath);
  }

  /// Saves current model configurations to a specific file path.
  ///
  /// Creates parent directories if they don't exist.
  Future<void> saveConfigsTo(String filePath) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(_models.map((m) => m.toJson()).toList()),
      encoding: utf8,
    );
  }

  /// Gets a model configuration by ID.
  ///
  /// Returns `null` if no model with the given ID exists.
  ModelConfig? getModel(String id) {
    try {
      return _models.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns the first enabled model configuration, or null.
  ModelConfig? get firstEnabledModel => _models.cast<ModelConfig?>().firstWhere(
        (m) => m != null && m.enabled,
        orElse: () => null,
      );

  /// Returns all enabled model configurations.
  List<ModelConfig> listModels() => _models.where((m) => m.enabled).toList();

  /// Returns all model configurations including disabled ones.
  List<ModelConfig> listAllModels() => List.unmodifiable(_models);

  /// Adds a new model configuration.
  ///
  /// If a model with the same ID already exists, it will be replaced.
  /// Auto-persists if a config file path is configured.
  Future<void> addModel(ModelConfig model) async {
    _models.removeWhere((m) => m.id == model.id);
    _models.add(model);
    if (_configFilePath != null) {
      await saveConfigs();
    }
  }

  /// Removes a model configuration by ID.
  ///
  /// Auto-persists if a config file path is configured.
  Future<void> removeModel(String id) async {
    _models.removeWhere((m) => m.id == id);
    if (_configFilePath != null) {
      await saveConfigs();
    }
  }

  /// Updates a model configuration by ID.
  ///
  /// Auto-persists if a config file path is configured.
  Future<void> updateModel(ModelConfig model) async {
    final index = _models.indexWhere((m) => m.id == model.id);
    if (index != -1) {
      _models[index] = model;
      if (_configFilePath != null) {
        await saveConfigs();
      }
    }
  }

  /// Sets the active model by ID.
  ///
  /// Returns the model config if found, or null if not found.
  ModelConfig? setActiveModel(String id) {
    final model = getModel(id);
    if (model != null) {
      activeModelId = id;
    }
    return model;
  }

  /// Returns the number of configured models.
  int get count => _models.length;

  /// Clears all model configurations.
  Future<void> clear() async {
    _models.clear();
    activeModelId = null;
    if (_configFilePath != null) {
      await saveConfigs();
    }
  }
}

/// Exception for model configuration errors.
class LiteLLMConfigException implements Exception {
  final String message;
  const LiteLLMConfigException(this.message);

  @override
  String toString() => 'LiteLLMConfigException: $message';
}