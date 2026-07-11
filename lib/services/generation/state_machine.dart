/// AI 小说生成状态机 — 精准逻辑实现
///
/// 设计文档: docs/generation-state-machine-v1.md
/// 纯逻辑层，不依赖 Flutter/UI
library;

// ═══════════════════════════════════════════════
// 1. 输入模型
// ═══════════════════════════════════════════════

class GenerationInput {
  final String idea;
  final String genre;
  final String style;
  final int? targetWords;

  const GenerationInput({
    required this.idea,
    this.genre = '玄幻',
    this.style = '起点爆款',
    this.targetWords,
  });

  bool get isValid =>
      idea.trim().length >= 10 &&
      _validGenres.contains(genre) &&
      _validStyles.contains(style);

  String? get validationError {
    if (idea.trim().isEmpty) return '请输入创意';
    if (idea.trim().length < 10) return '创意至少 10 个字';
    if (!_validGenres.contains(genre)) return '无效的小说类型';
    if (!_validStyles.contains(style)) return '无效的写作风格';
    return null;
  }

  static const _validGenres = ['玄幻', '仙侠', '都市', '科幻', '悬疑', '言情', '轻小说'];
  static const _validStyles = ['起点爆款', '番茄爽文', '传统文学', '轻小说'];
}

// ═══════════════════════════════════════════════
// 2. 结果模型
// ═══════════════════════════════════════════════

class CharacterBrief {
  final String name;
  final String role;
  final String personality;
  final String arc;
  const CharacterBrief({required this.name, this.role = 'protagonist', this.personality = '', this.arc = ''});
}

class SynopsisResult {
  final String synopsis;
  final List<CharacterBrief> characters;
  final String worldSettings;
  final String coreTheme;
  const SynopsisResult({required this.synopsis, this.characters = const [], this.worldSettings = '', this.coreTheme = ''});
  bool get isValid => synopsis.trim().length >= 100 && characters.isNotEmpty;
}

class SceneOutline {
  final int number;
  final String title;
  final String summary;
  final List<String> characters;
  final String location;
  const SceneOutline({required this.number, required this.title, this.summary = '', this.characters = const [], this.location = ''});
}

class ChapterOutline {
  final int number;
  final String title;
  final String summary;
  final List<SceneOutline> scenes;
  const ChapterOutline({required this.number, required this.title, this.summary = '', this.scenes = const []});
}

class VolumeOutline {
  final int number;
  final String title;
  final List<ChapterOutline> chapters;
  const VolumeOutline({required this.number, required this.title, this.chapters = const []});
}

class OutlineResult {
  final List<VolumeOutline> volumes;
  const OutlineResult({this.volumes = const []});
  bool get isValid => volumes.isNotEmpty && volumes.every((v) => v.chapters.length >= 3);
}

class ChapterContent {
  final int number;
  final String title;
  final String content;
  final int wordCount;
  final int generatedAt;
  const ChapterContent({required this.number, required this.title, this.content = '', this.wordCount = 0, this.generatedAt = 0});
}

class NovelResult {
  final SynopsisResult synopsis;
  final OutlineResult outline;
  final List<ChapterContent> chapters;
  const NovelResult({required this.synopsis, required this.outline, this.chapters = const []});
}

// ═══════════════════════════════════════════════
// 3. 生成元数据
// ═══════════════════════════════════════════════

class GenerationMeta {
  final int startedAt;
  final int phaseStartedAt;
  final int tokensUsed;
  final String streamedContent;

  const GenerationMeta({this.startedAt = 0, this.phaseStartedAt = 0, this.tokensUsed = 0, this.streamedContent = ''});

  GenerationMeta copyWith({int? startedAt, int? phaseStartedAt, int? tokensUsed, String? streamedContent}) =>
      GenerationMeta(
        startedAt: startedAt ?? this.startedAt,
        phaseStartedAt: phaseStartedAt ?? this.phaseStartedAt,
        tokensUsed: tokensUsed ?? this.tokensUsed,
        streamedContent: streamedContent ?? this.streamedContent,
      );

