import 'package:lingbi/services/interfaces/i_settings_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/ai_service.dart';
import 'provider_registry.dart';

/// 设置服务 - 管理主题、AI 模型选择、API Keys 的持久化
class SettingsService extends ChangeNotifier implements ISettingsService {
  SettingsService({required AIService aiService}) : _aiService = aiService;
  final AIService _aiService;
  final ProviderRegistry providerRegistry = ProviderRegistry();
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedProvider = 'free';
  final Map<String, String> _apiKeys = {};
  final Map<String, String> _apiUrls = {};
  bool _initialized = false;
  String? _settingsPath;

  @override
  ThemeMode get themeMode => _themeMode;
  @override
  String get selectedProvider => _selectedProvider;
  @override
  bool get isInitialized => _initialized;

  @override
  String getApiKey(String provider) => _apiKeys[provider] ?? '';
  @override
  String getApiUrl(String provider) => _apiUrls[provider] ?? '';
  @override
  void setApiUrl(String provider, String url) {
    _apiUrls[provider] = url;
    notifyListeners();
    _save();
  }

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

  void addProvider(ProviderConfig config) {
    providerRegistry.add(config);
    notifyListeners();
    _save();
  }

  void removeProvider(String id) {
    providerRegistry.remove(id);
    notifyListeners();
    _save();
  }

  /// 保存 provider 注册表变更（供 selectModel 等操作调用）
  void saveProviderRegistry() {
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

  Future<void> _load() async {
    if (_settingsPath == null) return;
    final file = File(_settingsPath!);
    if (!await file.exists()) return;
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _themeMode = _parseThemeMode(json['themeMode'] as String?);
      _selectedProvider = json['selectedProvider'] as String? ?? 'free';
      if (json['apiKeys'] is Map) {
        (json['apiKeys'] as Map).forEach((k, v) {
          if (v is String && v.isNotEmpty) _apiKeys[k.toString()] = v;
        });
      }
      if (json['apiUrls'] is Map) {
        (json['apiUrls'] as Map).forEach((k, v) {
          if (v is String && v.isNotEmpty) _apiUrls[k.toString()] = v;
        });
      }
      if (json['providers'] is List) {
        final reg = ProviderRegistry.fromJson({'providers': json['providers']});
        reg.getAll().forEach(providerRegistry.add);
      }
      // 将已保存的 API keys 和 URLs 应用到 AI 服务
      for (final entry in _apiKeys.entries) {
        _aiService.configureApiKey(entry.key, entry.value);
      }
      for (final entry in _apiUrls.entries) {
        _aiService.setBaseUrl(entry.key, entry.value);
      }
      _aiService.setProvider(_selectedProvider);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_settingsPath == null) return;
    try {
      final file = File(_settingsPath!);
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({
        'themeMode': _themeMode.name,
        'selectedProvider': _selectedProvider,
        'apiKeys': _apiKeys,
        'apiUrls': _apiUrls,
        'providers': providerRegistry.toJson()['providers'],
      }));
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
