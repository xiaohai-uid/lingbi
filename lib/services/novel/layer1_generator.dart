import '../../core/models/novel_structure.dart';
import '../../core/ai/llm_factory.dart';
import '../../core/ai/llm_models.dart';
import '../../core/ai/retry_handler.dart';
import '../prompt_service.dart';

/// Layer 1 生成器 — 从用户创意生成故事梗概和核心人设
///
/// 通过 LLMFactory 调用真实 LLM 生成结构化输出。
/// LLMFactory 是静态类，直接使用 LLMFactory.create() 调用。
class Layer1Generator {
  Layer1Generator({
    PromptService? promptService,
    RetryHandler? retryHandler,
  })  : _promptService = promptService ?? PromptService(),
        _retryHandler = retryHandler ?? const RetryHandler();
  final PromptService _promptService;
  final RetryHandler _retryHandler;
  String providerName = 'free';

  /// 设置使用的 LLM Provider 名称

  /// 生成故事梗概和核心人设
  Future<SynopsisAndCharacters> generate({
    required String userIdea,
    String genre = '玄幻',
    String style = 'qidian',
    int numCharacters = 4,
  }) async {
    if (userIdea.isEmpty) {
      return const SynopsisAndCharacters(synopsis: '');
    }

    final prompt = _promptService.renderPrompt('expand_idea', {
      'idea': userIdea,
      'genre': genre,
      'style': style,
      'numCharacters': numCharacters.toString(),
    });

    final request = LLMRequest(
      messages: [LLMMessage(role: 'system', content: prompt)],
      temperature: 0.8,
      maxTokens: 2048,
    );

    return _retryHandler.execute(() => LLMFactory.create(providerName)
            .generateStructured<SynopsisAndCharacters>(
          request,
          SynopsisAndCharacters.fromJson,
        ));
  }
}
