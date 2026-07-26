import 'package:lingbi/services/interfaces/i_export_service.dart';
import 'dart:io';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 导出服务 - 支持 Markdown / TXT / PDF / Word 格式导出
class ExportService implements IExportService {
  ExportService();

  @override
  Future<void> exportAsMarkdown({
    required String content,
    required String savePath,
  }) async {
    final file = File(savePath);
    await file.writeAsString(content);
  }

  @override
  Future<void> exportAsTxt({
    required String content,
    required String savePath,
  }) async {
    final plainText = _stripMarkdown(content);
    final file = File(savePath);
    await file.writeAsString(plainText);
  }

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

  @override
  Future<void> exportAsWord({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final html = _generateWordHtml(title, content);
    await File(savePath).writeAsString(html);
  }

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

  /// 生成 Word 兼容 HTML（embedded .doc 格式，兼容作家助手）
  String _generateWordHtml(String title, String content) {
    final plainText = _stripMarkdown(content);
    final paragraphs = plainText.split('\n\n')
        .where((p) => p.trim().isNotEmpty).toList();
    final bodyHtml = paragraphs.map((p) {
      final lines = p.split('\n')
          .map((l) => l.trim()).where((l) => l.isNotEmpty);
      return '<p>${lines.join('<br/>')}</p>';
    }).join('\n');

    final sb = StringBuffer();
    sb.writeln('<html>');
    sb.writeln('<head>');
    sb.writeln('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">');
    sb.writeln('<style>');
    sb.writeln('body { font-family: SimSun, serif; font-size: 12pt; line-height: 1.8; padding: 20pt; }');
    sb.writeln('h1 { font-size: 18pt; font-weight: bold; text-align: center; margin-bottom: 20pt; }');
    sb.writeln('p { text-indent: 2em; margin: 0; line-height: 1.8; }');
    sb.writeln('</style>');
    sb.writeln('</head>');
    sb.writeln('<body>');
    sb.writeln('<h1>${_escapeHtml(title)}</h1>');
    sb.writeln(bodyHtml);
    sb.writeln('</body>');
    sb.writeln('</html>');
    return sb.toString();
  }

  /// HTML 转义
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

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

  String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\|?*]'), '_').trim();
  }
}
