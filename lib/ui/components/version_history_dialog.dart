import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/di/service_locator.dart';
import '../../services/version_history_service.dart';

/// 版本历史对话框
class VersionHistoryDialog extends StatefulWidget {
  final String projectDir;
  final String docId;

  const VersionHistoryDialog({
    super.key,
    required this.projectDir,
    required this.docId,
  });

  @override
  State<VersionHistoryDialog> createState() => _VersionHistoryDialogState();
}

class _VersionHistoryDialogState extends State<VersionHistoryDialog> {
  List<VersionInfo> _versions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    try {
      final versions = await ServiceLocator
          .instance.versionHistoryService
          .getVersions(projectDir: widget.projectDir, docId: widget.docId);
      setState(() { _versions = versions; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _preview(String versionId) async {
    final content = await ServiceLocator
        .instance.versionHistoryService
        .getVersionContent(
          projectDir: widget.projectDir,
          docId: widget.docId,
          versionId: versionId,
        );
    if (!mounted || content == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 600, height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('版本预览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(child: Text(content))),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.s22)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restore(String versionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.s84),
        content: Text(AppLocalizations.of(context)!.s51),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.s33)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.s81)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final content = await ServiceLocator
          .instance.versionHistoryService
          .restoreVersion(
            projectDir: widget.projectDir,
            docId: widget.docId,
            versionId: versionId,
          );
      if (mounted) Navigator.pop(context, content);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500, height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('版本历史', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: _loading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                  ? Center(child: Text('加载失败: $_error', style: const TextStyle(color: Colors.red)))
                  : _versions.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context)!.s65))
                    : ListView.builder(
                        itemCount: _versions.length,
                        itemBuilder: (ctx, i) {
                          final v = _versions[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(v.summary.isNotEmpty ? v.summary : '版本 ${v.id}'),
                              subtitle: Text('${_formatTime(v.timestamp)} · ${v.wordCount} 字'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.preview, size: 20),
                                    tooltip: '预览',
                                    onPressed: () => _preview(v.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.restore, size: 20),
                                    tooltip: '恢复',
                                    onPressed: () => _restore(v.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
