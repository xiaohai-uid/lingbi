import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'editor_toolbar.dart';

class EditorPanel extends StatefulWidget {

  const EditorPanel({
    super.key,
    this.initialContent,
    this.documentTitle,
    this.onContentChanged,
    this.onSave,
  });
  final String? initialContent;
  final String? documentTitle;
  final ValueChanged<String>? onContentChanged;
  final Future<void> Function(String content)? onSave;

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late QuillController _controller;
  late FocusNode _focusNode;
  Timer? _autoSaveTimer;
  StreamSubscription? _changesSubscription;
  String _lastSavedContent = '';
  String _currentContent = '';
  bool _isDirty = false;
  SaveStatus _saveStatus = SaveStatus.saved;
  bool _contentLoaded = false;
  int _saveGeneration = 0; // 防止文档切换后旧保存覆盖新状态

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = QuillController.basic();
    _loadContent(widget.initialContent ?? '');
    _lastSavedContent = widget.initialContent ?? '';
    _currentContent = widget.initialContent ?? '';
    _contentLoaded = true;

    // 监听内容变化
    _changesSubscription = _controller.document.changes.listen((_) {
      if (!_contentLoaded) return;
      final text = plainText;
      if (text != _currentContent) {
        _currentContent = text;
        if (!_isDirty && text != _lastSavedContent) {
          setState(() {
            _isDirty = true;
            _saveStatus = SaveStatus.unsaved;
          });
        }
        widget.onContentChanged?.call(text);
      }
    });

    // 启动自动保存定时器（每 30 秒）
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSave();
    });
  }

  @override
  void didUpdateWidget(EditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 文档切换时保存当前内容
    if (widget.initialContent != oldWidget.initialContent) {
      // 使旧保存操作失效，防止其完成后覆盖新文档状态
      _saveGeneration++;
      // 如果当前有未保存内容，先保存
      if (_isDirty && widget.onSave != null) {
        final contentToSave = _currentContent;
        final onSave = widget.onSave!;
        // fire-and-forget：保存旧文档内容
        onSave(contentToSave).catchError((_) {});
      }
      // 再加载新文档
      _loadContent(widget.initialContent ?? '');
      _lastSavedContent = widget.initialContent ?? '';
      _currentContent = widget.initialContent ?? '';
      setState(() {
        _isDirty = false;
        _saveStatus = SaveStatus.saved;
      });
    }
  }

  @override
  void dispose() {
    // 退出时保存
    if (_isDirty) {
      _performSave();
    }
    _autoSaveTimer?.cancel();
    _changesSubscription?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _loadContent(String content) {
    _contentLoaded = false;
    // 取消旧订阅并释放旧控制器
    _changesSubscription?.cancel();
    final oldController = _controller;
    final doc = Document()..insert(0, content);
    _controller = QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
    // 释放旧控制器（初始化时 _controller 已存在）
    if (oldController.document != doc) {
      oldController.dispose();
    }
    // 重新订阅新控制器的变化
    _changesSubscription = _controller.document.changes.listen((_) {
      if (!_contentLoaded) return;
      final text = plainText;
      if (text != _currentContent) {
        _currentContent = text;
        if (!_isDirty && text != _lastSavedContent) {
          setState(() {
            _isDirty = true;
            _saveStatus = SaveStatus.unsaved;
          });
        }
        widget.onContentChanged?.call(text);
      }
    });
    _contentLoaded = true;
  }

  String get plainText {
    final buffer = StringBuffer();
    for (final node in _controller.document.toDelta().toList()) {
      if (node.data is String) {
        buffer.write(node.data);
      }
    }
    return buffer.toString();
  }

  Future<void> _autoSave() async {
    if (!_isDirty || widget.onSave == null) return;
    await _performSave();
  }

  Future<void> _performSave() async {
    if (widget.onSave == null) return;
    final generation = _saveGeneration;
    setState(() => _saveStatus = SaveStatus.saving);
    try {
      await widget.onSave!(_currentContent);
      // 如果文档已切换，丢弃这次保存结果
      if (generation != _saveGeneration) return;
      _lastSavedContent = _currentContent;
      setState(() {
        _isDirty = false;
        _saveStatus = SaveStatus.saved;
      });
    } catch (e) {
      if (generation != _saveGeneration) return;
      setState(() => _saveStatus = SaveStatus.error);
    }
  }

  IconData _saveIcon() {
    switch (_saveStatus) {
      case SaveStatus.saved:
        return Icons.check_circle_outline;
      case SaveStatus.unsaved:
        return Icons.edit_outlined;
      case SaveStatus.saving:
        return Icons.hourglass_top;
      case SaveStatus.error:
        return Icons.error_outline;
    }
  }

  Color _saveColor(ThemeData theme) {
    switch (_saveStatus) {
      case SaveStatus.saved:
        return Colors.green;
      case SaveStatus.unsaved:
        return Colors.orange;
      case SaveStatus.saving:
        return theme.colorScheme.primary;
      case SaveStatus.error:
        return Colors.red;
    }
  }

  String _saveLabel() {
    switch (_saveStatus) {
      case SaveStatus.saved:
        return '已保存';
      case SaveStatus.unsaved:
        return '未保存';
      case SaveStatus.saving:
        return '保存中...';
      case SaveStatus.error:
        return '保存失败';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _performSave,
      },
      child: Focus(
        autofocus: true,
        child: Column(
      children: [
        // 标题栏
        if (widget.documentTitle != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.documentTitle!,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // 保存状态指示
                Tooltip(
                  message: _saveLabel(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _saveColor(theme).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_saveIcon(), size: 14, color: _saveColor(theme)),
                        const SizedBox(width: 4),
                        Text(
                          _saveLabel(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _saveColor(theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        // 工具栏
        EditorToolbar(
          controller: _controller,
          onSave: _isDirty ? _performSave : null,
        ),
                // 编辑器主体
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              config: const QuillEditorConfig(
                placeholder: '开始写作...',
                padding: EdgeInsets.symmetric(vertical: 20),
                expands: true,
              ),
            ),
          ),
        ),
        // 底部状态栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Text(
                '字数: ${_currentContent.length}',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 16),
              Text(
                '行数: ${_currentContent.split('\n').length}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
      ),
      ),
    );
  }
}

enum SaveStatus { saved, unsaved, saving, error }
