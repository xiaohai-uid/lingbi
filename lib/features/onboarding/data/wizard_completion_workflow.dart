import 'dart:io';

import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/models/project.dart';

/// 项目创建抽象（供 DI 注入 ProjectService 适配器）
abstract class ProjectCreator {
  Future<Project> createProject({
    required String directoryPath,
    required ProjectBrief brief,
  });
}

/// 正典写入抽象（供 DI 注入 CanonService 适配器）
abstract class CanonWriter {
  Future<void> createEntry(CanonEntry entry);
}

/// 向导完成后的产出
class WizardCompletionResult {
  const WizardCompletionResult({
    required this.project,
    required this.canonEntries,
    required this.firstChapterInstruction,
  });

  final Project project;
  final List<CanonEntry> canonEntries;
  final String firstChapterInstruction;
}

/// 向导完成编排器：创建项目 + 写入初始正典
///
/// 由 GuidedWizardPage 在向导完成时调用。
/// 依赖通过接口注入，测试使用 Fake 实现。
class WizardCompletionWorkflow {
  WizardCompletionWorkflow({
    required ProjectCreator projectCreator,
    required CanonWriter canonWriter,
    required String Function() projectRootResolver,
  })  : _projectCreator = projectCreator,
        _canonWriter = canonWriter,
        _projectRootResolver = projectRootResolver;

  final ProjectCreator _projectCreator;
  final CanonWriter _canonWriter;
  final String Function() _projectRootResolver;

  /// 执行向导完成编排
  ///
  /// 前置条件：向导状态机必须已完成（isCompleted == true）。
  /// 产出：创建的项目 + 写入的正典条目。
  Future<WizardCompletionResult> execute(
    GuidedWizardStateMachine machine,
  ) async {
    // buildOutput 内部会检查 isCompleted，未完成时抛 StateError
    // 先用临时 projectId 构建 output（后续替换为真实 id）
    final output = machine.buildOutput('pending');

    // 1. 创建项目
    final projectRoot = _projectRootResolver();
    final directoryPath =
        '$projectRoot${Platform.pathSeparator}${output.brief.title}';
    final project = await _projectCreator.createProject(
      directoryPath: directoryPath,
      brief: output.brief,
    );

    // 2. 用真实 projectId 重建正典条目并写入
    final canonEntries = <CanonEntry>[];
    for (final template in output.initialCanon) {
      final entry = CanonEntry(
        projectId: project.id,
        type: template.type,
        name: template.name,
        description: template.description,
        attributes: template.attributes,
      );
      await _canonWriter.createEntry(entry);
      canonEntries.add(entry);
    }

    return WizardCompletionResult(
      project: project,
      canonEntries: canonEntries,
      firstChapterInstruction: output.firstChapterInstruction,
    );
  }
}
