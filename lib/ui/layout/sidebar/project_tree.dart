import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:flutter/material.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/document.dart';
import 'project_item.dart';

class ProjectTree extends StatefulWidget {

  const ProjectTree({
    super.key,
    this.onDocumentSelected,
    this.onProjectSelected,
    this.onNewProject,
    this.onOpenProject,
    this.filterProjectId,
  });
  final ValueChanged<Document>? onDocumentSelected;
  final ValueChanged<Project>? onProjectSelected;
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenProject;
  final String? filterProjectId;

  @override
  State<ProjectTree> createState() => _ProjectTreeState();
}

class _ProjectTreeState extends State<ProjectTree> {
  final ProjectService _projectService = ServiceLocator.instance.projectService;
  final DocumentService _documentService = ServiceLocator.instance.documentService;
  List<Project> _projects = [];
  String? _expandedProjectId;
  final Map<String, List<Document>> _documents = {};
  bool _loading = false;

  List<Project> get _filteredProjects {
    if (widget.filterProjectId != null) {
      return _projects.where((p) => p.id == widget.filterProjectId).toList();
    }
    return _projects;
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      _projects = await _projectService.getProjects();
      if (widget.filterProjectId != null &&
          _projects.any((p) => p.id == widget.filterProjectId)) {
        _expandedProjectId = widget.filterProjectId;
        await _loadDocuments(widget.filterProjectId!);
      } else if (_expandedProjectId != null) {
        await _loadDocuments(_expandedProjectId!);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDocuments(String projectId) async {
    try {
      _documents[projectId] = await _documentService.getDocuments(projectId);
    } catch (_) {
      _documents[projectId] = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // ─── 顶栏 ───
        _buildHeader(theme),
        const Divider(height: 1),
        // ─── 项目列表 ───
        if (_loading)
          const Expanded(
            child: Center(child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
          )
        else if (_projects.isEmpty)
          _buildEmptyState(theme)
        else
          Expanded(child: _buildProjectList(theme)),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome,
                size: 14, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Text('灵笔', style: theme.textTheme.titleMedium),
          const Spacer(),
          _IconBtn(
            icon: Icons.add,
            tooltip: '新建项目',
            onPressed: widget.onNewProject,
          ),
          const SizedBox(width: 2),
          _IconBtn(
            icon: Icons.folder_open,
            tooltip: '打开项目',
            onPressed: widget.onOpenProject,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.menu_book_outlined,
                    size: 40, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text('开始写作', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('创建您的第一个项目',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建项目'),
                onPressed: widget.onNewProject,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: _filteredProjects.length,
      itemBuilder: (context, index) {
        final project = _filteredProjects[index];
        final isExpanded = project.id == _expandedProjectId;
        final docs = _documents[project.id] ?? [];
        return Column(
          children: [
            ProjectItem(
              project: project,
              isExpanded: isExpanded,
              onTap: () async {
                if (isExpanded) {
                  setState(() => _expandedProjectId = null);
                } else {
                  setState(() => _expandedProjectId = project.id);
                  await _loadDocuments(project.id);
                  setState(() {});
                }
                widget.onProjectSelected?.call(project);
              },
            ),
            // 文档列表
            if (isExpanded && docs.isNotEmpty)
              ...docs.map((doc) => _DocItem(
                    doc: doc,
                    onTap: () => widget.onDocumentSelected?.call(doc),
                  )),
          ],
        );
      },
    );
  }
}

/// 文档列表项
class _DocItem extends StatelessWidget {

  const _DocItem({required this.doc, required this.onTap});
  final Document doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 52, right: 12, top: 2, bottom: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doc.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13, fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 小图标按钮

class _IconBtn extends StatelessWidget {

  const _IconBtn({required this.icon, required this.tooltip, this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
