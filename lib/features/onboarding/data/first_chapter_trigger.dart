import 'dart:io';

import 'package:lingbi/features/onboarding/data/wizard_completion_workflow.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';

/// 第一章触发目标抽象（供 DI 注入 FirstChapterWorkflowController）
abstract class FirstChapterTriggerTarget {
  Stream<FirstChapterEvent> start(FirstChapterRequest request);
  Future<void> cancel();
}

/// 向导完成 → 第一章候选生成的触发器
///
/// 职责：从 WizardCompletionResult 构建 FirstChapterRequest，
/// 委托给 FirstChapterWorkflow 执行生成，透传事件流。
class FirstChapterTrigger {
  FirstChapterTrigger({required FirstChapterTriggerTarget target})
      : _target = target;

  final FirstChapterTriggerTarget _target;

  /// 触发第一章生成，返回事件流
  Stream<FirstChapterEvent> fire(WizardCompletionResult result) {
    final project = result.project;
    const chapterId = 'chapter-1';
    final targetFilePath =
        '${project.directoryPath}${Platform.pathSeparator}$chapterId.md';

    final request = FirstChapterRequest(
      projectId: project.id,
      chapterId: chapterId,
      targetFilePath: targetFilePath,
      instruction: result.firstChapterInstruction,
    );

    return _target.start(request);
  }

  /// 取消正在进行的生成
  Future<void> cancel() => _target.cancel();
}
