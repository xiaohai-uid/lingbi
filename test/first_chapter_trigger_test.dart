import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/onboarding/data/first_chapter_trigger.dart';
import 'package:lingbi/features/onboarding/data/wizard_completion_workflow.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';

/// Fake: 记录 start 调用并返回可控事件流
class _FakeFirstChapterWorkflow implements FirstChapterTriggerTarget {
  FirstChapterRequest? lastRequest;
  bool cancelCalled = false;
  bool shouldFail = false;

  @override
  Stream<FirstChapterEvent> start(FirstChapterRequest request) async* {
    lastRequest = request;
    if (shouldFail) {
      yield const FirstChapterEvent(
        stage: FirstChapterStage.failed,
        message: '生成失败：模型不可用',
      );
      return;
    }
    yield const FirstChapterEvent(
      stage: FirstChapterStage.readingAssets,
      message: '正在读取项目资产',
    );
    yield const FirstChapterEvent(
      stage: FirstChapterStage.generating,
      message: '正在生成候选稿',
      contentChunk: '第一章',
    );
    yield const FirstChapterEvent(
      stage: FirstChapterStage.candidateReady,
      message: '候选正文已就绪',
      candidateId: 'candidate-1',
    );
  }

  @override
  Future<void> cancel() async => cancelCalled = true;
}

void main() {
  late _FakeFirstChapterWorkflow fakeWorkflow;
  late FirstChapterTrigger trigger;

  setUp(() {
    fakeWorkflow = _FakeFirstChapterWorkflow();
    trigger = FirstChapterTrigger(target: fakeWorkflow);
  });

  group('FirstChapterTrigger', () {
    test('从 WizardCompletionResult 构建正确的 FirstChapterRequest', () async {
      final result = WizardCompletionResult(
        project: Project(name: '万界守夜人', directoryPath: '/tmp/万界守夜人'),
        canonEntries: [],
        firstChapterInstruction: '主角首次觉醒',
      );

      await trigger.fire(result).drain<void>();

      final req = fakeWorkflow.lastRequest!;
      expect(req.projectId, result.project.id);
      expect(req.instruction, '主角首次觉醒');
      expect(req.targetFilePath, contains('万界守夜人'));
      expect(req.chapterId, isNotEmpty);
    });

    test('事件流透传给调用方', () async {
      final result = WizardCompletionResult(
        project: Project(name: '测试', directoryPath: '/tmp/测试'),
        canonEntries: [],
        firstChapterInstruction: '开篇',
      );

      final events = await trigger.fire(result).toList();

      expect(events.length, 3);
      expect(events.first.stage, FirstChapterStage.readingAssets);
      expect(events[1].stage, FirstChapterStage.generating);
      expect(events.last.stage, FirstChapterStage.candidateReady);
    });

    test('生成失败时事件流包含 failed 阶段', () async {
      fakeWorkflow.shouldFail = true;
      final result = WizardCompletionResult(
        project: Project(name: '失败测试', directoryPath: '/tmp/失败'),
        canonEntries: [],
        firstChapterInstruction: '目标',
      );

      final events = await trigger.fire(result).toList();

      expect(events.single.stage, FirstChapterStage.failed);
      expect(events.single.message, contains('生成失败'));
    });

    test('cancel 委托给底层 workflow', () async {
      final result = WizardCompletionResult(
        project: Project(name: '取消测试', directoryPath: '/tmp/取消'),
        canonEntries: [],
        firstChapterInstruction: '目标',
      );

      // 启动但不消费完
      final stream = trigger.fire(result);
      final sub = stream.listen((_) {});
      await trigger.cancel();
      await sub.cancel();

      expect(fakeWorkflow.cancelCalled, isTrue);
    });

    test('targetFilePath 包含项目目录和章节文件名', () async {
      final result = WizardCompletionResult(
        project: Project(
          name: '长夜',
          directoryPath: '/projects/长夜',
        ),
        canonEntries: [],
        firstChapterInstruction: '开篇',
      );

      await trigger.fire(result).drain<void>();

      expect(fakeWorkflow.lastRequest!.targetFilePath, contains('/projects/长夜'));
      expect(fakeWorkflow.lastRequest!.targetFilePath, endsWith('.md'));
    });
  });
}
