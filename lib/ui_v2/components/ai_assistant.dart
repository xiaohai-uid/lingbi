import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lingbi/shared/ai/ai_response_normalizer.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/guided_flow_definition.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_loop.dart';
import 'package:lingbi/features/writing/services/agent/agent_tool_registry.dart';
import 'package:lingbi/features/writing/services/agent/novel_writing_loop.dart';
import 'package:lingbi/services/agent_writing_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/skill/data/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/features/review/data/clarity_check_service.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';
import 'model_selector.dart';

class _ChatMessage {
  _ChatMessage({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
    this.processContent = '',
    this.isThinking = false,
    this.isClarification = false,
    this.clarifyQuestion = '',
    this.quickOptions = const [],
    this.originalMessage = '',
    this.toolSteps = const [],
  });
  final String content;
  final bool isUser;
  final bool isStreaming;
  final String processContent;
  final bool isThinking;

  /// 是否为确认卡消息（T4）
  final bool isClarification;

  /// 确认卡问题
  final String clarifyQuestion;

  /// 快速选项
  final List<String> quickOptions;

  /// 触发确认卡的原始消息（选择选项后拼接发送）
  final String originalMessage;

  /// Agent 工具循环的步骤时间线（供渲染）。
  final List<AgentStep> toolSteps;
}

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
  final List<_ChatMessage> _messages = [];
  final ClarityCheckService _clarityCheck = ClarityCheckService();
  bool _isLoading = false;
  AgentToolLoop? _activeLoop; // Phase 1.3: 保存当前循环引用以支持取消

  // ─── 引导模式状态 ───
  bool _guidedMode = false;
  double _guidedProgress = 0;
  String _guidedStepName = '';
  bool _guidedFlowComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _setupProjectContext();
      // Phase 1.2: 不再自动启动 GuidedFlow 纯文字引导
      // _checkGuidedFlowState();
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

  /// 检查当前项目是否有未完成的引导流程；若无但项目带题材，则自动启动。
  // ignore: unused_element — Phase 1.2 已禁用自动引导，保留方法供后续参考
  Future<void> _checkGuidedFlowState() async {
    final pid = widget.projectId;
    if (pid == null) return;
    final engine = ServiceLocator.instance.guidedFlowEngine;
    var state = await engine.getState(pid);

    // R2b 修复：新建/打开带题材的项目时，自动启动对应题材引导流程，
    // 使模板真正生效（此前 GuidedFlowPage 未接入导航，引导从不启动）。
    if (state == null || (!state.isActive && !state.isCompleted)) {
      final genreId = await _resolveProjectGenre(pid);
      if (genreId != null && genreId.isNotEmpty) {
        final flowId = ServiceLocator.instance.guidedFlowSkillLoader
            .findFlowIdByGenre(genreId, type: GuidedFlowType.long);
        if (flowId != null) {
          try {
            state = await engine.startFlow(flowId: flowId, projectId: pid);
          } catch (_) {
            state = null;
          }
        }
      }
    }

    if (state != null && state.isActive && !state.isCompleted) {
      // 绑定到非空局部变量：下方 _generateGuidedOpening 的 await 闭包会捕获
      // state，导致 Dart 流分析取消其空值提升。
      final activeState = state;
      setState(() {
        _guidedMode = true;
        _guidedProgress = engine.getProgress(pid);
        _guidedStepName = engine.getCurrentStep(pid)?.name ?? '';
        _guidedFlowComplete = false;
      });
      // 加载历史对话
      if (activeState.conversationHistory.isNotEmpty) {
        setState(() {
          for (final turn in activeState.conversationHistory) {
            _messages.add(_ChatMessage(
              content: turn.content,
              isUser: turn.role == 'user',
            ));
          }
        });
        _scrollToBottom();
      }
      // 进入引导模式后，若尚无对话则生成第一步开场白。
      if (_messages.isEmpty) {
        await _generateGuidedOpening();
      }
    }
  }

  /// 解析项目题材 ID（Project.genre 存的就是 genreId）。
  Future<String?> _resolveProjectGenre(String projectId) async {
    final project =
        await ServiceLocator.instance.projectService.getProject(projectId);
    return project?.genre;
  }

  /// 切换引导/自由模式
  void _toggleGuidedMode() {
    setState(() => _guidedMode = !_guidedMode);
  }

  /// 引导模式下发送消息
  Future<void> _sendGuidedMessage(String text) async {
    final pid = widget.projectId;
    if (pid == null) return;
    final engine = ServiceLocator.instance.guidedFlowEngine;

    setState(() {
      _messages.add(_ChatMessage(content: text, isUser: true));
      _messages.add(_ChatMessage(
        content: '',
        isUser: false,
        isStreaming: true,
        isThinking: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await engine.processUserInput(
        projectId: pid,
        userInput: text,
      );
      if (!mounted) return;

      final entryIndex = _messages.length - 1;
      setState(() {
        _messages[entryIndex] = _ChatMessage(
          content: response.aiMessage,
          isUser: false,
        );
        _guidedProgress = response.progress;
        _guidedStepName = response.currentStepName;
        _isLoading = false;
      });
      _scrollToBottom();

      // 步骤完成提示
      if (response.isStepComplete && !response.isFlowComplete) {
        setState(() {
          _messages.add(_ChatMessage(
            content: '✓ 「${response.currentStepName}」已完成，进入下一步...',
            isUser: false,
          ));
        });
        // 生成新步骤开场白
        await _generateGuidedOpening();
      }

      if (response.isFlowComplete) {
        setState(() {
          _guidedFlowComplete = true;
          _guidedProgress = 1;
          _messages.add(_ChatMessage(
            content: '🎉 所有引导步骤已完成！设定已保存到项目。',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      final entryIndex = _messages.length - 1;
      setState(() {
        _messages[entryIndex] = _ChatMessage(
          content: '引导处理失败: $e',
          isUser: false,
        );
        _isLoading = false;
      });
    }
  }

  /// 生成引导步骤开场白
  Future<void> _generateGuidedOpening() async {
    final pid = widget.projectId;
    if (pid == null) return;
    final engine = ServiceLocator.instance.guidedFlowEngine;

    setState(() {
      _messages.add(_ChatMessage(
        content: '',
        isUser: false,
        isStreaming: true,
        isThinking: true,
      ));
      _isLoading = true;
    });

    try {
      final opening = await engine.generateStepOpening(pid);
      if (!mounted) return;
      final entryIndex = _messages.length - 1;
      setState(() {
        _messages[entryIndex] = _ChatMessage(
          content: opening,
          isUser: false,
        );
        _guidedStepName = engine.getCurrentStep(pid)?.name ?? '';
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
    _activeLoop?.cancel();
    _activeLoop = null;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (overrideText == null) _inputController.clear();

    // 引导模式下走 GuidedFlowEngine
    if (_guidedMode && !_guidedFlowComplete) {
      await _sendGuidedMessage(text);
      return;
    }

    // T4: 清晰度检查
    final clarityResult = _clarityCheck.assess(text);
    if (clarityResult.needsClarification) {
      setState(() {
        _messages.add(_ChatMessage(content: text, isUser: true));
        _messages.add(_ChatMessage(
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
        _messages.add(_ChatMessage(content: text, isUser: true));
      }
      _messages.add(_ChatMessage(
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

    final provider = _aiService.currentProvider;
    final registry = AgentToolRegistry(
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      confirmWrite: _confirmToolWrite,
      askUser: _askUserFromAgent,
      skillLookup: _skillLookup,
      onToolEvent: (name, display) {},
    );
    final fallback = NovelWritingLoop(
      provider: provider,
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      canonService: ServiceLocator.instance.canonService,
      projectId: widget.projectId,
    );
    final loop = AgentToolLoop(
      provider: provider,
      registry: registry,
      fallback: fallback,
      maxIterations: 50,
      onStep: (step) {
        if (!mounted) return;
        setState(() {
          final m = _messages[entryIndex];
          _messages[entryIndex] = _ChatMessage(
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
        final m = _messages[entryIndex];
        _messages[entryIndex] = _ChatMessage(
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
        _messages[entryIndex] = _ChatMessage(
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
              _messages[entryIndex] = _ChatMessage(
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
              _messages[entryIndex] = _ChatMessage(
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
        _messages[entryIndex] = _ChatMessage(
          content: '错误: $e',
          isUser: false,
          processContent: processBuffer,
        );
      });
    }

    if (mounted) {
      setState(() {
        _messages[entryIndex] = _ChatMessage(
          content: _messages[entryIndex].content,
          isUser: false,
          processContent: _messages[entryIndex].processContent,
        );
        _isLoading = false;
      });
    }
  }

  /// A1: Agent 工具循环中 AI 向用户提问的回调。
  Future<String> _askUserFromAgent(
      String question, List<String> options) async {
    final answer = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(question, style: const TextStyle(fontSize: 15)),
        content: options.isEmpty
            ? null
            : SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final opt in options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(opt),
                            child: Text(opt),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('跳过'),
            child: const Text('跳过'),
          ),
        ],
      ),
    );
    return answer ?? '跳过';
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
        _messages.add(_ChatMessage(
          content: '无法解析项目目录，请先打开一个项目。',
          isUser: false,
        ));
      });
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(
        content: '🤖 交给 AI 自主创作下一章',
        isUser: true,
      ));
      _messages.add(_ChatMessage(
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
    final registry = AgentToolRegistry(
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      confirmWrite: _confirmToolWrite,
      onToolEvent: (name, display) {
        // 工具事件已通过 AgentToolLoop.onStep 汇总，此处预留扩展。
      },
    );
    final fallback = NovelWritingLoop(
      provider: provider,
      projectDir: dir,
      store: ServiceLocator.instance.atomicFileStore,
      canonService: ServiceLocator.instance.canonService,
      projectId: pid,
    );
    final loop = AgentToolLoop(
      provider: provider,
      registry: registry,
      fallback: fallback,
      onStep: (step) {
        if (!mounted) return;
        setState(() {
          final m = _messages[entryIndex];
          _messages[entryIndex] = _ChatMessage(
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

    try {
      final result = await loop.run(
        systemPrompt: AgentWritingService.systemPrompt(
          projectName: widget.projectName ?? '未命名项目',
        ),
        userGoal: '请阅读小说资料中的设定与前情，续写下一章并保存到 章节内容/ 目录。',
      );
      if (!mounted) return;
      setState(() {
        final m = _messages[entryIndex];
        _messages[entryIndex] = _ChatMessage(
          content: result.finalText.isEmpty
              ? (result.usedFallback ? '已按确定性流程完成创作。' : '本轮未产出正文，请查看工具步骤。')
              : result.finalText,
          isUser: false,
          toolSteps: m.toolSteps,
        );
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[entryIndex] = _ChatMessage(
          content: 'Agent 写作失败：$e',
          isUser: false,
        );
        _isLoading = false;
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
            if (_guidedMode) _buildGuidedProgressBar(c),
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
          // 引导/自由模式切换
          if (_guidedStepName.isNotEmpty || _guidedMode)
            Tooltip(
              message: _guidedMode ? '切换到自由对话' : '切换到引导模式',
              child: InkWell(
                onTap: _toggleGuidedMode,
                borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingBiTokens.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _guidedMode
                        ? c.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                  ),
                  child: Text(
                    _guidedMode ? '引导中' : '自由',
                    style: TextStyle(
                      fontSize: 11,
                      color: _guidedMode ? c.accent : c.muted,
                    ),
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

  /// 引导进度条（显示在 header 下方）
  Widget _buildGuidedProgressBar(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LingBiTokens.space4,
        vertical: LingBiTokens.space1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_guidedStepName.isNotEmpty)
                Text(
                  _guidedFlowComplete ? '引导完成' : '当前: $_guidedStepName',
                  style: TextStyle(fontSize: 11, color: c.fgSecondary),
                ),
              const Spacer(),
              Text(
                '${(_guidedProgress * 100).toInt()}%',
                style: TextStyle(fontSize: 11, color: c.accent),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _guidedProgress,
              minHeight: 3,
              backgroundColor: c.borderOpaque,
              valueColor: AlwaysStoppedAnimation<Color>(
                _guidedFlowComplete ? LingBiTokens.success : c.accent,
              ),
            ),
          ),
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
                      child = _buildUserMessage(c, msg.content);
                    } else if (msg.isClarification) {
                      child = _buildClarificationCard(c, msg);
                    } else {
                      child = _buildAiMessage(
                        c,
                        msg.content,
                        processContent: msg.processContent,
                        isStreaming: msg.isStreaming,
                        isThinking: msg.isThinking,
                        toolSteps: msg.toolSteps,
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
        _buildInputBar(c),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAiMessage(
    LingBiColors c,
    String text, {
    String processContent = '',
    bool isStreaming = false,
    bool isThinking = false,
    List<AgentStep> toolSteps = const [],
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          ),
          child: Center(
            child: Icon(LingBiIcons.aiAssistant, size: 16, color: c.accent),
          ),
        ),
        const SizedBox(width: LingBiTokens.space2),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(LingBiTokens.space3),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
              border: Border.all(
                color: c.borderOpaque.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 思考折叠面板
                if (processContent.isNotEmpty)
                  _buildProcessTile(
                    c,
                    processContent,
                    isThinkingNow: isThinking && isStreaming,
                  ),
                // Agent 工具步骤时间线
                if (toolSteps.isNotEmpty) _buildToolSteps(c, toolSteps),
                // 回答内容
                if (text.isEmpty && isStreaming)
                  SizedBox(
                    height: 20,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.accent.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: LingBiTokens.space2),
                        Text(
                          isThinking ? '思考中…' : '生成中…',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (text.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A3: 流式时用纯文本+光标，完成后用 Markdown 渲染
                      if (isStreaming)
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: c.fg,
                              height: 1.6,
                            ),
                            children: [
                              TextSpan(text: text),
                              TextSpan(
                                text: ' ▍',
                                style: TextStyle(
                                  color: c.accent.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 14,
                              color: c.fg,
                              height: 1.6,
                            ),
                            h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.fg),
                            h2: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.fg),
                            h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.fg),
                            listBullet: TextStyle(color: c.fgSecondary),
                            code: TextStyle(
                              fontSize: 13,
                              backgroundColor: c.surfaceContainer,
                            ),
                          ),
                        ),
                      // A3: 字数统计
                      if (!isStreaming && text.length > 20)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '共 ${_countWords(text)} 字',
                            style: TextStyle(fontSize: 11, color: c.muted),
                          ),
                        ),
                    ],
                  ),
                // "转为候选"按钮（仅在非流式且有内容时显示）
                if (!isStreaming &&
                    text.isNotEmpty &&
                    widget.onConvertToCandidate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InkWell(
                      onTap: () => widget.onConvertToCandidate!(text),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.note_add_outlined,
                                size: 13, color: c.accent),
                            const SizedBox(width: 4),
                            Text(
                              '转为候选',
                              style: TextStyle(fontSize: 11, color: c.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 思考过程折叠面板
  Widget _buildProcessTile(
    LingBiColors c,
    String processContent, {
    bool isThinkingNow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isThinkingNow,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 4),
          dense: true,
          leading: Icon(
            Icons.psychology_outlined,
            size: 14,
            color: c.muted,
          ),
          title: Text(
            isThinkingNow ? '思考中…' : '💭 思考过程',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
          ),
          trailing: Icon(
            isThinkingNow ? Icons.expand_more : Icons.chevron_right,
            size: 16,
            color: c.muted,
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.surfaceContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  processContent,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.fgSecondary.withValues(alpha: 0.8),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Agent 工具步骤时间线（折叠面板）
  Widget _buildToolSteps(LingBiColors c, List<AgentStep> steps) {
    final toolCount =
        steps.where((s) => s.kind == 'tool' || s.kind == 'error').length;
    final hasError = steps.any((s) => s.kind == 'error');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 4),
          dense: true,
          leading: Icon(
            hasError ? Icons.build_circle_outlined : Icons.build_outlined,
            size: 14,
            color: hasError ? LingBiTokens.warning : c.muted,
          ),
          title: Text(
            '🛠 工具步骤（$toolCount）',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.surfaceContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _toolStepIcon(s.kind),
                              size: 12,
                              color: s.kind == 'error'
                                  ? LingBiTokens.warning
                                  : s.kind == 'final'
                                      ? LingBiTokens.success
                                      : c.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.fgSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _toolStepIcon(String kind) => switch (kind) {
        'tool' => Icons.check_circle_outline,
        'error' => Icons.warning_amber_rounded,
        'final' => Icons.flag_outlined,
        'fallback' => Icons.swap_horiz,
        _ => Icons.more_horiz,
      };

  /// A3: 字数统计（中文字符 + 英文单词）。
  int _countWords(String text) {
    final chineseChars = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]')
        .allMatches(text)
        .length;
    final englishWords = RegExp(r'[a-zA-Z]+')
        .allMatches(text)
        .length;
    return chineseChars + englishWords;
  }

  /// T4: 确认卡（模糊请求追问）
  Widget _buildClarificationCard(LingBiColors c, _ChatMessage msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          ),
          child: Center(
            child: Icon(Icons.help_outline, size: 16, color: c.accent),
          ),
        ),
        const SizedBox(width: LingBiTokens.space2),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(LingBiTokens.space3),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
              border: Border.all(
                color: c.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.clarifyQuestion,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.fg,
                    height: 1.4,
                  ),
                ),
                if (msg.quickOptions.isNotEmpty) ...[
                  const SizedBox(height: LingBiTokens.space2),
                  Wrap(
                    spacing: LingBiTokens.space2,
                    runSpacing: LingBiTokens.space1,
                    children: [
                      for (final option in msg.quickOptions)
                        InkWell(
                          onTap: () =>
                              _onOptionSelected(msg.originalMessage, option),
                          borderRadius:
                              BorderRadius.circular(LingBiTokens.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: option == '直接生成'
                                  ? c.accent.withValues(alpha: 0.1)
                                  : c.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                  LingBiTokens.radiusPill),
                              border: Border.all(
                                color: option == '直接生成'
                                    ? c.accent.withValues(alpha: 0.4)
                                    : c.borderOpaque.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: option == '直接生成'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color:
                                    option == '直接生成' ? c.accent : c.fgSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: LingBiTokens.space2),
                InkWell(
                  onTap: () => _onSkipClarification(msg.originalMessage),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      '跳过，直接生成 →',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(LingBiColors c, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(LingBiTokens.space3),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.fg,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(width: LingBiTokens.space2),
        Icon(LingBiIcons.edit, size: 18, color: c.fgSecondary),
      ],
    );
  }

  Widget _buildInputBar(LingBiColors c) {
    return Container(
      padding: const EdgeInsets.all(LingBiTokens.space3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '输入消息…',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.fg,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          IconButton(
            onPressed: _isLoading ? _cancelGeneration : _sendMessage,
            icon: Icon(
              _isLoading ? Icons.stop_circle_outlined : LingBiIcons.send,
              size: 20,
            ),
            color: _isLoading ? LingBiTokens.error : c.accent,
          ),
        ],
      ),
    );
  }
}
