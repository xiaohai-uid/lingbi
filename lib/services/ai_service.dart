import 'dart:async';

import 'package:lingbi/shared/interfaces/i_ai_service.dart';
import '../shared/ai/ai_provider.dart';
import '../shared/ai/ai_response_normalizer.dart';
import '../shared/ai/free_provider.dart';
import '../shared/ai/model_registry.dart';
import '../shared/ai/models/endpoint_config.dart';
import '../shared/ai/provider_factory.dart';
import '../shared/errors/ai_error.dart';
import '../features/settings/data/quota_service.dart';

class AIService implements IAIService {
  AIService({required QuotaService quotaService}) : _quota = quotaService;
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
    if (idx >= 0) { _endpoints[idx] = config; } else { _endpoints.add(config); }
    _providerCache.remove(config.id);
  }

  void removeEndpoint(String id) {
    _endpoints.removeWhere((e) => e.id == id);
    _providerCache.remove(id);
    if (_currentProvider == id) _currentProvider = 'free';
  }

  EndpointConfig? getEndpoint(String id) {
    try { return _endpoints.firstWhere((e) => e.id == id); } catch (_) { return null; }
  }

  @override String get currentProviderName => _currentProvider;

  @override List<AIProvider> get availableProviders {
    final list = <AIProvider>[_freeProvider];
    for (final config in _endpoints) {
      final p = _getOrCreateProvider(config.id);
      if (p != null && p.isAvailable) list.add(p);
    }
    return list;
  }

  AIProvider get currentProvider {
    if (_currentProvider == 'free') return _freeProvider;
    return _getOrCreateProvider(_currentProvider) ?? _freeProvider;
  }

  AIProvider? _getOrCreateProvider(String configId) {
    if (_providerCache.containsKey(configId)) return _providerCache[configId];
    final config = getEndpoint(configId);
    if (config == null) return null;
    try {
      final provider = ProviderFactory.create(config);
      _providerCache[configId] = provider;
      return provider;
    } catch (_) { return null; }
  }

  @override void setProvider(String name) {
    _currentProvider = name;
  }

  @override void setProjectContext(String context) { _projectContext = context; }

  @override void configureApiKey(String provider, String key) {
    final idx = _endpoints.indexWhere((e) => e.id == provider);
    if (idx >= 0) {
      _endpoints[idx] = _endpoints[idx].copyWith(apiKey: key.isEmpty ? null : key);
      _providerCache.remove(provider);
    } else if (key.isNotEmpty && provider != 'free') {
      // Auto-create endpoint for known providers (backward compatibility)
      final protocol = (provider == 'claude') ? Protocol.anthropic : Protocol.openai;
      final baseUrl = provider == 'sensenova'
          ? 'https://token.sensenova.cn/v1'
          : 'https://api.$provider.com';
      addEndpoint(EndpointConfig(
        id: provider,
        name: provider,
        baseUrl: baseUrl,
        apiKey: key,
        protocol: protocol,
        modelId: provider == 'openai' ? 'gpt-4o' : 
                 provider == 'claude' ? 'claude-sonnet-4-20250514' :
                 provider == 'deepseek' ? 'deepseek-chat' :
                 provider == 'sensenova' ? 'deepseek-v4-flash' : 'gpt-4o',
      ));
    }
  }

  List<ChatMessage> _buildMessages(String userMessage) {
    final messages = <ChatMessage>[];
    if (_projectContext.isNotEmpty) {
      messages.add(ChatMessage(role: 'system', content: '当前项目上下文：\n$_projectContext\n\n你是一个专业的写作助手，帮助用户进行小说创作。请基于上述上下文提供帮助。'));
    } else {
      messages.add(const ChatMessage(role: 'system', content: '你是一个专业的 AI 写作助手，帮助用户进行小说创作。可以续写、改写、扩写文本，也可以分析结构和风格。'));
    }
    messages.add(ChatMessage(role: 'user', content: userMessage));
    return messages;
  }

  ModelInfo? get currentModelInfo {
    return ModelRegistry.instance.findModel(currentProvider.currentModelId, providerId: _currentProvider == 'free' ? null : _currentProvider);
  }

  String get currentModelId => currentProvider.currentModelId;
  void cancelCurrentRequest() { _activeSubscription?.cancel(); _activeSubscription = null; }

  Stream<String> testGeneration({String? providerId, int maxTokens = 100}) async* {
    final provider = providerId != null ? _resolveProvider(providerId) : currentProvider;
    final controller = StreamController<String>();
    _activeSubscription = provider.chat(messages: const [ChatMessage(role: 'user', content: '请用一句不超过 30 字的中文，描写雨夜中的旧车站。')], maxTokens: maxTokens).listen(
      (chunk) => controller.add(chunk),
      onError: (Object error) { controller.addError(AiErrorMapper.map(error, provider: providerId ?? _currentProvider)); },
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
    final sw = Stopwatch()..start();
    try {
      final resp = await provider.chatSync(messages: [const ChatMessage(role: 'user', content: '只回复：连接成功')], maxTokens: 10);
      sw.stop();
      final t = resp.trim();
      if (t.isEmpty) return ConnectionTestResult(success: false, latencyMs: sw.elapsedMilliseconds, modelId: modelId ?? provider.currentModelId, providerId: pid, message: '收到空响应，请检查模型配置', errorCategory: '空响应');
      return ConnectionTestResult(success: true, latencyMs: sw.elapsedMilliseconds, modelId: modelId ?? provider.currentModelId, providerId: pid, message: '连接成功', responsePreview: _buildResponsePreview(t));
    } catch (e) {
      sw.stop();
      final cat = _classifyError(e);
      return ConnectionTestResult(success: false, latencyMs: sw.elapsedMilliseconds, modelId: modelId ?? provider.currentModelId, providerId: pid, message: cat, errorCategory: cat);
    }
  }

  String _buildResponsePreview(String response) {
    final c = response.replaceAll(RegExp(r'[\r\n\t]'), ' ').replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (c.length <= 80) return c;
    return '${c.substring(0, 77)}...';
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
      if (modelIds.isNotEmpty) ModelRegistry.instance.replaceRemoteModels(providerId, modelIds);
    } catch (_) {}
    return ModelRegistry.instance.getModelsForProvider(providerId);
  }

  AIProvider _resolveProvider(String providerId) {
    if (providerId == 'free') return _freeProvider;
    return _getOrCreateProvider(providerId) ?? _freeProvider;
  }

  Stream<NormalizerEvent> normalizedChat({required String message, double temperature = 0.7, int maxTokens = 2048, bool treatAllAsCandidate = false}) async* {
    if (!_quota.tryConsume()) { yield const NormalizerError(message: '今日免费额度已用完。请配置自己的 API Key 或明天再试。'); return; }
    yield* AiResponseNormalizer(treatAllAsCandidate: treatAllAsCandidate).normalize(currentProvider.chat(messages: _buildMessages(message), temperature: temperature, maxTokens: maxTokens));
  }

  @override Stream<String> chat({required String message, double temperature = 0.7, int maxTokens = 2048}) async* {
    if (!_quota.tryConsume()) { yield '今日免费额度已用完（${_quota.dailyLimit}次/天）。请配置自己的 API Key 或明天再试。'; return; }
    final controller = StreamController<String>();
    _activeSubscription = currentProvider.chat(messages: _buildMessages(message), temperature: temperature, maxTokens: maxTokens).listen(
      (chunk) => controller.add(chunk),
      onError: (Object error) { controller.addError(AiErrorMapper.map(error, provider: _currentProvider)); },
      onDone: () => controller.close(),
    );
    yield* controller.stream;
    _activeSubscription = null;
  }

  @override Future<String> analyzeStyle(String text) async {
    return currentProvider.chatSync(messages: [
      const ChatMessage(role: 'system', content: '你是一个文学风格分析专家。请分析以下文本的写作风格，包括：用词特点、句式结构、语气语调、修辞手法、节奏感。请用中文回复，输出结构化分析。'),
      ChatMessage(role: 'user', content: text),
    ], maxTokens: 1024);
  }

  @override Future<String> analyzeNovel(String text) async {
    return currentProvider.chatSync(messages: [
      const ChatMessage(role: 'system', content: '你是一个小说结构分析专家。请从以下文本中识别：角色、情节线、章节结构、叙事视角、主题、冲突类型。请用中文输出结构化报告。'),
      ChatMessage(role: 'user', content: text),
    ]);
  }

  @override Stream<String> continueWriting(String text) {
    return currentProvider.chat(messages: [
      const ChatMessage(role: 'system', content: '你是一个小说续写助手。请根据前文内容，自然地续写下一段。保持风格一致。'),
      ChatMessage(role: 'user', content: text),
    ], maxTokens: 1024);
  }

  Future<void> dispose() async {
    await _freeProvider.dispose();
    for (final p in _providerCache.values) {
      await p.dispose();
    }
    _providerCache.clear();
  }
}
