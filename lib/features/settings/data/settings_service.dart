import 'package:lingbi/shared/interfaces/i_settings_service.dart';
import 'package:lingbi/features/sync/data/sync/webdav_service.dart';
import 'package:lingbi/features/sync/data/sync/sync_manager.dart';
import 'package:lingbi/features/settings/data/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/shared/ai/models/endpoint_config.dart';

/// 当前引导配置 schema 版本
///
/// 升级此值时：重新展示向导，但保留安全存储中的 API Key、
/// 已有 Provider 和模型配置，不清空用户项目数据。
const int currentOnboardingSchemaVersion = 1;

/// 首次启动引导状态
class OnboardingState {
  const OnboardingState({
    required this.completed,
    required this.schemaVersion,
    this.completedAt,
    this.selectedProviderId,
    this.selectedModelId,
    this.localOnlyMode = false,
    this.lastStep = 0,
    this.wizardStateJson,
  });

  /// 全新安装时的初始状态
  const OnboardingState.initial()
      : completed = false,
        schemaVersion = currentOnboardingSchemaVersion,
        completedAt = null,
        selectedProviderId = null,
        selectedModelId = null,
        localOnlyMode = false,
        lastStep = 0,
        wizardStateJson = null;

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      completed: json['completed'] as bool? ?? false,
      schemaVersion: json['schemaVersion'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      selectedProviderId: json['selectedProviderId'] as String?,
      selectedModelId: json['selectedModelId'] as String?,
      localOnlyMode: json['localOnlyMode'] as bool? ?? false,
      lastStep: json['lastStep'] as int? ?? 0,
      wizardStateJson: json['wizardState'] as Map<String, dynamic>?,
    );
  }

  /// 是否已完成引导
  final bool completed;

  /// 配置 schema 版本
  final int schemaVersion;

  /// 完成时间
  final DateTime? completedAt;

  /// 选择的供应商 ID
  final String? selectedProviderId;

  /// 选择的模型 ID
  final String? selectedModelId;

  /// 是否为本地写作模式
  final bool localOnlyMode;

  /// 上次停留步骤（中途退出恢复）
  final int lastStep;

  /// 引导型向导状态机的序列化快照（用于中断恢复）
  final Map<String, dynamic>? wizardStateJson;

  /// 是否需要展示引导向导
  ///
  /// 条件：未完成 或 schema 版本不匹配
  bool get needsOnboarding =>
      !completed || schemaVersion != currentOnboardingSchemaVersion;

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'schemaVersion': schemaVersion,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (selectedProviderId != null)
          'selectedProviderId': selectedProviderId,
        if (selectedModelId != null) 'selectedModelId': selectedModelId,
        'localOnlyMode': localOnlyMode,
        'lastStep': lastStep,
        if (wizardStateJson != null) 'wizardState': wizardStateJson,
      };

  OnboardingState copyWith({
    bool? completed,
    int? schemaVersion,
    DateTime? completedAt,
    String? selectedProviderId,
    String? selectedModelId,
    bool? localOnlyMode,
    int? lastStep,
    Map<String, dynamic>? wizardStateJson,
  }) {
    return OnboardingState(
      completed: completed ?? this.completed,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      completedAt: completedAt ?? this.completedAt,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      localOnlyMode: localOnlyMode ?? this.localOnlyMode,
      lastStep: lastStep ?? this.lastStep,
      wizardStateJson: wizardStateJson ?? this.wizardStateJson,
    );
  }

  /// 重置引导状态（从设置页重新打开向导）
  ///
  /// 保留 schema 版本为当前值，清除完成标记和步骤。
  OnboardingState reset() {
    return const OnboardingState(
      completed: false,
      schemaVersion: currentOnboardingSchemaVersion,
    );
  }
}

