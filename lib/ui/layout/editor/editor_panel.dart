import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingbi/utils/word_counter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'editor_toolbar.dart';

import 'package:lingbi/data/database/world_database.dart' as db;
import 'package:lingbi/services/identity/identity_detector.dart';
import 'package:lingbi/services/retroactive_edit_service.dart';
import 'package:lingbi/services/interfaces/i_retroactive_edit_service.dart';
import 'package:lingbi/ui/components/selection_edit_popup.dart';
import 'package:lingbi/services/identity/identity_rules.dart';
import 'package:lingbi/ui/components/identity_notification.dart';
import 'package:lingbi/ui/components/identity_dialog.dart';

class EditorPanel extends StatefulWidget {
  const EditorPanel({
    super.key,
    this.initialContent,
    this.documentTitle,
    this.onContentChanged,
    this.onSave,
    this.identityDetector,
    this.worldId,
    this.sceneId,
    this.characters = const [],
    this.onConfirmIdentity,
    this.onIgnoreAllIdentities,
    this.retroactiveEditService,
  });
  final String? initialContent;
  final String? documentTitle;
  final ValueChanged<String>? onContentChanged;
  final Future<void> Function(String content)? onSave;
  final IdentityDetector? identityDetector;
  final String? worldId;
  final String? sceneId;
  final List<db.Character> characters;
  final RetroactiveEditService? retroactiveEditService;
  final void Function(IdentityCandidate)? onConfirmIdentity;
  final VoidCallback? onIgnoreAllIdentities;

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late QuillController _controller;
  late FocusNode _focusNode;
  Timer? _autoSaveTimer;
  Timer? _detectTimer;
  StreamSubscription? _changesSubscription;
  String _lastSavedContent = '';
  String _currentContent = '';
  bool _isDirty = false;
  SaveStatus _saveStatus = SaveStatus.saved;
  bool _contentLoaded = false;
  DetectionResult? _detectionResult;
  bool _showEditPopup = false;
  String _selectedText = "";
  int _selectionStart = 0;
  int _selectionEnd = 0;
  bool _canUndo = false;
  String _lastContentBeforeEdit = "";

  bool get _identityEnabled =>
      widget.identityDetector != null && widget.sceneId != null;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = QuillController.basic();
    _loadContent(widget.initialContent ?? '');
    _lastSavedContent = widget.initialContent ?? '';
    _currentContent = widget.initialContent ?? '';
    _contentLoaded = true;

