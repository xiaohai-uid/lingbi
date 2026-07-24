import 'package:lingbi/services/interfaces/i_ai_service.dart';
import 'package:lingbi/services/settings_service.dart';
import '../core/ai/ai_provider.dart';
import '../core/ai/free_provider.dart';
import '../core/ai/sensenova_provider.dart';
import '../core/ai/deepseek_provider.dart';
import '../core/ai/openai_provider.dart';
import '../core/ai/claude_provider.dart';
import 'quota_service.dart';

/// AI 服务 - 管理所有 AI 提供者并负责路由
class AIService implements IAIService {

  AIService({required QuotaService quotaService})
      : _quota = quotaService;
  final FreeProvider _freeProvider = FreeProvider();
  final SenseNovaProvider _sensenovaProvider = SenseNovaProvider();
  final DeepSeekProvider _deepseekProvider = DeepSeekProvider();
  final OpenAIProvider _openaiProvider = OpenAIProvider();
  final ClaudeProvider _claudeProvider = ClaudeProvider();
  final QuotaService _quota;
  String _currentProvider = 'free';
  String _projectContext = '';

  /// 自定义端点 Provider 映射（id -> OpenAIProvider）
  final Map<String, OpenAIProvider> _customProviders = {};

  @override
  String get currentProviderName => _currentProvider;

  @override
  List<AIProvider> get availableProviders {
    final list = <AIProvider>[_freeProvider];
    if (_sensenovaProvider.isAvailable) list.add(_sensenovaProvider);
    if (_deepseekProvider.isAvailable) list.add(_deepseekProvider);
    if (_openaiProvider.isAvailable) list.add(_openaiProvider);
    if (_claudeProvider.isAvailable) list.add(_claudeProvider);
    list.addAll(_customProviders.values);
    return list;
  }

  AIProvider get currentProvider {
    switch (_currentProvider) {
      case 'sensenova':
        return _sensenovaProvider;
      case 'deepseek':
        return _deepseekProvider;
      case 'openai':
        return _openaiProvider;
      case 'claude':
        return _claudeProvider;
      default:
        // 检查自定义 Provider
        if (_customProviders.containsKey(_currentProvider)) {
          return _customProviders[_currentProvider]!;
        }
        return _freeProvider;
    }
  }

  @override
  void setProvider(String name) {
    final builtIn = ['free', 'sensenova', 'deepseek', 'openai', 'claude'];
    if (builtIn.contains(name) || _customProviders.containsKey(name)) {
      _currentProvider = name;
    }
  }

  @override
  void setProjectContext(String context) {
    _projectContext = context;
  }

  /// 配置 API Key
  @override
  void configureApiKey(String provider, String key) {
    switch (provider) {
      case 'sensenova':
        _sensenovaProvider.apiKey = key;
      case 'deepseek':
        _deepseekProvider.apiKey = key;
      case 'openai':
        _openaiProvider.apiKey = key;
      case 'claude':
        _claudeProvider.apiKey = key;
    }
  }

  /// 注册自定义 Provider（从 CustomEndpointConfig 创建/更新 OpenAIProvider）
  void registerCustomProvider(CustomEndpointConfig config) {
    final provider = OpenAIProvider(
      apiKey: config.apiKey,
      modelOverride: config.modelId,
    );
    provider.baseUrl = config.baseUrl;
    _customProviders[config.id] = provider;
  }

  /// 移除自定义 Provider
  void unregisterCustomProvider(String id) {
    _customProviders.remove(id);
    if (_currentProvider == id) {
      _currentProvider = 'free';
    }
  }

  /// 设置自定义端点的 Base URL
  void setCustomBaseUrl(String providerId, String url) {
    final provider = _customProviders[providerId];
    if (provider != null) {
      provider.baseUrl = url;
    }
  }

  /// 测试自定义端点连接（发送一条简单消息验证可用性）
  Future<String> testCustomEndpoint(CustomEndpointConfig config) async {
    final provider = OpenAIProvider(
      apiKey: config.apiKey,
      modelOverride: config.modelId,
    );
    provider.baseUrl = config.baseUrl;
    try {
      final result = await provider.chatSync(
        messages: [const ChatMessage(role: 'user', content: 'Hi')],
        maxTokens: 5,
      );
      if (result.contains('error') || result.contains('Error')) {
        return result;
      }
      return '连接成功';
    } catch (e) {
      return '连接失败: $e';
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

  /// 发送聊天消息（流式）
  @override
  Stream<String> chat({
    required String message,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    if (!_quota.tryConsume()) {
      yield '今日免费额度已用完（${_quota.dailyLimit}次/天）。请配置自己的 API Key 或明天再试。';
      return;
    }

    final messages = _buildMessages(message);
    yield* currentProvider.chat(
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// 风格蒸馏：分析文本风格
  @override
  Future<String> analyzeStyle(String text) async {
    final messages = [
      const ChatMessage(
        role: 'system',
        content: '你是一个文学风格分析专家。请分析以下文本的写作风格，包括：用词特点、句式结构、语气语调、修辞手法、节奏感。请用中文回复，输出结构化分析。',
      ),
      ChatMessage(role: 'user', content: text),
    ];
    return currentProvider.chatSync(messages: messages, maxTokens: 1024);
  }

  /// 小说拆解：分析小说结构
  @override
  Future<String> analyzeNovel(String text) async {
    final messages = [
      const ChatMessage(
        role: 'system',
        content: '你是一个小说结构分析专家。请从以下文本中识别：角色、情节线、章节结构、叙事视角、主题、冲突类型。请用中文输出结构化报告。',
      ),
      ChatMessage(role: 'user', content: text),
    ];
    return currentProvider.chatSync(messages: messages);
  }

  /// 智能续写
  @override
  Stream<String> continueWriting(String text) {
    final messages = [
      const ChatMessage(
        role: 'system',
        content: '你是一个小说续写助手。请根据前文内容，自然地续写下一段。保持风格一致。',
      ),
      ChatMessage(role: 'user', content: text),
    ];
    return currentProvider.chat(messages: messages, maxTokens: 1024);
  }

  Future<void> dispose() async {
    await _freeProvider.dispose();
    await _sensenovaProvider.dispose();
    await _deepseekProvider.dispose();
    await _openaiProvider.dispose();
    await _claudeProvider.dispose();
    for (final p in _customProviders.values) {
      await p.dispose();
    }
  }
}
