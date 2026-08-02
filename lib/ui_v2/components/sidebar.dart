import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/document.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.projectId,
    this.projectName,
    this.projectDirectoryPath,
    this.onDocumentSelected,
    this.onDocumentCreated,
  });
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String? projectId;
  final String? projectName;
  final String? projectDirectoryPath;
  final ValueChanged<Document>? onDocumentSelected;
  final ValueChanged<Document>? onDocumentCreated;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<Document> _documents = [];
  bool _loading = true;
  String? _lastProjectId;
  bool _didInitLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitLoad) {
      _didInitLoad = true;
      _loadDocuments();
    }
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId) {
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    final pid = widget.projectId;
    if (pid == null) {
      if (mounted) {
        setState(() {
          _documents = [];
          _loading = false;
          _lastProjectId = null;
        });
      }
      return;
    }
    if (pid == _lastProjectId && _documents.isNotEmpty) return;
    if (mounted) setState(() => _loading = true);
    try {
      final docs =
          await ServiceLocator.instance.documentService.getDocuments(pid);
      if (mounted && pid == widget.projectId) {
        setState(() {
          _documents = docs;
          _loading = false;
          _lastProjectId = pid;
        });
      }
    } catch (_) {
      if (mounted && pid == widget.projectId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showAddDocumentDialog() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建文档'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入文档名称'),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || widget.projectId == null) {
      return;
    }
    try {
      final doc = await ServiceLocator.instance.documentService.createDocument(
        projectId: widget.projectId!,
        title: title.trim(),
        directoryPath: widget.projectDirectoryPath ?? '',
      );
      await _loadDocuments();
      widget.onDocumentCreated?.call(doc);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建文档失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Semantics(
      label: '章节导航',
      container: true,
      child: Container(
        width: LingBiTokens.sidebarWidth,
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(
            right: BorderSide(color: c.borderOpaque.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectHeader(c),
            const Divider(height: 1),
            Expanded(child: _buildChapterTree(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space3,
        LingBiTokens.space3,
        LingBiTokens.space3,
        LingBiTokens.space2,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
            ),
            child: const Center(
              child: Text(
                '灵',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          Expanded(
            child: Text(
              widget.projectName ?? '未命名项目',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.fg,
              ),
            ),
          ),
          _iconButton(
            LingBiIcons.add,
            c,
            _showAddDocumentDialog,
            semanticLabel: '新建文档',
          ),
        ],
      ),
    );
  }

  Widget _buildChapterTree(LingBiColors c) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: LingBiTokens.space2),
      children: [
        _buildNavSectionHeader('写作', c),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
          )
        else if (_documents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingBiTokens.space3,
              vertical: LingBiTokens.space2,
            ),
            child: Text(
              '暂无文档，点击 + 创建',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          )
        else
          ..._documents.map((doc) => _buildDocumentItem(doc, c)),
        const SizedBox(height: LingBiTokens.space4),
        _buildNavSectionHeader('资料库', c),
        _buildNavLink(LingBiIcons.character, '角色库', 0, c),
        _buildNavLink(LingBiIcons.location, '世界设定', 1, c),
        _buildNavLink(LingBiIcons.timeline, '时间线', 2, c),
        _buildNavLink(LingBiIcons.note, '笔记', 3, c),
      ],
    );
  }

  Widget _buildNavSectionHeader(String label, LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space4,
        LingBiTokens.space2,
        LingBiTokens.space4,
        LingBiTokens.space1,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDocumentItem(Document doc, LingBiColors c) {
    return InkWell(
      onTap: () => widget.onDocumentSelected?.call(doc),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space1,
        ),
        child: Row(
          children: [
            Icon(LingBiIcons.note, size: 16, color: c.fgSecondary),
            const SizedBox(width: LingBiTokens.space2),
            Expanded(
              child: Text(
                doc.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: c.fgSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (doc.wordCount > 0)
              Text(
                '${doc.wordCount}字',
                style: TextStyle(fontSize: 11, color: c.muted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(
    IconData icon,
    String label,
    int index,
    LingBiColors c,
  ) {
    return InkWell(
      onTap: () => widget.onItemSelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.fgSecondary),
            const SizedBox(width: LingBiTokens.space2),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
    IconData icon,
    LingBiColors c,
    VoidCallback onTap, {
    required String semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(LingBiTokens.space1),
            child: Icon(icon, size: 18, color: c.fgSecondary),
          ),
        ),
      ),
    );
  }
}
