/// TextRefinementService — AI 润色/扩写/改写/续写/缩写/换语调
library;

import '../interfaces/i_retroactive_edit_service.dart';

class TextRefinementService {
  static const supportedModes = [
    'continue', 'polish', 'expand', 'rewrite', 'shorten', 'changeTone',
  ];

  static String modeLabel(String mode) {
    return switch (mode) {
      'continue' => '续写',
      'polish' => '润色',
      'expand' => '扩写',
      'rewrite' => '改写',
      'shorten' => '缩写',
      'changeTone' => '换语调',
      _ => mode,
    };
  }

  static String modeIcon(String mode) {
    return switch (mode) {
      'continue' => '▶️',
      'polish' => '✨',
      'expand' => '📝',
      'rewrite' => '✏️',
      'shorten' => '📏',
      'changeTone' => '🎭',
      _ => '🔧',
    };
  }

  static String buildPrompt({
    required String mode,
    required String text,
    String? targetTone,
  }) {
    final instruction = switch (mode) {
      'continue' => '根据以下文本，自然地续写下一段。保持风格一致，注意和前文自然衔接。',
      'polish' => '润色以下文本，使其更流畅、更优美。保持原意不变，优化表达方式。',
      'expand' => '扩写以下文本，增加细节描写、人物心理或环境氛围，使内容更丰富。',
      'rewrite' => '用不同风格改写以下文本。可以改变句式结构、调整表达角度，但保留核心意思。',
      'shorten' => '缩写以下文本，精简冗余表达。保留核心信息、关键情节和重要描写，压缩到原文的50-70%。',
      'changeTone' => '保持以下文本的核心内容和情节不变，但将语调改为「$targetTone」风格。调整用词、句式、语气以匹配目标语调。',
      _ => '处理以下文本。',
    };

    final toneHint = mode == 'changeTone' && targetTone != null
        ? '\n目标语调：$targetTone\n'
        : '';

    return '你是一个专业小说编辑。$instruction$toneHint\n\n'
        '原文：\n$text\n\n'
        '请直接输出处理后的文本，不要加额外说明。';
  }

  /// 根据 EditMode 获取对应的 mode 字符串
  static String modeFromEnum(EditMode mode) {
    return switch (mode) {
      EditMode.rewrite => 'rewrite',
      EditMode.expand => 'expand',
      EditMode.polish => 'polish',
      EditMode.shorten => 'shorten',
      EditMode.continue_ => 'continue',
      EditMode.changeTone => 'changeTone',
    };
  }
}
