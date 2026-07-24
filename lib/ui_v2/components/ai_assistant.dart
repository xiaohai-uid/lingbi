import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/ai_service.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

class _ChatMessage {

  _ChatMessage({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
  });
  final String content;
  final bool isUser;
  final bool isStreaming;
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

  /// “转为候选”回调 — 将 AI 回复转入 CandidateService，不直接修改编辑器
  final ValueChanged<String>? onConvertToCandidate;

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AIService _aiService = ServiceLocator.instance.aiService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.projectId != null) {
      _setupProjectContext();
    }
  }

  @override
  void didUpdateWidget(AiAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId && widget.projectId != null) {
      _setupProjectContext();
    }
  }

  void _setupProjectContext() {
    final name = widget.projectName ?? '';
    _aiService.setProjectContext('项目名称：$name\n项目 ID：${widget.projectId}');
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(content: text, isUser: true));
      _messages.add(_ChatMessage(content: '', isUser: false, isStreaming: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final entryIndex = _messages.length - 1;
    try {
      await for (final chunk in _aiService.chat(message: text)) {
        if (!mounted) break;
        setState(() {
          _messages[entryIndex] = _ChatMessage(
            content: _messages[entryIndex].content + chunk,
            isUser: false,
            isStreaming: true,
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[entryIndex] = _ChatMessage(
          content: '错误: $e',
          isUser: false,
        );
      });
    }

    if (mounted) {
      setState(() {
        _messages[entryIndex] = _ChatMessage(
          content: _messages[entryIndex].content,
          isUser: false,
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Container(
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
          _buildTabs(c),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(c),
                _buildWebSearchTab(c),
                _buildCanonTab(c),
              ],
            ),
          ),
        ],
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
          const Spacer(),
          Icon(LingBiIcons.more, size: 16, color: c.muted),
        ],
      ),
    );
  }

  Widget _buildTabs(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space3,
        LingBiTokens.space2,
        LingBiTokens.space3,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: c.fg,
          unselectedLabelColor: c.fgSecondary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: '对话'),
            Tab(text: '搜索'),
            Tab(text: '正典'),
          ],
        ),
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
                    return Padding(
                      padding: index > 0
                          ? const EdgeInsets.only(top: LingBiTokens.space3)
                          : EdgeInsets.zero,
                      child: msg.isUser
                          ? _buildUserMessage(c, msg.content)
                          : _buildAiMessage(
                              c,
                              msg.content,
                              isStreaming: msg.isStreaming,
                            ),
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
            Icon(LingBiIcons.aiAssistant, size: 36, color: c.accent.withValues(alpha: 0.4)),
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

  Widget _buildWebSearchTab(LingBiColors c) {
    // TODO: 接入真实网络搜索服务，替换硬编码数据
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(LingBiTokens.space3),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索网络资料…',
              prefixIcon: Icon(LingBiIcons.globe, size: 18),
              suffixIcon: Icon(LingBiIcons.send, size: 18),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space3),
            children: [
              _buildSearchResult(
                c,
                '纳斯卡线条：古代外星理论的历史考据',
                '考古学 · 知乎专栏',
              ),
              const SizedBox(height: LingBiTokens.space2),
              _buildSearchResult(
                c,
                '秘鲁考古新发现：2024年纳斯卡地画研究进展',
                '中国社会科学院考古研究所',
              ),
              const SizedBox(height: LingBiTokens.space2),
              _buildSearchResult(
                c,
                '二进制编码在古文明中的可能起源',
                '维基百科',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanonTab(LingBiColors c) {
    // TODO: 接入真实正典数据服务，替换硬编码数据
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(LingBiTokens.space3),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索正典内容…',
              prefixIcon: Icon(LingBiIcons.search, size: 18),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space3),
            children: [
              _buildCanonItem(c, '时间之喉', '传说地点', '纳斯卡地下的神秘空间，传说连结过去与未来…'),
              const SizedBox(height: LingBiTokens.space2),
              _buildCanonItem(c, '陈曦', '主要角色', '考古学家，35岁，对古代科技有深入研究…'),
              const SizedBox(height: LingBiTokens.space2),
              _buildCanonItem(c, '青铜芯片', '关键物品', '刻有二进制代码的古代芯片，来源不明…'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiMessage(LingBiColors c, String text, {bool isStreaming = false}) {
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
                text.isEmpty && isStreaming
                    ? SizedBox(
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
                              '思考中…',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.muted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: c.fg,
                            height: 1.6,
                          ),
                          children: [
                            TextSpan(text: text),
                            if (isStreaming)
                              TextSpan(
                                text: ' ▍',
                                style: TextStyle(
                                  color: c.accent.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                          ],
                        ),
                      ),
                // “转为候选”按钮（仅在非流式且有内容时显示）
                if (!isStreaming && text.isNotEmpty && widget.onConvertToCandidate != null)
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
                              style: TextStyle(
                                  fontSize: 11, color: c.accent),
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

  Widget _buildSearchResult(LingBiColors c, String title, String source) {
    return Container(
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.fg,
              height: 1.4,
            ),
          ),
          const SizedBox(height: LingBiTokens.space1),
          Text(
            source,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanonItem(
    LingBiColors c,
    String title,
    String type,
    String desc,
  ) {
    return Container(
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
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.fg,
                ),
              ),
              const SizedBox(width: LingBiTokens.space2),
              _buildTypeBadge(c, type),
            ],
          ),
          const SizedBox(height: LingBiTokens.space1),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: c.fgSecondary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(LingBiColors c, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LingBiTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: c.cinnabar.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: c.cinnabar,
        ),
      ),
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
            onPressed: _isLoading ? null : _sendMessage,
            icon: const Icon(LingBiIcons.send, size: 20),
            color: c.accent,
          ),
        ],
      ),
    );
  }
}
