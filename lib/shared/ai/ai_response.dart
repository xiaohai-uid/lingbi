/// AI 响应结构化输出模型
///
/// AI 响应不再作为单一纯文本字符串，而是由多个语义块组成。
/// 每个块有明确类型，UI 层据此进行分层渲染、折叠和复制控制。
library;

/// 响应块类型
enum AIBlockType {
  /// 思考/推理过程（流式时展开，完成后自动折叠）
  process,

  /// 最终回答（始终展开，视觉突出）
  answer,

  /// 工具调用活动（搜索、文件操作等）
  tool,

  /// 警告信息（上下文截断、模型降级等）
  warning,

  /// 候选正文（可直接采纳到编辑器的创作内容）
  candidate,

  /// 错误信息
  error,
}

/// AI 响应中的单个语义块
class AIResponseBlock {
  const AIResponseBlock({
    required this.type,
    required this.content,
    this.isStreaming = false,
    this.timestamp,
    this.metadata,
  });

  /// 块类型
  final AIBlockType type;

  /// 块文本内容
  final String content;

  /// 是否正在流式输出中
  final bool isStreaming;

  /// 块产生时间
  final DateTime? timestamp;

  /// 附加元数据（如工具名、错误码等）
  final Map<String, dynamic>? metadata;

  /// 是否为空内容
  bool get isEmpty => content.isEmpty;

  /// 复制内容（用于剪贴板）
  AIResponseBlock copyWith({
    AIBlockType? type,
    String? content,
    bool? isStreaming,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AIResponseBlock(
      type: type ?? this.type,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => '[${type.name}] $content';
}

/// 完整的 AI 响应（由多个块组成）
class AIResponse {
  AIResponse({List<AIResponseBlock>? blocks})
      : blocks = blocks ?? [],
        createdAt = DateTime.now();

  /// 响应包含的所有块（按时间顺序）
  final List<AIResponseBlock> blocks;

  /// 响应创建时间
  final DateTime createdAt;

  /// 是否仍在流式生成中
  bool get isStreaming => blocks.any((b) => b.isStreaming);

  /// 获取所有最终回答文本（用于复制）
  String get answerText => blocks
      .where((b) => b.type == AIBlockType.answer || b.type == AIBlockType.candidate)
      .map((b) => b.content)
      .join('\n\n');

  /// 获取所有候选正文
  List<AIResponseBlock> get candidates =>
      blocks.where((b) => b.type == AIBlockType.candidate).toList();

  /// 获取错误块（如果有）
  AIResponseBlock? get errorBlock {
    final errors = blocks.where((b) => b.type == AIBlockType.error);
    return errors.isEmpty ? null : errors.last;
  }

  /// 是否有错误
  bool get hasError => blocks.any((b) => b.type == AIBlockType.error);

  /// 追加文本到最后一个同类型块（流式更新用）
  void appendToLastBlock(AIBlockType type, String chunk) {
    if (blocks.isNotEmpty && blocks.last.type == type && blocks.last.isStreaming) {
      final last = blocks.last;
      blocks[blocks.length - 1] = last.copyWith(
        content: last.content + chunk,
      );
    } else {
      blocks.add(AIResponseBlock(
        type: type,
        content: chunk,
        isStreaming: true,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 标记所有块为流式结束
  void finishStreaming() {
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i].isStreaming) {
        blocks[i] = blocks[i].copyWith(isStreaming: false);
      }
    }
  }

  /// 添加一个完整的块
  void addBlock(AIResponseBlock block) {
    blocks.add(block);
  }

  /// 添加错误块
  void addError(String message, {Map<String, dynamic>? metadata}) {
    blocks.add(AIResponseBlock(
      type: AIBlockType.error,
      content: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// 添加警告块
  void addWarning(String message) {
    blocks.add(AIResponseBlock(
      type: AIBlockType.warning,
      content: message,
      timestamp: DateTime.now(),
    ));
  }
}

/// 流式 AI 响应事件的封装（用于 Stream）
sealed class AIStreamEvent {
  const AIStreamEvent();
}

/// 新的文本块到达
class AIStreamChunk extends AIStreamEvent {
  const AIStreamChunk({
    required this.type,
    required this.text,
  });

  final AIBlockType type;
  final String text;
}

/// 流式完成
class AIStreamDone extends AIStreamEvent {
  const AIStreamDone({this.response});

  final AIResponse? response;
}

/// 流式错误
class AIStreamError extends AIStreamEvent {
  const AIStreamError({
    required this.message,
    this.code,
    this.userHint,
  });

  final String message;
  final String? code;
  final String? userHint;
}
