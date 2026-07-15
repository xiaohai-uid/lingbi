import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/di/service_locator.dart';
import '../../services/export_service.dart';

/// 多格式导出对话框
class ExportDialog extends StatefulWidget {
  final String title;
  final String content;

  const ExportDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _exporting = false;

  Future<void> _export(String format, String extension, String label) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '导出为 $label',
      fileName: '${widget.title}.$extension',
      type: extension == 'pdf' ? FileType.custom : FileType.any,
      allowedExtensions: extension == 'pdf' ? ['pdf'] : null,
    );
    if (result == null) return;

    setState(() => _exporting = true);
    try {
      final svc = ServiceLocator.instance.exportService;
      switch (format) {
        case 'md':
          await svc.exportAsMarkdown(content: widget.content, savePath: result);
        case 'txt':
          await svc.exportAsTxt(content: widget.content, savePath: result);
        case 'pdf':
          await svc.exportAsPdf(title: widget.title, content: widget.content, savePath: result);
        case 'docx':
          await svc.exportAsDocx(title: widget.title, content: widget.content, savePath: result);
        case 'epub':
          await svc.exportAsEpub(title: widget.title, content: widget.content, savePath: result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 导出成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: _exporting
          ? SizedBox(
              height: 150,
              child: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.s70),
                ],
              )),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('导出文档', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('"${widget.title}"', style: const TextStyle(color: Colors.grey)),
                SizedBox(height: 20),
                _buildFormatButton(Icons.description, 'Markdown', 'md', 'md'),
                SizedBox(height: 8),
                _buildFormatButton(Icons.text_fields, '纯文本 (TXT)', 'txt', 'txt'),
                SizedBox(height: 8),
                _buildFormatButton(Icons.picture_as_pdf, 'PDF', 'pdf', 'pdf'),
                SizedBox(height: 8),
                _buildFormatButton(Icons.description_outlined, 'Word (DOCX)', 'docx', 'docx'),
                SizedBox(height: 8),
                _buildFormatButton(Icons.book, '电子书 (EPUB)', 'epub', 'epub'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.s33)),
                  ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildFormatButton(IconData icon, String label, String format, String ext) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: () => _export(format, ext, label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
