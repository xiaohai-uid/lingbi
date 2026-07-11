/// 测试: TextRefinementService — AI 润色/扩写/改写
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/generation/text_refinement.dart';

void main() {
  group('TextRefinementService', () {
    test('buildPrompt 续写模式', () {
      final prompt = TextRefinementService.buildPrompt(
          mode: 'continue', text: '林北辰睁开眼睛');

      expect(prompt, contains('续写'));
      expect(prompt, contains('林北辰睁开眼睛'));
      expect(prompt, contains('自然衔接'));
    });

    test('buildPrompt 润色模式', () {
      final prompt = TextRefinementService.buildPrompt(
          mode: 'polish', text: '他走得很快速。');

      expect(prompt, contains('润色'));
      expect(prompt, contains('他走得很快速。'));
      expect(prompt, contains('更流畅'));
    });

    test('buildPrompt 扩写模式', () {
      final prompt = TextRefinementService.buildPrompt(
          mode: 'expand', text: '两人对视一笑。');

      expect(prompt, contains('扩写'));
      expect(prompt, contains('两人对视一笑。'));
      expect(prompt, contains('更丰富'));
    });

    test('buildPrompt 改写模式', () {
      final prompt = TextRefinementService.buildPrompt(
          mode: 'rewrite', text: '天空很蓝。');

      expect(prompt, contains('改写'));
      expect(prompt, contains('天空很蓝。'));
      expect(prompt, contains('不同风格'));
    });

    test('支持的 mode 列表', () {
      expect(TextRefinementService.supportedModes,
          containsAll(['continue', 'polish', 'expand', 'rewrite']));
    });
  });
}