  static GenerationMeta initial() => GenerationMeta(
        startedAt: DateTime.now().millisecondsSinceEpoch,
        phaseStartedAt: DateTime.now().millisecondsSinceEpoch,
      );
}

// ═══════════════════════════════════════════════
// 4. 错误模型
// ═══════════════════════════════════════════════

class GenerationError {
  final String code;
  final String message;
  final bool retryable;
  final int? retryAfter;

  const GenerationError({required this.code, required this.message, this.retryable = false, this.retryAfter});

  static const network = GenerationError(code: 'NETWORK', message: '网络连接失败，请检查网络后重试', retryable: true);
  static const apiKeyInvalid = GenerationError(code: 'API_KEY_INVALID', message: 'API Key 无效，请在设置中更新', retryable: false);
  static const quotaExceeded = GenerationError(code: 'QUOTA_EXCEEDED', message: '今日配额已用完', retryable: false);
  static const timeout = GenerationError(code: 'TIMEOUT', message: '生成超时，请重试', retryable: true, retryAfter: 5);
  static const invalidOutput = GenerationError(code: 'INVALID_OUTPUT', message: 'AI 输出格式异常，已自动重试', retryable: true);
  static const unknown = GenerationError(code: 'UNKNOWN', message: '未知错误', retryable: true);
}

// ═══════════════════════════════════════════════
// 5. 状态 (sealed class)
// ═══════════════════════════════════════════════

sealed class GenerationState {
  const GenerationState();
}

class IdleState extends GenerationState { const IdleState(); }

class ReadyState extends GenerationState {
  final GenerationInput input;
  const ReadyState(this.input);
}

class GeneratingSynopsisState extends GenerationState {
  final GenerationInput input;
  final GenerationMeta meta;
  const GeneratingSynopsisState(this.input, this.meta);
}

class ReviewingSynopsisState extends GenerationState {
  final GenerationInput input;
  final SynopsisResult result;
  const ReviewingSynopsisState(this.input, this.result);
}

class GeneratingOutlineState extends GenerationState {
  final GenerationInput input;
  final SynopsisResult synopsis;
  final GenerationMeta meta;
  const GeneratingOutlineState(this.input, this.synopsis, this.meta);
}

class ReviewingOutlineState extends GenerationState {
  final GenerationInput input;
  final OutlineResult result;
  const ReviewingOutlineState(this.input, this.result);
}

class GeneratingContentState extends GenerationState {
  final GenerationInput input;
  final OutlineResult plan;
  final int currentChapter;
  final GenerationMeta meta;
  const GeneratingContentState(this.input, this.plan, this.currentChapter, this.meta);
}

class PausedState extends GenerationState {
  final GenerationInput input;
  final PausedSnapshot snapshot;
  const PausedState(this.input, this.snapshot);
}

class CompletedState extends GenerationState {
  final GenerationInput input;
  final NovelResult result;
  const CompletedState(this.input, this.result);
}

class ErrorState extends GenerationState {
  final GenerationInput input;
  final GenerationError error;
  final String from;
  const ErrorState(this.input, this.error, this.from);
}

class CancelledState extends GenerationState {
  final GenerationInput input;
  const CancelledState(this.input);
}

class PausedSnapshot {
  final String from;
  final String partialContent;
  final int? currentChapter;
  const PausedSnapshot({required this.from, this.partialContent = '', this.currentChapter});
}

class AwaitingChoiceState extends GenerationState {
  final GenerationInput input;
  final String generatedContent;
  final List<String> directions;
  const AwaitingChoiceState(this.input, this.generatedContent, this.directions);
}

// ═══════════════════════════════════════════════
// 6. 事件 (sealed class)
// ═══════════════════════════════════════════════

sealed class GenerationEvent { const GenerationEvent(); }

class SetInputEvent extends GenerationEvent {
  final GenerationInput input;
  const SetInputEvent(this.input);
}

class StartGenerationEvent extends GenerationEvent { const StartGenerationEvent(); }
class StreamChunkEvent extends GenerationEvent {
  final String chunk;
  const StreamChunkEvent(this.chunk);
}

class PhaseCompleteEvent extends GenerationEvent {
  final Object output;
  const PhaseCompleteEvent(this.output);
}

