/// 测试: GenerationController — 状态机 + LLM 流式调用桥接
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/generation/state_machine.dart';
import 'package:lingbi/services/generation/controller.dart';

void main() {
  group('GenerationController', () {
    test('stateStream 随输入变更而更新', () async {
      final ctrl = GenerationController();
      final states = <GenerationState>[];

      ctrl.stateStream.listen(states.add);

      ctrl.setInput(GenerationInput(idea: '一个修仙少年从废材崛起的故事'));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(states.length, 1, reason: 'setInput 后应发出 1 个状态');
      expect(states.last, isA<ReadyState>(), reason: '状态应为 ReadyState');
    });

    test('startGeneration 后状态变为 generating_synopsis', () async {
      final ctrl = GenerationController();
      final states = <GenerationState>[];

      ctrl.stateStream.listen(states.add);
      ctrl.setInput(GenerationInput(idea: '一个程序员穿越到异世界的故事'));
      ctrl.startGeneration();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(states.any((s) => s is GeneratingSynopsisState), isTrue,
          reason: '应经过 GeneratingSynopsisState');
    });

    test('streamChunk 累加到 streamedContent', () async {
      final ctrl = GenerationController();
      final states = <GenerationState>[];

      ctrl.stateStream.listen(states.add);
      ctrl.setInput(GenerationInput(idea: '一个测试流式累加的长篇故事创作场景'));
      ctrl.startGeneration();

      ctrl.streamChunk('在一');
      ctrl.streamChunk('个遥远');
      ctrl.streamChunk('的代码大陆');
      await Future.delayed(const Duration(milliseconds: 10));

      final last = states.last;
      if (last is GeneratingSynopsisState) {
        expect(last.meta.streamedContent, '在一个遥远的代码大陆');
        expect(last.streamedWordCount, 10);
      } else {
        fail('状态应为 GeneratingSynopsisState，实际为 $last');
      }
    });

    test('模拟完整生成流程 — 从输入到流式输出', () async {
      final ctrl = GenerationController();
      final states = <GenerationState>[];

      ctrl.stateStream.listen((s) => states.add(s));

      ctrl.setInput(GenerationInput(idea: '一个程序员穿越到异世界的完整故事创作流程'));
      expect(ctrl.currentState, isA<ReadyState>());
      ctrl.startGeneration();

      for (final c in ['在', '一个', '名为', '代码', '大陆', '的', '世界', '上…']) {
        ctrl.streamChunk(c);
      }
      await Future.delayed(const Duration(milliseconds: 10));

      expect(ctrl.currentState, isA<GeneratingSynopsisState>());
      if (ctrl.currentState is GeneratingSynopsisState) {
        expect(
            (ctrl.currentState as GeneratingSynopsisState).meta.streamedContent,
            '在一个名为代码大陆的世界上…');
      }
    });

    test('cancel 后状态变为 cancelled', () async {
      final ctrl = GenerationController();
      ctrl.setInput(GenerationInput(idea: '一个测试取消功能的故事场景'));
      ctrl.startGeneration();
      ctrl.cancel();
      expect(ctrl.currentState, isA<CancelledState>());
    });

    test('stateStream 在 dispose 后关闭', () async {
      final ctrl = GenerationController();
      var closed = false;
      ctrl.stateStream.listen(null, onDone: () => closed = true);
      ctrl.dispose();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(closed, isTrue);
    });
  });

  test('交互式生成 — 段落完成显示方向选择', () async {
      final ctrl = GenerationController();
      ctrl.setInput(GenerationInput(idea: '一个测试交互式生成的长篇故事创作流程'));
      ctrl.startGeneration();
      // 快速过掉梗概和大纲阶段，进入正文生成
      ctrl.phaseComplete(SynopsisResult(synopsis: 'X' * 100, characters: [
        CharacterBrief(name: '测试', role: 'protagonist', personality: '', arc: '')
      ]));
      ctrl.confirm();
      ctrl.phaseComplete(OutlineResult(volumes: [
        VolumeOutline(number: 1, title: '第一卷', chapters: [
          ChapterOutline(number: 1, title: '第一章', summary: '测试', scenes: [
            SceneOutline(number: 1, title: '场景1', summary: '', characters: [], location: ''),
          ]),
        ]),
      ]));
      ctrl.confirm();
      // 现在在 GeneratingContentState
      ctrl.streamChunk('这是一段生成的正文内容');
      ctrl.completeSegment('这是一段生成的正文内容');

      expect(ctrl.currentState, isA<AwaitingChoiceState>());
      if (ctrl.currentState is AwaitingChoiceState) {
        final state = ctrl.currentState as AwaitingChoiceState;
        expect(state.directions.length, 3);
        expect(state.directions[0], '继续推进剧情');
      }
    });

    test('交互式生成 — 选择方向后继续生成', () async {
      final ctrl = GenerationController();
      ctrl.setInput(GenerationInput(idea: '一个测试方向选择后继续生成的小说创意'));
      ctrl.startGeneration();
      ctrl.phaseComplete(SynopsisResult(synopsis: 'X' * 100, characters: [
        CharacterBrief(name: '测试', role: 'protagonist', personality: '', arc: '')
      ]));
      ctrl.confirm();
      ctrl.phaseComplete(OutlineResult(volumes: [
        VolumeOutline(number: 1, title: '第一卷', chapters: [
          ChapterOutline(number: 1, title: '第一章', summary: '测试', scenes: [
            SceneOutline(number: 1, title: '场景1', summary: '', characters: [], location: ''),
          ]),
        ]),
      ]));
      ctrl.confirm();
      ctrl.streamChunk('正文内容');
      ctrl.completeSegment('正文内容');
      ctrl.selectDirection(0);

      expect(ctrl.currentState, isA<GeneratingContentState>());
    });
}