import 'package:lingbi/services/interfaces/i_ai_service.dart';
import '../core/ai/base_client.dart';
import '../core/ai/llm_factory.dart';
import '../core/ai/llm_models.dart';
import '../core/ai/deepseek_provider.dart';
import '../core/ai/openai_provider.dart';
import '../core/ai/claude_provider.dart';
import '../core/ai/free_provider.dart';
import 'provider_registry.dart';
import 'quota_service.dart';

/// AI 服务
class AIService implements IAIService {
  AIService({required QuotaService quotaService, ProviderRegistry? providerRegistry})
      : _quota = quotaService,
        _providerRegistry = providerRegistry;
  final QuotaService _quota;
  ProviderRegistry? _providerRegistry;
  String _currentProvider = 'free';
  String _projectContext = '';
  BaseLLMClient? _cachedProvider;
  String? _lastActiveProviderId;
  final Map<String, String> _apiKeys = {};
  final Map<String, String> _apiUrls = {};

  ProviderConfig? get _activeConfig {
    final active = _providerRegistry?.getActiveProvider();
    if (active != null && (active.selectedModel?.isNotEmpty == true)) {
      return active;
    }
    return null;
  }

  @override
  String get currentProviderName =>
      _activeConfig?.name ?? _currentProvider;

  @override
  List<String> get availableProviders {
    final custom =
        _providerRegistry?.getAll().map((p) => p.name).toList() ?? [];
    // Ensure built-in providers are initialized
    LLMFactory.initBuiltins();
    final builtIn = LLMFactory.availableProviders;
    return [...custom, ...builtIn];
  }

  /// 获取当前 Provider 实例（带缓存，自动检测 registry 变更）
  BaseLLMClient get _provider {
    final active = _activeConfig;
    final activeId = active?.id;

    if (_cachedProvider != null && _lastActiveProviderId == activeId) {
      return _cachedProvider!;
    }

    _cachedProvider = null;
    _lastActiveProviderId = activeId;

    if (active != null) {
      _cachedProvider = _createProviderFromConfig(active);
    } else {
      _cachedProvider =
          _createProvider(_currentProvider, _apiKeys[_currentProvider]);
    }
    return _cachedProvider!;
  }

  BaseLLMClient _createProviderFromConfig(ProviderConfig config) {
    final provider = OpenAIProvider(
      apiKey: config.apiKey.isNotEmpty ? config.apiKey : null,
      modelOverride: config.selectedModel,
      name: config.name,
    );
    if (config.baseUrl.isNotEmpty) {
      final base = config.baseUrl.replaceAll(RegExp(r'/+$'), '');
      provider.baseUrl = '$base/chat/completions';
    }
    return provider;
  }

  BaseLLMClient _createProvider(String name, String? apiKey) {
    switch (name) {
      case 'deepseek':
        return DeepSeekProvider(apiKey: apiKey);
      case 'openai':
        final url = _apiUrls[name];
        final isSenseNova = url != null && url.contains('sensenova');
        final provider = OpenAIProvider(
          apiKey: apiKey,
          modelOverride:
              isSenseNova ? 'sensenova-6.7-flash-lite' : 'gpt-4o-mini',
        );
        if (url != null && url.isNotEmpty) {
          provider.baseUrl = url;
        }
        return provider;
      case 'claude':
        return ClaudeProvider(apiKey: apiKey);
      default:
        return FreeProvider();
    }
  }

  @override
  void setProvider(String name) {
    if (_providerRegistry != null) {
      final matches =
          _providerRegistry!.getAll().where((p) => p.name == name);
      if (matches.isNotEmpty) {
        _providerRegistry!.setActiveProvider(matches.first.id);
        _cachedProvider = null;
        _lastActiveProviderId = null;
        return;
      }
    }
    if (LLMFactory.availableProviders.contains(name) &&
        name != _currentProvider) {
      _currentProvider = name;
      _cachedProvider = null;
      _lastActiveProviderId = null;
    }
  }

  void setProviderRegistry(ProviderRegistry registry) {
    _providerRegistry = registry;
    _cachedProvider = null;
    _lastActiveProviderId = null;
  }

  /// 设置 API Key 并刷新当前 provider
  void setApiKey(String provider, String key) {
    _apiKeys[provider] = key;
    if (provider == _currentProvider) {
      _cachedProvider = null;
      _lastActiveProviderId = null;
    }
  }

  @override
  void setProjectContext(String context) {
    _projectContext = context;
  }

  /// 设置自定义 Base URL
  void setBaseUrl(String provider, String url) {
    _apiUrls[provider] = url;
    if (provider == _currentProvider) {
      _cachedProvider = null;
      _lastActiveProviderId = null;
    }
  }

  @override
  void configureApiKey(String provider, String key) {
    setApiKey(provider, key);
  }

