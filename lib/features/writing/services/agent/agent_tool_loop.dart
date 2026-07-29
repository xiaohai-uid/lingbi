/// AgentToolLoop — 真 function-calling 的多轮工具循环。
///
/// 对标 OpenWrite 的对话式 Agent：把[AgentToolRegistry.specs]交给模型，
/// 模型自主决定读文件 / 写章节 / 提问 / 查 Skill，循环回灌工具结果直到
/// 模型给出最终答复（finishReason='stop'）或达到 maxIterations。
///
/// 关键工程约束（符合"模型控制走 Skill/Agent 沙箱"）：
/// - 模型只能通过 [AgentToolRegistry] 声明的受控工具影响外部世界；
/// - **能力探测 + 回退**：Provider 不支持工具（或运行期拒绝）时，
///   自动回退到确定性的 NovelWritingLoop，保证免费模型也能出稿。
library;

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/features/writing/services/agent/novel_writing_loop.dart';
import 'package:lingbi/features/writing/services/agent/session_compactor.dart';

/// Agent 执行过程中的一步（供 UI 渲染时间线 / 测试断言）。
class AgentStep {
  const AgentStep({
    required this.kind,
    required this.text,
    this.toolName,
  });

  /// 'thinking' 模型思考文本 | 'tool' 工具执行 | 'final' 最终答复
  /// | 'error' 错误 | 'fallback' 回退提示。
  final String kind;
  final String text;
  final String? toolName;
}

/// Agent 一次完整运行的结果。
class AgentRunResult {
  const AgentRunResult({
    required this.finalText,
    required this.steps,
    required this.usedFallback,
    this.iterations = 0,
  });

  /// 模型最终答复（回退时为回退产物正文）。
  final String finalText;
  final List<AgentStep> steps;

  /// 是否走了确定性回退流程。
  final bool usedFallback;

  /// 实际发生的工具循环轮数。
  final int iterations;
}

/// 多轮工具循环编排器。
class AgentToolLoop {
  AgentToolLoop({
    required this.provider,
    required this.registry,
    this.fallback,
    SessionCompactor? compactor,
    this.maxIterations = 8,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.onStep,
  }) : compactor = compactor ?? SessionCompactor.forProvider(provider);

  final AIProvider provider;
  final AgentToolRegistry registry;

  /// 不支持工具时的回退编排器；为 null 时退化为普通对话。
  final NovelWritingLoop? fallback;

  /// 会话级上下文压缩器（逼近预算时折叠早期消息）。
  final SessionCompactor compactor;

  final int maxIterations;
  final double temperature;
  final int maxTokens;

  /// 步骤回调（实时上报给 UI）。
  final void Function(AgentStep step)? onStep;

  /// 运行 Agent：以 [systemPrompt] 为系统指令、[userGoal] 为任务目标。
  Future<AgentRunResult> run({
    required String systemPrompt,
    required String userGoal,
  }) async {
    final steps = <AgentStep>[];
    void emit(AgentStep s) {
      steps.add(s);
      onStep?.call(s);
    }

    if (!provider.supportsTools) {
      emit(const AgentStep(
        kind: 'fallback',
        text: '当前模型不支持工具调用，已回退到确定性写作流程。',
      ));
      final text = await _runFallback(userGoal, emit);
      return AgentRunResult(
        finalText: text,
        steps: steps,
        usedFallback: true,
      );
    }

    final messages = <ChatMessage>[
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: userGoal),
    ];
    final tools = registry.specs;

    var iterations = 0;
    final finalBuffer = StringBuffer();

    while (iterations < maxIterations) {
      iterations++;

      // 逼近上下文预算时折叠早期消息，避免撑爆窗口（p7）。
      final compacted = compactor.compact(messages);
      if (compacted.length != messages.length) {
        messages
          ..clear()
          ..addAll(compacted);
        emit(const AgentStep(
          kind: 'thinking',
          text: '上下文接近预算，已折叠较早的对话以腾出空间。',
        ));
      }

      final ToolTurn turn;
      try {
        turn = await provider.chatWithTools(
          messages: messages,
          tools: tools,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } on UnsupportedError {
        // 能力探测漏判：运行期才发现不支持 → 回退。
        emit(const AgentStep(
          kind: 'fallback',
          text: '模型运行期拒绝工具调用，已回退到确定性流程。',
        ));
        final text = await _runFallback(userGoal, emit);
        return AgentRunResult(
          finalText: text,
          steps: steps,
          usedFallback: true,
          iterations: iterations,
        );
      }

      if (turn.content.trim().isNotEmpty) {
        emit(AgentStep(kind: 'thinking', text: turn.content.trim()));
      }

      if (!turn.hasToolCalls) {
        // 模型给出最终答复，循环结束。
        finalBuffer.write(turn.content);
        emit(AgentStep(kind: 'final', text: turn.content.trim()));
        break;
      }

      // 追加 assistant 的 tool_calls 请求消息（协议要求回灌）。
      messages.add(ChatMessage(
        role: 'assistant',
        content: turn.content,
        toolCalls: turn.toolCalls,
      ));

      // 逐个执行工具调用，把结果以 role:'tool' 追加。
      for (final call in turn.toolCalls) {
        final result = await registry.execute(call);
        emit(AgentStep(
          kind: result.isError ? 'error' : 'tool',
          text: result.display ?? call.name,
          toolName: call.name,
        ));
        messages.add(ChatMessage(
          role: 'tool',
          content: result.content,
          toolCallId: call.id,
          name: call.name,
        ));
      }
    }

    if (iterations >= maxIterations && finalBuffer.isEmpty) {
      emit(AgentStep(
        kind: 'error',
        text: '已达到最大工具轮次（$maxIterations），请缩小任务范围或手动继续。',
      ));
    }

    return AgentRunResult(
      finalText: finalBuffer.toString().trim(),
      steps: steps,
      usedFallback: false,
      iterations: iterations,
    );
  }

  /// 回退到确定性写作循环；无回退编排器时退化为一次普通对话。
  Future<String> _runFallback(
    String userGoal,
    void Function(AgentStep) emit,
  ) async {
    final fb = fallback;
    if (fb == null) {
      final text = await provider.chatSync(
        messages: [ChatMessage(role: 'user', content: userGoal)],
        temperature: temperature,
        maxTokens: maxTokens,
      );
      emit(AgentStep(kind: 'final', text: text.trim()));
      return text;
    }
    final result = await fb.writeNextChapter(
      guidance: userGoal,
      autoApprove: true,
    );
    if (result == null) {
      emit(const AgentStep(kind: 'error', text: '回退流程未产出章节。'));
      return '';
    }
    emit(AgentStep(
      kind: 'tool',
      text: '确定性流程已写入 ${result.chapterPath}',
      toolName: 'file_write',
    ));
    final content = result.candidate.content;
    emit(AgentStep(kind: 'final', text: content.trim()));
    return content;
  }
}
