import 'dart:async';
import '../../core/models/novel_structure.dart';
import '../../core/ai/llm_factory.dart';
import '../../core/ai/llm_models.dart';
import '../prompt_service.dart';
import '../memory_service.dart';
import 'package:drift/drift.dart' hide isNull;

/// Layer 3 生成器 — 逐场景正文生成（流式）
///
/// 基于 Layer 2 的章节细纲，通过 LLM 流式生成完整正文。
/// 支持通过 [MemoryService] 自动注入记忆上下文。
class Layer3Generator {
  Layer3Generator({
    PromptService? promptService,
    MemoryService? memoryService,
  })  : _promptService = promptService ?? PromptService(),
        _memoryService = memoryService;
  final PromptService _promptService;
  final MemoryService? _memoryService;
  String providerName = 'free';

  /// 生成单个场景的正文（流式）
  ///
  /// 如果配置了 [MemoryService]，会自动调用 [MemoryService.buildMemoryContext]
  /// 将记忆上下文追加到 system prompt 的 characterContext 后面。
  Stream<String> generateScene({
    required SceneOutline scene,
    required String synopsis,
    required String characterContext,
    required String chapterContext,
    String? previousSceneSummary,
    String? worldId,
    String? chapterId,
  }) async* {
    String memoryContext = '';

    if (_memoryService != null && worldId != null && chapterId != null) {
      try {
        memoryContext = await _memoryService!.buildMemoryContext(
          worldId: worldId,
          currentChapterId: chapterId,
        );
      } catch (_) {
        // 记忆上下文构建失败时不阻断生成
        memoryContext = '';
      }
    }

    final fullCharacterContext = memoryContext.isNotEmpty
        ? '$characterContext\n\n$memoryContext'
        : characterContext;

    final prompt = _promptService.renderPrompt('stream_scene', {
      'sceneTitle': scene.title,
      'sceneSummary': scene.summary,
      'characters': scene.characters.join('、'),
      'location': scene.location,
      'mood': scene.mood ?? '平静',
      'conflict': scene.conflict ?? '',
      'synopsis': synopsis,
      'characterContext': fullCharacterContext,
      'previousSceneSummary': previousSceneSummary ?? '无',
    });

    final request = LLMRequest(
      messages: [LLMMessage(role: 'system', content: prompt)],
      temperature: 0.8,
      maxTokens: [redacted],
    );

    yield* LLMFactory.create(providerName).streamText(request);
  }

  /// 生成完整章节（所有场景按顺序）
  Stream<String> generateChapter({
    required ChapterOutline chapter,
    required SynopsisAndCharacters synopsis,
    String? worldId,
    String? chapterId,
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
        worldId: worldId,
        chapterId: chapterId,
      )) {
        yield chunk;
      }

      yield '\n\n';
    }
  }
}