class ChapterCompleteEvent extends GenerationEvent {
  final ChapterContent content;
  const ChapterCompleteEvent(this.content);
}

class AllCompleteEvent extends GenerationEvent {
  final NovelResult result;
  const AllCompleteEvent(this.result);
}

class ConfirmEvent extends GenerationEvent {
  final String? feedback;
  const ConfirmEvent({this.feedback});
}

class RejectEvent extends GenerationEvent {
  final String? reason;
  const RejectEvent({this.reason});
}

class EditInputEvent extends GenerationEvent {
  final GenerationInput input;
  const EditInputEvent(this.input);
}

class PauseEvent extends GenerationEvent { const PauseEvent(); }
class ResumeEvent extends GenerationEvent { const ResumeEvent(); }
class CancelEvent extends GenerationEvent { const CancelEvent(); }
class RetryEvent extends GenerationEvent { const RetryEvent(); }
class ResetEvent extends GenerationEvent { const ResetEvent(); }
class CompleteSegmentEvent extends GenerationEvent {
  final String content;
  const CompleteSegmentEvent(this.content);
}
class SelectDirectionEvent extends GenerationEvent {
  final int index;
  const SelectDirectionEvent(this.index);
}

class ErrorEvent extends GenerationEvent {
  final GenerationError error;
  const ErrorEvent(this.error);
}

// ═══════════════════════════════════════════════
// 7. 状态机转换函数
// ═══════════════════════════════════════════════

GenerationState transition(GenerationState current, GenerationEvent event) {
  // 使用 if-else 链而非 pattern matching，避免 Dart 版本兼容问题
  final s = current;
  final e = event;

  // ---- idle ----
  if (s is IdleState && e is SetInputEvent && e.input.isValid) {
    return ReadyState(e.input);
  }

  // ---- ready ----
  if (s is ReadyState) {
    if (e is SetInputEvent) return ReadyState(e.input);
    if (e is StartGenerationEvent) return GeneratingSynopsisState(s.input, GenerationMeta.initial());
  }

  // ---- generating_synopsis ----
  if (s is GeneratingSynopsisState) {
    if (e is StreamChunkEvent) {
      final content = s.meta.streamedContent.length > 50000
          ? e.chunk
          : s.meta.streamedContent + e.chunk;
      return GeneratingSynopsisState(s.input, s.meta.copyWith(streamedContent: content));
    }
    if (e is PhaseCompleteEvent) return ReviewingSynopsisState(s.input, e.output as SynopsisResult);
    if (e is CancelEvent) return CancelledState(s.input);
    if (e is ErrorEvent) return ErrorState(s.input, e.error, 'generating_synopsis');
  }

  // ---- reviewing_synopsis ----
  if (s is ReviewingSynopsisState) {
    if (e is ConfirmEvent) return GeneratingOutlineState(s.input, s.result, GenerationMeta.initial());
    if (e is RejectEvent) return ReadyState(s.input);
    if (e is EditInputEvent) return ReadyState(e.input);
  }

  // ---- generating_outline ----
  if (s is GeneratingOutlineState) {
    if (e is StreamChunkEvent) {
      final content = s.meta.streamedContent.length > 50000
          ? e.chunk
          : s.meta.streamedContent + e.chunk;
      return GeneratingOutlineState(s.input, s.synopsis, s.meta.copyWith(streamedContent: content));
    }
    if (e is PhaseCompleteEvent) return ReviewingOutlineState(s.input, e.output as OutlineResult);
    if (e is CancelEvent) return CancelledState(s.input);
    if (e is ErrorEvent) return ErrorState(s.input, e.error, 'generating_outline');
  }

  // ---- reviewing_outline ----
  if (s is ReviewingOutlineState) {
    if (e is ConfirmEvent) {
      return GeneratingContentState(s.input, s.result, 0, GenerationMeta.initial());
    }
    if (e is RejectEvent) return ReadyState(s.input);
  }

  // ---- generating_content ----
  if (s is GeneratingContentState) {
    if (e is StreamChunkEvent) {
      final content = s.meta.streamedContent.length > 50000
          ? e.chunk
          : s.meta.streamedContent + e.chunk;
      return GeneratingContentState(s.input, s.plan, s.currentChapter, s.meta.copyWith(streamedContent: content));
    }
    if (e is ChapterCompleteEvent) {
      return GeneratingContentState(s.input, s.plan, s.currentChapter + 1, GenerationMeta.initial());
    }
    if (e is AllCompleteEvent) return CompletedState(s.input, e.result);
    if (e is PauseEvent) {
      return PausedState(s.input, PausedSnapshot(
        from: 'generating_content',
        partialContent: s.meta.streamedContent,
        currentChapter: s.currentChapter,
      ));
    }
    if (e is CancelEvent) return CancelledState(s.input);
    if (e is ErrorEvent) return ErrorState(s.input, e.error, 'generating_content');
    // 段落完成 → 进入选择方向
    if (e is CompleteSegmentEvent) {
      return AwaitingChoiceState(s.input, e.content, ['继续推进剧情', '展开场景描写', '发展人物关系']);
    }
  }

  // ---- awaiting_choice ----
  if (s is AwaitingChoiceState) {
    if (e is SelectDirectionEvent) {
      return GeneratingContentState(s.input, _defaultOutline, 0, GenerationMeta.initial());
    }
    if (e is CancelEvent) return CancelledState(s.input);
  }

  // ---- paused ----
  if (s is PausedState) {
    if (e is ResumeEvent) {
      return GeneratingContentState(s.input, _defaultOutline, 0, GenerationMeta.initial());
    }
    if (e is CancelEvent) return CancelledState(s.input);
  }

  // ---- error ----
  if (s is ErrorState) {
    if (e is ErrorEvent) return ErrorState(s.input, e.error, s.from);
    if (e is RetryEvent && s.error.retryable) return ReadyState(s.input);
    if (e is CancelEvent) return CancelledState(s.input);
  }

  // ---- cancelled ----
  if (s is CancelledState && e is ResetEvent) return ReadyState(s.input);

  // ---- completed ----
  if (s is CompletedState && e is ResetEvent) return const IdleState();

  // 非法转换 → 静默忽略
  return current;
}

