import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/ui_v2/models/project_template.dart';
import 'package:lingbi/utils/paths.dart';
import '../theme/tokens.dart';
import 'sidebar.dart';
import 'top_bar.dart';
import 'ai_assistant.dart';
import 'project_tabs.dart';
import '../pages/welcome_page.dart';
import '../pages/editor_page.dart';
import '../pages/storyboard_page.dart';
import '../pages/import_export_page.dart';
import '../pages/project_overview_page.dart';
import '../pages/project_onboarding_page.dart';
import '../pages/skill_market_page.dart';
import '../pages/settings_page.dart';
import '../services/command_palette_service.dart';
import 'toolbox_page.dart';
import 'project_brief_sheet.dart';
import 'command_palette.dart';
import 'document_search_dialog.dart';

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
  bool _showingSettings = false;
  bool _showProjectOnboarding = false;
  int _sidebarIndex = 0;
  ProjectTab _currentTab = ProjectTab.overview;
  Project? _currentProject;
  Document? _currentDocument;
  final CommandPaletteService _commandService = CommandPaletteService();

  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.projectTabController.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.projectTabController.removeListener(_onTabsChanged);
    _commandService.dispose();
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
        _showProjectOnboarding = false;
        _currentProject = null;
        _currentDocument = null;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    final project = _currentProject;
    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先打开一个项目再搜索')),
      );
      return;
    }
    try {
      final results = await ServiceLocator.instance.documentService
          .searchDocuments(project.id, query);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(LingBiTokens.space8),
          child: DocumentSearchDialog(
            query: query,
            results: results,
            onSelected: (document) {
              Navigator.of(dialogContext).pop();
              setState(() {
                _currentDocument = document;
                _currentTab = ProjectTab.writing;
              });
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $error')),
        );
      }
    }
  }

  void _toggleSidebar() => setState(() => _sidebarVisible = !_sidebarVisible);
  void _toggleAiPanel() => setState(() => _aiPanelVisible = !_aiPanelVisible);

  void _openSkillMarket() => setState(() {
        _showingSettings = false;
        _showingSkillMarket = !_showingSkillMarket;
      });

  /// Collapse all project tabs → back to welcome screen
  void _collapseNavigation() {
    ServiceLocator.instance.projectTabController.closeAll();
    setState(() {
      _hasProject = false;
      _showingSkillMarket = false;
      _showingSettings = false;
      _showProjectOnboarding = false;
      _currentProject = null;
      _currentDocument = null;
    });
  }

  void _executeCommand(AppCommand command) {
    switch (command) {
      case AppCommand.newProject:
        _collapseNavigation();
        return;
      case AppCommand.openProject:
        _openProject();
        return;
      case AppCommand.commandPalette:
        CommandPalette.show(context, onSelected: _executeCommand);
        return;
      case AppCommand.toggleAi:
        _toggleAiPanel();
        return;
      case AppCommand.settings:
        setState(() {
          _showingSkillMarket = false;
          _showingSettings = true;
        });
        return;
      case AppCommand.save:
        _commandService.dispatch(AppCommand.save);
        return;
      case AppCommand.dismiss:
        if (_showingSettings || _showingSkillMarket) {
          setState(() {
            _showingSettings = false;
            _showingSkillMarket = false;
          });
        }
        return;
    }
  }

  Widget _commandShell(Widget child) {
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
          _executeCommand(AppCommand.newProject),
      const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
          _executeCommand(AppCommand.openProject),
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
          _executeCommand(AppCommand.commandPalette),
      const SingleActivator(LogicalKeyboardKey.keyA,
          control: true,
          shift: true): () => _executeCommand(AppCommand.toggleAi),
      const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
          _executeCommand(AppCommand.settings),
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
          _executeCommand(AppCommand.save),
      if (_showingSettings || _showingSkillMarket)
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _executeCommand(AppCommand.dismiss),
    };
    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(autofocus: true, child: child),
    );
  }

  Future<void> _createProject(ProjectTemplate template) async {
    final result = await ProjectBriefSheet.show(
      context,
      template: template,
    );

    if (result != null && mounted) {
      try {
        final projectDir =
            '${resolveDefaultProjectRoot()}${Platform.pathSeparator}${result.title}';

        final project =
            await ServiceLocator.instance.projectService.createPortableProject(
          directoryPath: projectDir,
          brief: result,
        );

        ServiceLocator.instance.projectTabController.openProject(project);

        setState(() {
          _hasProject = true;
          _currentProject = project;
          _currentTab = ProjectTab.overview;
          _showProjectOnboarding = true;
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
          _currentTab = ProjectTab.overview;
          _showProjectOnboarding = false;
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
    late final Widget content;
    if (_showingSettings) {
      content = Material(
        color: c.bg,
        child: Column(
          children: [
            _buildTopBar(),
            const Expanded(child: SettingsPage()),
          ],
        ),
      );
    } else if (!_hasProject && !_showingSkillMarket) {
      content = Material(
        color: c.bg,
        child: Column(
          children: [
            _buildTopBar(),
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
    } else if (_showingSkillMarket) {
      content = Material(
        color: c.bg,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SkillMarketPage(
                onBack: () => setState(() => _showingSkillMarket = false),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Material(
        color: c.bg,
        child: Column(
          children: [
            _buildTopBar(),
            ProjectNavigationBar(
              currentTab: _currentTab,
              onTabChanged: (tab) => setState(() {
                _currentTab = tab;
                _showProjectOnboarding = false;
              }),
              onCollapse: _collapseNavigation,
            ),
            Expanded(child: _buildResponsiveWorkspace()),
          ],
        ),
      );
    }
    return _commandShell(
      Semantics(label: '灵笔 Windows 主工作区', container: true, child: content),
    );
  }

  Widget _buildTopBar() {
    return TopBar(
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
    );
  }

  Widget _buildResponsiveWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final policy = WorkspaceLayoutPolicy.forWidth(constraints.maxWidth);
        final aiDocked =
            _aiPanelVisible && policy.aiPresentation != AiPresentation.overlay;
        final sidebarHasRoom = !aiDocked || constraints.maxWidth >= 1180;
        final showSidebar =
            _sidebarVisible && sidebarHasRoom && constraints.maxWidth >= 900;
        final editor = Expanded(
          child: Semantics(
            label: '项目内容区',
            container: true,
            child: _buildPage(),
          ),
        );
        final base = Row(
          children: [
            if (showSidebar)
              Sidebar(
                selectedIndex: _sidebarIndex,
                onItemSelected: (i) => setState(() => _sidebarIndex = i),
                projectId: _currentProject?.id,
                projectName: _currentProject?.name,
                projectDirectoryPath: _currentProject?.directoryPath,
                onDocumentSelected: (doc) =>
                    setState(() => _currentDocument = doc),
                onDocumentCreated: (doc) =>
                    setState(() => _currentDocument = doc),
              ),
            editor,
            if (aiDocked)
              AiAssistantPanel(
                // R4 修复：随 projectId 强制重建 State，隔离不同项目的对话/引导状态。
                key: ValueKey('ai-panel-${_currentProject?.id ?? 'none'}'),
                projectId: _currentProject?.id,
                projectName: _currentProject?.name,
              ),
          ],
        );
        if (!_aiPanelVisible ||
            policy.aiPresentation != AiPresentation.overlay) {
          return base;
        }
        return Stack(
          children: [
            base,
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: Material(
                elevation: 12,
                child: AiAssistantPanel(
                  // R4 修复：随 projectId 强制重建 State，隔离不同项目的对话/引导状态。
                  key: ValueKey('ai-panel-${_currentProject?.id ?? 'none'}'),
                  projectId: _currentProject?.id,
                  projectName: _currentProject?.name,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage() {
    if (_showProjectOnboarding) {
      return ProjectOnboardingPage(
        projectId: _currentProject!.id,
        workflow: ServiceLocator.instance.projectOnboardingWorkflow,
        genreId: _currentProject!.genre,
        onCompleted: () => setState(() {
          _showProjectOnboarding = false;
          _currentTab = ProjectTab.overview;
        }),
        onManualWriting: () => setState(() {
          _showProjectOnboarding = false;
          _currentTab = ProjectTab.writing;
        }),
      );
    }
    switch (_currentTab) {
      case ProjectTab.overview:
        return ProjectOverviewPage(
          project: _currentProject!,
          repository: ServiceLocator.instance.projectAssetRepository,
          onAssetSelected: (asset) => setState(() {
            if (asset.type == ProjectAssetType.firstChapter) {
              _currentTab = ProjectTab.writing;
            } else {
              _showProjectOnboarding = true;
            }
          }),
        );
      case ProjectTab.writing:
        return EditorPage(
          projectId: _currentProject?.id,
          projectDirectoryPath: _currentProject?.directoryPath,
          documentId: _currentDocument?.id,
          documentTitle: _currentDocument?.title,
          commandService: _commandService,
        );
      case ProjectTab.ideation:
        return StoryboardPage(projectId: _currentProject?.id);
      case ProjectTab.review:
        return ToolboxPage(projectId: _currentProject?.id);
      case ProjectTab.publish:
        return ImportExportPage(projectId: _currentProject?.id);
    }
  }
}
