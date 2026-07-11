/// 测试: RetroactiveEditService — 回溯编辑
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/retroactive_edit_service.dart';
import 'package:lingbi/services/interfaces/i_retroactive_edit_service.dart';
import 'package:lingbi/services/interfaces/i_ai_service.dart';
import 'package:lingbi/services/generation/text_refinement.dart';

class MockAIService implements IAIService {
  final String mockResponse;

  MockAIService(this.mockResponse);

  @override
  String get currentProviderName => 'mock';

  @override
  List<String> get availableProviders => ['mock'];

  @override
  void setProvider(String name) {}

  @override
  void setProjectContext(String context) {}

  @override
  void configureApiKey(String provider, String key) {}

  @override
  Stream<String> chat({
    required String message,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    // Return the mock response in chunks
    final chunkSize = (mockResponse.length / 3).ceil();
    for (var i = 0; i < mockResponse.length; i += chunkSize) {
      yield mockResponse.substring(i, (i + chunkSize).clamp(0, mockResponse.length));
    }
  }

  @override
  Future<String> analyzeStyle(String text) async => mockResponse;

  @override
  Future<String> analyzeNovel(String text) async => mockResponse;

  @override
  Stream<String> continueWriting(String text) async* {
    yield mockResponse;
  }

  @override
  Future<String> generateText(String prompt) async => mockResponse;
}

void main() {
  group('TextRefinementService', () {
    test('buildPrompt 生成 rewrite prompt', () {
      final prompt = TextRefinementService.buildPrompt(
        mode: 'rewrite',
        text: '主角走进了山洞。',
      );
      expect(prompt, contains('改写'));
      expect(prompt, contains('主角走进了山洞'));
    });

    test('buildPrompt 生成 changeTone prompt', () {
      final prompt = TextRefinementService.buildPrompt(
        mode: 'changeTone',
        text: '他快速跑向大门。',
        targetTone: '古风',
      );
      expect(prompt, contains('古风'));
      expect(prompt, contains('语调'));
    });

    test('buildPrompt 生成 shorten prompt', () {
      final prompt = TextRefinementService.buildPrompt(
        mode: 'shorten',
        text: '这是一段很长的描述文字。',
      );
      expect(prompt, contains('缩写'));
      expect(prompt, contains('50-70%'));
    });

    test('modeLabel 返回中文标签', () {
      expect(TextRefinementService.modeLabel('rewrite'), '改写');
      expect(TextRefinementService.modeLabel('shorten'), '缩写');
      expect(TextRefinementService.modeLabel('changeTone'), '换语调');
    });

    test('modeIcon 返回图标', () {
      expect(TextRefinementService.modeIcon('rewrite'), '✏️');
      expect(TextRefinementService.modeIcon('polish'), '✨');
    });

    test('modeFromEnum 转换 EditMode', () {
      expect(TextRefinementService.modeFromEnum(EditMode.rewrite), 'rewrite');
      expect(TextRefinementService.modeFromEnum(EditMode.continue_), 'continue');
      expect(TextRefinementService.modeFromEnum(EditMode.changeTone), 'changeTone');
    });
  });

  group('RetroactiveEditService', () {
    test('edit 调用 AI 并返回结果', () async {
      final mockAi = MockAIService('改写后的文本内容');
      final service = RetroactiveEditService(aiService: mockAi);

      final result = await service.edit(
        selectedText: '原文内容',
        fullContext: '完整上下文',
        mode: EditMode.rewrite,
      );

      expect(result.newText, '改写后的文本内容');
      expect(result.mode, 'rewrite');
    });

    test('undo 返回编辑前内容', () async {
      final mockAi = MockAIService('改写内容');
      final service = RetroactiveEditService(aiService: mockAi);

      // 模拟编辑操作
      service.snapshotBefore('doc-1', '原始内容');
      final result = await service.edit(
        selectedText: '原始内容',
        fullContext: '上下文',
        mode: EditMode.rewrite,
      );
      service.snapshotAfter('doc-1', '原始内容', result.newText);

      // 撤销
      final previous = await service.undo('doc-1');
      expect(previous, '原始内容');
    });

    test('undo 无历史时返回 null', () async {
      final mockAi = MockAIService('内容');
      final service = RetroactiveEditService(aiService: mockAi);

      final result = await service.undo('nonexistent');
      expect(result, isNull);
    });

    test('getHistory 返回历史列表', () async {
      final mockAi = MockAIService('内容');
      final service = RetroactiveEditService(aiService: mockAi);

      service.snapshotBefore('doc-1', '旧内容');
      final result = await service.edit(
        selectedText: '旧内容',
        fullContext: '上下文',
        mode: EditMode.polish,
      );
      service.snapshotAfter('doc-1', '旧内容', result.newText);

      final history = service.getHistory('doc-1');
      expect(history, isNotEmpty);
    });
  });
}
