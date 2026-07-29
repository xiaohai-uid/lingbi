import 'package:lingbi/services/interfaces/i_export_service.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lingbi/services/atomic_file_store.dart';

/// 导出服务 - 支持 Markdown / TXT / PDF / Word 格式导出
class ExportService implements IExportService {
  ExportService({AtomicFileStore? atomicStore})
      : _atomicStore = atomicStore ?? AtomicFileStore();

  final AtomicFileStore _atomicStore;

  @override
  Future<void> exportAsMarkdown({
    required String content,
    required String savePath,
  }) async {
    await _atomicStore.writeString(savePath, content);
  }

  @override
  Future<void> exportAsTxt({
    required String content,
    required String savePath,
  }) async {
    final plainText = _stripMarkdown(content);
    await _atomicStore.writeString(savePath, plainText);
  }

  @override
  Future<void> exportAsPdf({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final pdfBytes = await _generatePdf(title, content);
    await _atomicStore.writeBytes(savePath, pdfBytes);
  }

  @override
  Future<void> exportAsDocx({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final docxBytes = _generateDocx(title, content);
    await _atomicStore.writeBytes(savePath, docxBytes);
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
          await _atomicStore.writeString(filePath, plainText);
          break;
        case 'pdf':
          filePath = '${dir.path}/$safeName.pdf';
          final pdfBytes = await _generatePdf(doc.title, content);
          await _atomicStore.writeBytes(filePath, pdfBytes);
          break;
        case 'docx':
          filePath = '${dir.path}/$safeName.docx';
          await _atomicStore.writeBytes(
              filePath, _generateDocx(doc.title, content));
          break;
        default:
          filePath = '${dir.path}/$safeName.md';
          await _atomicStore.writeString(filePath, content);
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
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
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

  /// 生成标准 OOXML (.docx) 字节。仅用已有 `archive` 包，不引入新依赖。
  ///
  /// 产物包含最小合法结构：`[Content_Types].xml`、`_rels/.rels`、
  /// `word/document.xml`、`word/_rels/document.xml.rels`，可被 Word/WPS 打开，
  /// 也可被 `archive` 解回校验。
  List<int> _generateDocx(String title, String content) {
    final paragraphs = StringBuffer();
    if (title.trim().isNotEmpty) {
      paragraphs.write(_docxParagraph(title.trim(), style: 'Title'));
    }
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trimRight();
      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length.clamp(1, 6);
        paragraphs.write(_docxParagraph(
          _stripInline(heading.group(2)!),
          style: 'Heading$level',
        ));
      } else {
        paragraphs.write(_docxParagraph(_stripInline(line)));
      }
    }

    const documentXml = _docxDocumentOpen;
    final body = '$documentXml${paragraphs.toString()}$_docxDocumentClose';

    final archive = Archive()
      ..add(ArchiveFile.string('[Content_Types].xml', _docxContentTypes))
      ..add(ArchiveFile.string('_rels/.rels', _docxRootRels))
      ..add(ArchiveFile.string(
          'word/_rels/document.xml.rels', _docxDocumentRels))
      ..add(ArchiveFile.string('word/document.xml', body));
    return ZipEncoder().encodeBytes(archive);
  }

  String _docxParagraph(String text, {String? style}) {
    final pPr = style == null ? '' : '<w:pPr><w:pStyle w:val="$style"/></w:pPr>';
    final run = text.isEmpty
        ? ''
        : '<w:r><w:t xml:space="preserve">${_xmlEscape(text)}</w:t></w:r>';
    return '<w:p>$pPr$run</w:p>';
  }

  String _stripInline(String text) {
    var t = text;
    t = t.replaceAll(RegExp(r'\*{1,3}|_{1,3}'), '');
    t = t.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    t = t.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '');
    return t;
  }

  String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _stripMarkdown(String md) {
    var text = md;
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\*{1,3}|_{1,3}'), '');
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'`[^`]+`'), '');
    text = text.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '');
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

// ─── OOXML (.docx) 模板片段 ──────────────────────────────────────

const String _docxContentTypes =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '</Types>';

const String _docxRootRels =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
    '</Relationships>';

const String _docxDocumentRels =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"></Relationships>';

const String _docxDocumentOpen =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:body>';

const String _docxDocumentClose = '<w:sectPr/></w:body></w:document>';
