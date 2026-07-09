import 'dart:async';
import '../../core/models/novel_structure.dart';
import '../../core/ai/llm_factory.dart';
import '../../core/ai/llm_models.dart';
import '../prompt_service.dart';

/// Layer 3 生成器 — 逐场景正文生成（流式）
///
/// 基于 Layer 2 的章节细纲，通过 LLM 流式生成完整正文。
class Layer3Generator {
  Layer3Generator({
    PromptService? promptService,
  }) : _promptService = promptService ?? PromptService();
  final PromptService _promptService;
  String providerName = 'free';

  /// 生成单个场景的正文（流式）
  Stream<String> generateScene({
    required SceneOutline scene,
    required String synopsis,
    required String characterContext,
    required String chapterContext,
    String? previousSceneSummary,
  }) {
    final prompt = _promptService.renderPrompt('stream_scene', {
      'sceneTitle': scene.title,
      'sceneSummary': scene.summary,
      'characters': scene.characters.join('、'),
      'location': scene.location,
      'mood': scene.mood ?? '平静',
      'conflict': scene.conflict ?? '',
      'synopsis': synopsis,
      'characterContext': characterContext,
      'previousSceneSummary': previousSceneSummary ?? '无',
    });

    final request = LLMRequest(
      messages: [LLMMessage(role: 'system', content: prompt)],
      temperature: 0.8,
      maxTokens: 2048,
    );

    return LLMFactory.create(providerName).streamText(request);
  }

  /// 生成完整章节（所有场景按顺序）
  Stream<String> generateChapter({
    required ChapterOutline chapter,
    required SynopsisAndCharacters synopsis,
  }) async* {
    for (var i = 0; i < chapter.scenes.length; i++) {
      final scene = chapter.scenes[i];
      final previous = i > 0 ? chapter.scenes[i - 1].summary : '';

      yield '\n\n【场景 ${scene.sceneNumber}：${scene.title}】\n\n';

      await for (final chunk in generateScene(
        scene: scene,
        synopsis: synopsis.synopsis,
        characterContext: synopsis.characters
            .map((c) => '${c.name}(${c.role})：${c.personality}')
            .join('；'),
        chapterContext: chapter.summary,
        previousSceneSummary: previous,
      )) {
        yield chunk;
      }

      yield '\n\n';
    }
  }
}
