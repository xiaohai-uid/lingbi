import 'package:lingbi/services/interfaces/i_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/ai_service.dart';

/// 自定义端点配置数据类
class CustomEndpointConfig {

  const CustomEndpointConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
  });

  factory CustomEndpointConfig.fromJson(Map<String, dynamic> json) {
    return CustomEndpointConfig(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
    );
  }
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String modelId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'modelId': modelId,
      };

  CustomEndpointConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? modelId,
  }) {
    return CustomEndpointConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelId: modelId ?? this.modelId,
    );
  }
}

/// 设置服务 - 管理主题、AI 模型选择、API Keys 的持久化
class SettingsService extends ChangeNotifier implements ISettingsService {

  SettingsService({required AIService aiService})
      : _aiService = aiService,
        _secureStorage = const FlutterSecureStorage();
  final AIService _aiService;
  final FlutterSecureStorage _secureStorage;
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedProvider = 'free';
  final Map<String, String> _apiKeys = {};
  bool _initialized = false;
  String? _settingsPath;

  /// 自定义端点列表
  List<CustomEndpointConfig> _customEndpoints = [];

  /// 安全存储是否可用（CI 无 keychain 环境下为 false，回退到明文 JSON）
  bool _secureStorageAvailable = false;

  /// 当前是否使用明文 JSON 存储 API Key（安全存储不可用时的回退）
  bool get isUsingPlaintextFallback => !_secureStorageAvailable;

  /// 安全存储 key 前缀
  static const _secureKeyPrefix = 'api_key_';

  @override
  ThemeMode get themeMode => _themeMode;
  @override
  String get selectedProvider => _selectedProvider;
  @override
  bool get isInitialized => _initialized;

  /// 获取自定义端点列表（只读）
  List<CustomEndpointConfig> get customEndpoints =>
      List.unmodifiable(_customEndpoints);

  @override
  String getApiKey(String provider) => _apiKeys[provider] ?? '';