    _changesSubscription = _controller.document.changes.listen(_onDocChanged);
    _controller.selectionChanges.listen(_onSelectionChanged);

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSave();
    });
  }

  void _onSelectionChanged(_) {
    final sel = _controller.selection;
    if (sel.isValid && !sel.isCollapsed) {
      final text = _controller.document.sublist(sel.start, sel.end);
      setState(() {
        _selectedText = text;
        _selectionStart = sel.start;
        _selectionEnd = sel.end;
        _showEditPopup = true;
      });
    } else {
      if (_showEditPopup) {
        setState(() => _showEditPopup = false);
      }
    }
  }

  void _onDocChanged(_) {
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
      _scheduleIdentityDetection();
    }
  }

  void _scheduleIdentityDetection() {
    if (!_identityEnabled) return;
    _detectTimer?.cancel();
    _detectTimer = Timer(const Duration(milliseconds: 2500), _runDetection);
  }

  Future<void> _runDetection() async {
    if (!_identityEnabled) return;
    try {
      final result = await widget.identityDetector!.detect(
        sceneText: _currentContent,
        sceneCharacters: widget.characters,
        sceneId: widget.sceneId!,
        volumeId: '',
      );
      if (result.hasResults && mounted) {
        setState(() => _detectionResult = result);
      }
    } catch (_) {
      // 身份检测为辅助功能，失败不影响写作
    }
  }

  @override
  void didUpdateWidget(EditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContent != oldWidget.initialContent) {
      _loadContent(widget.initialContent ?? '');
      _lastSavedContent = widget.initialContent ?? '';
      _currentContent = widget.initialContent ?? '';
      setState(() {
        _isDirty = false;
        _saveStatus = SaveStatus.saved;
        _detectionResult = null;
      });
    }
  }

  @override
  void dispose() {
    if (_isDirty) {
      _performSave();
    }
    _autoSaveTimer?.cancel();
    _detectTimer?.cancel();
    _changesSubscription?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _loadContent(String content) {
    _contentLoaded = false;
    _changesSubscription?.cancel();
    final doc = Document()..insert(0, content);
    _controller = QuillController(
        document: doc, selection: const TextSelection.collapsed(offset: 0));
    _changesSubscription = _controller.document.changes.listen(_onDocChanged);
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

  Future<void> _handleEdit(EditMode mode, {String? targetTone}) async {
    if (widget.retroactiveEditService == null) return;
    _lastContentBeforeEdit = _currentContent;
    final service = widget.retroactiveEditService!;
    service.snapshotBefore('editor', _currentContent);
    try {
      final result = await service.edit(
        selectedText: _selectedText,
        fullContext: _currentContent,
        mode: mode,
        targetTone: targetTone,
        startOffset: _selectionStart,
        endOffset: _selectionEnd,
      );
      final before = _currentContent.substring(0, _selectionStart);
      final after = _currentContent.substring(_selectionEnd);
      final newContent = before + result.newText + after;
      service.snapshotAfter('editor', _currentContent, newContent);
      _loadContent(newContent);
      _currentContent = newContent;
      widget.onContentChanged?.call(newContent);
      setState(() {
        _showEditPopup = false;
        _canUndo = true;
        _isDirty = true;
        _saveStatus = SaveStatus.unsaved;
      });
    } catch (_) {
      _loadContent(_lastContentBeforeEdit);
    }
  }

  Future<void> _handleUndo() async {
    if (widget.retroactiveEditService == null) return;
    final previous = await widget.retroactiveEditService!.undo('editor');
    if (previous != null) {
      _loadContent(previous);
      _currentContent = previous;
      widget.onContentChanged?.call(previous);
      setState(() {
        _showEditPopup = false;
        _canUndo = false;
      });
    }
  }

  Future<void> _autoSave() async {
    if (!_isDirty || widget.onSave == null) return;
    await _performSave();
  }

  Future<void> _performSave() async {
    if (widget.onSave == null) return;
    setState(() => _saveStatus = SaveStatus.saving);
    try {
      await widget.onSave!(_currentContent);
      _lastSavedContent = _currentContent;
      setState(() {
        _isDirty = false;
        _saveStatus = SaveStatus.saved;
      });
    } catch (e) {
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

  void _showIdentityDialog() {
    final result = _detectionResult;
    if (result == null) return;
    final nameMap = {for (final c in widget.characters) c.id: c.name};
    showDialog<void>(
      context: context,
      builder: (ctx) => IdentityConfirmDialog(
        result: result,
        characterNameOf: (id) => nameMap[id] ?? '未知角色',
        onConfirm: (c) => widget.onConfirmIdentity?.call(c),
        onIgnoreAll: () => widget.onIgnoreAllIdentities?.call(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _performSave,
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            Column(
              children: [
                if (widget.documentTitle != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(48, 24, 48, 4),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF2A2A50)
                            : const Color(0xFFE5E0EC),
                      )),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.documentTitle!,
                            style: (isDark
                                    ? theme.textTheme.headlineMedium
                                    : theme.textTheme.headlineSmall)
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE8E6E0),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: _saveLabel(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _saveColor(theme).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_saveIcon(),
                                    size: 14, color: _saveColor(theme)),
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
                EditorToolbar(
                  controller: _controller,
                  onSave: _isDirty ? _performSave : null,
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                    child: QuillEditor.basic(
                      controller: _controller,
                      focusNode: _focusNode,
                      config: const QuillEditorConfig(
                        placeholder: '开始写作...',
                        padding: EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14142A)
                        : const Color(0xFFF7F6F9),
                    border: Border(
                        top: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A2A50)
                          : const Color(0xFFE5E0EC),
                    )),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '字数: ${countWords(_currentContent)}',
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
            if (_showEditPopup)
              Positioned(
                top: 100,
                right: 24,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: SelectionEditPopup(
                    selectedText: _selectedText,
                    canUndo: _canUndo,
                    onEdit: _handleEdit,
                    onUndo: _canUndo ? _handleUndo : null,
                  ),
                ),
              ),
            if (_detectionResult != null && _detectionResult!.hasResults)
              Positioned(
                top: widget.documentTitle != null ? 88 : 16,
                right: 24,
                child: IdentityNotificationBubble(
                  candidates: _detectionResult!.candidates,
                  onTap: _showIdentityDialog,
                  onDismiss: () => setState(() => _detectionResult = null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum SaveStatus { saved, unsaved, saving, error }
