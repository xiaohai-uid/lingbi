import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/errors/ai_error.dart';
import 'package:lingbi/core/models/document.dart' as app;
import 'package:lingbi/modules/pipeline/candidate_service.dart';
import 'package:lingbi/services/skill_action_service.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';
import '../components/writing_toolbar.dart';
import '../components/slash_command_menu.dart';
import '../components/candidate_panel.dart';
import '../components/model_status_bar.dart';
import '../components/error_banner.dart';

class EditorPage extends StatefulWidget {

  const EditorPage({
    super.key,
    this.projectId,
    this.documentId,
    this.documentTitle,
  });
  final String? projectId;
  final String? documentId;
  final String? documentTitle;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  String _title = '';
  String _content = '';
  bool _isDirty = false;
  bool _saving = false;
  Timer? _autoSaveTimer;
  app.Document? _document;
  late QuillController _quillController;
  late FocusNode _quillFocusNode;
  final _titleController = TextEditingController();
  StreamSubscription? _changesSubscription;
  bool _contentLoaded = false;

  // AI 写作状态
  bool _showAiPanel = false;
  bool _showSlashMenu = false;
  final _instructionController = TextEditingController();
  SkillAction? _selectedSkill;
  bool _isGenerating = false;
  String _streamingText = '';
  String? _aiError;
  CandidateEntry? _currentCandidate;
  bool _showCandidatePanel = false;

  @override
  void initState() {
    super.initState();
    _quillFocusNode = FocusNode();
    _quillController = QuillController.basic();
    _subscribeChanges();
    _loadDocument();
  }

  void _subscribeChanges() {
    _changesSubscription?.cancel();
    _changesSubscription = _quillController.document.changes.listen((_) {
      if (!_contentLoaded) return;
      final text = _extractPlainText();
      if (text != _content) {
        setState(() {
          _content = text;
          _isDirty = true;
        });
        _autoSaveTimer?.cancel();
        _autoSaveTimer = Timer(const Duration(seconds: 30), _save);
      }
    });
  }

  String _extractPlainText() {
    final buffer = StringBuffer();
    for (final op in _quillController.document.toDelta().toList()) {
      if (op.data is String) {
        buffer.write(op.data);
      }
    }
    return buffer.toString();
  }

