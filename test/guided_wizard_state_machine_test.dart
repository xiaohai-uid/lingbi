import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/shared/models/canon_entry.dart';

void main() {
  group('GuidedWizardStateMachine', () {
    late GuidedWizardStateMachine machine;

    setUp(() {
      machine = GuidedWizardStateMachine();
    });

    group('步骤流转', () {
      test('初始状态在第一步（title）', () {
        expect(machine.state.currentStep, GuidedWizardStep.title);
        expect(machine.state.isCompleted, false);
      });

      test('完成当前步后前进到下一步', () {
        machine.advance('万界守夜人');
        expect(machine.state.currentStep, GuidedWizardStep.genre);
      });

      test('按顺序完成全部 5 步后标记为已完成', () {
        machine.advance('万界守夜人'); // title
        machine.advance('玄幻'); // genre
        machine.advance('守夜人林渊'); // protagonist
        machine.advance('灵气复苏的现代都市'); // worldview
        machine.advance('主角首次觉醒'); // firstChapterGoal

        expect(machine.state.isCompleted, true);
        expect(machine.state.currentStep, GuidedWizardStep.firstChapterGoal);
      });

      test('已完成后继续 advance 不改变状态', () {
        _completeAll(machine);
        final before = machine.state;
        machine.advance('多余输入');
        expect(machine.state, before);
      });
    });

    group('跳过与默认值', () {
      test('跳过 title 步填充默认值 "未命名作品"', () {
        machine.skip();
        expect(machine.state.currentStep, GuidedWizardStep.genre);
        expect(machine.state.stepData[GuidedWizardStep.title], '未命名作品');
        expect(machine.state.skippedSteps, contains(GuidedWizardStep.title));
      });

      test('跳过 genre 步填充默认值 "通用"', () {
        machine.advance('书名');
        machine.skip();
        expect(machine.state.stepData[GuidedWizardStep.genre], '通用');
        expect(machine.state.skippedSteps, contains(GuidedWizardStep.genre));
      });

      test('跳过 protagonist 步填充默认角色名 "主角"', () {
        machine.advance('书名');
        machine.advance('玄幻');
        machine.skip();
        expect(machine.state.stepData[GuidedWizardStep.protagonist], '主角');
        expect(
            machine.state.skippedSteps, contains(GuidedWizardStep.protagonist));
      });

      test('跳过 worldview 步填充空字符串（不注入 prompt）', () {
        machine.advance('书名');
        machine.advance('玄幻');
        machine.advance('主角名');
        machine.skip();
        expect(machine.state.stepData[GuidedWizardStep.worldview], '');
        expect(machine.state.skippedSteps, contains(GuidedWizardStep.worldview));
      });

      test('跳过 firstChapterGoal 步填充默认目标', () {
        machine.advance('书名');
        machine.advance('玄幻');
        machine.advance('主角名');
        machine.advance('世界观');
        machine.skip();
        expect(
          machine.state.stepData[GuidedWizardStep.firstChapterGoal],
          '开篇引入，建立世界观和主角',
        );
        expect(machine.state.isCompleted, true);
      });

      test('全部跳过仍然完成且默认值完整', () {
        for (var i = 0; i < GuidedWizardStep.values.length; i++) {
          machine.skip();
        }
        expect(machine.state.isCompleted, true);
        expect(machine.state.stepData[GuidedWizardStep.title], '未命名作品');
        expect(machine.state.stepData[GuidedWizardStep.genre], '通用');
        expect(machine.state.stepData[GuidedWizardStep.protagonist], '主角');
        expect(machine.state.stepData[GuidedWizardStep.worldview], '');
        expect(
          machine.state.stepData[GuidedWizardStep.firstChapterGoal],
          '开篇引入，建立世界观和主角',
        );
      });
    });

    group('中断恢复', () {
      test('lastStep 记录当前进度', () {
        machine.advance('书名');
        machine.advance('玄幻');
        expect(machine.state.lastStep, 2);
      });

      test('从持久化状态恢复到中断位置', () {
        machine.advance('书名');
        machine.advance('玄幻');
        final json = machine.state.toJson();

        final restored = GuidedWizardStateMachine.fromState(
          GuidedWizardState.fromJson(json),
        );
        expect(restored.state.currentStep, GuidedWizardStep.protagonist);
        expect(restored.state.lastStep, 2);
        expect(restored.state.stepData[GuidedWizardStep.title], '书名');
        expect(restored.state.stepData[GuidedWizardStep.genre], '玄幻');
      });

      test('恢复后可继续完成剩余步骤', () {
        machine.advance('书名');
        machine.skip(); // genre skipped
        final json = machine.state.toJson();

        final restored = GuidedWizardStateMachine.fromState(
          GuidedWizardState.fromJson(json),
        );
        restored.advance('主角名');
        restored.advance('世界观');
        restored.advance('目标');
        expect(restored.state.isCompleted, true);
      });
    });

    group('buildOutput 状态契约', () {
      test('未完成时 buildOutput 抛出 StateError', () {
        machine.advance('书名');
        expect(() => machine.buildOutput('project-1'), throwsStateError);
      });

      test('完成后 buildOutput 产出非空 ProjectBrief', () {
        _completeAll(machine);
        final output = machine.buildOutput('project-1');

        expect(output.brief.title, '万界守夜人');
        expect(output.brief.genreId, '玄幻');
        expect(output.brief.templateId, isNotEmpty);
      });

      test('全部跳过时 ProjectBrief 字段仍非空', () {
        for (var i = 0; i < GuidedWizardStep.values.length; i++) {
          machine.skip();
        }
        final output = machine.buildOutput('project-1');

        expect(output.brief.title, '未命名作品');
        expect(output.brief.genreId, '通用');
        expect(output.brief.templateId, isNotEmpty);
      });

      test('正典至少包含一条角色和一条设定', () {
        _completeAll(machine);
        final output = machine.buildOutput('project-1');

        final characters = output.initialCanon
            .where((e) => e.type == CanonEntryType.character);
        final lore =
            output.initialCanon.where((e) => e.type == CanonEntryType.lore);

        expect(characters, isNotEmpty);
        expect(lore, isNotEmpty);
      });

      test('跳过 protagonist 时仍有默认角色条目', () {
        machine.advance('书名');
        machine.advance('玄幻');
        machine.skip(); // protagonist skipped
        machine.advance('世界观');
        machine.advance('目标');

        final output = machine.buildOutput('project-1');
        final characters = output.initialCanon
            .where((e) => e.type == CanonEntryType.character);
        expect(characters.length, 1);
        expect(characters.first.name, '主角');
      });

      test('跳过 worldview 时不生成世界规则正典条目', () {
        machine.advance('书名');
        machine.advance('玄幻');
        machine.advance('主角名');
        machine.skip(); // worldview skipped → empty
        machine.advance('目标');

        final output = machine.buildOutput('project-1');
        final lore =
            output.initialCanon.where((e) => e.type == CanonEntryType.lore);
        // 空世界规则不注入，所以 lore 中不含世界规则
        final worldRules = lore.where((e) => e.name.contains('世界规则'));
        expect(worldRules, isEmpty);
      });

      test('firstChapterInstruction 反映用户输入', () {
        _completeAll(machine);
        final output = machine.buildOutput('project-1');
        expect(output.firstChapterInstruction, '主角首次觉醒');
      });

      test('firstChapterInstruction 使用默认值当跳过时', () {
        for (var i = 0; i < GuidedWizardStep.values.length; i++) {
          machine.skip();
        }
        final output = machine.buildOutput('project-1');
        expect(output.firstChapterInstruction, '开篇引入，建立世界观和主角');
      });

      test('正典条目的 projectId 与传入一致', () {
        _completeAll(machine);
        final output = machine.buildOutput('my-project-id');
        for (final entry in output.initialCanon) {
          expect(entry.projectId, 'my-project-id');
        }
      });
    });

    group('序列化往返', () {
      test('toJson/fromJson 保持状态一致', () {
        machine.advance('书名');
        machine.skip();
        machine.advance('主角名');

        final json = machine.state.toJson();
        final restored = GuidedWizardState.fromJson(json);

        expect(restored.currentStep, machine.state.currentStep);
        expect(restored.lastStep, machine.state.lastStep);
        expect(restored.stepData, machine.state.stepData);
        expect(restored.skippedSteps, machine.state.skippedSteps);
        expect(restored.isCompleted, machine.state.isCompleted);
      });
    });
  });
}

void _completeAll(GuidedWizardStateMachine machine) {
  machine.advance('万界守夜人');
  machine.advance('玄幻');
  machine.advance('守夜人林渊');
  machine.advance('灵气复苏的现代都市');
  machine.advance('主角首次觉醒');
}