  /// 测试指定 Provider 的连接
  Future<String> testConnection(String provider, String apiKey) async {
    if (apiKey.isEmpty) return '请输入 API Key';
    try {
      setApiKey(provider, apiKey);
      _currentProvider = provider;
      _cachedProvider = null;
      final p = _provider;
      if (!p.isAvailable) return 'API Key 无效或未配置';
      // 调用简单生成测试连接
      final result = await p.generateText(const LLMRequest(
        messages: [LLMMessage(role: 'user', content: '回复"连接成功"')],
        maxTokens: 10,
      ));
      if (result.contains('连接成功') || result.isNotEmpty) {
        return '✅ 连接成功！可用模型: $provider-chat';
      }
      return '✅ 连接成功';
    } catch (e) {
      return '❌ 连接失败: $e';
    }
  }

  List<LLMMessage> _buildMessages(String userMessage) {
    final messages = <LLMMessage>[];
    if (_projectContext.isNotEmpty) {
      messages.add(LLMMessage(
        role: 'system',
        content:
            '当前项目上下文：\n$_projectContext\n\n你是一个专业的写作助手，帮助用户进行小说创作。请基于上述上下文提供帮助。',
      ));
    } else {
      messages.add(const LLMMessage(
        role: 'system',
        content: '你是一个专业的 AI 写作助手，帮助用户进行小说创作。可以续写、改写、扩写文本，也可以分析结构和风格。',
      ));
    }
    messages.add(LLMMessage(role: 'user', content: userMessage));
    return messages;
  }

  @override
  Stream<String> chat({
    required String message,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) {
    if (!_quota.canUse) {
      throw StateError('今日 AI 调用配额已用完，请明日再试或升级套餐');
    }
    final params = _activeConfig?.defaultParams;
    final messages = <LLMMessage>[];
    if (systemPrompt != null) {
      messages.add(LLMMessage(role: 'system', content: systemPrompt));
    }
    messages.addAll(_buildMessages(message));
    final request = LLMRequest(
      messages: messages,
      temperature: params?.temperature ?? temperature,
      maxTokens: params?.maxTokens ?? maxTokens,
      topP: params?.topP,
    );
    return _provider.streamText(request);
  }

  @override
  Future<String> analyzeStyle(String text) async {
    final request = LLMRequest(
      messages: [
        const LLMMessage(
            role: 'system', content: '分析以下文本的写作风格，包括：句式特点、用词偏好、节奏感等。'),
        LLMMessage(role: 'user', content: text),
      ],
      maxTokens: 1024,
    );
    return _provider.generateText(request);
  }

  @override
  Future<String> analyzeNovel(String text) async {
    final request = LLMRequest(
      messages: [
        const LLMMessage(
            role: 'system', content: '分析以下小说的结构，包括：情节推进、人物塑造、冲突设置、节奏把控等。'),
        LLMMessage(role: 'user', content: text),
      ],
      maxTokens: 2048,
    );
    return _provider.generateText(request);
  }

  @override
  Stream<String> continueWriting(String text) {
    final request = LLMRequest(
      messages: [
        const LLMMessage(
          role: 'system',
          content: '你是一个小说续写助手。请根据前文内容，自然地续写下一段。保持风格一致。',
        ),
        LLMMessage(role: 'user', content: text),
      ],
      maxTokens: 1024,
    );
    return _provider.streamText(request);
  }

  /// 三层生成 — 完整小说（梗概 + 大纲 + 第一章正文）
  Future<String> generateNovel(String idea,
      {String genre = '', String style = ''}) async {
    final request = LLMRequest(
      messages: [
        const LLMMessage(
            role: 'system',
            content: '你是专业小说创作助手。根据用户提供的创意、类型和风格，完成以下三项任务：\n\n'
                '【任务1：故事设定】\n'
                '世界观、时代背景、核心主题、主要人物（含性格特点）\n\n'
                '【任务2：第一卷大纲】\n'
                '第1章到第5章的章节标题和内容概要\n\n'
                '【任务3：第一章正文】\n'
                '基于以上设定和大纲，写出第一章的完整正文（不少于2000字）。\n'
                '要求：描写生动、对话自然、节奏紧凑、人物性格鲜明。\n\n'
                '输出格式：\n'
                '---\n'
                '## 故事设定\n'
                '...\n\n'
                '## 大纲\n'
                '### 第1章：xxx\n'
                '### 第2章：xxx\n'
                '...\n\n'
                '## 正文\n'
                '第1章正文内容...\n'),
        LLMMessage(role: 'user', content: '创意：$idea\n类型：$genre\n风格：$style'),
      ],
      maxTokens: 8192,
      temperature: 0.8,
    );
    return _provider.generateText(request);
  }

  /// 流式生成场景正文 (Layer3)
  Stream<String> streamNovelScene(String outline, String context) {
    final request = LLMRequest(
      messages: [
        const LLMMessage(
            role: 'system',
            content: '你是一个专业小说作者。根据大纲和上下文流式生成正文。注意保持人物性格一致、节奏紧凑。'),
        LLMMessage(role: 'user', content: '大纲：$outline\n\n上下文：$context'),
      ],
      maxTokens: 4096,
      temperature: 0.7,
    );
    return _provider.streamText(request);
  }
}
