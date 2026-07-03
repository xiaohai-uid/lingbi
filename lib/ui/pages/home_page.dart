import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/project_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingbi/ui/layout/main_scaffold.dart';
import 'package:lingbi/ui/layout/sidebar/project_tree.dart';
import 'package:lingbi/ui/layout/editor/editor_panel.dart';
import 'package:lingbi/ui/layout/ai_panel/ai_panel.dart';
import 'package:lingbi/ui/pages/project_page.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/services/project_tab_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProjectService _projectService = ServiceLocator.instance.projectService;
  final DocumentService _documentService = ServiceLocator.instance.documentService;
  final ProjectTabController _tabController = ProjectTabController();
  Document? _currentDocument;
  String _editorContent = '';

  void _onProjectSelected(Project project) {
    _tabController.openProject(project);
  }

  void _onDocumentSelected(Document doc) async {
    try {
      final content = await _documentService.readContent(doc.filePath);
      setState(() {
        _currentDocument = doc;
        _editorContent = content;
      });
    } catch (e) {
      _showError('无法打开文档: $e');
    }
  }

  Future<void> _newProject() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建项目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '项目名称', hintText: '例如：我的小说'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '项目描述（可选）'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(ctx, {'name': nameController.text, 'description': descController.text});
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final projectDir = '${docsDir.path}/灵笔/${result['name']!}';
        await Directory(projectDir).create(recursive: true);

        final project = await _projectService.createProject(
          name: result['name']!,
          description: result['description'] ?? '',
          directoryPath: projectDir,
        );

        await _documentService.createDocument(
          projectId: project.id,
          title: '首页',
          directoryPath: projectDir,
          content: '# ${result['name']!}\n\n欢迎使用灵笔！\n',
        );

        _showMessage('项目「${result['name']!}」创建成功');
        _onProjectSelected(project);
      } catch (e) {
        _showError('创建项目失败: $e');
      }
    }
  }

  void _newDocument() {
    if (_tabController.isEmpty) {
      _newProject();
    }
  }

  Future<void> _openProject() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: '选择项目目录');
    if (dir != null && mounted) {
      try {
        final dirName = dir.split(Platform.pathSeparator).last;
        final project = await _projectService.createProject(name: dirName, directoryPath: dir);
        _showMessage('项目已打开');
        _onProjectSelected(project);
      } catch (e) {
        _showError('打开项目失败: $e');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red.shade700));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final scaffold = Scaffold(
      body: _tabController.isEmpty
          ? MainScaffold(
              sidebar: ProjectTree(
                onDocumentSelected: _onDocumentSelected,
                onProjectSelected: _onProjectSelected,
                onNewProject: _newProject,
                onOpenProject: _openProject,
              ),
              editor: EditorPanel(
                initialContent: _editorContent,
                documentTitle: _currentDocument?.title,
              ),
              aiPanel: const AIPanel(),
            )
          : Column(
              children: [
                // Tab 栏
                Container(
                  height: 40,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabController.tabs.length + 1, // +1 for the sidebar toggle
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        // Sidebar-style "back to project list"
                        return _buildTabButton(
                          icon: Icons.home,
                          label: '项目',
                          isActive: false,
                          onTap: () => _tabController.closeAll(),
                        );
                      }
                      final tabIndex = i - 1;
                      final tab = _tabController.tabs[tabIndex];
                      final isActive = tabIndex == _tabController.activeIndex;
                      return _buildTabButton(
                        label: tab.project.name,
                        isActive: isActive,
                        onTap: () {
                          _tabController.switchTo(tabIndex);
                          setState(() {});
                        },
                        onClose: () => _tabController.closeTab(tabIndex),
                        onCloseOther: () => _tabController.closeOtherTabs(tabIndex),
                      );
                    },
                  ),
                ),
                // 当前 Tab 的工作区
                Expanded(
                  child: _tabController.activeTab != null
                      ? ProjectPage(
                          project: _tabController.activeTab!.project,
                          key: ValueKey('project_${_tabController.activeTab!.project.id}'),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
    );

    if (_tabController.isEmpty) {
      return scaffold;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newDocument,
        const SingleActivator(LogicalKeyboardKey.keyW, control: true): () {
          if (_tabController.tabs.isNotEmpty) {
            _tabController.closeTab(_tabController.activeIndex);
            setState(() {});
          }
        },
        const SingleActivator(LogicalKeyboardKey.tab, control: true): () {
          if (_tabController.tabs.length > 1) {
            final next = (_tabController.activeIndex + 1) % _tabController.tabs.length;
            _tabController.switchTo(next);
            setState(() {});
          }
        },
        const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true): () {
          if (_tabController.tabs.length > 1) {
            final prev = (_tabController.activeIndex - 1 + _tabController.tabs.length) % _tabController.tabs.length;
            _tabController.switchTo(prev);
            setState(() {});
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: scaffold,
      ),
    );
  }

  Widget _buildTabButton({
    IconData? icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClose,
    VoidCallback? onCloseOther,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onSecondaryTap: () {
        final close = onClose;
        final closeOther = onCloseOther;
        if (closeOther != null) {
          showMenu<String>(
            context: context,
            position: const RelativeRect.fromLTRB(0, 40, 200, 80),
            items: [
              const PopupMenuItem(value: 'close', child: Text('关闭')),
              const PopupMenuItem(value: 'close_other', child: Text('关闭其他')),
            ],
          ).then((v) {
            if (v == 'close') close?.call();
            if (v == 'close_other') closeOther();
          });
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          color: isActive ? theme.colorScheme.surface : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.home, size: 14, color: theme.colorScheme.primary),
              ),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 14, color: theme.disabledColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}