  @override
  void didUpdateWidget(covariant EditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentId != widget.documentId) {
      _loadDocument();
    }
  }

  void _loadQuillContent(String content) {
    _contentLoaded = false;
    _changesSubscription?.cancel();
    final oldController = _quillController;
    final doc = Document()..insert(0, content);
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    if (oldController.document != doc) {
      oldController.dispose();
    }
    _subscribeChanges();
    _contentLoaded = true;
  }

  Future<void> _loadDocument() async {
    if (widget.documentId == null) {
      setState(() {
        _title = widget.documentTitle ?? '';
        _content = '';
      });
      _loadQuillContent('');
      _titleController.text = _title;
      return;
    }
    try {
      final doc =
          await ServiceLocator.instance.documentService.getDocument(
              widget.documentId!);
      if (doc == null) {
        setState(() {
          _title = widget.documentTitle ?? '';
          _content = '';
        });
        _loadQuillContent('');
        _titleController.text = _title;
        return;
      }
      final content =
          await ServiceLocator.instance.documentService.readContent(doc.filePath);
      if (!mounted) return;
      setState(() {
        _document = doc;
        _title = widget.documentTitle ?? doc.title;
        _content = content;
      });
      _loadQuillContent(content);
      _titleController.text = _title;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _title = widget.documentTitle ?? '';
        _content = '';
      });
      _loadQuillContent('');
      _titleController.text = _title;
    }
  }

  Future<void> _save() async {
    if (!_isDirty || _document == null) return;
    setState(() => _saving = true);
    try {
      final updated = await ServiceLocator.instance.documentService
          .saveDocument(_document!, _content);
      if (!mounted) return;
      setState(() {
        _document = updated;
        _isDirty = false;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Fire-and-forget final save
    if (_isDirty && _document != null) {
      ServiceLocator.instance.documentService
          .saveDocument(_document!, _content);
    }
    _changesSubscription?.cancel();
    _quillFocusNode.dispose();
    _quillController.dispose();
    _titleController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Format command handling (bridged to QuillController)
  // ---------------------------------------------------------------------------

  void _handleFormatCommand(String command) {
    switch (command) {
      case FormatCommands.aiWriting:
        _toggleAiPanel();
        return;
      case FormatCommands.bold:
        _toggleAttribute(Attribute.bold);
      case FormatCommands.italic:
        _toggleAttribute(Attribute.italic);
      case FormatCommands.underline:
        _toggleAttribute(Attribute.underline);
      case FormatCommands.strikethrough:
        _toggleAttribute(Attribute.strikeThrough);
      case FormatCommands.code:
        _toggleAttribute(Attribute.inlineCode);
      case FormatCommands.heading:
        _toggleAttribute(Attribute.h2);
      case FormatCommands.quote:
        _toggleAttribute(Attribute.blockQuote);
      case FormatCommands.bulletList:
        _toggleAttribute(Attribute.ul);
      case FormatCommands.numberedList:
        _toggleAttribute(Attribute.ol);
      case FormatCommands.link:
        final linkAttr = Attribute.fromKeyValue('link', 'https://');
        if (linkAttr != null) _toggleAttribute(linkAttr);
      case FormatCommands.image:
        _quillController.replaceText(
          _quillController.selection.start,
          _quillController.selection.end - _quillController.selection.start,
          BlockEmbed.image('image_url'),
          null,
        );
      case FormatCommands.undo:
        _quillController.undo();
      case FormatCommands.redo:
        _quillController.redo();
    }
    setState(() {
      _content = _extractPlainText();
      _isDirty = true;
    });
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), _save);
  }

  void _toggleAttribute(Attribute<dynamic> attr) {
    _quillController.formatSelection(attr);
  }

  // ---------------------------------------------------------------------------
  // AI 写作
  // ---------------------------------------------------------------------------

  void _toggleAiPanel() {
    setState(() => _showAiPanel = !_showAiPanel);
  }

  /// 检查是否有项目和章节
  String? _validateAiReady() {
    if (widget.projectId == null || widget.projectId!.isEmpty) {
      return '请先打开一个项目';
    }
    if (widget.documentId == null || widget.documentId!.isEmpty) {
      return '请先选择一个章节';
    }
    return null;
  }

  Future<void> _startGeneration() async {
    final validationError = _validateAiReady();
    if (validationError != null) {
      setState(() => _aiError = validationError);
      return;
    }

    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) {
      setState(() => _aiError = '请输入写作要求');
      return;
    }

    // 先保存文档
    if (_isDirty) {
      await _save();
      if (_isDirty) {
        // 保存失败
        setState(() => _aiError = '文档保存失败，无法基于过期内容生成');
        return;
      }
    }

    setState(() {
      _isGenerating = true;
      _aiError = null;
      _streamingText = '';
    });

    // 本阶段使用 AIService 直接生成（待 Task 5 接入完整管线）
    try {
      final aiService = ServiceLocator.instance.aiService;
      final buffer = StringBuffer();
      final skillId = _selectedSkill?.id ?? 'smart-continuation';
      final systemPrompt = '你是一个专业的小说写作助手。技能: $skillId。'
          '请根据用户要求续写或改写内容，直接输出正文，不要加解释。';

      await for (final chunk in aiService.currentProvider.chat(
        messages: [
          ChatMessage(role: 'system', content: systemPrompt),
          ChatMessage(role: 'user', content: instruction),
        ],
        maxTokens: 4096,
      )) {
        if (!mounted) return;
        buffer.write(chunk);
        setState(() => _streamingText = buffer.toString());
      }

      if (mounted) {
        setState(() {
          _isGenerating = false;
          // 生成完成，创建候选条目并显示 CandidatePanel
          _currentCandidate = CandidateEntry(
            id: 'local-${DateTime.now().millisecondsSinceEpoch}',
            chapterId: widget.documentId ?? '',
            content: buffer.toString(),
            status: CandidateStatus.pending,
            model: aiService.currentProviderName,
            createdAt: DateTime.now(),
          );
          _showCandidatePanel = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _aiError = 'AI 生成失败: $e';
        });
      }
    }
  }

  void _cancelGeneration() {
    setState(() {
      _isGenerating = false;
      _streamingText = '';
    });
  }

  void _onSlashDetected() {
    final skills = ServiceLocator.instance.skillActionService.registeredSkills;
    if (skills.isNotEmpty) {
      setState(() => _showSlashMenu = true);
    }
  }

  void _onSkillSelected(SkillAction skill) {
    setState(() {
      _selectedSkill = skill;
      _showSlashMenu = false;
      _showAiPanel = true;
    });
  }

  // ---------------------------------------------------------------------------
  // 候选采纳（编辑器内存操作，进入撤销栈）
  // ---------------------------------------------------------------------------

  void _handleAdopt(AdoptMode mode) {
    final candidate = _currentCandidate;
    if (candidate == null) return;
    final text = candidate.content;

    switch (mode) {
      case AdoptMode.insertAtCursor:
        final offset = _quillController.selection.start;
        _quillController.replaceText(offset, 0, text, null);
      case AdoptMode.replaceSelection:
        final start = _quillController.selection.start;
        final length = _quillController.selection.end - start;
        _quillController.replaceText(start, length, text, null);
      case AdoptMode.appendToEnd:
        final docLength = _quillController.document.length;
        // 在文档末尾插入（留一个换行）
        _quillController.replaceText(docLength - 1, 0, '\n$text', null);
    }

    setState(() {
      _content = _extractPlainText();
      _isDirty = true;
      _showCandidatePanel = false;
      _currentCandidate = null;
      _streamingText = '';
    });
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), _save);
  }

  void _handleDiscard() {
    setState(() {
      _showCandidatePanel = false;
      _currentCandidate = null;
      _streamingText = '';
    });
  }

  void _handleRegenerate() {
    setState(() {
      _showCandidatePanel = false;
      _currentCandidate = null;
      _streamingText = '';
    });
    _startGeneration();
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            WritingToolbar(
              onFormatCommand: _handleFormatCommand,
              wordCount: _content.length,
            ),
            if (_showAiPanel) _buildAiWritingPanel(c),
            // 候选面板
            if (_showCandidatePanel && _currentCandidate != null)
              Padding(
                padding: const EdgeInsets.all(LingBiTokens.space3),
                child: CandidatePanel(
                  candidate: _currentCandidate!,
                  processBlocks: const [],
                  isStreaming: false,
                  onAdopt: _handleAdopt,
                  onDiscard: _handleDiscard,
                  onRegenerate: _handleRegenerate,
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      color: c.bg,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: LingBiTokens.space10,
                              vertical: LingBiTokens.space8,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 720,
                                minHeight: constraints.maxHeight,
                              ),
                              child: _buildEditor(c),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // 斜杠命令菜单
                  if (_showSlashMenu)
                    Positioned(
                      left: 80,
                      top: 40,
                      child: SlashCommandMenu(
                        skills: ServiceLocator.instance.skillActionService
                            .registeredSkills,
                        onSelected: _onSkillSelected,
                        onDismiss: () =>
                            setState(() => _showSlashMenu = false),
                      ),
                    ),
                ],
              ),
            ),
            _buildStatusBar(c),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(LingBiColors c) {
    final displayTitle = _title.isNotEmpty ? _title : '未命名章节';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.accent,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: LingBiTokens.space2),
        TextField(
          controller: _titleController,
          onChanged: (v) {
            setState(() {
              _title = v;
              _isDirty = true;
            });
            _autoSaveTimer?.cancel();
            _autoSaveTimer = Timer(const Duration(seconds: 30), _save);
          },
          decoration: InputDecoration(
            hintText: '章节标题…',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            hintStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: c.muted.withValues(alpha: 0.4),
              letterSpacing: -1.0 / 32 * 32,
            ),
          ),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: c.fg,
            letterSpacing: -1.0 / 32 * 32,
            height: 1.20,
          ),
        ),
        const SizedBox(height: LingBiTokens.space8),
        Expanded(
          child: QuillEditor.basic(
            controller: _quillController,
            focusNode: _quillFocusNode,
            config: const QuillEditorConfig(
              placeholder: '开始写作…',
              scrollable: false,
              expands: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiWritingPanel(LingBiColors c) {
    return Container(
      padding: const EdgeInsets.all(LingBiTokens.space3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text('AI 写作',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.fg)),
              const Spacer(),
              if (_selectedSkill != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _selectedSkill!.name,
                    style: TextStyle(fontSize: 11, color: c.accent),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: c.muted),
                onPressed: () => setState(() => _showAiPanel = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          // 模型状态栏
          const SizedBox(height: 8),
          const ModelStatusBar(compact: true),
          const SizedBox(height: 8),
          // 输入区
          TextField(
            controller: _instructionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '输入写作要求，如“续写主角进入咖啡馆的场景”…',
              hintStyle: TextStyle(fontSize: 13, color: c.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                    color: c.borderOpaque.withValues(alpha: 0.3)),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            style: TextStyle(fontSize: 13, color: c.fg),
            onSubmitted: (_) => _startGeneration(),
          ),
          const SizedBox(height: 8),
          // 操作按钮
          Row(
            children: [
              if (_isGenerating)
                TextButton.icon(
                  onPressed: _cancelGeneration,
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('停止'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                )
              else
                FilledButton.icon(
                  onPressed: _startGeneration,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('开始生成'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _onSlashDetected,
                child: Text('选择技能 (/)',
                    style: TextStyle(fontSize: 12, color: c.muted)),
              ),
            ],
          ),
          // 错误提示（使用 ErrorBanner）
          if (_aiError != null) ...[
            const SizedBox(height: 6),
            ErrorBanner(
              error: UserFacingError(
                title: '生成错误',
                message: _aiError!,
                dataRetained: _streamingText.isNotEmpty,
                nextStep: '请检查配置或重试',
                canRetry: true,
                recoveryAction: RecoveryAction.retry,
              ),
              onRetry: _startGeneration,
              onDismiss: () => setState(() => _aiError = null),
            ),
          ],
          // 流式输出预览
          if (_streamingText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: c.borderOpaque.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _streamingText,
                  style: TextStyle(fontSize: 13, color: c.fg, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBar(LingBiColors c) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space4),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(LingBiIcons.wordCount, size: 12, color: c.muted),
          const SizedBox(width: LingBiTokens.space1),
          Text(
            '${_content.length} 字',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.muted,
            ),
          ),
          const SizedBox(width: LingBiTokens.space4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: c.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: LingBiTokens.space4),
          Text(
            _saving ? '保存中…' : (_isDirty ? '未保存' : '自动保存'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: c.muted,
            ),
          ),
          const SizedBox(width: LingBiTokens.space1),
          Icon(
            LingBiIcons.check,
            size: 12,
            color: _isDirty ? c.muted.withValues(alpha: 0.5) : LingBiTokens.success,
          ),
        ],
      ),
    );
  }
}
