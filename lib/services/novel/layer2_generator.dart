import 'dart:convert';
import '../../core/models/novel_structure.dart';
import '../../core/ai/llm_factory.dart';
import '../../core/ai/llm_models.dart';
import '../../core/ai/retry_handler.dart';
import '../prompt_service.dart';

/// Layer 2 生成器 — 基于故事梗概生成卷章细纲
///
/// 通过 LLMFactory 调用真实 LLM 生成结构化细纲。
class Layer2Generator {
  Layer2Generator({
    PromptService? promptService,
    RetryHandler? retryHandler,
  })  : _promptService = promptService ?? PromptService(),
        _retryHandler = retryHandler ?? const RetryHandler();
  final PromptService _promptService;
  final RetryHandler _retryHandler;
  String providerName = 'free';

  /// 生成分卷结构
  Future<LayeredNovelStructure> generate({
    required SynopsisAndCharacters synopsis,
    int numVolumes = 3,
    int chaptersPerVolume = 10,
    int scenesPerChapter = 4,
  }) async {
    final prompt = _promptService.renderPrompt('generate_outline', {
      'synopsis': jsonEncode(synopsis.toJson()),
      'numVolumes': numVolumes.toString(),
      'chaptersPerVolume': chaptersPerVolume.toString(),
      'scenesPerChapter': scenesPerChapter.toString(),
    });

    final request = LLMRequest(
      messages: [LLMMessage(role: 'system', content: prompt)],
      temperature: 0.7,
      maxTokens: 4096,
    );

    return _retryHandler.execute(() => LLMFactory.create(providerName)
            .generateStructured<LayeredNovelStructure>(
          request,
          LayeredNovelStructure.fromJson,
        ));
  }
}
