/// Markdown 辅助工具函数
class MarkdownHelper {
  /// 从 Markdown 内容中提取标题
  static List<String> extractHeadings(String content) {
    final regex = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true);
    return regex.allMatches(content).map((m) => m.group(2)!.trim()).toList();
  }

  /// 从 Markdown 内容中提取 H1 标题（文档标题）
  static String? extractTitle(String content) {
    final headings = extractHeadings(content);
    return headings.isNotEmpty ? headings.first : null;
  }

  /// 生成 Markdown 大纲（层级结构）
  static List<HeadingNode> buildOutline(String content) {
    final regex = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true);
    final nodes = <HeadingNode>[];
    for (final match in regex.allMatches(content)) {
      final level = match.group(1)!.length;
      final text = match.group(2)!.trim();
      nodes.add(HeadingNode(level: level, text: text));
    }
    return nodes;
  }

  /// 计算 Markdown 内容的纯文本字数
  static int wordCount(String markdown) {
    // 移除 Markdown 标记
    final text = markdown
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '')  // 图片
        .replaceAll(RegExp(r'\[([^\]]*)\]\(.*?\)'), r'$1')  // 链接
        .replaceAll(RegExp(r'[#*_~>`|\\\-]'), '')     // 标记符号
        .replaceAll(RegExp(r'\n{2,}'), '\n')           // 多余空行
        .trim();

    // 统计中英文混排字数
    final chinese = RegExp(r'[\u4e00-\u9fff]');
    final chineseCount = chinese.allMatches(text).length;
    final english = text.replaceAll(chinese, ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    return chineseCount + english;
  }
}

class HeadingNode {
  final int level;
  final String text;

  HeadingNode({required this.level, required this.text});
}