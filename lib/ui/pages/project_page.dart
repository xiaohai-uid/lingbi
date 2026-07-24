import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/version_history_service.dart';
import 'package:lingbi/services/export_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/modules/pipeline/project_session_scope.dart';
import 'package:lingbi/ui/layout/main_scaffold.dart';
import 'package:lingbi/ui/layout/editor/editor_panel.dart';
import 'package:lingbi/ui/layout/sidebar/project_tree.dart';
import 'package:lingbi/ui/layout/ai_panel/ai_panel.dart';
import 'package:lingbi/ui/pages/settings_page.dart';
import 'package:lingbi/ui/pages/canon_page.dart';
import 'package:lingbi/ui/pages/story_canvas_page.dart';
import 'package:lingbi/ui/widgets/novel_writing_panel.dart';
import 'package:lingbi/ui/widgets/version_history_panel.dart';

class ProjectPage extends StatefulWidget {

  const ProjectPage({super.key, required this.project});
  final Project project;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  final DocumentService _documentService = ServiceLocator.instance.documentService;
  final ExportService _exportService = ServiceLocator.instance.exportService;
  final VersionHistoryService _versionHistory = ServiceLocator.instance.versionHistoryService;
  Document? _currentDocument;
  String _editorContent = '';
  bool _isDirty = false;
  late ProjectSessionScope _session;

