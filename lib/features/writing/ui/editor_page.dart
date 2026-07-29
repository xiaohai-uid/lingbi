import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/errors/ai_error.dart';
import 'package:lingbi/shared/models/document.dart' as app;
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/features/writing/services/agent/novel_writing_loop.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_state_store.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_workflow.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';
import 'package:lingbi/ui_v2/theme/lingbi_icons.dart';
import 'writing_toolbar.dart';
import 'package:lingbi/ui_v2/components/slash_command_menu.dart';
import 'candidate_panel.dart';
import 'package:lingbi/ui_v2/components/model_status_bar.dart';
import 'package:lingbi/ui_v2/components/error_banner.dart';
import 'package:lingbi/ui_v2/services/command_palette_service.dart';
import 'package:lingbi/features/review/data/clarity_check_service.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    this.projectId,
    this.documentId,
    this.documentTitle,
    this.projectDirectoryPath,
    this.commandService,
  });
  final String? projectId;
  final String? documentId;
  final String? documentTitle;
  final String? projectDirectoryPath;
  final CommandPaletteService? commandService;

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
  bool _isRemovingSlash = false;
  int _lastSlashIndex = -1;

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
  FirstChapterWorkflowController? _chapterWorkflow;

  // AI 续写下一章（NovelWritingLoop）：待确认候选，采纳后原子写入新章节文件
  ChapterCandidate? _pendingLoopCandidate;

  // T4: 清晰度检查状态
  final ClarityCheckService _clarityCheck = ClarityCheckService();
  ClarityCheckResult? _pendingClarification;
  String _streamingProcess = '';

  @override
  void initState() {
    super.initState();
    _quillFocusNode = FocusNode();
    _quillController = QuillController.basic();
    _subscribeChanges();
    widget.commandService?.events.addListener(_onAppCommand);
    _loadDocument();
  }

  void _onAppCommand() {
    if (widget.commandService?.events.value == AppCommand.save) {
      _save();
    }
  }

  void _subscribeChanges() {
    _changesSubscription?.cancel();
    _changesSubscription = _quillController.document.changes.listen((change) {
      if (!_contentLoaded) return;

      // 检测 "/" 输入以触发斜杠命令菜单（仅响应用户本地输入）
      if (!_isRemovingSlash && change.source == ChangeSource.local) {
        _detectSlashInsert(change);
      }

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

  /// 检查变更 delta 中是否包含满足触发条件的 "/" 插入操作。
  void _detectSlashInsert(DocChange change) {
    int position = 0;
    for (final op in change.change.toList()) {
      if (op.isRetain) {
        position += op.length ?? 0;
      } else if (op.isInsert && op.data is String) {
        final text = op.data as String;
        final slashIdx = text.indexOf('/');
        if (slashIdx >= 0) {
          final absIndex = position + slashIdx;
          final fullText = _extractPlainText();
          final validTrigger = absIndex == 0 ||
              (absIndex > 0 &&
                  (fullText[absIndex - 1] == '\n' ||
                      fullText[absIndex - 1] == ' '));
          if (validTrigger) {
            _lastSlashIndex = absIndex;
            _onSlashDetected();
            return;
          }
        }
        position += text.length;
      } else if (op.isInsert) {
        // 嵌入式对象插入（非文本），占 1 个位置
        position += 1;
      }
      // 删除操作不影响文档位置偏移
    }
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
    if (oldWidget.commandService != widget.commandService) {
      oldWidget.commandService?.events.removeListener(_onAppCommand);
      widget.commandService?.events.addListener(_onAppCommand);
    }
    if (oldWidget.projectId != widget.projectId ||
        oldWidget.projectDirectoryPath != widget.projectDirectoryPath) {
      _chapterWorkflow = null;
    }
    if (oldWidget.documentId != widget.documentId ||
        oldWidget.projectId != widget.projectId) {
      _loadDocument();
    }
  }

  void _loadQuillContent(String content) {
    _contentLoaded = false;
    _changesSubscription?.cancel();
    widget.commandService?.events.removeListener(_onAppCommand);
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
        _document = null;
        _title = widget.documentTitle ?? '';
        _content = '';
      });
      _loadQuillContent('');
      _titleController.text = _title;
      return;
    }
    try {
      final doc = await ServiceLocator.instance.documentService
          .getDocument(widget.documentId!);
      if (doc == null) {
        setState(() {
          _document = null;
          _title = widget.documentTitle ?? '';
          _content = '';
        });
        _loadQuillContent('');
        _titleController.text = _title;
        return;
      }
      final content = await ServiceLocator.instance.documentService
          .readContent(doc.filePath);
      if (!mounted) return;
      setState(() {
        _document = null;
        _document = doc;
        _title = widget.documentTitle ?? doc.title;
        _content = content;
      });
      _loadQuillContent(content);
      _titleController.text = _title;
      await _restoreFirstChapterWorkflow();
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

  FirstChapterWorkflowController? _createChapterWorkflow() {
    final projectId = widget.projectId;
    final projectDirectory = widget.projectDirectoryPath;
    if (projectId == null ||
        projectId.isEmpty ||
        projectDirectory == null ||
        projectDirectory.isEmpty) {
      return null;
    }
    final locator = ServiceLocator.instance;
    final application = NovelApplicationService(
      projectDir: projectDirectory,
      projectId: projectId,
      documentService: locator.documentService,
      canonService: locator.canonService,
      aiService: locator.aiService,
    );
    return FirstChapterWorkflowController(
      pipeline: NovelFirstChapterPipeline(application),
      stateStore:
          FileFirstChapterStateStore(projectDirectory: projectDirectory),
    );
  }

  Future<void> _restoreFirstChapterWorkflow() async {
    final projectId = widget.projectId;
    if (projectId == null || _document == null) return;
    _chapterWorkflow ??= _createChapterWorkflow();
    final state = await _chapterWorkflow?.resume(projectId);
    if (!mounted ||
        state == null ||
        state.chapterId != _document!.id ||
        state.stage != FirstChapterStage.waitingForConfirmation ||
        state.candidateId == null) {
      return;
    }
    setState(() {
      _currentCandidate = CandidateEntry(
        id: state.candidateId!,
        chapterId: state.chapterId,
        content: state.candidateContent ?? '',
        model: ServiceLocator.instance.aiService.currentProviderName,
        createdAt: state.updatedAt,
      );
      _showCandidatePanel = true;
      _aiError = state.error;
    });
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
    if (widget.projectDirectoryPath == null ||
        widget.projectDirectoryPath!.isEmpty) {
      return '项目目录不可用，无法安全保存候选稿';
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

    // T4: 清晰度检查
    final clarityResult = _clarityCheck.assess(instruction);
    if (clarityResult.needsClarification) {
      setState(() => _pendingClarification = clarityResult);
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
      _streamingProcess = '';
    });

    try {
      final workflow = _chapterWorkflow ??= _createChapterWorkflow();
      final document = _document;
      if (workflow == null || document == null) {
        throw StateError('缺少项目目录或章节文件，无法启动安全生成');
      }
      final buffer = StringBuffer();
      final skillId = _selectedSkill?.id ?? 'smart-continuation';
      final request = FirstChapterRequest(
        projectId: widget.projectId!,
        chapterId: document.id,
        targetFilePath: document.filePath,
        instruction: '技能: $skillId。\n$instruction',
      );

      await for (final event in workflow.start(request)) {
        if (!mounted) return;
        if (event.contentChunk != null) {
          buffer.write(event.contentChunk);
          setState(() => _streamingText = buffer.toString());
        }
        setState(() => _streamingProcess = event.message);
        if (event.stage == FirstChapterStage.failed) {
          setState(() {
            _isGenerating = false;
            _aiError = event.message;
          });
          return;
        }
      }

      if (mounted) {
        final state = await workflow.resume(widget.projectId!);
        if (!mounted || state?.candidateId == null) return;
        setState(() {
          _isGenerating = false;
          _currentCandidate = CandidateEntry(
            id: state!.candidateId!,
            chapterId: state.chapterId,
            content: state.candidateContent ?? buffer.toString(),
            model: ServiceLocator.instance.aiService.currentProviderName,
            createdAt: state.updatedAt,
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

  /// T4: 用户选择快速选项后继续生成
  void _onClarificationOption(String option) {
    final original = _instructionController.text.trim();
    _instructionController.text = '$original（$option）';
    setState(() => _pendingClarification = null);
    _startGeneration();
  }

  /// T4: 用户跳过确认直接生成
  void _onSkipClarification() {
    setState(() => _pendingClarification = null);
    _startGeneration();
  }

  void _cancelGeneration() {
    _chapterWorkflow?.cancel();
    setState(() {
      _isGenerating = false;
      _streamingText = '';
      _streamingProcess = '';
    });
  }

  /// AI 续写下一章（对标 OpenWrite）：调用 [NovelWritingLoop] 编排器，
  /// 读维护文档+最近章节、经 ContextCompiler 压缩上下文后生成候选正文，
  /// 不直接落盘——复用现有候选确认组件 [CandidatePanel]，采纳后写入新章节文件。
  Future<void> _continueNextChapter() async {
    final projectDirectory = widget.projectDirectoryPath;
    if (projectDirectory == null || projectDirectory.isEmpty) {
      setState(() => _aiError = '项目目录不可用，无法续写下一章');
      return;
    }
    setState(() {
      _isGenerating = true;
      _aiError = null;
      _streamingText = '';
      _streamingProcess = '正在读取人物库/世界观与最近章节…';
    });
    try {
      final locator = ServiceLocator.instance;
      final loop = NovelWritingLoop(
        provider: locator.aiService.currentProvider,
        projectDir: projectDirectory,
        canonService: locator.canonService,
        projectId: widget.projectId,
      );
      final candidate = await loop.proposeNextChapter(
        guidance: _instructionController.text.trim().isEmpty
            ? null
            : _instructionController.text.trim(),
      );
      if (!mounted) return;
      if (candidate.isEmpty) {
        setState(() {
          _isGenerating = false;
          _aiError = candidate.warnings.isNotEmpty
              ? candidate.warnings.join('\n')
              : '未生成可见正文，请重试或切换非推理模型';
        });
        return;
      }
      setState(() {
        _isGenerating = false;
        _pendingLoopCandidate = candidate;
        _currentCandidate = CandidateEntry(
          id: 'loop-ch${candidate.chapterNumber}',
          chapterId: '第${candidate.chapterNumber}章',
          content: candidate.content,
          model: locator.aiService.currentProviderName,
          createdAt: DateTime.now(),
        );
        _showCandidatePanel = true;
        _aiError = candidate.warnings.isEmpty ? null : candidate.warnings.join('\n');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _aiError = '续写失败: $e';
      });
    }
  }

  /// 采纳续写候选：经 [NovelWritingLoop.commitChapter] 原子写入新章节文件。
  Future<void> _commitLoopCandidate() async {
    final candidate = _pendingLoopCandidate;
    final projectDirectory = widget.projectDirectoryPath;
    if (candidate == null || projectDirectory == null) return;
    try {
      final locator = ServiceLocator.instance;
      final loop = NovelWritingLoop(
        provider: locator.aiService.currentProvider,
        projectDir: projectDirectory,
        canonService: locator.canonService,
        projectId: widget.projectId,
      );
      final result = await loop.commitChapter(candidate);
      if (!mounted) return;
      setState(() {
        _pendingLoopCandidate = null;
        _showCandidatePanel = false;
        _currentCandidate = null;
        _aiError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已写入：${result.chapterPath}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = '章节落盘失败: $e');
    }
  }

  void _onSlashDetected() {
    final skills = ServiceLocator.instance.skillActionService.registeredSkills;
    if (skills.isNotEmpty) {
      setState(() => _showSlashMenu = true);
    }
  }

  void _onSkillSelected(SkillAction skill) {
    // 删除触发菜单的 "/" 字符
    if (_lastSlashIndex >= 0) {
      _isRemovingSlash = true;
      _quillController.replaceText(_lastSlashIndex, 1, '', null);
      _isRemovingSlash = false;
      _lastSlashIndex = -1;
    }
    setState(() {
      _selectedSkill = skill;
      _showSlashMenu = false;
      _showAiPanel = true;
    });
  }

  // ---------------------------------------------------------------------------
  // 候选采纳（编辑器内存操作，进入撤销栈）
  // ---------------------------------------------------------------------------

  Future<void> _handleAdopt(AdoptMode mode) async {
    // 续写下一章候选：写入新章节文件（不走编辑器内存采纳）。
    if (_pendingLoopCandidate != null) {
      await _commitLoopCandidate();
      return;
    }
    final candidate = _currentCandidate;
    final workflow = _chapterWorkflow;
    if (candidate == null || workflow == null) return;
    final result = await workflow.adopt(candidate.id);
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() => _aiError = result.message);
      return;
    }
    await _loadDocument();
    if (!mounted) return;
    setState(() {
      _isDirty = false;
      _showCandidatePanel = false;
      _currentCandidate = null;
      _streamingText = '';
      _aiError = null;
    });
  }

  Future<void> _handleDiscard() async {
    if (_pendingLoopCandidate != null) {
      if (!mounted) return;
      setState(() {
        _pendingLoopCandidate = null;
        _showCandidatePanel = false;
        _currentCandidate = null;
        _streamingText = '';
      });
      return;
    }
    final candidate = _currentCandidate;
    if (candidate != null) await _chapterWorkflow?.reject(candidate.id);
    if (!mounted) return;
    setState(() {
      _showCandidatePanel = false;
      _currentCandidate = null;
      _streamingText = '';
    });
  }

  Future<void> _handleRegenerate() async {
    final wasLoopCandidate = _pendingLoopCandidate != null;
    await _handleDiscard();
    if (!mounted) return;
    if (wasLoopCandidate) {
      _continueNextChapter();
    } else {
      _startGeneration();
    }
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
                  safeReplaceOnly: true,
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
                        skills: ServiceLocator
                            .instance.skillActionService.registeredSkills,
                        onSelected: _onSkillSelected,
                        onDismiss: () => setState(() => _showSlashMenu = false),
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
                      fontSize: 13, fontWeight: FontWeight.w600, color: c.fg)),
              const Spacer(),
              if (_selectedSkill != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                borderSide:
                    BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
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
              if (!_isGenerating)
                OutlinedButton.icon(
                  onPressed: _continueNextChapter,
                  icon: const Icon(Icons.auto_stories, size: 16),
                  label: const Text('AI 续写下一章'),
                  style: OutlinedButton.styleFrom(foregroundColor: c.accent),
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
          // T4: 确认卡（模糊请求追问）
          if (_pendingClarification != null) ...[
            const SizedBox(height: 6),
            _buildClarificationCard(c, _pendingClarification!),
          ],
          // 流式输出预览
          if (_streamingText.isNotEmpty || _streamingProcess.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: c.borderOpaque.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_streamingProcess.isNotEmpty) ...[
                      Text(
                        '💭 ${_streamingProcess.length > 80 ? '${_streamingProcess.substring(0, 80)}...' : _streamingProcess}',
                        style: TextStyle(
                            fontSize: 11,
                            color: c.muted,
                            fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_streamingText.isNotEmpty)
                      Text(
                        _streamingText,
                        style:
                            TextStyle(fontSize: 13, color: c.fg, height: 1.5),
                      ),
                  ],
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
            color: _isDirty
                ? c.muted.withValues(alpha: 0.5)
                : LingBiTokens.success,
          ),
        ],
      ),
    );
  }

  /// T4: 编辑器 AI 写作确认卡
  Widget _buildClarificationCard(LingBiColors c, ClarityCheckResult result) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 14, color: c.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.question,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.fg,
                  ),
                ),
              ),
            ],
          ),
          if (result.quickOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final option in result.quickOptions)
                  InkWell(
                    onTap: () => _onClarificationOption(option),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: option == '直接生成'
                            ? c.accent.withValues(alpha: 0.1)
                            : c.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
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
                          color: option == '直接生成' ? c.accent : c.fgSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          InkWell(
            onTap: _onSkipClarification,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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
    );
  }
}
