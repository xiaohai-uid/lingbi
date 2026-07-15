/// 字数统计工具
///
/// 中文字数: 每个汉字计 1 字
/// 英文单词: 每个连续字母组计 1 词
/// 数字: 连续数字计 1 个(但中文数字计字)
library;

/// 统计文本字数 — 中文按字，英文按词
int countWords(String text) {
  if (text.trim().isEmpty) return 0;

  int count = 0;
  bool inWord = false;

  for (int i = 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);

    // 中文字符 (CJK统一表意文字)
    if (c >= 0x4E00 && c <= 0x9FFF ||
        c >= 0x3400 && c <= 0x4DBF ||
        c >= 0x20000 && c <= 0x2A6DF ||
        c >= 0x2A700 && c <= 0x2B73F ||
        c >= 0x2B740 && c <= 0x2B81F ||
        c >= 0x2B820 && c <= 0x2CEAF) {
      count++;
      inWord = false;
      continue;
    }

    // 英文字母 (包括带数字的词)
    if (c >= 0x41 && c <= 0x5A || // A-Z
        c >= 0x61 && c <= 0x7A || // a-z
        c >= 0x30 && c <= 0x39) { // 0-9
      if (!inWord) {
        count++;
        inWord = true;
      }
      continue;
    }

    // 其他字符 (空格、标点等) — 结束当前单词
    inWord = false;
  }

  return count;
}
