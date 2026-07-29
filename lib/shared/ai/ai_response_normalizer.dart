/// AI 响应规范化器
///
/// 在现有 Provider 的 `Stream<String>` 之上工作，不修改 Provider 架构。
/// 将原始文本流转换为结构化的 [NormalizedBlock] 序列。
///
/// `<think>` 和 `<analysis>` 只作为不可信的过程文本标记处理，
/// 不称为完整内部思考。
library;

import 'dart:async';

/// 规范化块类型
enum NormalizedBlockType {
  /// 过程信息（`<think>`/`<analysis>` 标记内容，不可信）
  process,

  /// 最终回答
  answer,

  /// 候选正文（创作内容，可采纳到编辑器）
  candidate,

  /// 工具活动
  tool,

  /// 警告
  warning,

  /// 错误
  error,
}

/// 规范化后的单个块
class NormalizedBlock {
  const NormalizedBlock({
    required this.type,
    required this.text,
    this.isComplete = false,
  });

  final NormalizedBlockType type;
  final String text;
  final bool isComplete;

  bool get isEmpty => text.isEmpty;

  NormalizedBlock copyWith({String? text, bool? isComplete}) {
    return NormalizedBlock(
      type: type,
      text: text ?? this.text,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// 规范化事件（用于 Stream 输出）
sealed class NormalizerEvent {
  const NormalizerEvent();
}

/// 增量文本到达
class NormalizerChunk extends NormalizerEvent {
  const NormalizerChunk({required this.block});
  final NormalizedBlock block;
}

/// 流结束
class NormalizerDone extends NormalizerEvent {
  const NormalizerDone({required this.blocks});
  final List<NormalizedBlock> blocks;
}

/// 流错误
class NormalizerError extends NormalizerEvent {
  const NormalizerError({required this.message, this.partialBlocks = const []});
  final String message;
  final List<NormalizedBlock> partialBlocks;
}

/// AI 响应规范化器
///
/// 用法：
/// ```dart
/// final normalizer = AiResponseNormalizer();
/// await for (final event in normalizer.normalize(rawStream)) {
///   switch (event) {
///     case NormalizerChunk(:final block): // 处理增量
///     case NormalizerDone(:final blocks): // 完成
///     case NormalizerError(:final message): // 错误
///   }
/// }
/// ```
class AiResponseNormalizer {
  AiResponseNormalizer({this.treatAllAsCandidate = false});

  /// 是否将所有非过程输出视为候选正文（技能生成模式）
  final bool treatAllAsCandidate;

  // 解析状态
  bool _inThinkTag = false;
  bool _inAnalysisTag = false;
  final StringBuffer _pendingBuffer = StringBuffer();
  final List<NormalizedBlock> _completedBlocks = [];

  /// 将原始 `Stream<String>` 转换为结构化事件流
  Stream<NormalizerEvent> normalize(Stream<String> rawStream) async* {
    _reset();

    try {
      await for (final chunk in rawStream) {
        _pendingBuffer.write(chunk);
        final events = _processBuffer();
        for (final event in events) {
          yield event;
        }
      }

      // 流结束，刷新剩余缓冲
      final remaining = _pendingBuffer.toString();
      if (remaining.isNotEmpty) {
        final type = _currentBlockType();
        _completedBlocks.add(NormalizedBlock(
          type: type,
          text: remaining,
          isComplete: true,
        ));
        yield NormalizerChunk(block: NormalizedBlock(
          type: type,
          text: remaining,
          isComplete: true,
        ));
      }

      // 推理模型兜底：可见正文为空但存在过程文本（<think>/<analysis>），
      // 提示用户当前模型为推理模型，建议切换，避免“转半天没字”。
      if (_shouldWarnReasoningOnly()) {
        const warn = NormalizedBlock(
          type: NormalizedBlockType.warning,
          text: '当前模型疑似为推理模型：全部输出都在思考过程中，可见正文为空。'
              '建议在设置中切换为非推理模型（如 deepseek-v4-flash）后重试。',
          isComplete: true,
        );
        _completedBlocks.add(warn);
        yield const NormalizerChunk(block: warn);
      }

      yield NormalizerDone(blocks: List.unmodifiable(_completedBlocks));
    } catch (e) {
      yield NormalizerError(
        message: e.toString(),
        partialBlocks: List.unmodifiable(_completedBlocks),
      );
    }
  }

  /// 同步规范化完整文本（非流式场景）
  List<NormalizedBlock> normalizeSync(String rawText) {
    _reset();
    _pendingBuffer.write(rawText);
    _processBuffer();

    // 刷新剩余
    final remaining = _pendingBuffer.toString();
    if (remaining.isNotEmpty) {
      _completedBlocks.add(NormalizedBlock(
        type: _currentBlockType(),
        text: remaining,
        isComplete: true,
      ));
    }
    return List.unmodifiable(_completedBlocks);
  }

  /// 获取最终回答文本（用于复制）
  static String extractAnswerText(List<NormalizedBlock> blocks) {
    return blocks
        .where((b) =>
            b.type == NormalizedBlockType.answer ||
            b.type == NormalizedBlockType.candidate)
        .map((b) => b.text)
        .join();
  }

  /// 获取过程文本
  static String extractProcessText(List<NormalizedBlock> blocks) {
    return blocks
        .where((b) => b.type == NormalizedBlockType.process)
        .map((b) => b.text)
        .join();
  }

  // ─── 内部解析逻辑 ─────────────────────────────────────────────

  void _reset() {
    _inThinkTag = false;
    _inAnalysisTag = false;
    _pendingBuffer.clear();
    _completedBlocks.clear();
  }

  NormalizedBlockType _currentBlockType() {
    if (_inThinkTag || _inAnalysisTag) return NormalizedBlockType.process;
    return treatAllAsCandidate
        ? NormalizedBlockType.candidate
        : NormalizedBlockType.answer;
  }

  /// 判断是否应给出“推理模型可见正文为空”的兜底提示。
  bool _shouldWarnReasoningOnly() {
    final hasProcess = _completedBlocks.any(
      (b) => b.type == NormalizedBlockType.process && b.text.trim().isNotEmpty,
    );
    if (!hasProcess) return false;
    final hasVisible = _completedBlocks.any(
      (b) =>
          (b.type == NormalizedBlockType.answer ||
              b.type == NormalizedBlockType.candidate) &&
          b.text.trim().isNotEmpty,
    );
    return !hasVisible;
  }

  /// 处理缓冲区，识别标签边界
  List<NormalizerEvent> _processBuffer() {
    final events = <NormalizerEvent>[];
    var content = _pendingBuffer.toString();

    // 循环处理直到没有更多完整标签
    var processed = true;
    while (processed) {
      processed = false;

      if (!_inThinkTag && !_inAnalysisTag) {
        // 检测 <think> 开始标签
        final thinkStart = content.indexOf('<think>');
        final analysisStart = content.indexOf('<analysis>');

        if (thinkStart >= 0 &&
            (analysisStart < 0 || thinkStart < analysisStart)) {
          // 输出标签前的正文
          if (thinkStart > 0) {
            final before = content.substring(0, thinkStart);
            final type = _currentBlockType();
            _completedBlocks.add(NormalizedBlock(type: type, text: before));
            events.add(NormalizerChunk(
                block: NormalizedBlock(type: type, text: before)));
          }
          content = content.substring(thinkStart + 7);
          _inThinkTag = true;
          processed = true;
        } else if (analysisStart >= 0) {
          if (analysisStart > 0) {
            final before = content.substring(0, analysisStart);
            final type = _currentBlockType();
            _completedBlocks.add(NormalizedBlock(type: type, text: before));
            events.add(NormalizerChunk(
                block: NormalizedBlock(type: type, text: before)));
          }
          content = content.substring(analysisStart + 10);
          _inAnalysisTag = true;
          processed = true;
        } else {
          // 无标签，检查是否有不完整的标签前缀（等待更多数据）
          final safeEnd = _findSafeBoundary(content);
          if (safeEnd > 0) {
            final safe = content.substring(0, safeEnd);
            final type = _currentBlockType();
            _completedBlocks.add(NormalizedBlock(type: type, text: safe));
            events.add(NormalizerChunk(
                block: NormalizedBlock(type: type, text: safe)));
            content = content.substring(safeEnd);
          }
          break;
        }
      } else {
        // 在过程标签内
        final closeTag = _inThinkTag ? '</think>' : '</analysis>';
        final closeIdx = content.indexOf(closeTag);

        if (closeIdx >= 0) {
          // 输出过程内容
          final processText = content.substring(0, closeIdx);
          if (processText.isNotEmpty) {
            _completedBlocks.add(const NormalizedBlock(
              type: NormalizedBlockType.process,
              text: '',
            ).copyWith(text: processText));
            events.add(NormalizerChunk(block: NormalizedBlock(
              type: NormalizedBlockType.process,
              text: processText,
            )));
          }
          content = content.substring(closeIdx + closeTag.length);
          _inThinkTag = false;
          _inAnalysisTag = false;
          processed = true;
        } else {
          // 标签未关闭，检查是否有不完整的关闭标签前缀
          final safeEnd = _findSafeCloseBoundary(content, closeTag);
          if (safeEnd > 0) {
            final safe = content.substring(0, safeEnd);
            _completedBlocks.add(NormalizedBlock(
              type: NormalizedBlockType.process,
              text: safe,
            ));
            events.add(NormalizerChunk(block: NormalizedBlock(
              type: NormalizedBlockType.process,
              text: safe,
            )));
            content = content.substring(safeEnd);
          }
          break;
        }
      }
    }

    _pendingBuffer
      ..clear()
      ..write(content);
    return events;
  }

  /// 找到安全输出边界（避免截断可能的标签开头）
  int _findSafeBoundary(String content) {
    // 检查末尾是否有 '<' 可能是标签开头
    final lastLt = content.lastIndexOf('<');
    if (lastLt >= 0 && lastLt > content.length - 10) {
      // 可能是 <think> 或 <analysis> 的开头
      final tail = content.substring(lastLt);
      if ('<think>'.startsWith(tail) || '<analysis>'.startsWith(tail)) {
        return lastLt;
      }
    }
    return content.length;
  }

  /// 找到过程标签内的安全输出边界
  int _findSafeCloseBoundary(String content, String closeTag) {
    final lastLt = content.lastIndexOf('<');
    if (lastLt >= 0 && lastLt > content.length - closeTag.length - 2) {
      final tail = content.substring(lastLt);
      if (closeTag.startsWith(tail)) {
        return lastLt;
      }
    }
    // 保留最后几个字符以防跨 chunk 的标签
    if (content.length > 4) return content.length - 4;
    return 0;
  }
}