final _defaultOutline = OutlineResult(volumes: [
  VolumeOutline(number: 1, title: '第一卷', chapters: [
    ChapterOutline(number: 1, title: '第一章', summary: ''),
  ]),
]);

// ═══════════════════════════════════════════════
// 8. 辅助函数
// ═══════════════════════════════════════════════

extension GenerationStateX on GenerationState {
  bool get canStart => this is ReadyState;

  bool get isGenerating =>
      this is GeneratingSynopsisState ||
      this is GeneratingOutlineState ||
      this is GeneratingContentState;

  bool get canConfirm => this is ReviewingSynopsisState || this is ReviewingOutlineState;
  bool get canCancel => isGenerating;
  bool get canPause => this is GeneratingContentState;
  bool get canRetry => this is ErrorState && (this as ErrorState).error.retryable;

  String get progressLabel {
    if (this is GeneratingSynopsisState) return '正在生成故事设定…';
    if (this is ReviewingSynopsisState) return '梗概已生成，请确认';
    if (this is GeneratingOutlineState) return '正在生成大纲…';
    if (this is ReviewingOutlineState) return '大纲已生成，请确认';
    if (this is GeneratingContentState) return '正在生成第 ${(this as GeneratingContentState).currentChapter + 1} 章…';
    if (this is PausedState) return '已暂停';
    if (this is ErrorState) return '错误: ${(this as ErrorState).error.message}';
    if (this is CancelledState) return '已取消';
    if (this is CompletedState) return '已完成';
    return '';
  }

  int get streamedWordCount {
    if (this is GeneratingSynopsisState) return _countChars((this as GeneratingSynopsisState).meta.streamedContent);
    if (this is GeneratingOutlineState) return _countChars((this as GeneratingOutlineState).meta.streamedContent);
    if (this is GeneratingContentState) return _countChars((this as GeneratingContentState).meta.streamedContent);
    return 0;
  }
}

int _countChars(String s) => s.replaceAll(RegExp(r'\s'), '').length;