  @override
  void initState() {
    super.initState();
    _session = ProjectSessionScope(
      projectId: widget.project.id,
      projectDir: widget.project.directoryPath,
      documentService: ServiceLocator.instance.documentService,
      canonService: ServiceLocator.instance.canonService,
      aiService: ServiceLocator.instance.aiService,
    );
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _saveDocument(String content) async {
    if (_currentDocument == null) return;
    try {
      await _documentService.saveDocument(_currentDocument!, content);
      // 保存版本快照
      _versionHistory.saveVersion(
        projectDir: widget.project.directoryPath,
        docId: _currentDocument!.id,
        content: content,
      ).catchError((_) {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
      rethrow;
    }
  }

  Future<void> _onDocumentSelected(Document doc) async {
    try {
      final content = await _documentService.readContent(doc.filePath);
      setState(() {
        _currentDocument = doc;
        _editorContent = content;
        _isDirty = false;
      });
      // 绑定章节到项目会话
      _session.bindChapter(chapterId: doc.id, filePath: doc.filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _newDocument() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建文档'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '文档标题', hintText: '例如：第1章'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) Navigator.pop(ctx, controller.text);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final doc = await _documentService.createDocument(
          projectId: widget.project.id, title: result,
          directoryPath: widget.project.directoryPath,
        );
        _onDocumentSelected(doc);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }

  /// 导入文档
  Future<void> _importDocuments() async {
    final files = await FilePicker.platform.pickFiles(
      dialogTitle: '选择要导入的文档',
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
      allowMultiple: true,
    );
    if (files == null || files.paths.isEmpty || !mounted) return;

    int successCount = 0;
    int failCount = 0;

    for (final path in files.paths) {
      if (path == null) continue;
      try {
        final file = File(path);
        final content = await file.readAsString();
        final fileName = file.uri.pathSegments.last;
        // 去掉扩展名作为标题
        final title = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;

        await _documentService.createDocument(
          projectId: widget.project.id,
          title: title,
          directoryPath: widget.project.directoryPath,
          content: content,
        );
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      _showMessage("导入完成: $successCount 个成功${failCount > 0 ? ', $failCount 个失败' : ''}");
    }
  }

  void _openCanon() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CanonPage(projectId: widget.project.id, projectName: widget.project.name),
    ));
  }

  void _openStoryCanvas() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StoryCanvasPage(projectId: widget.project.id, projectName: widget.project.name),
    ));
  }

  /// 导出当前文档
  Future<void> _exportDocument(String format) async {
    if (_currentDocument == null) {
      _showMessage('请先打开一个文档');
      return;
    }

    final extension = format == 'md' ? 'md' : format;
    final fileName = '${_currentDocument!.title}.$extension';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '导出文档',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    if (savePath == null || !mounted) return;

    try {
      switch (format) {
        case 'md':
          await _exportService.exportAsMarkdown(
            content: _editorContent,
            savePath: savePath,
          );
        case 'txt':
          await _exportService.exportAsTxt(
            content: _editorContent,
            savePath: savePath,
          );
        case 'pdf':
          await _exportService.exportAsPdf(
            title: _currentDocument!.title,
            content: _editorContent,
            savePath: savePath,
          );
      }
      _showMessage('文档已导出为 $format 格式');
    } catch (e) {
      _showError('导出失败: $e');
    }
  }

  /// 导出整个项目
  Future<void> _exportProject(String format) async {
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择导出目录',
    );
    if (outputDir == null || !mounted) return;

    try {
      final documents = await _documentService.getDocuments(widget.project.id);
      final contents = <String, String>{};
      for (final doc in documents) {
        try {
          contents[doc.id] = await _documentService.readContent(doc.filePath);
        } catch (_) {
          contents[doc.id] = '';
        }
      }

      await _exportService.exportProjectToDirectory(
        project: widget.project,
        documents: documents,
        contents: contents,
        outputDir: outputDir,
        format: format,
      );
      _showMessage('项目已导出为 $format 格式到 $outputDir');
    } catch (e) {
      _showError('项目导出失败: $e');
    }
  }

  void _showExportMenu() {
    final renderBox = context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        renderBox.size.width - 200, kToolbarHeight, renderBox.size.width, kToolbarHeight + 200,
      ),
      items: [
        const PopupMenuItem(value: 'doc_md', child: ListTile(leading: Icon(Icons.description), title: Text('导出当前文档 (Markdown)'), dense: true)),
        const PopupMenuItem(value: 'doc_txt', child: ListTile(leading: Icon(Icons.text_snippet), title: Text('导出当前文档 (TXT)'), dense: true)),
        const PopupMenuItem(value: 'doc_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('导出当前文档 (PDF)'), dense: true)),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'proj_md', child: ListTile(leading: Icon(Icons.folder), title: Text('导出整个项目 (Markdown)'), dense: true)),
        const PopupMenuItem(value: 'proj_txt', child: ListTile(leading: Icon(Icons.folder), title: Text('导出整个项目 (TXT)'), dense: true)),
        const PopupMenuItem(value: 'proj_pdf', child: ListTile(leading: Icon(Icons.folder), title: Text('导出整个项目 (PDF)'), dense: true)),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'doc_md': _exportDocument('md');
        case 'doc_txt': _exportDocument('txt');
        case 'doc_pdf': _exportDocument('pdf');
        case 'proj_md': _exportProject('md');
        case 'proj_txt': _exportProject('txt');
        case 'proj_pdf': _exportProject('pdf');
      }
    });
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  /// 构建 AI 面板区域（包含聊天 + 写作两个 Tab）
  Widget _buildAiPanelArea() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'AI 对话', icon: Icon(Icons.chat_bubble_outline, size: 16)),
              Tab(text: 'AI 写作', icon: Icon(Icons.auto_stories, size: 16)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                AIPanel(projectId: widget.project.id, projectName: widget.project.name),
                _buildWritingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 写作 Tab 内容
  Widget _buildWritingTab() {
    if (_currentDocument == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text('请先在左侧选择一个章节', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return NovelWritingPanel(
      service: _session.novelService,
      chapterId: _currentDocument!.id,
      targetFilePath: _currentDocument!.filePath,
      originalContent: _editorContent,
      onAdopted: _onCandidateAdopted,
      isDirty: _isDirty,
      onSaveBeforeWrite: _saveBeforeWrite,
    );
  }

  /// 采纳后刷新编辑器
  Future<void> _onCandidateAdopted() async {
    if (_currentDocument == null) return;
    try {
      final content = await _documentService.readContent(_currentDocument!.filePath);
      setState(() {
        _editorContent = content;
        _isDirty = false;
      });
      _showMessage('✅ 候选已采纳，编辑器已刷新');
    } catch (e) {
      _showError('刷新编辑器失败: $e');
    }
  }

  /// AI 写作前强制保存
  Future<bool> _saveBeforeWrite() async {
    if (_currentDocument == null) return false;
    try {
      await _saveDocument(_editorContent);
      setState(() => _isDirty = false);
      return true;
    } catch (e) {
      _showError('保存失败，无法开始 AI 写作: $e');
      return false;
    }
  }

  void _openVersionHistory() {
    if (_currentDocument == null) {
      _showMessage('请先打开一个文档');
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VersionHistoryPanel(
        document: _currentDocument!,
        projectDir: widget.project.directoryPath,
        onRestore: (content) async {
          await _saveDocument(_editorContent);
          await _documentService.saveDocument(_currentDocument!, content);
          setState(() {
            _editorContent = content;
          });
        },
        onRefresh: () {},
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(icon: const Icon(Icons.auto_stories), tooltip: '正典 (Canon)', onPressed: _openCanon),
          IconButton(icon: const Icon(Icons.account_tree), tooltip: '故事画布', onPressed: _openStoryCanvas),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: '新建/导入',
            onSelected: (v) {
              if (v == 'new') _newDocument();
              if (v == 'import') _importDocuments();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'new', child: ListTile(leading: Icon(Icons.note_add), title: Text('新建文档'), dense: true)),
              const PopupMenuItem(value: 'import', child: ListTile(leading: Icon(Icons.file_open), title: Text('导入文档'), dense: true)),
            ],
          ),
          IconButton(icon: const Icon(Icons.history), tooltip: '版本历史', onPressed: _openVersionHistory),
          IconButton(icon: const Icon(Icons.file_download), tooltip: '导出', onPressed: _showExportMenu),
          IconButton(icon: const Icon(Icons.settings), tooltip: '设置', onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
        ],
      ),
      body: MainScaffold(
        sidebar: ProjectTree(
          filterProjectId: widget.project.id,
          onDocumentSelected: _onDocumentSelected,
        ),
        editor: EditorPanel(
          initialContent: _editorContent,
          documentTitle: _currentDocument?.title,
          onSave: _currentDocument != null ? _saveDocument : null,
          onContentChanged: (_) {
            if (!_isDirty) setState(() => _isDirty = true);
          },
        ),
        aiPanel: _buildAiPanelArea(),
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): _showExportMenu,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newDocument,
      },
      child: Focus(
        autofocus: true,
        child: scaffold,
      ),
    );
  }
}
