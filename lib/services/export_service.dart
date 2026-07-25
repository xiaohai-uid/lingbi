import 'package:lingbi/services/interfaces/i_export_service.dart';
import 'dart:io';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 导出服务 - 支持 Markdown / TXT / PDF 格式导出
class ExportService implements IExportService {
  ExportService();

  /// 导出为 Markdown（直接复制）
  @override
  Future<void> exportAsMarkdown({
    required String content,
    required String savePath,
  }) async {
    final file = File(savePath);
    await file.writeAsString(content);
  }

  /// 导出为纯文本（去除 Markdown 标记）
  @override
  Future<void> exportAsTxt({
    required String content,
    required String savePath,
  }) async {
    final plainText = _stripMarkdown(content);
    final file = File(savePath);
    await file.writeAsString(plainText);
  }

  /// 导出为 PDF
  @override
  Future<void> exportAsPdf({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final file = File(savePath);
    final pdfBytes = await _generatePdf(title, content);
    await file.writeAsBytes(pdfBytes);
  }

  /// 导出整个项目到指定文件夹
  @override
  Future<void> exportProjectToDirectory({
    required Project project,
    required List<Document> documents,
    required Map<String, String> contents,
    required String outputDir,
    String format = 'md',
  }) async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (final doc in documents) {
      final content = contents[doc.id] ?? '';
      final safeName = _safeFileName(doc.title);
      String filePath;

      switch (format) {
        case 'txt':
          filePath = '${dir.path}/$safeName.txt';
          final plainText = _stripMarkdown(content);
          await File(filePath).writeAsString(plainText);
          break;
        case 'pdf':
          filePath = '${dir.path}/$safeName.pdf';
          final pdfBytes = await _generatePdf(doc.title, content);
          await File(filePath).writeAsBytes(pdfBytes);
          break;
        default:
          filePath = '${dir.path}/$safeName.md';
          await File(filePath).writeAsString(content);
      }
    }
  }

  /// 生成 PDF 字节数据
  Future<List<int>> _generatePdf(String title, String content) async {
    final pdf = pw.Document();
    final plainText = _stripMarkdown(content);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(title,
                  // ignore: prefer_const_constructors
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 16),
            pw.Paragraph(
              text: plainText,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// 去除 Markdown 标记
  String _stripMarkdown(String md) {
    var text = md;
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\*{1,3}|_{1,3}'), '');
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'`[^`]+`'), '');
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '');
    text = text.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), '');
    text = text.replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// 安全文件名（替换非法字符）
  String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
