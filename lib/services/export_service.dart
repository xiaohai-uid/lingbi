import 'package:lingbi/services/interfaces/i_export_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/core/models/world.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 导出服务 - 支持 Markdown / TXT / PDF / DOCX / EPUB 格式导出
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

  /// 导出为 DOCX（Word 文档）
  @override
  Future<void> exportAsDocx({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final docxBytes = await _generateDocx(title, content);
    final file = File(savePath);
    await file.writeAsBytes(docxBytes);
  }

  /// 导出为 EPUB（电子书）
  @override
  Future<void> exportAsEpub({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final epubBytes = await _generateEpub(title, content);
    final file = File(savePath);
    await file.writeAsBytes(epubBytes);
  }

  /// 导出整个项目到指定文件夹
  @override
  Future<void> exportProjectToDirectory({
    required World project,
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
        case 'docx':
          filePath = '${dir.path}/$safeName.docx';
          final docxBytes = await _generateDocx(doc.title, content);
          await File(filePath).writeAsBytes(docxBytes);
          break;
        case 'epub':
          filePath = '${dir.path}/$safeName.epub';
          final epubBytes = await _generateEpub(doc.title, content);
          await File(filePath).writeAsBytes(epubBytes);
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

  /// 生成 DOCX 字节数据
  Future<List<int>> _generateDocx(String title, String content) async {
    final plainText = _stripMarkdown(content);
    final escapedTitle = _xmlEscape(title);

    // 按段落拆分
    final paragraphs =
        plainText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    final bodyXml = StringBuffer();
    for (final para in paragraphs) {
      final escaped = _xmlEscape(para);
      if (para.startsWith('#')) {
        // 标题行
        final level = para.startsWith('## ') ? 2 : 1;
        final headingStyle = level == 2 ? 'Heading2' : 'Heading1';
        bodyXml.writeln(
          '<w:p><w:pPr><w:pStyle w:val="$headingStyle"/></w:pPr>'
          '<w:r><w:t>${_xmlEscape(para.replaceAll(RegExp(r'^#+\s*'), ''))}</w:t></w:r></w:p>',
        );
      } else {
        bodyXml.writeln(
          '<w:p><w:r><w:t>$escaped</w:t></w:r></w:p>',
        );
      }
    }

    final documentXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>'
        '<w:p><w:pPr><w:pStyle w:val="Title"/></w:pPr><w:r><w:t>$escapedTitle</w:t></w:r></w:p>'
        '<w:p><w:r><w:t xml:space="preserve"> </w:t></w:r></w:p>'
        '$bodyXml'
        '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr>'
        '</w:body></w:document>';

    const stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="SimSun" w:eastAsia="SimSun" w:hAnsi="SimSun"/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr></w:style>'
        '<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:rPr><w:rFonts w:ascii="SimHei" w:eastAsia="SimHei" w:hAnsi="SimHei"/><w:b/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr></w:style>'
        '<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:rPr><w:rFonts w:ascii="SimHei" w:eastAsia="SimHei" w:hAnsi="SimHei"/><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>'
        '<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:rPr><w:rFonts w:ascii="SimHei" w:eastAsia="SimHei" w:hAnsi="SimHei"/><w:b/><w:sz w:val="44"/><w:szCs w:val="44"/><w:color w:val="000000"/></w:rPr></w:style>'
        '</w:styles>';

    const settingsXml =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"/>';

    final archive = Archive()
      ..addFile(
          ArchiveFile('_rels/.rels', 0, '# Generated by LingBi'.codeUnits))
      ..addFile(ArchiveFile(
        'word/document.xml',
        0,
        utf8.encode(documentXml),
      ))
      ..addFile(ArchiveFile(
        'word/styles.xml',
        0,
        utf8.encode(stylesXml),
      ))
      ..addFile(ArchiveFile(
        'word/settings.xml',
        0,
        utf8.encode(settingsXml),
      ))
      ..addFile(ArchiveFile(
        'word/_rels/document.xml.rels',
        0,
        utf8.encode('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>'
            '</Relationships>'),
      ));

    return ZipEncoder().encode(archive)!;
  }

  /// 生成 EPUB 字节数据
  Future<List<int>> _generateEpub(String title, String content) async {
    final plainText = _stripMarkdown(content);
    final escapedTitle = _xmlEscape(title);
    final uuid = 'lingbi-${DateTime.now().microsecondsSinceEpoch}';

    // 按段落拆分，每段一个 HTML 文件（限制每章大小）
    final paragraphs =
        plainText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    const chunkSize = 50;
    final chunks = <List<String>>[];
    for (var i = 0; i < paragraphs.length; i += chunkSize) {
      chunks.add(paragraphs.sublist(
          i,
          i + chunkSize > paragraphs.length
              ? paragraphs.length
              : i + chunkSize));
    }

    final manifestItems = StringBuffer();
    final spineItems = StringBuffer();
    final navPoints = StringBuffer();
    for (var i = 0; i < chunks.length; i++) {
      final chapterId = 'chapter${i + 1}';
      final chapterTitle = i == 0 ? title : '第${i + 1}章';
      manifestItems.writeln(
        '<item id="$chapterId" href="Text/$chapterId.xhtml" media-type="application/xhtml+xml"/>',
      );
      spineItems.writeln('<itemref idref="$chapterId"/>');
      navPoints.writeln(
        '<navPoint id="$chapterId" playOrder="${i + 1}"><navLabel><text>${_xmlEscape(chapterTitle)}</text></navLabel><content src="Text/$chapterId.xhtml"/></navPoint>',
      );
    }

    // 构建 HTML 内容
    final chapterFiles = <ArchiveFile>[];
    for (var i = 0; i < chunks.length; i++) {
      final chapterTitle = i == 0 ? title : '第${i + 1}章';
      final bodyContent =
          chunks[i].map((p) => '<p>${_xmlEscape(p)}</p>').join('\n');
      final chapterHtml = '<?xml version="1.0" encoding="UTF-8"?>'
          '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
          '<html xmlns="http://www.w3.org/1999/xhtml">'
          '<head><title>${_xmlEscape(chapterTitle)}</title><link rel="stylesheet" type="text/css" href="../Styles/style.css"/></head>'
          '<body><h1>${_xmlEscape(chapterTitle)}</h1>$bodyContent</body></html>';

      chapterFiles.add(ArchiveFile(
        'OEBPS/Text/chapter${i + 1}.xhtml',
        0,
        utf8.encode(chapterHtml),
      ));
    }

    final contentOpf = '<?xml version="1.0" encoding="UTF-8"?>'
        '<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="3.0">'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
        '<dc:title>$escapedTitle</dc:title>'
        '<dc:identifier id="BookId">$uuid</dc:identifier>'
        '<dc:language>zh</dc:language>'
        '<meta property="dcterms:modified">2024-01-01T00:00:00Z</meta>'
        '</metadata>'
        '<manifest>'
        '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>'
        '<item id="style" href="Styles/style.css" media-type="text/css"/>'
        '$manifestItems'
        '</manifest>'
        '<spine toc="ncx">'
        '$spineItems'
        '</spine>'
        '</package>';

    final tocNcx = '<?xml version="1.0" encoding="UTF-8"?>'
        '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">'
        '<head><meta name="dtb:uid" content="$uuid"/><meta name="dtb:depth" content="1"/><meta name="dtb:totalPageCount" content="0"/><meta name="dtb:maxPageNumber" content="0"/></head>'
        '<docTitle><text>$escapedTitle</text></docTitle>'
        '<navMap>$navPoints</navMap>'
        '</ncx>';

    const containerXml = '<?xml version="1.0" encoding="UTF-8"?>'
        '<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">'
        '<rootfiles>'
        '<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
        '</rootfiles>'
        '</container>';

    const styleCss =
        'body { font-family: "SimSun", serif; line-height: 1.6; margin: 1em; } h1 { font-size: 1.5em; margin-bottom: 0.5em; } p { margin: 0.5em 0; text-indent: 2em; }';

    final archive = Archive()
      ..addFile(ArchiveFile('mimetype', 0, 'application/epub+zip'.codeUnits))
      ..addFile(
          ArchiveFile('META-INF/container.xml', 0, utf8.encode(containerXml)))
      ..addFile(ArchiveFile('OEBPS/content.opf', 0, utf8.encode(contentOpf)))
      ..addFile(ArchiveFile('OEBPS/toc.ncx', 0, utf8.encode(tocNcx)))
      ..addFile(
          ArchiveFile('OEBPS/Styles/style.css', 0, utf8.encode(styleCss)));

    chapterFiles.forEach(archive.addFile);

    return ZipEncoder().encode(archive)!;
  }

  /// 去除 Markdown 标记
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

  /// XML 转义
  String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// 安全文件名（替换非法字符）
  String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