  /// 初始化 & 加载持久化设置
  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _settingsPath = '${dir.path}/lingbi_data/settings.json';
    await _load();
    _initialized = true;
  }

  /// 设置主题模式
  @override
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _save();
  }

  /// 设置 AI Provider
  @override
  void setProvider(String name) {
    _selectedProvider = name;
    _aiService.setProvider(name);
    notifyListeners();
    _save();
  }

  /// 设置 API Key
  @override
  void setApiKey(String provider, String key) {
    _apiKeys[provider] = key;
    _aiService.configureApiKey(provider, key);
    notifyListeners();
    _save();
  }

  /// 添加自定义端点
  void addCustomEndpoint(CustomEndpointConfig config) {
    _customEndpoints.add(config);
    _aiService.registerCustomProvider(config);
    notifyListeners();
    _save();
  }

  /// 移除自定义端点
  void removeCustomEndpoint(String id) {
    _customEndpoints.removeWhere((e) => e.id == id);
    _aiService.unregisterCustomProvider(id);
    notifyListeners();
    _save();
  }

  /// 更新自定义端点
  void updateCustomEndpoint(CustomEndpointConfig config) {
    final idx = _customEndpoints.indexWhere((e) => e.id == config.id);
    if (idx >= 0) {
      _customEndpoints[idx] = config;
      _aiService.registerCustomProvider(config);
      notifyListeners();
      _save();
    }
  }

  Future<void> _load() async {
    final envMappings = {
      'sensenova': 'SENSENOVA_API_KEY',
      'deepseek': 'DEEPSEEK_API_KEY',
      'openai': 'OPENAI_API_KEY',
      'claude': 'ANTHROPIC_API_KEY',
    };

    // 1. 先从环境变量读取 API Keys（优先级最高）
    final env = Platform.environment;
    for (final entry in envMappings.entries) {
      final envVal = env[entry.value];
      if (envVal != null && envVal.isNotEmpty) {
        _apiKeys[entry.key] = envVal;
      }
    }

    // 2. 尝试从安全存储读取 API Keys（不覆盖已有的环境变量值）
    final Map<String, String> legacyApiKeys = {};
    try {
      for (final provider in envMappings.keys) {
        final value =
            await _secureStorage.read(key: '$_secureKeyPrefix$provider');
        if (value != null && value.isNotEmpty && !_apiKeys.containsKey(provider)) {
          _apiKeys[provider] = value;
        }
      }
      _secureStorageAvailable = true;
    } catch (e) {
      _secureStorageAvailable = false;
      debugPrint('SettingsService: 安全存储不可用，回退到明文 JSON — $e');
    }

    // 3. 从配置文件加载非敏感配置 & 检查旧版明文 apiKeys
    if (_settingsPath != null) {
      final file = File(_settingsPath!);
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          _themeMode = _parseThemeMode(json['themeMode'] as String?);
          _selectedProvider = json['selectedProvider'] as String? ?? 'free';
          if (json['apiKeys'] is Map) {
            (json['apiKeys'] as Map).forEach((k, v) {
              final keyStr = k.toString();
              if (v is String && v.isNotEmpty && !_apiKeys.containsKey(keyStr)) {
                _apiKeys[keyStr] = v;
                legacyApiKeys[keyStr] = v;
              }
            });
          }
          // 加载自定义端点
          if (json['customEndpoints'] is List) {
            _customEndpoints = (json['customEndpoints'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => CustomEndpointConfig.fromJson(e))
                .toList();
          }
        } catch (_) {}
      }
    }

    // 4. 若发现旧版明文 apiKeys 且安全存储可用，迁移到安全存储并从 JSON 删除
    if (legacyApiKeys.isNotEmpty && _secureStorageAvailable) {
      for (final entry in legacyApiKeys.entries) {
        try {
          await _secureStorage.write(
            key: '$_secureKeyPrefix${entry.key}',
            value: entry.value,
          );
        } catch (e) {
          debugPrint('SettingsService: 迁移 API key ${entry.key} 失败 — $e');
        }
      }
      // 重写 settings.json，移除明文 apiKeys
      await _save();
      debugPrint(
          'SettingsService: 已将 ${legacyApiKeys.length} 个明文 API key 迁移到安全存储');
    }

    // 5. 自动切换到环境变量提供的 provider（当当前 provider 无有效 key 时）
    if (_selectedProvider == 'free' || !_apiKeys.containsKey(_selectedProvider)) {
      for (final entry in envMappings.entries) {
        final envVal = env[entry.value];
        if (envVal != null && envVal.isNotEmpty) {
          _selectedProvider = entry.key;
          break;
        }
      }
    }

    // 6. 将 API keys 应用到 AI 服务
    for (final entry in _apiKeys.entries) {
      _aiService.configureApiKey(entry.key, entry.value);
    }
    _aiService.setProvider(_selectedProvider);

    // 7. 将自定义端点注册到 AI 服务
    _customEndpoints.forEach(_aiService.registerCustomProvider);
  }

  Future<void> _save() async {
    if (_settingsPath == null) return;
    try {
      // API Keys 写入安全存储（若可用）；否则保留在 JSON 中作为 fallback
      var includeApiKeysInJson = !_secureStorageAvailable;
      if (_secureStorageAvailable) {
        for (final entry in _apiKeys.entries) {
          try {
            await _secureStorage.write(
              key: '$_secureKeyPrefix${entry.key}',
              value: entry.value,
            );
          } catch (e) {
            debugPrint('SettingsService: 写入安全存储失败 — $e');
            // 写入失败则本次 fallback 到 JSON
            includeApiKeysInJson = true;
          }
        }
      }

      final file = File(_settingsPath!);
      await file.create(recursive: true);
      final data = <String, dynamic>{
        'themeMode': _themeMode.name,
        'selectedProvider': _selectedProvider,
        'customEndpoints': _customEndpoints.map((e) => e.toJson()).toList(),
      };
      if (includeApiKeysInJson) {
        data['apiKeys'] = _apiKeys;
      }
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  ThemeMode _parseThemeMode(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
