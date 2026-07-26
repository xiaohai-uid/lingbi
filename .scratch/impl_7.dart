import 'dart:io';

void main() {
  // 1. Create parameter validation utility
  var file = File('lib/utils/ai_param_validator.dart');
  var content = '''
/// AI 参数校验工具
///
/// 发送前自动校验温度和最大 Token 参数合法性，越界即时提示。
/// 发送前自动清理异常字符，防止特殊字符导致请求被拒。
class AiParamValidator {
  /// 温度范围
  static const double minTemperature = 0.0;
  static const double maxTemperature = 2.0;

  /// 最大 Token 范围
  static const int minMaxTokens = 1;
  static const int maxMaxTokens = 128000;

  /// 校验温度参数
  ///
  /// 返回 null 表示合法，否则返回错误提示。
  static String? validateTemperature(double temperature) {
    if (temperature < minTemperature || temperature > maxTemperature) {
      return '温度值必须在 \$minTemperature ~ \$maxTemperature 之间';
    }
    return null;
  }

  /// 校验最大 Token 参数
  ///
  /// 返回 null 表示合法，否则返回错误提示。
  static String? validateMaxTokens(int maxTokens) {
    if (maxTokens < minMaxTokens) {
      return '最大 Token 数不能少于 \$minMaxTokens';
    }
    if (maxTokens > maxMaxTokens) {
      return '最大 Token 数不能超过 \$maxMaxTokens';
    }
    return null;
  }

  /// 清理异常字符
  ///
  /// 去除控制字符（保留换行和制表符），防止请求被拒。
  static String sanitizeText(String text) {
    // 保留 \n, \r, \t, 去除其他控制字符
    return text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// 清理消息列表中的异常字符
  static List<dynamic> sanitizeMessages(List<dynamic> messages) {
    return messages.map((msg) {
      if (msg is Map<String, dynamic> && msg['content'] is String) {
        return {...msg, 'content': sanitizeText(msg['content'] as String)};
      }
      return msg;
    }).toList();
  }
}
''';
  file.writeAsStringSync(content);
  print('Created ai_param_validator.dart');

  // 2. Add Word export to ExportService
  file = File('lib/services/export_service.dart');
  content = file.readAsStringSync();
  
  // Add exportAsWord method
  final wordExport = '''

  /// 导出为 Word 兼容格式（HTML embedded in .doc）
  ///
  /// 使用 HTML 格式嵌入 .doc 文件，兼容作家助手导入。
  @override
  Future<void> exportAsWord({
    required String title,
    required String content,
    required String savePath,
  }) async {
    final html = _generateWordHtml(title, content);
    final file = File(savePath);
    await file.writeAsString(html);
  }

  /// 生成 Word 兼容 HTML
  String _generateWordHtml(String title, String content) {
    final plainText = _stripMarkdown(content);
    // 转换 Markdown 换行为段落
    final paragraphs = plainText.split('\n\n').where((p) => p.trim().isNotEmpty);
    final bodyHtml = paragraphs.map((p) {
      final lines = p.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
      return '<p>${lines.join("<br/>")}</p>';
    }).join('\n');
    
    return '''<html xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<!--[if gte mso 9]>
<xml>
<w:WordDocument>
<w:View>Print</w:View>
</w:WordDocument>
</xml>
<![endif]-->
<style>
/* 作家助手兼容样式 */
body { font-family: SimSun, serif; font-size: 12pt; line-height: 1.8; padding: 20pt; }
h1 { font-size: 18pt; font-weight: bold; text-align: center; margin-bottom: 20pt; }
p { text-indent: 2em; margin: 0; line-height: 1.8; }
</style>
</head>
<body>
<h1>\$title</h1>
\$bodyHtml
</body>
</html>''';
  }
''';
  
  content = content.replaceFirst("import 'package:lingbi/services/interfaces/i_export_service.dart';", "import 'package:lingbi/services/interfaces/i_export_service.dart';");
  content = content.replaceFirst("}", wordExport + "\n}");
  file.writeAsStringSync(content);
  print('Added Word export to ExportService');

  // 3. Update IExportService interface
  file = File('lib/services/interfaces/i_export_service.dart');
  content = file.readAsStringSync();
  content = content.replaceFirst("}", '''
  Future<void> exportAsWord({
    required String title,
    required String content,
    required String savePath,
  });
}''');
  file.writeAsStringSync(content);
  print('Updated IExportService interface');

  print('Done');
}
