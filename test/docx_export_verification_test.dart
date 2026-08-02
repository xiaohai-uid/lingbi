import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/import_export/data/export_service.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/models/project.dart';

/// #47 验证：导出 DOCX
///
/// 验收条件：
/// 1. 已采纳章节可导出为 .docx 文件
/// 2. 导出文件包含章节标题（Heading/Title 样式）
/// 3. 导出文件段落格式正确（正文段落、无乱码）
/// 4. 多章节导出时按顺序排列
/// 5. 导出文件是合法 OOXML zip 结构
void main() {
  late Directory tempDir;
  late ExportService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_export_');
    service = ExportService();
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('DOCX 导出结构', () {
    test('导出文件是合法 zip 且包含 OOXML 必要条目', () async {
      final savePath = '${tempDir.path}/chapter.docx';
      await service.exportAsDocx(
        title: '第一章：觉醒',
        content: '林渊站在楼顶。\n\n灵气如潮水般涌来。',
        savePath: savePath,
      );

      final file = File(savePath);
      expect(file.existsSync(), isTrue);

      // 解压验证 OOXML 结构
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toSet();

      expect(names, contains('[Content_Types].xml'));
      expect(names, contains('_rels/.rels'));
      expect(names, contains('word/document.xml'));
      expect(names, contains('word/_rels/document.xml.rels'));
    });

    test('document.xml 包含 Title 样式标题', () async {
      final savePath = '${tempDir.path}/titled.docx';
      await service.exportAsDocx(
        title: '万界守夜人',
        content: '正文内容',
        savePath: savePath,
      );

      final bytes = File(savePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.files
          .firstWhere((f) => f.name == 'word/document.xml')
          .content as List<int>;
      final xml = utf8.decode(docXml);

      expect(xml, contains('w:val="Title"'));
      expect(xml, contains('万界守夜人'));
    });

    test('Markdown 标题转为 Heading 样式', () async {
      final savePath = '${tempDir.path}/headings.docx';
      await service.exportAsDocx(
        title: '测试',
        content: '## 第二节\n\n段落内容\n\n### 小节',
        savePath: savePath,
      );

      final bytes = File(savePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.files
          .firstWhere((f) => f.name == 'word/document.xml')
          .content as List<int>;
      final xml = utf8.decode(docXml);

      expect(xml, contains('w:val="Heading2"'));
      expect(xml, contains('w:val="Heading3"'));
      expect(xml, contains('第二节'));
      expect(xml, contains('小节'));
    });

    test('中文内容无乱码（XML 转义正确）', () async {
      final savePath = '${tempDir.path}/chinese.docx';
      await service.exportAsDocx(
        title: '特殊字符 <测试> & "引号"',
        content: '包含 <html> & "引号" 的正文',
        savePath: savePath,
      );

      final bytes = File(savePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.files
          .firstWhere((f) => f.name == 'word/document.xml')
          .content as List<int>;
      final xml = utf8.decode(docXml);

      // XML 转义后不含裸 < > &
      expect(xml, contains('&lt;测试&gt;'));
      expect(xml, contains('&amp;'));
      // 不含未转义的裸尖括号（除了 XML 标签本身）
      expect(xml, isNot(contains('<测试>')));
    });

    test('空标题时不生成 Title 段落', () async {
      final savePath = '${tempDir.path}/notitle.docx';
      await service.exportAsDocx(
        title: '  ',
        content: '只有正文',
        savePath: savePath,
      );

      final bytes = File(savePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.files
          .firstWhere((f) => f.name == 'word/document.xml')
          .content as List<int>;
      final xml = utf8.decode(docXml);

      expect(xml, isNot(contains('w:val="Title"')));
      expect(xml, contains('只有正文'));
    });
  });

  group('多章节导出', () {
    test('exportProjectToDirectory 按文档顺序生成多个 docx', () async {
      final outputDir = '${tempDir.path}/output';
      final project = Project(
        name: '测试项目',
        directoryPath: tempDir.path,
      );
      final documents = [
        Document(id: 'doc-1', projectId: project.id, title: '第一章', filePath: ''),
        Document(id: 'doc-2', projectId: project.id, title: '第二章', filePath: ''),
        Document(id: 'doc-3', projectId: project.id, title: '第三章', filePath: ''),
      ];
      final contents = {
        'doc-1': '第一章内容',
        'doc-2': '第二章内容',
        'doc-3': '第三章内容',
      };

      await service.exportProjectToDirectory(
        project: project,
        documents: documents,
        contents: contents,
        outputDir: outputDir,
        format: 'docx',
      );

      final dir = Directory(outputDir);
      final docxFiles = dir
          .listSync()
          .where((f) => f.path.endsWith('.docx'))
          .toList();
      expect(docxFiles.length, 3);

      // 验证每个文件都是合法 zip
      for (final f in docxFiles) {
        final bytes = (f as File).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        expect(
          archive.files.map((e) => e.name),
          contains('word/document.xml'),
        );
      }
    });
  });
}
