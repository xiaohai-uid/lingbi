import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/review/data/version_history_service.dart';
import 'package:flutter/material.dart';
import 'package:lingbi/shared/models/document.dart';

/// 版本历史面板
class VersionHistoryPanel extends StatefulWidget {

  const VersionHistoryPanel({
    super.key,
    required this.document,
    required this.projectDir,
    required this.onRestore,
    required this.onRefresh,
  });
  final Document document;
  final String projectDir;
  final Future<void> Function(String content) onRestore;
  final VoidCallback onRefresh;

  @override
  State<VersionHistoryPanel> createState() => _VersionHistoryPanelState();
}

class _VersionHistoryPanelState extends State<VersionHistoryPanel> {
  final VersionHistoryService _service = ServiceLocator.instance.versionHistoryService;
  List<VersionInfo> _versions = [];
  bool _loading = true;
  String? _previewContent;
  String? _previewVersionId;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _loading = true);
    final versions = await _service.getVersions(
      projectDir: widget.projectDir,
      docId: widget.document.id,
    );
    if (mounted) {
      setState(() {
        _versions = versions;
        _loading = false;
      });
    }
  }

  Future<void> _previewVersion(String versionId) async {
    final content = await _service.getVersionContent(
      projectDir: widget.projectDir,
      docId: widget.document.id,
      versionId: versionId,
    );
    if (mounted) {
      setState(() {
        _previewContent = content;
        _previewVersionId = versionId;
      });
    }
  }

  Future<void> _confirmRestore(String versionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复确认'),
        content: const Text('将当前文档内容替换为所选历史版本。当前内容会先保存为版本快照。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('恢复')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.onRestore(_previewContent ?? '');
      _previewContent = null;
      _previewVersionId = null;
      widget.onRefresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文档已恢复到所选版本')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.document.title} - 版本历史'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: '刷新', onPressed: _loadVersions),
          if (_previewContent != null)
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('恢复到此版本'),
              onPressed: () => _confirmRestore(_previewVersionId!),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _versions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 48, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text('暂无版本历史', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text('保存文档后会自动创建版本快照',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor)),
                    ],
                  ),
                )
              : _previewContent != null
                  ? _buildPreview(theme)
                  : _buildVersionList(theme),
    );
  }

  Widget _buildVersionList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _versions.length,
      itemBuilder: (ctx, i) {
        final version = _versions[i];
        final isLatest = i == 0;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isLatest ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                isLatest ? Icons.check_circle : Icons.history,
                size: 18,
                color: isLatest ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              version.summary.isNotEmpty ? version.summary : '(无标题)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: isLatest ? FontWeight.w600 : FontWeight.normal),
            ),
            subtitle: Text(
              '${_formatDate(version.timestamp)} · ${version.wordCount} 字',
              style: theme.textTheme.labelSmall,
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _previewVersion(version.id),
          ),
        );
      },
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _previewContent = null;
                  _previewVersionId = null;
                }),
              ),
              const SizedBox(width: 8),
              Text('预览版本', style: theme.textTheme.titleSmall),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _previewContent ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
