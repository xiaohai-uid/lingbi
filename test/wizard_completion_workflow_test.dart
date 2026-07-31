import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/features/onboarding/data/wizard_completion_workflow.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/models/project.dart';

/// Fake: 记录 createPortableProject 调用
class _FakeProjectCreator implements ProjectCreator {
  Project? lastProject;
  ProjectBrief? lastBrief;

  @override
  Future<Project> createProject({
    required String directoryPath,
    required ProjectBrief brief,
  }) async {
    lastBrief = brief;
    lastProject = Project(
      name: brief.title,
      directoryPath: directoryPath,
      genre: brief.genreId,
    );
    return lastProject!;
  }
}

/// Fake: 记录所有 create 调用
class _FakeCanonWriter implements CanonWriter {
  final List<CanonEntry> created = [];

  @override
  Future<void> createEntry(CanonEntry entry) async {
    created.add(entry);
  }
}

void main() {
  late _FakeProjectCreator projectCreator;
  late _FakeCanonWriter canonWriter;
  late WizardCompletionWorkflow workflow;

  setUp(() {
    projectCreator = _FakeProjectCreator();
    canonWriter = _FakeCanonWriter();
    workflow = WizardCompletionWorkflow(
      projectCreator: projectCreator,
      canonWriter: canonWriter,
      projectRootResolver: () => '/tmp/lingbi_projects',
    );
  });

  group('WizardCompletionWorkflow', () {
    test('向导完成后自动创建项目', () async {
      final machine = GuidedWizardStateMachine();
      machine.advance('万界守夜人');
      machine.advance('玄幻');
      machine.advance('林渊');
      machine.advance('灵气复苏');
      machine.advance('主角觉醒');

      final result = await workflow.execute(machine);

      expect(result.project.name, '万界守夜人');
      expect(projectCreator.lastBrief?.title, '万界守夜人');
      expect(projectCreator.lastBrief?.genreId, '玄幻');
    });

    test('正典自动写入：至少 1 条角色 + 1 条设定', () async {
      final machine = GuidedWizardStateMachine();
      machine.advance('书名');
      machine.advance('都市');
      machine.advance('张三');
      machine.advance('现代都市');
      machine.advance('开篇');

      await workflow.execute(machine);

      final characters = canonWriter.created
          .where((e) => e.type == CanonEntryType.character);
      final lore =
          canonWriter.created.where((e) => e.type == CanonEntryType.lore);

      expect(characters, isNotEmpty);
      expect(characters.first.name, '张三');
      expect(lore, isNotEmpty);
    });

    test('全部跳过时仍有默认正典条目', () async {
      final machine = GuidedWizardStateMachine();
      for (var i = 0; i < GuidedWizardStep.values.length; i++) {
        machine.skip();
      }

      final result = await workflow.execute(machine);

      expect(result.project.name, '未命名作品');
      final characters = canonWriter.created
          .where((e) => e.type == CanonEntryType.character);
      expect(characters.length, 1);
      expect(characters.first.name, '主角');
    });

    test('正典条目的 projectId 与创建的项目一致', () async {
      final machine = GuidedWizardStateMachine();
      machine.advance('测试');
      machine.advance('悬疑');
      machine.advance('李四');
      machine.advance('密室');
      machine.advance('开场');

      final result = await workflow.execute(machine);

      for (final entry in canonWriter.created) {
        expect(entry.projectId, result.project.id);
      }
    });

    test('项目目录路径使用 resolver 拼接项目名', () async {
      final machine = GuidedWizardStateMachine();
      machine.advance('长夜');
      machine.advance('玄幻');
      machine.advance('主角');
      machine.advance('世界');
      machine.advance('目标');

      await workflow.execute(machine);

      // 验证 directoryPath 包含项目根 + 项目名
      expect(
        projectCreator.lastProject?.directoryPath,
        contains('/tmp/lingbi_projects'),
      );
      expect(
        projectCreator.lastProject?.directoryPath,
        contains('长夜'),
      );
    });

    test('向导未完成时 execute 抛出 StateError', () async {
      final machine = GuidedWizardStateMachine();
      machine.advance('只完成了第一步');

      expect(() => workflow.execute(machine), throwsStateError);
    });

    test('execute 返回 WizardCompletionResult 包含项目和正典', () async {
      final machine = GuidedWizardStateMachine();
      machine.advance('书名');
      machine.advance('题材');
      machine.advance('主角');
      machine.advance('世界观');
      machine.advance('目标');

      final result = await workflow.execute(machine);

      expect(result.project, isNotNull);
      expect(result.canonEntries, isNotEmpty);
      expect(result.canonEntries.length, canonWriter.created.length);
    });
  });
}
