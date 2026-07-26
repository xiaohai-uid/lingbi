import 'dart:io';

void main() {
  var file = File('lib/services/export_service.dart');
  var content = file.readAsStringSync();
  
  // Add exportAsWord method before the closing brace of ExportService class
  final wordMethod = '''

  /// 导出为 Word 兼容格式
  ///
  /// 使用 HTML 格式嵌入 .doc 文件，兼容作家助手导入。
  @override
  Future<void> exportAsWord({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final html = _generateWordHtml(title, content);
    await File(savePath).writeAsString(html);
  }

  /// 生成 Word 兼容 HTML
  String _generateWordHtml(String title, String content) {
    final plainText = _stripMarkdown(content);
    final paragraphs = plainText.split('\n\n')
        .where((p) => p.trim().isNotEmpty).toList();
    final bodyHtml = paragraphs.map((p) {
      final lines = p.split('\n')
          .map((l) => l.trim()).where((l) => l.isNotEmpty);
      return '<p>${lines.join("<br/>")}</p>';
    }).join('\n');

    return '<html>\n'
        '<head>\n'
        '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">\n'
        '<style>\n'
        'body { font-family: SimSun, serif; font-size: 12pt; line-height: 1.8; padding: 20pt; }\n'
        'h1 { font-size: 18pt; font-weight: bold; text-align: center; margin-bottom: 20pt; }\n'
        'p { text-indent: 2em; margin: 0; line-height: 1.8; }\n'
        '</style>\n'
        '</head>\n'
        '<body>\n'
        '<h1>$title</h1>\n'
        '$bodyHtml\n'
        '</body>\n'
        '</html>';
  }
''';
  
  // Insert before the last closing brace of the class
  final lastBrace = content.lastIndexOf('}');
  content = content.substring(0, lastBrace) + wordMethod + '\n' + content.substring(lastBrace);
  
  file.writeAsStringSync(content);
  print('Added Word export method');
}
