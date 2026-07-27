import 'dart:io';
import 'package:flutter/material.dart';
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
import 'toolbox_page.dart';
import 'project_brief_sheet.dart';

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
  bool _showProjectOnboarding = false;
  int _sidebarIndex = 0;
  ProjectTab _currentTab = ProjectTab.overview;
  Project? _currentProject;
  Document? _currentDocument;

  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.projectTabController.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.projectTabController.removeListener(_onTabsChanged);
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
      _showProjectOnboarding = false;
      _currentProject = null;
      _currentDocument = null;
    });
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
            onTabChanged: (tab) => setState(() {
              _currentTab = tab;
              _showProjectOnboarding = false;
            }),
            onCollapse: _collapseNavigation,
          ),
          Expanded(
            child: Row(
              children: [
                if (_sidebarVisible)
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
    if (_showProjectOnboarding) {
      return ProjectOnboardingPage(
        projectId: _currentProject!.id,
        workflow: ServiceLocator.instance.projectOnboardingWorkflow,
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
          documentId: _currentDocument?.id,
          documentTitle: _currentDocument?.title,
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
