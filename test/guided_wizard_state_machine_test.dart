import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/shared/models/canon_entry.dart';

void main() {
  group('GuidedWizardStateMachine', () {
    late GuidedWizardStateMachine machine;

    setUp(() {
      machine = GuidedWizardStateMachine();
    });

    group('维度设置', () {
      test('初始状态所有维度为空', () {
        expect(machine.state.dimensionData, isEmpty);
        expect(machine.state.isCompleted, false);
      });

      test('setDimension 设置单个维度值', () {
        machine.setDimension(
          WizardDimension.genre,
          const WizardStepValue(selected: ['玄幻']),
        );
        expect(
          machine.state.dimensionData[WizardDimension.genre]?.selected,
          ['玄幻'],
        );
      });

      test('多选维度支持多个值', () {
        machine.setDimension(
          WizardDimension.genre,
          const WizardStepValue(selected: ['玄幻', '都市', '仙侠']),
        );
        expect(
          machine.state.dimensionData[WizardDimension.genre]?.selected,
          ['玄幻', '都市', '仙侠'],
        );
      });

      test('自定义文本与卡片选择共存', () {
        machine.setDimension(
          WizardDimension.genre,
          const WizardStepValue(selected: ['玄幻'], customText: '克苏鲁'),
        );
        final value = machine.state.dimensionData[WizardDimension.genre]!;
        expect(value.selected, ['玄幻']);
        expect(value.customText, '克苏鲁');
        expect(value.combined, '玄幻、克苏鲁');
      });

      test('canAddSelection 在上限内返回 true', () {
        expect(machine.canAddSelection(WizardDimension.genre, 0), true);
        expect(machine.canAddSelection(WizardDimension.genre, 2), true);
      });

      test('canAddSelection 达到上限返回 false', () {
        expect(machine.canAddSelection(WizardDimension.genre, 3), false);
      });

      test('单选维度无上限限制', () {
        expect(machine.canAddSelection(WizardDimension.wordCount, 100), true);
      });
    });

    group('跳过与默认值', () {
      test('跳过 title 填充默认值 "未命名作品"', () {
        machine.skip(WizardDimension.title);
        expect(
          machine.state.dimensionData[WizardDimension.title]?.selected,
          ['未命名作品'],
        );
        expect(
          machine.state.skippedDimensions,
          contains(WizardDimension.title),
        );
      });

      test('跳过 creativeDirection 填充默认值 "通用"', () {
        machine.skip(WizardDimension.creativeDirection);
        expect(
          machine.state.dimensionData[WizardDimension.creativeDirection]
              ?.selected,
          ['通用'],
        );
      });

      test('不可跳过的维度 skip 无效', () {
        machine.skip(WizardDimension.protagonist);
        expect(machine.state.dimensionData[WizardDimension.protagonist], isNull);
        expect(
          machine.state.skippedDimensions,
          isNot(contains(WizardDimension.protagonist)),
        );
      });

      test('设置值后移除跳过标记', () {
        machine.skip(WizardDimension.title);
        expect(
          machine.state.skippedDimensions,
          contains(WizardDimension.title),
        );
        machine.setDimension(
          WizardDimension.title,
          const WizardStepValue(selected: ['我的书名']),
        );
        expect(
          machine.state.skippedDimensions,
          isNot(contains(WizardDimension.title)),
        );
      });
    });

    group('屏校验', () {
      test('第一屏初始不完整', () {
        expect(machine.isScreenOneComplete(), false);
      });

      test('第一屏三维度全填后完整', () {
        machine.setDimension(
            WizardDimension.genre, const WizardStepValue(selected: ['玄幻']));
        machine.setDimension(
            WizardDimension.wordCount,
            const WizardStepValue(selected: ['长篇(50万+)']));
        machine.setDimension(
            WizardDimension.platform, const WizardStepValue(selected: ['起点']));
        expect(machine.isScreenOneComplete(), true);
      });

      test('第二屏必填维度未填时不完整', () {
        expect(machine.isScreenTwoComplete(), false);
      });

      test('第二屏必填维度填完后完整（可跳过维度可空）', () {
        machine.setDimension(
            WizardDimension.protagonist,
            const WizardStepValue(selected: ['林渊']));
        machine.setDimension(
            WizardDimension.worldview,
            const WizardStepValue(selected: ['灵气复苏']));
        machine.setDimension(
            WizardDimension.firstChapterGoal,
            const WizardStepValue(selected: ['主角觉醒']));
        // title 和 creativeDirection 可跳过，不填也算完整
        expect(machine.isScreenTwoComplete(), true);
      });
    });

    group('markCompleted', () {
      test('校验未通过时抛出 StateError', () {
        expect(() => machine.markCompleted(), throwsStateError);
      });

      test('校验通过后标记完成并填充默认值', () {
        _fillAllRequired(machine);
        machine.markCompleted();
        expect(machine.state.isCompleted, true);
        // 可跳过维度自动填充默认值
        expect(
          machine.state.dimensionData[WizardDimension.title]?.selected,
          ['未命名作品'],
        );
        expect(
          machine.state.dimensionData[WizardDimension.creativeDirection]
              ?.selected,
          ['通用'],
        );
      });

      test('已填的可跳过维度不被覆盖', () {
        _fillAllRequired(machine);
        machine.setDimension(
            WizardDimension.title,
            const WizardStepValue(selected: ['我的书名']));
        machine.markCompleted();
        expect(
          machine.state.dimensionData[WizardDimension.title]?.selected,
          ['我的书名'],
        );
      });
    });

    group('buildOutput 状态契约', () {
      test('未完成时 buildOutput 抛出 StateError', () {
        expect(() => machine.buildOutput('project-1'), throwsStateError);
      });

      test('完成后 buildOutput 产出非空 ProjectBrief', () {
        _fillAllRequired(machine);
        machine.setDimension(
            WizardDimension.title,
            const WizardStepValue(selected: ['万界守夜人']));
        machine.markCompleted();
        final output = machine.buildOutput('project-1');

        expect(output.brief.title, '万界守夜人');
        expect(output.brief.genreId, '玄幻');
        expect(output.brief.templateId, isNotEmpty);
      });

      test('多题材 genreId 用 + 拼接', () {
        _fillAllRequired(machine);
        machine.setDimension(
            WizardDimension.genre,
            const WizardStepValue(selected: ['玄幻', '都市']));
        machine.markCompleted();
        final output = machine.buildOutput('project-1');

        expect(output.brief.genreId, '玄幻+都市');
        expect(output.genres, ['玄幻', '都市']);
      });

      test('正典至少包含一条角色和一条设定', () {
        _fillAllRequired(machine);
        machine.markCompleted();
        final output = machine.buildOutput('project-1');

        final characters = output.initialCanon
            .where((e) => e.type == CanonEntryType.character);
        final lore =
            output.initialCanon.where((e) => e.type == CanonEntryType.lore);

        expect(characters, isNotEmpty);
        expect(lore, isNotEmpty);
      });

      test('世界观为空时不生成世界规则正典条目', () {
        machine.setDimension(
            WizardDimension.genre, const WizardStepValue(selected: ['玄幻']));
        machine.setDimension(
            WizardDimension.wordCount,
            const WizardStepValue(selected: ['长篇(50万+)']));
        machine.setDimension(
            WizardDimension.platform, const WizardStepValue(selected: ['起点']));
        machine.setDimension(
            WizardDimension.protagonist,
            const WizardStepValue(selected: ['林渊']));
        // worldview 不填
        machine.setDimension(
            WizardDimension.firstChapterGoal,
            const WizardStepValue(selected: ['觉醒']));
        machine.markCompleted();
        final output = machine.buildOutput('project-1');

        final worldRules = output.initialCanon
            .where((e) => e.name.contains('世界规则'));
        expect(worldRules, isEmpty);
      });

      test('新维度字段正确输出', () {
        _fillAllRequired(machine);
        machine.setDimension(
            WizardDimension.creativeDirection,
            const WizardStepValue(selected: ['爽文升级', '热血争霸']));
        machine.markCompleted();
        final output = machine.buildOutput('project-1');

        expect(output.wordCount, '长篇(50万+)');
        expect(output.platform, '起点');
        expect(output.creativeDirection, '爽文升级、热血争霸');
      });

      test('正典条目的 projectId 与传入一致', () {
        _fillAllRequired(machine);
        machine.markCompleted();
        final output = machine.buildOutput('my-project-id');
        for (final entry in output.initialCanon) {
          expect(entry.projectId, 'my-project-id');
        }
      });
    });

    group('序列化往返', () {
      test('toJson/fromJson 保持状态一致', () {
        machine.setDimension(
            WizardDimension.genre,
            const WizardStepValue(selected: ['玄幻', '都市']));
        machine.setDimension(
            WizardDimension.title,
            const WizardStepValue(selected: [], customText: '自定义书名'));
        machine.skip(WizardDimension.creativeDirection);

        final json = machine.state.toJson();
        final restored = GuidedWizardState.fromJson(json);

        expect(restored.dimensionData, machine.state.dimensionData);
        expect(restored.skippedDimensions, machine.state.skippedDimensions);
        expect(restored.isCompleted, machine.state.isCompleted);
      });

      test('恢复后可继续设置维度并完成', () {
        machine.setDimension(
            WizardDimension.genre, const WizardStepValue(selected: ['玄幻']));
        machine.setDimension(
            WizardDimension.wordCount,
            const WizardStepValue(selected: ['长篇(50万+)']));
        final json = machine.state.toJson();

        final restored = GuidedWizardStateMachine.fromState(
          GuidedWizardState.fromJson(json),
        );
        restored.setDimension(
            WizardDimension.platform,
            const WizardStepValue(selected: ['起点']));
        restored.setDimension(
            WizardDimension.protagonist,
            const WizardStepValue(selected: ['林渊']));
        restored.setDimension(
            WizardDimension.worldview,
            const WizardStepValue(selected: ['灵气复苏']));
        restored.setDimension(
            WizardDimension.firstChapterGoal,
            const WizardStepValue(selected: ['觉醒']));
        restored.markCompleted();
        expect(restored.state.isCompleted, true);
      });
    });
  });
}

/// 填充所有必填维度（不含可跳过的 title 和 creativeDirection）
void _fillAllRequired(GuidedWizardStateMachine machine) {
  machine.setDimension(
      WizardDimension.genre, const WizardStepValue(selected: ['玄幻']));
  machine.setDimension(
      WizardDimension.wordCount,
      const WizardStepValue(selected: ['长篇(50万+)']));
  machine.setDimension(
      WizardDimension.platform, const WizardStepValue(selected: ['起点']));
  machine.setDimension(
      WizardDimension.protagonist, const WizardStepValue(selected: ['林渊']));
  machine.setDimension(
      WizardDimension.worldview,
      const WizardStepValue(selected: ['灵气复苏的现代都市']));
  machine.setDimension(
      WizardDimension.firstChapterGoal,
      const WizardStepValue(selected: ['主角首次觉醒']));
}
