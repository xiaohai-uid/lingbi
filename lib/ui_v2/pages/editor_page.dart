import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/document.dart' as app;
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';
import '../components/writing_toolbar.dart';

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
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Format command handling (bridged to QuillController)
  // ---------------------------------------------------------------------------

  void _handleFormatCommand(String command) {
    switch (command) {
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
            Expanded(
              child: GestureDetector(
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
