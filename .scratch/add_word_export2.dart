import 'dart:io';

void main() {
  var file = File('lib/services/export_service.dart');
  var content = file.readAsStringSync();
  
  final wordMethod = '''

  @override
  Future<void> exportAsWord({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final html = _generateWordHtml(title, content);
    await File(savePath).writeAsString(html);
  }

  String _generateWordHtml(String title, String content) {
    final plainText = _stripMarkdown(content);
    final paragraphs = plainText.split('\n\n')
        .where((p) => p.trim().isNotEmpty).toList();
    final bodyHtml = paragraphs.map((p) {
      final lines = p.split('\n')
          .map((l) => l.trim()).where((l) => l.isNotEmpty);
      return '<p>' + lines.join('<br/>') + '</p>';
    }).join('\n');

    var sb = StringBuffer();
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
    sb.writeln('<h1>' + title + '</h1>');
    sb.writeln(bodyHtml);
    sb.writeln('</body>');
    sb.writeln('</html>');
    return sb.toString();
  }
''';
  
  final lastBrace = content.lastIndexOf('}');
  content = content.substring(0, lastBrace) + wordMethod + '\n' + content.substring(lastBrace);
  
  file.writeAsStringSync(content);
  print('Added Word export method');
}
