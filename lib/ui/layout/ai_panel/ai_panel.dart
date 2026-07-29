import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/canon/data/canon_linking_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:lingbi/ui/widgets/web_search_widget.dart';
import 'package:lingbi/ui/pages/settings_page.dart';
import 'chat_widget.dart';

class AIPanel extends StatefulWidget {

  const AIPanel({super.key, this.projectId, this.projectName});
  final String? projectId;
  final String? projectName;

  @override
  State<AIPanel> createState() => _AIPanelState();
}

class _AIPanelState extends State<AIPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AIService _aiService = ServiceLocator.instance.aiService;
  final CanonLinkingService _linkingService = ServiceLocator.instance.canonLinkingService;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatEntry> _messages = [];
  bool _isLoading = false;
  String _canonSummary = '';
  String? _currentProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 初始化时绑定项目上下文
    if (widget.projectId != null) {
      _currentProjectId = widget.projectId;
      _setupProjectContext();
    }
  }

  @override
  void didUpdateWidget(AIPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId && widget.projectId != null) {
      _currentProjectId = widget.projectId;
      _setupProjectContext();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 设置项目上下文：通知 AIService 并加载 Canon 摘要
  void _setupProjectContext() {
    final name = widget.projectName ?? '';
    _aiService.setProjectContext('项目名称：$name\n项目 ID：$_currentProjectId');
    _loadCanonSummary();
  }

  void setProject(String projectId) {
    _currentProjectId = projectId;
    _setupProjectContext();
  }

  Future<void> _loadCanonSummary() async {
    if (_currentProjectId == null) return;
    try {
      final summary = await _linkingService.generateCanonSummary(_currentProjectId!, '');
      if (mounted) {
        setState(() => _canonSummary = summary.isEmpty
            ? '📚 正典关联\n\n暂无关联的正典条目，请在正典页面添加角色/地点。'
            : summary);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _canonSummary = '📚 正典关联\n\n选择文档后自动检测角色/地点提及');
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatEntry(role: 'user', content: text));
      _isLoading = true;
      _messages.add(ChatEntry(role: 'assistant', content: '', isStreaming: true));
    });
    _scrollToBottom();

    final entryIndex = _messages.length - 1;
    try {
      await for (final chunk in _aiService.chat(message: text)) {
        if (!mounted) break;
        setState(() {
          _messages[entryIndex] = ChatEntry(
            role: 'assistant',
            content: _messages[entryIndex].content + chunk,
            isStreaming: true,
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[entryIndex] = ChatEntry(role: 'assistant', content: '错误: $e');
      });
    }

    if (mounted) {
      setState(() {
        _messages[entryIndex] = ChatEntry(
          role: 'assistant',
          content: _messages[entryIndex].content,
        );
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('风格蒸馏'),
              subtitle: const Text('分析选中文本的风格特征'),
              onTap: () {
                Navigator.pop(ctx);
                _inputController.text = '/风格 分析这段文本的写作风格...';
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('小说拆解'),
              subtitle: const Text('分析小说结构和角色'),
              onTap: () {
                Navigator.pop(ctx);
                _inputController.text = '/拆解 分析这部小说的结构...';
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('智能续写'),
              subtitle: const Text('根据前文续写下一段'),
              onTap: () {
                Navigator.pop(ctx);
                _inputController.text = '/续写 ';
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Text('AI 助手', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.auto_awesome, size: 18),
                tooltip: '快捷操作',
                onPressed: _showQuickActions,
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 18),
                tooltip: 'AI 设置',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ));
                },
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat, size: 18), text: '聊天'),
            Tab(icon: Icon(Icons.search, size: 18), text: '搜索'),
            Tab(icon: Icon(Icons.auto_stories, size: 18), text: '关联'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Chat tab
              Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.auto_awesome, size: 32, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 8),
                                Text('AI 写作助手', style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text('续写 · 改写 · 风格蒸馏 · 小说拆解',
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) => ChatWidget(entry: _messages[i]),
                          ),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: LinearProgressIndicator(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            decoration: InputDecoration(
                              hintText: '向 AI 提问...',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            minLines: 1,
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Web search tab
              const WebSearchWidget(),
              // Canon linking tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📚 正典关联', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text(
                      '当前文档中检测到的角色、地点和传说条目将显示在这里。',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _canonSummary,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
