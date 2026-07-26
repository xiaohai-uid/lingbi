import 'dart:async';

import 'package:lingbi/services/interfaces/i_ai_service.dart';
import '../core/ai/ai_provider.dart';
import '../core/ai/ai_response_normalizer.dart';
import '../core/ai/free_provider.dart';
import '../core/ai/model_registry.dart';
import '../core/ai/models/endpoint_config.dart';
import '../core/ai/provider_factory.dart';
import '../core/errors/ai_error.dart';
import 'quota_service.dart';

/// AI 服务 - 管理所有 AI 提供者并负责路由
///
/// 所有供应商通过 EndpointConfig 列表管理，通过 ProviderFactory 创建。
/// 不再持有硬编码 Provider 实例，不再使用 switch(name) 路由。
class AIService implements IAIService {

  AIService({required QuotaService quotaService})
      : _quota = quotaService;
  final FreeProvider _freeProvider = FreeProvider();
  final QuotaService _quota;
  String _currentProvider = 'free';
  String _projectContext = '';

  StreamSubscription<String>? _activeSubscription;
  bool get isGenerating => _activeSubscription != null;

  final List<EndpointConfig> _endpoints = [];
  final Map<String, AIProvider> _providerCache = {};

  List<EndpointConfig> get endpoints => List.unmodifiable(_endpoints);

  void addEndpoint(EndpointConfig config) {
    final idx = _endpoints.indexWhere((e) => e.id == config.id);
    if (idx >= 0) {
      _endpoints[idx] = config;
    } else {
      _endpoints.add(config);
    }
    _providerCache.remove(config.id);
  }

  void removeEndpoint(String id) {
    _endpoints.removeWhere((e) => e.id == id);
    _providerCache.remove(id);
    if (_currentProvider == id) {
      _currentProvider = 'free';
    }
  }

