/// NameGenerator — AI 取名服务
///
/// 生成角色名、地名、功法名等网文命名
library;

/// AI 取名生成器
class NameGenerator {
  /// 构建 prompt
  static String buildPrompt({
    required String genre,
    required String style,
  }) {
    return '你是网文命名专家。根据以下信息，生成至少10个适合该类型小说的命名建议。\n\n'
        '小说类型：$genre\n'
        '写作风格：$style\n\n'
        '请按以下分类输出：\n'
        '【角色名】至少5个，每个格式为"名字 - 身份，性格特点"\n'
        '【地名】至少3个，每个格式为"地名 - 说明"\n'
        '【功法/招式】至少3个，每个格式为"名称 - 说明"\n\n'
        '格式要求：\n'
        '- 每个分类用【】标记\n'
        '- 每个条目用"数字. 内容"格式\n'
        '- 名字要有网文特色，符合 $genre 类型的风格';
  }

  /// 解析 AI 返回的命名文本
  ///
  /// 返回 Map: { '角色名': [...], '地名': [...], '功法': [...] }
  static Map<String, List<String>> parseNames(String text) {
    final result = <String, List<String>>{};
    if (text.trim().isEmpty) return result;

    final lines = text.split('\n');
    String? currentCategory;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 检测分类标记
      final catMatch = RegExp(r'【(.+?)】').firstMatch(trimmed);
      if (catMatch != null) {
        currentCategory = catMatch.group(1);
        result[currentCategory!] = [];
        continue;
      }

      // 检测条目 (数字. 内容)
      if (currentCategory != null) {
        final itemMatch = RegExp(r'^\d+[\.\s]\s*(.+)').firstMatch(trimmed);
        if (itemMatch != null) {
          result[currentCategory]!.add(itemMatch.group(1)!);
        }
      }
    }

    return result;
  }
}
