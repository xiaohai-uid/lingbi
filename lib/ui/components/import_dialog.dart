import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/file_system/file_service.dart';
import '../../core/di/service_locator.dart';

class ImportFileInfo {
  final String fileName;
  final int fileSize;
  final String content;
  final String title;

  ImportFileInfo({
    required this.fileName,
    required this.fileSize,
    required this.content,
    required this.title,
  });
}

/// 文档导入对话框
class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  List<PlatformFile> _selectedFiles = [];
  Set<int> _checked = {};
  bool _importing = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _checked = Set.from(List.generate(result.files.length, (i) => i));
      });
    }
  }

  Future<void> _import() async {
    if (_checked.isEmpty) return;
    setState(() => _importing = true);
    try {
      final imports = <ImportFileInfo>[];
      for (final idx in _checked) {
        final file = _selectedFiles[idx];
        if (file.path == null) continue;
        final content = await File(file.path!).readAsString();
        final lines = content.split('\n');
        String title = file.name.replaceAll(RegExp(r'\.(md|txt)$'), '');
        for (final line in lines) {
          final m = RegExp(r'^#\s+(.+)').firstMatch(line);
          if (m != null) { title = m[1]!; break; }
        }
        imports.add(ImportFileInfo(
          fileName: file.name,
          fileSize: file.size,
          content: content,
          title: title,
        ));
      }
      if (mounted) Navigator.pop(context, imports);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500, height: 450,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('导入文档', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context)!.s106),
                  onPressed: _importing ? null : _pickFiles,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedFiles.isEmpty)
              const Expanded(child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('点击"选择文件"添加 .md / .txt 文件', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedFiles.length,
                  itemBuilder: (ctx, i) {
                    final f = _selectedFiles[i];
                    return CheckboxListTile(
                      title: Text(f.name),
                      subtitle: Text(_formatSize(f.size)),
                      value: _checked.contains(i),
                      onChanged: _importing ? null : (v) {
                        setState(() {
                          if (v == true) _checked.add(i); else _checked.remove(i);
                        });
                      },
                    );
                  },
                ),
              ),
            if (_selectedFiles.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('已选 ${_checked.length} / ${_selectedFiles.length} 个文件'),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.s33)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (_importing || _checked.isEmpty) ? null : _import,
                        child: _importing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(AppLocalizations.of(context)!.s45),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
