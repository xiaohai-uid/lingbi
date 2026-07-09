import 'dart:convert';

/// Service for exporting document content in various formats.
class ExportService {
  /// Export document content to the specified format.
  ///
  /// Supported formats: markdown, txt, pdf
  /// Returns a map with keys: success, format, filename, content (base64), and optionally error/note.
  Future<Map<String, dynamic>> export(
    String content,
    String title,
    String format,
  ) async {
    if (content.isEmpty) {
      return {
        'success': false,
        'error': 'Content cannot be empty',
      };
    }

    if (title.isEmpty) {
      return {
        'success': false,
        'error': 'Title cannot be empty',
      };
    }

    try {
      switch (format.toLowerCase()) {
        case 'markdown':
          return _exportMarkdown(content, title);
        case 'txt':
          return _exportTxt(content, title);
        case 'pdf':
          return _exportPdf(content, title);
        default:
          return {
            'success': false,
            'error':
                'Unsupported format: $format. Supported formats: markdown, txt, pdf',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Export failed: ${e.toString()}',
      };
    }
  }

  /// List supported export formats.
  List<String> get supportedFormats => ['markdown', 'txt', 'pdf'];

  /// Export content as Markdown.
  Map<String, dynamic> _exportMarkdown(String content, String title) {
    final fileContent = '# $title\n\n$content';
    return {
      'success': true,
      'format': 'markdown',
      'filename': '$title.md',
      'content': base64Encode(utf8.encode(fileContent)),
      'size': utf8.encode(fileContent).length,
    };
  }

  /// Export content as plain text (Markdown stripped).
  Map<String, dynamic> _exportTxt(String content, String title) {
    final plainContent = _stripMarkdown(content);
    final header = '$title\n${'=' * title.length}\n\n';
    final fileContent = '$header$plainContent';
    return {
      'success': true,
      'format': 'txt',
      'filename': '$title.txt',
      'content': base64Encode(utf8.encode(fileContent)),
      'size': utf8.encode(fileContent).length,
    };
  }

  /// Export content as PDF (HTML-based mock, real integration would use WeasyPrint).
  Map<String, dynamic> _exportPdf(String content, String title) {
    final htmlContent = _generateHtml(content, title);
    // In production, this would call a PDF conversion tool.
    // For now, we return base64-encoded HTML that acts as a PDF placeholder.
    return {
      'success': true,
      'format': 'pdf',
      'filename': '$title.pdf',
      'content': base64Encode(utf8.encode(htmlContent)),
      'size': utf8.encode(htmlContent).length,
      'note':
          'Mock implementation — integrate WeasyPrint or similar for real PDF export',
    };
  }

  /// Generate a simple HTML document from markdown content.
  String _generateHtml(String content, String title) {
    final bodyHtml = _markdownToHtml(content);
    return '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>$title</title>
<style>
  body { font-family: 'Noto Sans SC', sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 2em; }
  h1, h2, h3 { color: #333; }
  code { background: #f4f4f4; padding: 2px 4px; border-radius: 3px; }
  pre { background: #f4f4f4; padding: 1em; border-radius: 5px; overflow-x: auto; }
  blockquote { border-left: 3px solid #ccc; margin-left: 0; padding-left: 1em; color: #666; }
</style>
</head>
<body>
<h1>$title</h1>
$bodyHtml
</body>
</html>''';
  }

  /// Simple Markdown-to-HTML conversion.
  String _markdownToHtml(String md) {
    var html = md;
    // Headers
    html = html.replaceAllMapped(
      RegExp(r'^######\s+(.*?)$', multiLine: true),
      (m) => '<h6>${m[1]}</h6>',
    );
    html = html.replaceAllMapped(
      RegExp(r'^#####\s+(.*?)$', multiLine: true),
      (m) => '<h5>${m[1]}</h5>',
    );
    html = html.replaceAllMapped(
      RegExp(r'^####\s+(.*?)$', multiLine: true),
      (m) => '<h4>${m[1]}</h4>',
    );
    html = html.replaceAllMapped(
      RegExp(r'^###\s+(.*?)$', multiLine: true),
      (m) => '<h3>${m[1]}</h3>',
    );
    html = html.replaceAllMapped(
      RegExp(r'^##\s+(.*?)$', multiLine: true),
      (m) => '<h2>${m[1]}</h2>',
    );
    html = html.replaceAllMapped(
      RegExp(r'^#\s+(.*?)$', multiLine: true),
      (m) => '<h1>${m[1]}</h1>',
    );
    // Bold and italic
    html = html.replaceAllMapped(
      RegExp(r'\*\*\*(.+?)\*\*\*'),
      (m) => '<strong><em>${m[1]}</em></strong>',
    );
    html = html.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (m) => '<strong>${m[1]}</strong>',
    );
    html = html.replaceAllMapped(
      RegExp(r'\*(.+?)\*'),
      (m) => '<em>${m[1]}</em>',
    );
    // Inline code
    html = html.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => '<code>${m[1]}</code>',
    );
    // Code blocks
    html = html.replaceAllMapped(
      RegExp(r'```(\w*)\n([\s\S]*?)```'),
      (m) => '<pre><code>${m[2]}</code></pre>',
    );
    // Links
    html = html.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => '<a href="${m[2]}">${m[1]}</a>',
    );
    // Blockquotes
    html = html.replaceAllMapped(
      RegExp(r'^>\s+(.*?)$', multiLine: true),
      (m) => '<blockquote>${m[1]}</blockquote>',
    );
    // Unordered lists
    html = html.replaceAllMapped(
      RegExp(r'^[\s]*[-*+]\s+(.*?)$', multiLine: true),
      (m) => '<li>${m[1]}</li>',
    );
    // Paragraphs (double newlines)
    html = html.replaceAllMapped(
      RegExp(r'\n\n'),
      (m) => '</p><p>',
    );
    return '<p>$html</p>';
  }

  /// Strip Markdown syntax to produce plain text.
  String _stripMarkdown(String md) {
    return md
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\*{1,3}|_{1,3}'), '')
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'`[^`]+`'), '')
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^---$', multiLine: true), '')
        .trim();
  }
}
