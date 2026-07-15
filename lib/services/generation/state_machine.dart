/// AI 小说生成状态机 — 精准逻辑实现
///
/// 设计文档: docs/generation-state-machine-v1.md
/// 纯逻辑层，不依赖 Flutter/UI
library;

// ═══════════════════════════════════════════════
// 1. 输入模型
// ═══════════════════════════════════════════════

class GenerationInput {

  const GenerationInput({
    required this.idea,
    this.genre = '玄幻',
    this.style = '起点爆款',
    this.targetWords,
  });
  final String idea;
  final String genre;
  final String style;
  final int? targetWords;

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
  const CharacterBrief({required this.name, this.role = 'protagonist', this.personality = '', this.arc = ''});
  final String name;
  final String role;
  final String personality;
  final String arc;
}

class SynopsisResult {
  const SynopsisResult({required this.synopsis, this.characters = const [], this.worldSettings = '', this.coreTheme = ''});
  final String synopsis;
  final List<CharacterBrief> characters;
  final String worldSettings;
  final String coreTheme;
  bool get isValid => synopsis.trim().length >= 100 && characters.isNotEmpty;
}

class SceneOutline {
  const SceneOutline({required this.number, required this.title, this.summary = '', this.characters = const [], this.location = ''});
  final int number;
  final String title;
  final String summary;
  final List<String> characters;
  final String location;
}

class ChapterOutline {
  const ChapterOutline({required this.number, required this.title, this.summary = '', this.scenes = const []});
  final int number;
  final String title;
  final String summary;
  final List<SceneOutline> scenes;
}

class VolumeOutline {
  const VolumeOutline({required this.number, required this.title, this.chapters = const []});
  final int number;
  final String title;
  final List<ChapterOutline> chapters;
}

class OutlineResult {
  const OutlineResult({this.volumes = const []});
  final List<VolumeOutline> volumes;
  bool get isValid => volumes.isNotEmpty && volumes.every((v) => v.chapters.length >= 3);
}

class ChapterContent {
  const ChapterContent({required this.number, required this.title, this.content = '', this.wordCount = 0, this.generatedAt = 0});
  final int number;
  final String title;
  final String content;
  final int wordCount;
  final int generatedAt;
}

class NovelResult {
  const NovelResult({required this.synopsis, required this.outline, this.chapters = const []});
  final SynopsisResult synopsis;
  final OutlineResult outline;
  final List<ChapterContent> chapters;
}

// ═══════════════════════════════════════════════
// 3. 生成元数据
// ═══════════════════════════════════════════════

class GenerationMeta {

  const GenerationMeta({this.startedAt = 0, this.phaseStartedAt = 0, this.tokensUsed = 0, this.streamedContent = ''});
  final int startedAt;
  final int phaseStartedAt;
  final int tokensUsed;
  final String streamedContent;

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

  const GenerationError({required this.code, required this.message, this.retryable = false, this.retryAfter});
  final String code;
  final String message;
  final bool retryable;
  final int? retryAfter;

  static const network = GenerationError(code: 'NETWORK', message: '网络连接失败，请检查网络后重试', retryable: true);
  static const apiKeyInvalid = GenerationError(code: 'API_KEY_INVALID', message: 'API Key 无效，请在设置中更新');
  static const quotaExceeded = GenerationError(code: 'QUOTA_EXCEEDED', message: '今日配额已用完');
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
  const ReadyState(this.input);
  final GenerationInput input;
}

class GeneratingSynopsisState extends GenerationState {
  const GeneratingSynopsisState(this.input, this.meta);
  final GenerationInput input;
  final GenerationMeta meta;
}

class ReviewingSynopsisState extends GenerationState {
  const ReviewingSynopsisState(this.input, this.result);
  final GenerationInput input;
  final SynopsisResult result;
}

class GeneratingOutlineState extends GenerationState {
  const GeneratingOutlineState(this.input, this.synopsis, this.meta);
  final GenerationInput input;
  final SynopsisResult synopsis;
  final GenerationMeta meta;
}

class ReviewingOutlineState extends GenerationState {
  const ReviewingOutlineState(this.input, this.result);
  final GenerationInput input;
  final OutlineResult result;
}

class GeneratingContentState extends GenerationState {
  const GeneratingContentState(this.input, this.plan, this.currentChapter, this.meta);
  final GenerationInput input;
  final OutlineResult plan;
  final int currentChapter;
  final GenerationMeta meta;
}

class PausedState extends GenerationState {
  const PausedState(this.input, this.snapshot);
  final GenerationInput input;
  final PausedSnapshot snapshot;
}

class CompletedState extends GenerationState {
  const CompletedState(this.input, this.result);
  final GenerationInput input;
  final NovelResult result;
}

class ErrorState extends GenerationState {
  const ErrorState(this.input, this.error, this.from);
  final GenerationInput input;
  final GenerationError error;
  final String from;
}

class CancelledState extends GenerationState {
  const CancelledState(this.input);
  final GenerationInput input;
}

class PausedSnapshot {
  const PausedSnapshot({required this.from, this.partialContent = '', this.currentChapter});
  final String from;
  final String partialContent;
  final int? currentChapter;
}

class AwaitingChoiceState extends GenerationState {
  const AwaitingChoiceState(this.input, this.generatedContent, this.directions);
  final GenerationInput input;
  final String generatedContent;
  final List<String> directions;
}

// ═══════════════════════════════════════════════
// 6. 事件 (sealed class)
// ═══════════════════════════════════════════════

sealed class GenerationEvent { const GenerationEvent(); }

class SetInputEvent extends GenerationEvent {
  const SetInputEvent(this.input);
  final GenerationInput input;
}

class StartGenerationEvent extends GenerationEvent { const StartGenerationEvent(); }
class StreamChunkEvent extends GenerationEvent {
  const StreamChunkEvent(this.chunk);
  final String chunk;
}

class PhaseCompleteEvent extends GenerationEvent {
  const PhaseCompleteEvent(this.output);
  final Object output;
}

class ChapterCompleteEvent extends GenerationEvent {
  const ChapterCompleteEvent(this.content);
  final ChapterContent content;
}

class AllCompleteEvent extends GenerationEvent {
  const AllCompleteEvent(this.result);
  final NovelResult result;
}

class ConfirmEvent extends GenerationEvent {
  const ConfirmEvent({this.feedback});
  final String? feedback;
}

class RejectEvent extends GenerationEvent {
  const RejectEvent({this.reason});
  final String? reason;
}

class EditInputEvent extends GenerationEvent {
  const EditInputEvent(this.input);
  final GenerationInput input;
}

class PauseEvent extends GenerationEvent { const PauseEvent(); }
class ResumeEvent extends GenerationEvent { const ResumeEvent(); }
class CancelEvent extends GenerationEvent { const CancelEvent(); }
class RetryEvent extends GenerationEvent { const RetryEvent(); }
class ResetEvent extends GenerationEvent { const ResetEvent(); }
class CompleteSegmentEvent extends GenerationEvent {
  const CompleteSegmentEvent(this.content);
  final String content;
}
class SelectDirectionEvent extends GenerationEvent {
  const SelectDirectionEvent(this.index);
  final int index;
}

class ErrorEvent extends GenerationEvent {
  const ErrorEvent(this.error);
  final GenerationError error;
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

const _defaultOutline = OutlineResult(volumes: [
  VolumeOutline(number: 1, title: '第一卷', chapters: [
    ChapterOutline(number: 1, title: '第一章'),
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
