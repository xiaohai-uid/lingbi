/// 全屏引导模式 — 创建项目后的 AI 主动引导对话
///
/// 用户创建项目后进入此全屏模式，AI 主动提问引导构建世界观和核心角色。
/// 完成后退出全屏回到正常三栏布局。可跳过或稍后再说。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/guided_flow_engine.dart';
import '../theme/tokens.dart';

/// 对话消息（UI 层）
class _ChatMessage {
  _ChatMessage({required this.role, required this.content});

  final String role; // 'user' | 'assistant' | 'system'
  final String content;
}

class GuidedFlowPage extends StatefulWidget {
  const GuidedFlowPage({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.flowId,
    required this.onComplete,
    required this.onSkip,
  });

  final String projectId;
  final String projectName;
  final String flowId;

  /// 引导完成后的回调
  final VoidCallback onComplete;

  /// 跳过/稍后再说的回调
  final VoidCallback onSkip;

  @override
  State<GuidedFlowPage> createState() => _GuidedFlowPageState();
}

class _GuidedFlowPageState extends State<GuidedFlowPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isProcessing = false;
  bool _isInitialized = false;
  double _progress = 0;
  String _currentStepName = '';

  GuidedFlowEngine get _engine => ServiceLocator.instance.guidedFlowEngine;

  @override
  void initState() {
    super.initState();
    _initializeFlow();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeFlow() async {
    try {
      final state = await _engine.startFlow(
        flowId: widget.flowId,
        projectId: widget.projectId,
      );

      setState(() {
        _progress = _engine.getProgress(widget.projectId);
        _currentStepName =
            _engine.getCurrentStep(widget.projectId)?.name ?? '';
        _isInitialized = true;
      });

      // 如果是恢复的流程，加载历史
      if (state.conversationHistory.isNotEmpty) {
        setState(() {
          for (final turn in state.conversationHistory) {
            _messages.add(_ChatMessage(role: turn.role, content: turn.content));
          }
        });
      } else {
        // AI 主动发起提问
        await _generateOpening();
      }
    } catch (e) {
      setState(() => _isInitialized = true);
      _messages.add(_ChatMessage(
        role: 'system',
        content: '引导流程启动失败: $e',
      ));
    }
  }

  Future<void> _generateOpening() async {
    setState(() => _isProcessing = true);
    try {
      final opening = await _engine.generateStepOpening(widget.projectId);
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: opening));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'system',
            content: 'AI 响应失败: $e',
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendUserInput() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isProcessing = true;
    });
    _scrollToBottom();

    try {
      final response = await _engine.processUserInput(
        projectId: widget.projectId,
        userInput: text,
      );

      if (!mounted) return;

      setState(() {
        _messages
            .add(_ChatMessage(role: 'assistant', content: response.aiMessage));
        _progress = response.progress;
        _currentStepName = response.currentStepName;
      });
      _scrollToBottom();

      // 步骤完成提示
      if (response.isStepComplete && !response.isFlowComplete) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'system',
            content: '✓ 「${response.currentStepName}」已完成，进入下一步...',
          ));
        });
        // 生成新步骤的开场白
        await _generateOpening();
      }

      // 整个流程完成
      if (response.isFlowComplete) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'system',
            content: '🎉 所有引导步骤已完成！世界观和角色设定已保存。',
          ));
        });
        _scrollToBottom();
        // 延迟退出，让用户看到完成消息
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (mounted) widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'system', content: '处理失败: $e'));
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _skipFlow() async {
    await _engine.pauseFlow(widget.projectId);
    if (mounted) widget.onSkip();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Container(
      color: c.bg,
      child: Column(
        children: [
          _buildHeader(c),
          const Divider(height: 1),
          Expanded(child: _buildChatArea(c)),
          _buildInputArea(c),
        ],
      ),
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LingBiTokens.space6,
        vertical: LingBiTokens.space3,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '创作引导',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.fg,
                ),
              ),
              const SizedBox(width: LingBiTokens.space3),
              if (_currentStepName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingBiTokens.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _currentStepName,
                    style: TextStyle(fontSize: 12, color: c.accent),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: _skipFlow,
                child: Text(
                  '稍后再说',
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: LingBiTokens.space2),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 3,
              backgroundColor: c.borderOpaque,
              valueColor: AlwaysStoppedAnimation<Color>(c.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(LingBiColors c) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: LingBiTokens.space8,
        vertical: LingBiTokens.space4,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg, c);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, LingBiColors c) {
    if (msg.role == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: LingBiTokens.space2),
        child: Center(
          child: Text(
            msg.content,
            style: TextStyle(fontSize: 12, color: c.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LingBiTokens.space1),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(c, isUser: false),
            const SizedBox(width: LingBiTokens.space2),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: LingBiTokens.space4,
                vertical: LingBiTokens.space3,
              ),
              decoration: BoxDecoration(
                color: isUser ? c.accent : c.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(LingBiTokens.radiusMd),
                  topRight: const Radius.circular(LingBiTokens.radiusMd),
                  bottomLeft: Radius.circular(
                      isUser ? LingBiTokens.radiusMd : 2.0),
                  bottomRight: Radius.circular(
                      isUser ? 2.0 : LingBiTokens.radiusMd),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isUser ? Colors.white : c.fg,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: LingBiTokens.space2),
            _buildAvatar(c, isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(LingBiColors c, {required bool isUser}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? c.accent.withValues(alpha: 0.15) : c.surfaceContainer,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
      ),
      child: Center(
        child: Text(
          isUser ? '我' : '灵',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isUser ? c.accent : c.fgSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(LingBiColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LingBiTokens.space8,
        vertical: LingBiTokens.space4,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderOpaque.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendUserInput(),
              decoration: InputDecoration(
                hintText: '描述你的想法...',
                hintStyle: TextStyle(color: c.muted, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                  borderSide: BorderSide(color: c.borderOpaque),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                  borderSide: BorderSide(color: c.borderOpaque),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                  borderSide: BorderSide(color: c.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: LingBiTokens.space4,
                  vertical: LingBiTokens.space3,
                ),
              ),
            ),
          ),
          const SizedBox(width: LingBiTokens.space3),
          SizedBox(
            width: 40,
            height: 40,
            child: _isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    onPressed: _sendUserInput,
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
