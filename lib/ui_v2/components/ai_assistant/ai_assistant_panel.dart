import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingbi/shared/ai/ai_response_normalizer.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_loop.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/features/writing/services/agent/novel_writing_loop.dart';
import 'package:lingbi/services/agent_writing_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/skill/data/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/features/review/data/clarity_check_service.dart';
import '../../theme/tokens.dart';
import '../../theme/lingbi_icons.dart';
import '../model_selector.dart';
import 'chat_input_bar.dart';
import 'chat_message.dart';
import 'message_builders.dart';

class AiAssistantPanel extends StatefulWidget {
  const AiAssistantPanel({
    super.key,
    this.projectId,
    this.projectName,
    this.onConvertToCandidate,
  });
  final String? projectId;
  final String? projectName;

  /// "转为候选"回调 — 将 AI 回复转入 CandidateService，不直接修改编辑器
  final ValueChanged<String>? onConvertToCandidate;

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final AIService _aiService = ServiceLocator.instance.aiService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ClarityCheckService _clarityCheck = ClarityCheckService();
  bool _isLoading = false;
  AgentToolLoop? _activeLoop; // Phase 1.3: 保存当前循环引用以支持取消
  Completer<String>? _pendingAgentCompleter;
  int? _pendingAgentQuestionIndex;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _setupProjectContext();
    }
  }

  @override
  void didUpdateWidget(AiAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 项目切换由 ValueKey(projectId) 强制重建 State 来隔离（R4）；
    // 这里仅处理同项目改名时的上下文刷新。
    if (widget.projectId == oldWidget.projectId &&
        widget.projectName != oldWidget.projectName) {
      _setupProjectContext();
    }
  }

  void _setupProjectContext() {
    final name = widget.projectName ?? '';
    _aiService.setProjectContext('项目名称：$name\n项目 ID：${widget.projectId}');
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Phase 1.3: 停止当前生成。
  void _cancelGeneration() {
    final pending = _pendingAgentCompleter;
    final questionIndex = _pendingAgentQuestionIndex;
    if (pending != null &&
        questionIndex != null &&
        questionIndex < _messages.length &&
        !pending.isCompleted) {
      _onAgentOptionSelected(questionIndex, '跳过');
    } else if (pending != null && !pending.isCompleted) {
      pending.complete('跳过');
      _pendingAgentCompleter = null;
      _pendingAgentQuestionIndex = null;
    }
    _activeLoop?.cancel();
    _activeLoop = null;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (overrideText == null) _inputController.clear();

    // T4: 清晰度检查
    final clarityResult = _clarityCheck.assess(text);
    if (clarityResult.needsClarification) {
      setState(() {
        _messages.add(ChatMessage(content: text, isUser: true));
        _messages.add(ChatMessage(
          content: '',
          isUser: false,
          isClarification: true,
          clarifyQuestion: clarityResult.question,
          quickOptions: clarityResult.quickOptions,
          originalMessage: text,
        ));
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      if (overrideText == null) {
        _messages.add(ChatMessage(content: text, isUser: true));
      }
      _messages.add(ChatMessage(
        content: '',
        isUser: false,
        isStreaming: true,
        isThinking: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    final entryIndex = _messages.length - 1;

    // A1: 项目打开时统一走 Agent 工具循环（对标 OpenWrite "对话即写作"）
    if (widget.projectId != null) {
      await _sendViaAgent(text, entryIndex);
    } else {
      await _sendViaSimpleChat(text, entryIndex);
    }
  }

  /// A1: Agent 工具循环路径 — AI 自主决定读文件/写文件/提问/查 Skill。
  Future<void> _sendViaAgent(String text, int entryIndex) async {
    final project = await ServiceLocator.instance.projectService
        .getProject(widget.projectId!);
    final dir = project?.directoryPath;
    if (dir == null || dir.isEmpty) {
      // 项目目录不可用时回退到简单聊天
      await _sendViaSimpleChat(text, entryIndex);
      return;
    }

    // 可变索引：提问回答后更新为新的流式占位消息位置，避免顺序倒置。
    var activeIndex = entryIndex;

    final provider = _aiService.currentProvider;
    AgentToolLoop? loop;
    final registry = AgentToolRegistry(
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      mutationProtocol: ServiceLocator.instance.mutationProtocol,
      confirmWrite: _confirmToolWrite,
      askUser: (question, options) async {
        // 提问前结束旧流式气泡，避免永久“思考中”
        if (mounted) {
          setState(() {
            final old = _messages[activeIndex];
            // 没有任何可展示内容的占位气泡直接移除；否则保留已完成的
            // 工具时间线，但明确结束流式状态，避免留下空白气泡。
            if (old.content.isEmpty &&
                old.processContent.isEmpty &&
                old.toolSteps.isEmpty) {
              _messages.removeAt(activeIndex);
            } else {
              _messages[activeIndex] = ChatMessage(
                content: old.content,
                isUser: false,
                processContent: old.processContent,
                toolSteps: old.toolSteps,
              );
            }
          });
        }
        final answer = await _askUserFromAgent(question, options);
        // 回答后插入新的流式占位，后续步骤写入新位置
        if (mounted && identical(_activeLoop, loop)) {
          setState(() {
            _messages.add(ChatMessage(
              content: '',
              isUser: false,
              isStreaming: true,
              isThinking: true,
            ));
            activeIndex = _messages.length - 1;
          });
        }
        return answer;
      },
      skillLookup: _skillLookup,
      onToolEvent: (name, display) {},
      versionHistoryService: ServiceLocator.instance.versionHistoryService,
    );
    final fallback = NovelWritingLoop(
      provider: provider,
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      canonService: ServiceLocator.instance.canonService,
      projectId: widget.projectId,
      versionHistoryService: ServiceLocator.instance.versionHistoryService,
    );
    loop = AgentToolLoop(
      provider: provider,
      registry: registry,
      fallback: fallback,
      maxIterations: 50,
      onStep: (step) {
        if (!mounted) return;
        setState(() {
          final m = _messages[activeIndex];
          _messages[activeIndex] = ChatMessage(
            content: step.kind == 'final' ? step.text : m.content,
            isUser: false,
            isStreaming: true,
            isThinking: step.kind != 'final',
            toolSteps: [...m.toolSteps, step],
          );
        });
        _scrollToBottom();
      },
    );
    _activeLoop = loop; // Phase 1.3: 保存引用以支持取消

    try {
      final result = await loop.run(
        systemPrompt: AgentWritingService.systemPrompt(
          projectName: widget.projectName ?? '未命名项目',
        ),
        userGoal: text,
      );
      if (!mounted) return;
      setState(() {
        final m = _messages[activeIndex];
        _messages[activeIndex] = ChatMessage(
          content: result.finalText.isEmpty
              ? (m.toolSteps.isNotEmpty
                  ? '已完成工具操作，请查看项目文件。'
                  : '本轮未产出内容，请尝试更具体的指令。')
              : result.finalText,
          isUser: false,
          toolSteps: m.toolSteps,
        );
        _isLoading = false;
        _activeLoop = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[activeIndex] = ChatMessage(
          content: '处理失败：$e',
          isUser: false,
        );
        _isLoading = false;
        _activeLoop = null;
      });
    }
  }

  /// 简单聊天路径（无项目时的回退）。
  Future<void> _sendViaSimpleChat(String text, int entryIndex) async {
    String processBuffer = '';
    String answerBuffer = '';
    try {
      await for (final event in _aiService.normalizedChat(message: text)) {
        if (!mounted) break;
        switch (event) {
          case NormalizerChunk(:final block):
            if (block.type == NormalizedBlockType.process) {
              processBuffer += block.text;
            } else {
              answerBuffer += block.text;
            }
            setState(() {
              _messages[entryIndex] = ChatMessage(
                content: answerBuffer,
                isUser: false,
                isStreaming: true,
                processContent: processBuffer,
                isThinking: block.type == NormalizedBlockType.process,
              );
            });
            _scrollToBottom();
          case NormalizerDone():
            break;
          case NormalizerError(:final message):
            setState(() {
              _messages[entryIndex] = ChatMessage(
                content: '错误: $message',
                isUser: false,
                processContent: processBuffer,
              );
            });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[entryIndex] = ChatMessage(
          content: '错误: $e',
          isUser: false,
          processContent: processBuffer,
        );
      });
    }

    if (mounted) {
      setState(() {
        _messages[entryIndex] = ChatMessage(
          content: _messages[entryIndex].content,
          isUser: false,
          processContent: _messages[entryIndex].processContent,
        );
        _isLoading = false;
      });
    }
  }

  /// A1: Agent 工具循环中 AI 向用户提问的回调。
  /// 在聊天流中内联渲染选项按钮（对标 OpenWrite 原版行为）。
  Future<String> _askUserFromAgent(
      String question, List<String> options) async {
    final completer = Completer<String>();
    _pendingAgentCompleter = completer;
    setState(() {
      _messages.add(ChatMessage(
        content: '',
        isUser: false,
        isAgentQuestion: true,
        agentQuestion: question,
        agentOptions: options,
        agentCompleter: completer,
      ));
      _pendingAgentQuestionIndex = _messages.length - 1;
    });
    _scrollToBottom();
    try {
      return await completer.future;
    } finally {
      if (identical(_pendingAgentCompleter, completer)) {
        _pendingAgentCompleter = null;
        _pendingAgentQuestionIndex = null;
      }
    }
  }

  /// 用户点击 Agent 提问卡的选项按钮
  void _onAgentOptionSelected(int messageIndex, String option) {
    final msg = _messages[messageIndex];
    if (msg.agentAnswered || msg.agentCompleter == null) return;
    setState(() {
      _messages[messageIndex] = ChatMessage(
        content: '',
        isUser: false,
        isAgentQuestion: true,
        agentQuestion: msg.agentQuestion,
        agentOptions: msg.agentOptions,
        agentCompleter: msg.agentCompleter,
        agentAnswered: true,
      );
      // 显示用户的选择
      _messages.add(ChatMessage(content: option, isUser: true));
    });
    _scrollToBottom();
    msg.agentCompleter!.complete(option);
    if (identical(_pendingAgentCompleter, msg.agentCompleter)) {
      _pendingAgentCompleter = null;
      _pendingAgentQuestionIndex = null;
    }
  }

  /// A1: Skill 查找回调 — 按名称/ID 搜索已安装 Skill，返回其 prompt 正文。
  Future<String?> _skillLookup(String nameOrId) async {
    final service = ServiceLocator.instance.skillActionService;
    // 先精确匹配 ID
    final byId = service.getSkill(nameOrId);
    if (byId != null) {
      return byId is DynamicPromptSkill
          ? byId.manifest.promptTemplate
          : byId.description;
    }
    // 再模糊搜索
    final results = service.searchSkills(nameOrId);
    if (results.isEmpty) return null;
    final skill = results.first;
    return skill is DynamicPromptSkill
        ? skill.manifest.promptTemplate
        : skill.description;
  }

  /// 用户选择快速选项后将选项拼接到原始消息发送
  void _onOptionSelected(String originalMessage, String option) {
    // 移除确认卡
    setState(() {
      _messages.removeWhere(
          (m) => m.isClarification && m.originalMessage == originalMessage);
    });
    // 将选项拼接到原始消息
    final enrichedMessage = '$originalMessage（$option）';
    _sendMessage(enrichedMessage);
  }

  /// 用户选择"直接生成"跳过确认
  void _onSkipClarification(String originalMessage) {
    setState(() {
      _messages.removeWhere(
          (m) => m.isClarification && m.originalMessage == originalMessage);
    });
    _sendMessage(originalMessage);
  }

  // ─── Agent 写作（真 function-calling 工具循环）───────────────

  /// 启动 Agent 写作：模型自主读设定 / 提问 / 写章节，步骤实时渲染。
  Future<void> _runAgentWriting() async {
    final pid = widget.projectId;
    if (pid == null || _isLoading) return;
    final project =
        await ServiceLocator.instance.projectService.getProject(pid);
    final dir = project?.directoryPath;
    if (dir == null || dir.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          content: '无法解析项目目录，请先打开一个项目。',
          isUser: false,
        ));
      });
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        content: '🤖 交给 AI 自主创作下一章',
        isUser: true,
      ));
      _messages.add(ChatMessage(
        content: '',
        isUser: false,
        isStreaming: true,
        isThinking: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();
    final entryIndex = _messages.length - 1;

    final provider = _aiService.currentProvider;
    var activeIndex = entryIndex;
    AgentToolLoop? loop;
    final registry = AgentToolRegistry(
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      mutationProtocol: ServiceLocator.instance.mutationProtocol,
      confirmWrite: _confirmToolWrite,
      askUser: (question, options) async {
        if (mounted) {
          setState(() {
            final old = _messages[activeIndex];
            if (old.content.isEmpty &&
                old.processContent.isEmpty &&
                old.toolSteps.isEmpty) {
              _messages.removeAt(activeIndex);
            } else {
              _messages[activeIndex] = ChatMessage(
                content: old.content,
                isUser: false,
                processContent: old.processContent,
                toolSteps: old.toolSteps,
              );
            }
          });
        }
        final answer = await _askUserFromAgent(question, options);
        if (mounted && identical(_activeLoop, loop)) {
          setState(() {
            _messages.add(ChatMessage(
              content: '',
              isUser: false,
              isStreaming: true,
              isThinking: true,
            ));
            activeIndex = _messages.length - 1;
          });
        }
        return answer;
      },
      onToolEvent: (name, display) {
        // 工具事件已通过 AgentToolLoop.onStep 汇总，此处预留扩展。
      },
      versionHistoryService: ServiceLocator.instance.versionHistoryService,
    );
    final fallback = NovelWritingLoop(
      provider: provider,
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      canonService: ServiceLocator.instance.canonService,
      projectId: pid,
      versionHistoryService: ServiceLocator.instance.versionHistoryService,
    );
    loop = AgentToolLoop(
      provider: provider,
      registry: registry,
      fallback: fallback,
      onStep: (step) {
        if (!mounted) return;
        setState(() {
          final m = _messages[activeIndex];
          _messages[activeIndex] = ChatMessage(
            content: step.kind == 'final' ? step.text : m.content,
            isUser: false,
            isStreaming: true,
            isThinking: step.kind != 'final',
            toolSteps: [...m.toolSteps, step],
          );
        });
        _scrollToBottom();
      },
    );
    _activeLoop = loop;

    try {
      final result = await loop.run(
        systemPrompt: AgentWritingService.systemPrompt(
          projectName: widget.projectName ?? '未命名项目',
        ),
        userGoal: '请阅读小说资料中的设定与前情，续写下一章并保存到 章节内容/ 目录。',
      );
      if (!mounted) return;
      setState(() {
        final m = _messages[activeIndex];
        _messages[activeIndex] = ChatMessage(
          content: result.finalText.isEmpty
              ? (result.usedFallback ? '已按确定性流程完成创作。' : '本轮未产出正文，请查看工具步骤。')
              : result.finalText,
          isUser: false,
          toolSteps: m.toolSteps,
        );
        _isLoading = false;
        _activeLoop = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[activeIndex] = ChatMessage(
          content: 'Agent 写作失败：$e',
          isUser: false,
        );
        _isLoading = false;
        _activeLoop = null;
      });
    }
  }

  /// 工具写文件前的确认弹窗（先展示后保存）。
  Future<bool> _confirmToolWrite(String path, String content) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('写入文件确认'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('路径：$path',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('内容预览（${content.length} 字符）：'),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    content.length > 2000
                        ? '${content.substring(0, 2000)}…'
                        : content,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认写入'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Semantics(
      label: 'AI 助手面板',
      container: true,
      child: Container(
        width: LingBiTokens.aiPanelWidth,
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(
            left: BorderSide(color: c.borderOpaque.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(c),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: ModelSelector(compact: true),
            ),
            Expanded(
              child: _buildChatTab(c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space4,
        LingBiTokens.space3,
        LingBiTokens.space3,
        0,
      ),
      child: Row(
        children: [
          Icon(LingBiIcons.aiAssistant, size: 18, color: c.accent),
          const SizedBox(width: LingBiTokens.space2),
          Text(
            'AI 助手',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.fg,
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          if (widget.projectId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                border: Border.all(color: c.accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Agent 模式',
                style: TextStyle(fontSize: 10, color: c.accent),
              ),
            ),
          const Spacer(),
          // Agent 写作快捷入口（需项目上下文）
          if (widget.projectId != null)
            Tooltip(
              message: 'Agent 自主创作下一章',
              child: InkWell(
                onTap: _isLoading ? null : _runAgentWriting,
                borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingBiTokens.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                  ),
                  child: Text(
                    '✍ Agent 写作',
                    style: TextStyle(fontSize: 11, color: c.accent),
                  ),
                ),
              ),
            ),
          const SizedBox(width: LingBiTokens.space2),
          Icon(LingBiIcons.more, size: 16, color: c.muted),
        ],
      ),
    );
  }

  Widget _buildChatTab(LingBiColors c) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyChatHint(c)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(LingBiTokens.space3),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    Widget child;
                    if (msg.isUser) {
                      child = buildUserMessage(c: c, text: msg.content);
                    } else if (msg.isAgentQuestion) {
                      child = buildAgentQuestionCard(
                        c: c,
                        msg: msg,
                        messageIndex: index,
                        onAgentOptionSelected: _onAgentOptionSelected,
                      );
                    } else if (msg.isClarification) {
                      child = buildClarificationCard(
                        c: c,
                        msg: msg,
                        onOptionSelected: (option) =>
                            _onOptionSelected(msg.originalMessage, option),
                        onSkipClarification: () =>
                            _onSkipClarification(msg.originalMessage),
                      );
                    } else {
                      child = buildAiMessage(
                        context: context,
                        c: c,
                        text: msg.content,
                        processContent: msg.processContent,
                        isStreaming: msg.isStreaming,
                        isThinking: msg.isThinking,
                        toolSteps: msg.toolSteps,
                        onConvertToCandidate: widget.onConvertToCandidate ==
                                null
                            ? null
                            : () => widget.onConvertToCandidate!(msg.content),
                        countWords: countChatWords,
                      );
                    }
                    return Padding(
                      padding: index > 0
                          ? const EdgeInsets.only(top: LingBiTokens.space3)
                          : EdgeInsets.zero,
                      child: child,
                    );
                  },
                ),
        ),
        ChatInputBar(
          controller: _inputController,
          isLoading: _isLoading,
          onSend: () => _sendMessage(),
          onCancel: _cancelGeneration,
        ),
      ],
    );
  }

  Widget _buildEmptyChatHint(LingBiColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LingBiTokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LingBiIcons.aiAssistant,
                size: 36, color: c.accent.withValues(alpha: 0.4)),
            const SizedBox(height: LingBiTokens.space3),
            Text(
              '向 AI 助手提问，开始对话',
              style: TextStyle(
                fontSize: 13,
                color: c.muted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.projectId != null) ...[
              const SizedBox(height: LingBiTokens.space3),
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _sendMessage(
                          '请先通过 question 工具向我提问，确认本章目标、冲突和开场，再开始写作。',
                        ),
                icon: const Icon(Icons.forum_outlined, size: 16),
                label: const Text('让 AI 先问我几个关键问题'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
