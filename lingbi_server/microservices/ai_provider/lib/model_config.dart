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
class ModelConfigService {
  final List<ModelConfig> _models = [];

  /// Loads model configurations from a JSON file.
  ///
  /// The file should contain a JSON array of model configuration objects.
  /// If the file doesn't exist, this method does nothing.
  Future<void> loadConfigs(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);

      if (json is List) {
        _models.clear();
        _models.addAll(json.map((m) => ModelConfig.fromJson(m as Map<String, dynamic>)).toList());
      }
    } catch (e) {
      // If the file is malformed, start with empty config
      _models.clear();
    }
  }

  /// Saves current model configurations to a JSON file.
  ///
  /// Creates parent directories if they don't exist.
  Future<void> saveConfigs(String filePath) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(_models.map((m) => m.toJson()).toList()),
      encoding: utf8,
    );
  }

  /// Gets a model configuration by ID.
  ///
  /// Returns the first model if no model with the given ID exists.
  ModelConfig? getModel(String id) =>
      _models.firstWhere((m) => m.id == id, orElse: () => _models.first);

  /// Returns all enabled model configurations.
  List<ModelConfig> listModels() => _models.where((m) => m.enabled).toList();

  /// Returns all model configurations including disabled ones.
  List<ModelConfig> listAllModels() => _models;

  /// Adds a new model configuration.
  Future<void> addModel(ModelConfig model) async {
    // Remove existing model with same ID if it exists
    _models.removeWhere((m) => m.id == model.id);
    _models.add(model);
  }

  /// Removes a model configuration by ID.
  Future<void> removeModel(String id) async {
    _models.removeWhere((m) => m.id == id);
  }

  /// Updates a model configuration by ID.
  Future<void> updateModel(ModelConfig model) async {
    final index = _models.indexWhere((m) => m.id == model.id);
    if (index != -1) {
      _models[index] = model;
    }
  }

  /// Returns the number of configured models.
  int get count => _models.length;

  /// Clears all model configurations.
  void clear() => _models.clear();
}
