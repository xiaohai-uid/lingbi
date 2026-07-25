import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/utils/paths.dart';
import '../theme/tokens.dart';
import 'sidebar.dart';
import 'top_bar.dart';
import 'ai_assistant.dart';
import 'project_tabs.dart';
import '../pages/welcome_page.dart';
import '../pages/editor_page.dart';
import '../pages/canon_page.dart';
import '../pages/storyboard_page.dart';
import '../pages/version_history_page.dart';
import '../pages/import_export_page.dart';
import '../pages/settings_page.dart';
import '../pages/skill_market_page.dart';
import '../pages/guided_flow_page.dart';

class AppScaffold extends StatefulWidget {

  const AppScaffold({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _sidebarVisible = true;
  bool _aiPanelVisible = true;
  bool _hasProject = false;
  bool _showingSkillMarket = false;
  bool _showingGuidedFlow = false;
  String _guidedFlowProjectId = '';
  String _guidedFlowProjectName = '';
  String _guidedFlowId = 'default-long';
  int _sidebarIndex = 0;
  ProjectTab _currentTab = ProjectTab.editor;
  Project? _currentProject;
  Document? _currentDocument;

  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.projectTabController.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.projectTabController
        .removeListener(_onTabsChanged);
    super.dispose();
  }

  void _onTabsChanged() {
    final ctrl = ServiceLocator.instance.projectTabController;
    setState(() {
      _currentProject = ctrl.activeTab?.project;
      _hasProject = !ctrl.isEmpty;
    });
  }

  void _onProjectSwitch(int index) {
    ServiceLocator.instance.projectTabController.switchTo(index);
  }

  void _onCloseTab(int index) {
    final ctrl = ServiceLocator.instance.projectTabController;
    ctrl.closeTab(index);
    if (ctrl.isEmpty) {
      setState(() {
        _hasProject = false;
        _showingSkillMarket = false;
        _currentProject = null;
        _currentDocument = null;
      });
    }
  }

  void _onSearch(String query) {
    // TODO: wire to DocumentService search across current project's documents
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('搜索：「$query」')),
    );
  }

  void _toggleSidebar() => setState(() => _sidebarVisible = !_sidebarVisible);
  void _toggleAiPanel() => setState(() => _aiPanelVisible = !_aiPanelVisible);

  void _openSkillMarket() =>
      setState(() => _showingSkillMarket = !_showingSkillMarket);

  /// Collapse all project tabs → back to welcome screen
  void _collapseNavigation() {
    ServiceLocator.instance.projectTabController.closeAll();
    setState(() {
      _hasProject = false;
      _showingSkillMarket = false;
      _currentProject = null;
      _currentDocument = null;
    });
  }

  Future<void> _createProject() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedPlatform = '';
    String selectedGenre = '';
    final audienceController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新建项目'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '项目名称',
                    hintText: '例如：我的小说',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '项目描述（可选）'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPlatform.isEmpty ? null : selectedPlatform,
                        decoration: const InputDecoration(labelText: '目标平台'),
                        items: const [
                          DropdownMenuItem(value: '起点', child: Text('起点')),
                          DropdownMenuItem(value: '番茄', child: Text('番茄')),
                          DropdownMenuItem(value: '七猫', child: Text('七猫')),
                          DropdownMenuItem(value: '其他', child: Text('其他')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedPlatform = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedGenre.isEmpty ? null : selectedGenre,
                        decoration: const InputDecoration(labelText: '题材'),
                        items: const [
                          DropdownMenuItem(value: '玄幻', child: Text('玄幻')),
                          DropdownMenuItem(value: '都市', child: Text('都市')),
                          DropdownMenuItem(value: '悬疑', child: Text('悬疑')),
                          DropdownMenuItem(value: '言情', child: Text('言情')),
                          DropdownMenuItem(value: '科幻', child: Text('科幻')),
                          DropdownMenuItem(value: '历史', child: Text('历史')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedGenre = v ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: audienceController,
                  decoration: const InputDecoration(
                    labelText: '读者画像（可选）',
                    hintText: '例如：18-25岁男性、喜欢爽文',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.pop(ctx, {
                    'name': nameController.text,
                    'description': descController.text,
                    'targetPlatform': selectedPlatform,
                    'genre': selectedGenre,
                    'audience': audienceController.text,
                  });
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        final projectDir =
            '${resolveDefaultProjectRoot()}${Platform.pathSeparator}${result['name']!}';

        final project = await ServiceLocator.instance.projectService
            .createPortableProject(
          name: result['name']!,
          description: result['description'] ?? '',
          directoryPath: projectDir,
        );

        // 设置市场定位字段
        project.targetPlatform = result['targetPlatform'] ?? '';
        project.genre = result['genre'] ?? '';
        project.audience = result['audience'] ?? '';

        ServiceLocator.instance.projectTabController.openProject(project);

        setState(() {
          _hasProject = true;
          _currentProject = project;
          // 创建项目后自动进入全屏引导（按题材匹配专属 Skill）
          _showingGuidedFlow = true;
          _guidedFlowProjectId = project.id;
          _guidedFlowProjectName = project.name;
          _guidedFlowId = _resolveFlowId(project.genre);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建项目失败: $e')),
          );
        }
      }
    }
  }

  /// 按题材解析引导流程 flowId
  ///
  /// 有对应题材 Skill 时使用专属流程，否则降级到通用长篇流程。
  String _resolveFlowId(String genre) {
    final loader = ServiceLocator.instance.guidedFlowSkillLoader;
    final flowId = loader.findFlowIdByGenre(genre);
    return flowId ?? 'default-long';
  }

  Future<void> _openProject() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择项目目录',
    );
    if (dir != null && mounted) {
      try {
        final result =
            await ServiceLocator.instance.projectService.openPortableProject(
          dir,
        );

        // 将扫描到的文档同步到 ZVec
        for (final doc in result.documents) {
          await ServiceLocator.instance.documentService.saveDocument(
            doc,
            await ServiceLocator.instance.documentService
                .readContent(doc.filePath),
          );
        }

        ServiceLocator.instance.projectTabController
            .openProject(result.project);

        setState(() {
          _hasProject = true;
          _currentProject = result.project;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '项目「${result.project.name}」已打开（${result.documents.length} 个文档）',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打开项目失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);

    // 全屏引导模式（创建项目后）
    if (_showingGuidedFlow) {
      return Material(
        color: c.bg,
        child: GuidedFlowPage(
          projectId: _guidedFlowProjectId,
          projectName: _guidedFlowProjectName,
          flowId: _guidedFlowId,
          onComplete: () => setState(() => _showingGuidedFlow = false),
          onSkip: () => setState(() => _showingGuidedFlow = false),
        ),
      );
    }

    if (!_hasProject && !_showingSkillMarket) {
      return Material(
        color: c.bg,
        child: Column(
        children: [
          TopBar(
            isDarkMode: widget.isDarkMode,
            aiPanelVisible: _aiPanelVisible,
            sidebarVisible: _sidebarVisible,
            onToggleTheme: () => widget.onToggleTheme(!widget.isDarkMode),
            onToggleAiPanel: _toggleAiPanel,
            onToggleSidebar: _toggleSidebar,
            onSkillMarket: _openSkillMarket,
            onSearch: _onSearch,
            onProjectSwitch: _onProjectSwitch,
            onCloseTab: _onCloseTab,
          ),
          Expanded(
            child: WelcomePage(
              onCreateProject: _createProject,
              onOpenProject: _openProject,
              onOpenSkillMarket: _openSkillMarket,
            ),
          ),
        ],
      ),
      );
    }

    if (_showingSkillMarket) {
      return Material(
        color: c.bg,
        child: Column(
        children: [
          TopBar(
            isDarkMode: widget.isDarkMode,
            aiPanelVisible: _aiPanelVisible,
            sidebarVisible: _sidebarVisible,
            onToggleTheme: () => widget.onToggleTheme(!widget.isDarkMode),
            onToggleAiPanel: _toggleAiPanel,
            onToggleSidebar: _toggleSidebar,
            onSkillMarket: _openSkillMarket,
            onSearch: _onSearch,
            onProjectSwitch: _onProjectSwitch,
            onCloseTab: _onCloseTab,
          ),
          Expanded(
            child: SkillMarketPage(
              onBack: () => setState(() => _showingSkillMarket = false),
            ),
          ),
        ],
      ),
      );
    }

    return Material(
      color: c.bg,
      child: Column(
      children: [
        TopBar(
          isDarkMode: widget.isDarkMode,
          aiPanelVisible: _aiPanelVisible,
          sidebarVisible: _sidebarVisible,
          onToggleTheme: () => widget.onToggleTheme(!widget.isDarkMode),
          onToggleAiPanel: _toggleAiPanel,
          onToggleSidebar: _toggleSidebar,
          onSkillMarket: _openSkillMarket,
          onSearch: _onSearch,
          onProjectSwitch: _onProjectSwitch,
          onCloseTab: _onCloseTab,
        ),
        ProjectNavigationBar(
          currentTab: _currentTab,
          onTabChanged: (tab) => setState(() => _currentTab = tab),
          onCollapse: _collapseNavigation,
        ),
        Expanded(
          child: Row(
            children: [
              if (_sidebarVisible)
                Sidebar(
                  selectedIndex: _sidebarIndex,
                  onItemSelected: (i) =>
                      setState(() => _sidebarIndex = i),
                  projectId: _currentProject?.id,
                  projectName: _currentProject?.name,
                  projectDirectoryPath: _currentProject?.directoryPath,
                  onDocumentSelected: (doc) =>
                      setState(() => _currentDocument = doc),
                  onDocumentCreated: (doc) =>
                      setState(() => _currentDocument = doc),
                ),
              Expanded(child: _buildPage()),
              if (_aiPanelVisible)
                AiAssistantPanel(
                  projectId: _currentProject?.id,
                  projectName: _currentProject?.name,
                ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildPage() {
    switch (_currentTab) {
      case ProjectTab.editor:
        return EditorPage(
          projectId: _currentProject?.id,
          documentId: _currentDocument?.id,
          documentTitle: _currentDocument?.title,
        );
      case ProjectTab.canon:
        return CanonPage(projectId: _currentProject?.id);
      case ProjectTab.storyboard:
        return StoryboardPage(projectId: _currentProject?.id);
      case ProjectTab.history:
        return VersionHistoryPage(
          projectId: _currentProject?.id,
          projectDir: _currentProject?.directoryPath,
          docId: _currentDocument?.id,
        );
      case ProjectTab.importExport:
        return ImportExportPage(projectId: _currentProject?.id);
      case ProjectTab.settings:
        return const SettingsPage();
    }
  }
}
