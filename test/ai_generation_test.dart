/// AI 生成管线集成测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/free_provider.dart';
import 'package:lingbi/core/ai/llm_models.dart';

void main() {
  group('FreeProvider AI Generation', () {
    test('generateText returns non-empty response', () async {
      final provider = FreeProvider();
      final result = await provider.generateText(const LLMRequest(
        messages: [
          LLMMessage(role: 'system', content: '你是专业小说创作助手。根据创意生成故事梗概。'),
          LLMMessage(
              role: 'user',
              content: '创意：程序员穿越到异世界，用编程思维解决魔法问题\n类型：玄幻\n风格：起点爆款'),
        ],
        maxTokens: 4096,
        temperature: 0.8,
      ));
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(10));
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('streamText returns stream of chunks', () async {
      final provider = FreeProvider();
      final stream = provider.streamText(const LLMRequest(
        messages: [
          LLMMessage(role: 'system', content: '续写以下段落'),
          LLMMessage(role: 'user', content: '陈曦站在监测站的控制台前，凝视着屏幕上跳动的数据。'),
        ],
        maxTokens: 1024,
      ));
      final chunks = await stream.toList();
      expect(chunks, isNotEmpty);
      expect(chunks.length, greaterThanOrEqualTo(1));
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('AIService-like prompt produces structured output', () async {
      final provider = FreeProvider();
      final result = await provider.generateText(const LLMRequest(
        messages: [
          LLMMessage(
              role: 'system',
              content: '你是专业小说创作助手。根据用户提供的创意、类型和风格，生成一个完整的小说梗概。'
                  '梗概必须包含：\n1. 故事设定（世界观、时代背景）\n2. 核心主题\n3. 主要人物（至少2-3个，含性格特点）\n'
                  '4. 故事主线（起承转合）\n5. 第一卷的章节大纲（至少5章）'),
          LLMMessage(role: 'user', content: '创意：一个修真少年从废材崛起\n类型：玄幻\n风格：起点爆款'),
        ],
        maxTokens: 4096,
        temperature: 0.8,
      ));
      expect(result, contains('Free provider simulation'));
      expect(result.length, greaterThan(20));
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