/// 设置服务 - 管理主题、AI 模型选择、API Keys 的持久化
///
/// API Key 安全规则：
/// - 公开构建中禁止把 API Key 回退保存到明文 JSON
/// - 安全存储失败时：提示无法安全保存，允许本次会话临时使用，不得静默持久化
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
  List<EndpointConfig> _endpoints = [];

  /// 安全存储是否可用
  bool _secureStorageAvailable = false;

  /// 会话临时 Key（安全存储不可用时，仅存内存，不持久化）
  final Map<String, String> _sessionOnlyKeys = {};

  /// 安全存储失败提示（UI 层监听此标记显示提示）
  String? secureStorageWarning;

  /// 当前选择的模型 ID（每个 provider 一个）
  final Map<String, String> _selectedModelIds = {};

  /// 首次启动引导状态
  OnboardingState _onboardingState = const OnboardingState.initial();

  /// WebDAV 同步配置
  WebDavConfig _webDavConfig = const WebDavConfig(
    serverUrl: '',
    username: '',
    password: '',
    enabled: false,
  );

  /// 匿名数据贡献配置
  AnalyticsConsent _analyticsConsent = AnalyticsConsent();

  /// 订阅状态（从 LicenseService 恢复，或从 settings.json 快速读取）
  SubscriptionState _subscriptionState = const SubscriptionState();

  /// 获取当前引导状态
  OnboardingState get onboardingState => _onboardingState;

  /// 获取 WebDAV 配置
  WebDavConfig get webDavConfig => _webDavConfig;

  /// 获取匿名数据贡献配置
  AnalyticsConsent get analyticsConsent => _analyticsConsent;

  /// 获取订阅状态
  SubscriptionState get subscriptionState => _subscriptionState;

  /// 是否为 Pro 用户（活跃）
  bool get isPro => _subscriptionState.isPro && _subscriptionState.isActive;

  /// 当前是否使用会话临时 Key（安全存储不可用）
  bool get isUsingSessionOnlyKeys => _sessionOnlyKeys.isNotEmpty;

  /// 安全存储 key 前缀
  static const _secureKeyPrefix = 'api_key_';

  @override
  ThemeMode get themeMode => _themeMode;
  @override
  String get selectedProvider => _selectedProvider;
  @override
  bool get isInitialized => _initialized;

  /// 获取自定义端点列表（只读）
  List<EndpointConfig> get customEndpoints => List.unmodifiable(_endpoints);

  @override
  String getApiKey(String provider) =>
      _sessionOnlyKeys[provider] ?? _apiKeys[provider] ?? '';

  /// 设置临时会话 Key（仅存内存，优先级高于持久 Key）
  ///
  /// 规则：只存内存 / 不写 settings.json / 不写安全存储 / 退出清除 / UI 标注“仅本次会话”
  void setSessionApiKey(String provider, String key) {
    _sessionOnlyKeys[provider] = key;
    _aiService.configureApiKey(provider, key);
    notifyListeners();
  }

  /// 删除 API Key
  ///
  /// 删安全存储 / 删内存缓存 / 刷新 Provider 状态。
  /// 不删 Provider 或模型元数据。
  Future<void> deleteApiKey(String provider) async {
    _apiKeys.remove(provider);
    _sessionOnlyKeys.remove(provider);
    // 删除安全存储
    if (_secureStorageAvailable) {
      try {
        await _secureStorage.delete(key: '$_secureKeyPrefix$provider');
      } catch (_) {}
    }
    // 刷新 Provider 状态（配置空 key）
    _aiService.configureApiKey(provider, '');
    notifyListeners();
    _save();
  }

  /// 检查指定 provider 是否有有效 API Key
  bool hasApiKey(String provider) => getApiKey(provider).isNotEmpty;

  /// 检查指定 provider 是否使用会话临时 Key
  bool isSessionOnlyKey(String provider) =>
      _sessionOnlyKeys.containsKey(provider);

  /// 获取指定 provider 的模型 ID
  String getSelectedModelId(String provider) =>
      _selectedModelIds[provider] ?? '';

  /// 设置模型 ID
  void setSelectedModelId(String provider, String modelId) {
    _selectedModelIds[provider] = modelId;
    notifyListeners();
    _save();
  }

  /// Persist a model selection only after the runtime has validated it.
  ///
  /// Unlike the legacy synchronous setters, this method surfaces disk errors
  /// so the runtime transaction can roll back instead of reporting a false
  /// success to the user.
  Future<void> commitRuntimeSelection(
    String provider,
    String modelId,
  ) async {
    final previousProvider = _selectedProvider;
    final previousModel = _selectedModelIds[provider];
    _selectedProvider = provider;
    _selectedModelIds[provider] = modelId;
    try {
      await _save(rethrowOnError: true);
    } catch (_) {
      _selectedProvider = previousProvider;
      if (previousModel == null) {
        _selectedModelIds.remove(provider);
      } else {
        _selectedModelIds[provider] = previousModel;
      }
      rethrow;
    }
    notifyListeners();
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

  /// 设置 API Key
  ///
  /// 安全存储可用时写入安全存储；
  /// 安全存储不可用时仅保存为会话临时 Key，不持久化。
  @override
  void setApiKey(String provider, String key) {
    _apiKeys[provider] = key;
    _aiService.configureApiKey(provider, key);

    if (_secureStorageAvailable) {
      // 异步写入安全存储
      _secureStorage
          .write(key: '$_secureKeyPrefix$provider', value: key)
          .catchError((e) {
        // 安全存储写入失败 → 降级为会话临时
        _sessionOnlyKeys[provider] = key;
        secureStorageWarning =
            '无法安全保存 $provider 的 API Key，本次会话临时使用，关闭应用后需重新输入。';
        notifyListeners();
      });
    } else {
      // 安全存储不可用 → 会话临时
      _sessionOnlyKeys[provider] = key;
      secureStorageWarning = '安全存储不可用，API Key 仅在本次会话有效，不会保存到磁盘。';
    }

    notifyListeners();
    _save();
  }

  /// 完成引导向导
  void completeOnboarding({
    String? providerId,
    String? modelId,
    bool localOnly = false,
  }) {
    _onboardingState = OnboardingState(
      completed: true,
      schemaVersion: currentOnboardingSchemaVersion,
      completedAt: DateTime.now(),
      selectedProviderId: providerId,
      selectedModelId: modelId,
      localOnlyMode: localOnly,
      lastStep: 7,
    );
    notifyListeners();
    _save();
  }

  /// 重置引导状态（设置页重新打开向导）
  void resetOnboarding() {
    _onboardingState = _onboardingState.reset();
    notifyListeners();
    _save();
  }

  /// 设置 WebDAV 配置
  void setWebDavConfig(WebDavConfig config) {
    _webDavConfig = config;
    notifyListeners();
    _save();
  }

  /// 设置匿名数据贡献开关
  void setAnalyticsConsent({required bool enabled}) {
    _analyticsConsent = AnalyticsConsent(
      enabled: enabled,
      anonymousId: _analyticsConsent.anonymousId,
    );
    notifyListeners();
    _save();
  }

  /// 更新订阅状态（由 ServiceLocator 在激活/取消时调用）
  void updateSubscriptionState(SubscriptionState state) {
    _subscriptionState = state;
    notifyListeners();
    _save();
  }

  /// 更新引导步骤（中途退出恢复）
  void updateOnboardingStep(int step) {
    _onboardingState = _onboardingState.copyWith(lastStep: step);
    _save();
  }

  /// 更新引导状态（通用，由引导型向导调用）
  void updateOnboardingState(OnboardingState state) {
    _onboardingState = state;
    notifyListeners();
    _save();
  }

  /// 标记引导完成（由 OnboardingGate 在旧向导移除后自动调用）
  @override
  void markOnboardingComplete() {
    if (!_onboardingState.needsOnboarding) return;
    _onboardingState = _onboardingState.copyWith(
      completed: true,
      schemaVersion: currentOnboardingSchemaVersion,
      completedAt: DateTime.now(),
    );
    notifyListeners();
    _save();
  }

  /// 添加自定义端点
  void addCustomEndpoint(EndpointConfig config) {
    _endpoints.add(config);
    _aiService.addEndpoint(config);
    notifyListeners();
    _save();
  }

  /// 移除自定义端点
  void removeCustomEndpoint(String id) {
    _endpoints.removeWhere((e) => e.id == id);
    _aiService.removeEndpoint(id);
    notifyListeners();
    _save();
  }

  /// 更新自定义端点
  void updateCustomEndpoint(EndpointConfig config) {
    final idx = _endpoints.indexWhere((e) => e.id == config.id);
    if (idx >= 0) {
      _endpoints[idx] = config;
      _aiService.addEndpoint(config);
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
        if (value != null &&
            value.isNotEmpty &&
            !_apiKeys.containsKey(provider)) {
          _apiKeys[provider] = value;
        }
      }
      _secureStorageAvailable = true;
    } catch (e) {
      _secureStorageAvailable = false;
      debugPrint('SettingsService: 安全存储不可用，回退到明文 JSON — $e');
    }

    // 3. 从配置文件加载非敏感配置
    if (_settingsPath != null) {
      final file = File(_settingsPath!);
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          _themeMode = _parseThemeMode(json['themeMode'] as String?);
          _selectedProvider = json['selectedProvider'] as String? ?? 'free';
          // 加载模型 ID 选择
          if (json['selectedModelIds'] is Map) {
            (json['selectedModelIds'] as Map).forEach((k, v) {
              if (v is String && v.isNotEmpty) {
                _selectedModelIds[k.toString()] = v;
              }
            });
          }
          // 旧版明文 apiKeys：尝试迁移到安全存储，不保留在 JSON
          if (json['apiKeys'] is Map) {
            (json['apiKeys'] as Map).forEach((k, v) {
              final keyStr = k.toString();
              if (v is String &&
                  v.isNotEmpty &&
                  !_apiKeys.containsKey(keyStr)) {
                legacyApiKeys[keyStr] = v;
              }
            });
          }
          // 加载自定义端点
          if (json['customEndpoints'] is List) {
            _endpoints = (json['customEndpoints'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => EndpointConfig.fromJson(e))
                .toList();
          }
          // 加载引导状态
          if (json['onboarding'] is Map<String, dynamic>) {
            _onboardingState = OnboardingState.fromJson(
                json['onboarding'] as Map<String, dynamic>);
          }
          // 加载 WebDAV 配置
          if (json['webdav'] is Map<String, dynamic>) {
            _webDavConfig =
                WebDavConfig.fromJson(json['webdav'] as Map<String, dynamic>);
          }
          // 加载匿名数据贡献配置
          if (json['analyticsConsent'] is Map<String, dynamic>) {
            _analyticsConsent = AnalyticsConsent.fromJson(
                json['analyticsConsent'] as Map<String, dynamic>);
          }
          // 加载订阅状态
          if (json['subscription'] is Map<String, dynamic>) {
            _subscriptionState = SubscriptionState.fromJson(
                json['subscription'] as Map<String, dynamic>);
          }
          // 加载自定义存储路径
          loadCustomStoragePath(json);
        } catch (_) {}
      }
    }

    // 4. 若发现旧版明文 apiKeys 且安全存储可用，迁移到安全存储并从 JSON 删除
    //    安全存储不可用时，旧版明文 Key 不加载（禁止明文回退）
    if (legacyApiKeys.isNotEmpty && _secureStorageAvailable) {
      for (final entry in legacyApiKeys.entries) {
        try {
          await _secureStorage.write(
            key: '$_secureKeyPrefix${entry.key}',
            value: entry.value,
          );
          _apiKeys[entry.key] = entry.value;
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
    if (_selectedProvider == 'free' ||
        !_apiKeys.containsKey(_selectedProvider)) {
      for (final entry in envMappings.entries) {
        final envVal = env[entry.value];
        if (envVal != null && envVal.isNotEmpty) {
          _selectedProvider = entry.key;
          break;
        }
      }
    }

    // 7. 将自定义端点注册到 AI 服务
    _endpoints.forEach(_aiService.addEndpoint);
    // 6. 将 API keys 应用到 AI 服务
    for (final entry in _apiKeys.entries) {
      _aiService.configureApiKey(entry.key, entry.value);
    }

    // Restore the selected model onto each configured runtime endpoint.
    for (final entry in _selectedModelIds.entries) {
      final endpoint = _aiService.getEndpoint(entry.key);
      if (endpoint != null) {
        _aiService.addEndpoint(endpoint.copyWith(modelId: entry.value));
      }
    }
    _aiService.setProvider(_selectedProvider);

    // 7. 将自定义端点注册到 AI 服务
    _endpoints.forEach(_aiService.addEndpoint);
  }

  Future<void> _save({bool rethrowOnError = false}) async {
    if (_settingsPath == null) return;
    try {
      // API Keys 仅写入安全存储；禁止明文 JSON 回退
      if (_secureStorageAvailable) {
        for (final entry in _apiKeys.entries) {
          // 跳过会话临时 Key
          if (_sessionOnlyKeys.containsKey(entry.key)) continue;
          try {
            await _secureStorage.write(
              key: '$_secureKeyPrefix${entry.key}',
              value: entry.value,
            );
          } catch (e) {
            debugPrint('SettingsService: 写入安全存储失败 — $e');
            // 不 fallback 到 JSON，标记为会话临时
            _sessionOnlyKeys[entry.key] = entry.value;
            secureStorageWarning = '部分 API Key 无法安全保存，仅在本次会话有效。';
          }
        }
      }

      final file = File(_settingsPath!);
      await file.create(recursive: true);
      final data = <String, dynamic>{
        'themeMode': _themeMode.name,
        'selectedProvider': _selectedProvider,
        'selectedModelIds': _selectedModelIds,
        'onboarding': _onboardingState.toJson(),
        'webdav': _webDavConfig.toJson(),
        'analyticsConsent': _analyticsConsent.toJson(),
        'subscription': _subscriptionState.toJson(),
        'customEndpoints': _endpoints
            .map((e) => EndpointConfig(
                  protocol: e.protocol,
                  id: e.id,
                  name: e.name,
                  baseUrl: e.baseUrl,
                  apiKey: '', // 不在 JSON 中保存 apiKey
                  modelId: e.modelId,
                ).toJson())
            .toList(),
        if (_customStoragePath != null)
          'customStoragePath': _customStoragePath,
        // 禁止在 JSON 中写入 apiKeys
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      if (rethrowOnError) rethrow;
    }
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

  // ─── Phase 6.3: 自定义存储位置 ─────────────────────────────

  String? _customStoragePath;

  /// 获取自定义存储路径（null 表示使用默认路径）。
  String? get customStoragePath => _customStoragePath;

  /// 设置自定义存储路径。传 null 恢复默认。
  Future<void> setCustomStoragePath(String? path) async {
    _customStoragePath = path;
    _save();
    notifyListeners();
  }

  /// 从持久化加载自定义路径。
  void loadCustomStoragePath(Map<String, dynamic> json) {
    final stored = json['customStoragePath'] as String? ?? '';
    _customStoragePath = stored.isEmpty ? null : stored;
  }
}

/// API Key 日志脱敏工具
///
/// 推荐完全不记录 API Key。如必须记录，使用此函数脱敏。
/// 示例：sk-abc...xyz → sk-a...z
String maskApiKey(String key) {
  if (key.length <= 4) return '***';
  return '${key.substring(0, 3)}...${key[key.length - 1]}';
}