  EndpointConfig? getEndpoint(String id) {
    try {
      return _endpoints.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  String get currentProviderName => _currentProvider;

  @override
  List<AIProvider> get availableProviders {
    final list = <AIProvider>[_freeProvider];
    for (final config in _endpoints) {
      final provider = _getOrCreateProvider(config.id);
      if (provider != null && provider.isAvailable) {
        list.add(provider);
      }
    }
    return list;
  }

  AIProvider get currentProvider {
    if (_currentProvider == 'free') return _freeProvider;
    return _getOrCreateProvider(_currentProvider) ?? _freeProvider;
  }

  AIProvider? _getOrCreateProvider(String configId) {
    if (_providerCache.containsKey(configId)) {
      return _providerCache[configId];
    }
    final config = getEndpoint(configId);
    if (config == null) return null;
    try {
      final provider = ProviderFactory.create(config);
      _providerCache[configId] = provider;
      return provider;
    } catch (_) {
      return null;
    }
  }

  @override
  void setProvider(String name) {
    if (name == 'free' || _endpoints.any((e) => e.id == name)) {
      _currentProvider = name;
    }
  }

  @override
  void setProjectContext(String context) {
    _projectContext = context;
  }

  @override
  void configureApiKey(String provider, String key) {
    final idx = _endpoints.indexWhere((e) => e.id == provider);
    if (idx >= 0) {
      _endpoints[idx] = _endpoints[idx].copyWith(
        apiKey: key.isEmpty ? null : key,
      );
      _providerCache.remove(provider);
    }
  }

  List<ChatMessage> _buildMessages(String userMessage) {
    final messages = <ChatMessage>[];
    if (_projectContext.isNotEmpty) {
      messages.add(ChatMessage(
        role: 'system',
        content: '当前项目上下文：\n$_projectContext\n\n你是一个专业的写作助手，帮助用户进行小说创作。请基于上述上下文提供帮助。',
      ));
    } else {
      messages.add(const ChatMessage(
        role: 'system',
        content: '你是一个专业的 AI 写作助手，帮助用户进行小说创作。可以续写、改写、扩写文本，也可以分析结构和风格。',
      ));
    }
    messages.add(ChatMessage(role: 'user', content: userMessage));
    return messages;
  }

  ModelInfo? get currentModelInfo {
    return ModelRegistry.instance.findModel(
      currentProvider.currentModelId,
      providerId: _currentProvider == 'free' ? null : _currentProvider,
    );
  }

  String get currentModelId => currentProvider.currentModelId;

  void cancelCurrentRequest() {
    _activeSubscription?.cancel();
    _activeSubscription = null;
  }

  Stream<String> testGeneration({String? providerId, int maxTokens = 100}) async* {
    final provider = providerId != null
        ? _resolveProvider(providerId) : currentProvider;
    final controller = StreamController<String>();
    _activeSubscription = provider
        .chat(messages: const [
          ChatMessage(role: 'user', content: '请用一句不超过 30 字的中文，描写雨夜中的旧车站。'),
        ], maxTokens: maxTokens)
        .listen(
          (chunk) => controller.add(chunk),
          onError: (Object error) {
            controller.addError(AiErrorMapper.map(error, provider: providerId ?? _currentProvider));
          },
          onDone: () => controller.close(),
        );
    yield* controller.stream;
    _activeSubscription = null;
  }

  Future<ConnectionTestResult> testConnection() async {
    return currentProvider.testConnection();
  }

  Future<ConnectionTestResult> testConnectionUnified({String? providerId, String? modelId}) async {
    final pid = providerId ?? _currentProvider;
    final provider = _resolveProvider(pid);
    final stopwatch = Stopwatch()..start();
    try {
      final response = await provider.chatSync(
        messages: [const ChatMessage(role: 'user', content: '只回复：连接成功')],
        maxTokens: 10,
      );
      stopwatch.stop();
      final trimmed = response.trim();
      if (trimmed.isEmpty) {
        return ConnectionTestResult(success: false, latencyMs: stopwatch.elapsedMilliseconds,
          modelId: modelId ?? provider.currentModelId, providerId: pid,
          message: '收到空响应，请检查模型配置', errorCategory: '空响应');
      }
      return ConnectionTestResult(success: true, latencyMs: stopwatch.elapsedMilliseconds,
        modelId: modelId ?? provider.currentModelId, providerId: pid,
        message: '连接成功', responsePreview: _buildResponsePreview(trimmed));
    } catch (e) {
      stopwatch.stop();
      final category = _classifyError(e);
      return ConnectionTestResult(success: false, latencyMs: stopwatch.elapsedMilliseconds,
        modelId: modelId ?? provider.currentModelId, providerId: pid,
        message: category, errorCategory: category);
    }
  }

  String _buildResponsePreview(String response) {
    final cleaned = response.replaceAll(RegExp(r'[\r\n\t]'), ' ').replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (cleaned.length <= 80) return cleaned;
    return '${cleaned.substring(0, 77)}...';
  }

  String _classifyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('unauthorized')) return '密钥无效，请检查 API Key 是否复制完整';
    if (msg.contains('403') || msg.contains('forbidden')) return '权限不足，请检查账户状态';
    if (msg.contains('404') || msg.contains('not found')) return '模型不存在，请检查 modelId 配置';
    if (msg.contains('429') || msg.contains('rate limit')) return '频率限制，请稍后重试';
    if (msg.contains('balance') || msg.contains('insufficient') || msg.contains('余额')) return '余额不足，请充值后重试';
    if (msg.contains('socket') || msg.contains('timeout') || msg.contains('connection') || msg.contains('network')) return '网络不可达，请检查网络连接';
    if (msg.contains('500') || msg.contains('502') || msg.contains('503') || msg.contains('internal server')) return '服务端错误，请稍后重试';
    if (msg.contains('empty') || msg.contains('空')) return '空响应，请检查模型配置';
    if (msg.contains('format') || msg.contains('parse') || msg.contains('json')) return '格式异常，响应无法解析';
    return '连接失败，请检查配置';
  }

  Future<List<ModelInfo>> discoverModels(String providerId) async {
    final provider = _resolveProvider(providerId);
    try {
      final modelIds = await provider.listModels();
      if (modelIds.isNotEmpty) {
        ModelRegistry.instance.replaceRemoteModels(providerId, modelIds);
      }
    } catch (_) {}
    return ModelRegistry.instance.getModelsForProvider(providerId);
  }

  AIProvider _resolveProvider(String providerId) {
    if (providerId == 'free') return _freeProvider;
    return _getOrCreateProvider(providerId) ?? _freeProvider;
  }

  Stream<NormalizerEvent> normaliz
