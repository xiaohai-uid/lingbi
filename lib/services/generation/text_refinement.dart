/// TextRefinementService — AI 润色/扩写/改写/续写
library;

class TextRefinementService {
  static const supportedModes = ['continue', 'polish', 'expand', 'rewrite'];

  static String modeLabel(String mode) {
    return switch (mode) {
      'continue' => '续写',
      'polish' => '润色',
      'expand' => '扩写',
      'rewrite' => '改写',
      _ => mode,
    };
  }

  static String buildPrompt({
    required String mode,
    required String text,
  }) {
    final instruction = switch (mode) {
      'continue' => '根据以下文本，自然地续写下一段。保持风格一致，注意和前文自然衔接。',
      'polish' => '润色以下文本，使其更流畅、更优美。保持原意不变，优化表达方式。',
      'expand' => '扩写以下文本，增加细节描写、人物心理或环境氛围，使内容更丰富。',
      'rewrite' => '用不同风格改写以下文本。可以改变句式结构、调整表达角度，但保留核心意思。',
      _ => '处理以下文本。',
    };

    return '你是一个专业小说编辑。$instruction\n\n'
        '原文：\n$text\n\n'
        '请直接输出处理后的文本，不要加额外说明。';
  }
}