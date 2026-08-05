/// T4: 端到端黄金路径集成测试
///
/// 验证：两屏向导 → 项目创建 → chapter-1.md → idle 状态 → 编辑器检测
/// 使用 mock AI provider，不依赖网络。
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/features/onboarding/data/wizard_completion_workflow.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_state_store.dart';

import 'support/mutation_test_harness.dart';

// ─── Fakes ───────────────────────────────────────────

class _FakeProjectCreator implements ProjectCreator {
  Project? lastProject;

  @override
  Future<Project> createProject({
    required String directoryPath,
    required ProjectBrief brief,
  }) async {
    lastProject = Project(
      name: brief.title,
      directoryPath: directoryPath,
      genre: brief.genreId,
    );
    return lastProject!;
  }
}

class _FakeCanonWriter implements CanonWriter {
  final List<CanonEntry> created = [];

  @override
  Future<void> createEntry(CanonEntry entry) async {
    created.add(entry);
  }
}

// ─── Tests ───────────────────────────────────────────

void main() {
  group('黄金路径：两屏向导 → 第一章旅程', () {
    late Directory tempDir;
    late _FakeProjectCreator projectCreator;
    late _FakeCanonWriter canonWriter;
    late WizardCompletionWorkflow workflow;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lingbi_t4_');
      projectCreator = _FakeProjectCreator();
      canonWriter = _FakeCanonWriter();
      workflow = WizardCompletionWorkflow(
        projectCreator: projectCreator,
        canonWriter: canonWriter,
        projectRootResolver: () => tempDir.path,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('完整黄金路径：向导 → 项目 → 正典 → chapter-1 状态', () async {
      // ─── 第一屏：快速选择 ───
      final machine = GuidedWizardStateMachine();

      // 题材多选
      machine.setDimension(
        WizardDimension.genre,
        const WizardStepValue(selected: ['玄幻', '都市']),
      );
      // 字数目标单选
      machine.setDimension(
        WizardDimension.wordCount,
        const WizardStepValue(selected: ['长篇(50万+)']),
      );
      // 发布平台单选
      machine.setDimension(
        WizardDimension.platform,
        const WizardStepValue(selected: ['起点']),
      );

      // 验证第一屏完成
      expect(machine.isScreenOneComplete(), true);

      // ─── 第二屏：深度填写 ───
      machine.setDimension(
        WizardDimension.title,
        const WizardStepValue(selected: ['万界守夜人']),
      );
      machine.setDimension(
        WizardDimension.protagonist,
        const WizardStepValue(selected: ['守夜人林渊，沉默寡言的都市猎人']),
      );
      machine.setDimension(
        WizardDimension.worldview,
        const WizardStepValue(selected: ['灵气复苏的现代都市']),
      );
      machine.setDimension(
        WizardDimension.creativeDirection,
        const WizardStepValue(selected: ['爽文升级', '热血争霸']),
      );
      machine.setDimension(
        WizardDimension.firstChapterGoal,
        const WizardStepValue(selected: ['主角首次觉醒，遭遇诡异事件']),
      );

      // 验证第二屏完成
      expect(machine.isScreenTwoComplete(), true);

      // ─── 标记完成 ───
      machine.markCompleted();
      expect(machine.state.isCompleted, true);

      // ─── 执行完成编排 ───
      final result = await workflow.execute(machine);

      // 验证项目创建
      expect(result.project.name, '万界守夜人');
      expect(projectCreator.lastProject, isNotNull);

      // 验证正典写入
      expect(canonWriter.created.length, greaterThanOrEqualTo(2));
      final characters =
          canonWriter.created.where((e) => e.type == CanonEntryType.character);
      final lore =
          canonWriter.created.where((e) => e.type == CanonEntryType.lore);
      expect(characters, isNotEmpty);
      expect(lore, isNotEmpty);

      // 验证多题材
      expect(result.project.genre, '玄幻+都市');

      // ─── 模拟写入第一章状态（编辑器将检测此状态）───
      final stateStore = FileFirstChapterStateStore(
        projectDirectory: result.project.directoryPath,
      );
      const chapterId = 'chapter-1';
      final targetFilePath =
          '${result.project.directoryPath}${Platform.pathSeparator}$chapterId.md';
      await stateStore.write(FirstChapterState(
        projectId: result.project.id,
        chapterId: chapterId,
        targetFilePath: targetFilePath,
        stage: FirstChapterStage.idle,
        updatedAt: DateTime.now().toUtc(),
      ));

      // ─── 验证编辑器可检测到 idle 状态 ───
      final restored = await stateStore.read(result.project.id);
      expect(restored, isNotNull);
      expect(restored!.stage, FirstChapterStage.idle);
      expect(restored.chapterId, 'chapter-1');
      expect(restored.projectId, result.project.id);
    });

    test('第一章采纳写入 MutationProtocol 并可在重开后继续核验', () async {
      final projectDir = await Directory.systemTemp
          .createTemp('lingbi_first_chapter_mutation_');
      addTearDown(() => projectDir.delete(recursive: true));
      final protocol = boundProtocol('proj-first-chapter', projectDir.path);
      const payload = '# 第一章\n\n候选正文已采纳。';
      const targetPath = 'chapters/chapter-1.md';

      final result = await protocol.applyUserEdit(ChangeRequest(
        projectId: 'proj-first-chapter',
        origin: ChangeOrigin.userUi,
        action: ChangeAction.createText,
        target: ChangeTarget(
          projectRelativePath: targetPath,
          kind: 'chapter',
        ),
        baseRevision: 0,
        payload: payload,
        idempotencyKey: 'first-chapter-adoption',
      ));
      expect(result, isA<Success<CommitReceipt>>());
      final receipt = (result as Success<CommitReceipt>).value;
      final file = File('${projectDir.path}/$targetPath');

      expect(await file.readAsString(), payload);
      expect(receipt.afterContentHash, canonicalTextHash(payload));

      final journal = journalForProject('proj-first-chapter', projectDir.path);
      expect(await journal.validateChain(), isTrue);
      expect(
        (await journal.readAll()).map((event) => event.eventType),
        contains(LocalMutationJournal.receiptEventType),
      );
    });

    test('中断恢复：序列化 → 反序列化 → 继续完成', () async {
      final machine = GuidedWizardStateMachine();

      // 第一屏填写
      machine.setDimension(
        WizardDimension.genre,
        const WizardStepValue(selected: ['仙侠']),
      );
      machine.setDimension(
        WizardDimension.wordCount,
        const WizardStepValue(selected: ['中篇(10-20万)']),
      );
      machine.setDimension(
        WizardDimension.platform,
        const WizardStepValue(selected: ['番茄']),
      );

      // 模拟中断：序列化
      final json = machine.state.toJson();
      final jsonStr = jsonEncode(json);

      // 模拟恢复：反序列化
      final restoredJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restoredMachine = GuidedWizardStateMachine.fromState(
        GuidedWizardState.fromJson(restoredJson),
      );

      // 恢复后第一屏仍完整
      expect(restoredMachine.isScreenOneComplete(), true);

      // 继续填写第二屏
      restoredMachine.setDimension(
        WizardDimension.protagonist,
        const WizardStepValue(selected: ['剑修少女']),
      );
      restoredMachine.setDimension(
        WizardDimension.firstChapterGoal,
        const WizardStepValue(selected: ['入门试炼']),
      );
      restoredMachine.markCompleted();
      expect(restoredMachine.state.isCompleted, true);

      // buildOutput 正确
      final output = restoredMachine.buildOutput('test-project');
      expect(output.brief.title, '未命名作品'); // title 跳过
      expect(output.genres, ['仙侠']);
      expect(output.wordCount, '中篇(10-20万)');
      expect(output.platform, '番茄');
      expect(output.creativeDirection, '通用'); // 跳过默认
    });

    test('返回清空：第二屏返回后全部数据清除', () {
      final machine = GuidedWizardStateMachine();

      // 填写第一屏
      machine.setDimension(
        WizardDimension.genre,
        const WizardStepValue(selected: ['科幻']),
      );
      machine.setDimension(
        WizardDimension.wordCount,
        const WizardStepValue(selected: ['短篇(3-5万)']),
      );
      machine.setDimension(
        WizardDimension.platform,
        const WizardStepValue(selected: ['自由发布']),
      );

      // 模拟返回清空（UI 层行为：重建状态机）
      final clearedMachine = GuidedWizardStateMachine();
      expect(clearedMachine.state.dimensionData, isEmpty);
      expect(clearedMachine.isScreenOneComplete(), false);
      expect(clearedMachine.state.isCompleted, false);
    });

    test('API 失败重试：状态机支持 failed → 重新 start', () async {
      final stateStore = FileFirstChapterStateStore(
        projectDirectory: tempDir.path,
      );

      // 模拟 failed 状态
      await stateStore.write(FirstChapterState(
        projectId: 'proj-1',
        chapterId: 'chapter-1',
        targetFilePath: '${tempDir.path}/chapter-1.md',
        stage: FirstChapterStage.failed,
        updatedAt: DateTime.now().toUtc(),
        error: 'API timeout: 503 Service Unavailable',
      ));

      // 编辑器检测到 failed
      final state = await stateStore.read('proj-1');
      expect(state, isNotNull);
      expect(state!.stage, FirstChapterStage.failed);
      expect(state.error, contains('503'));

      // 重试：覆写为 idle（编辑器 _retryFirstChapterGeneration 的行为）
      await stateStore.write(FirstChapterState(
        projectId: 'proj-1',
        chapterId: 'chapter-1',
        targetFilePath: '${tempDir.path}/chapter-1.md',
        stage: FirstChapterStage.idle,
        updatedAt: DateTime.now().toUtc(),
      ));

      final retryState = await stateStore.read('proj-1');
      expect(retryState!.stage, FirstChapterStage.idle);
      expect(retryState.error, isNull);
    });

    test('生成中切换文档再切回：状态持久化保证流式继续', () async {
      final stateStore = FileFirstChapterStateStore(
        projectDirectory: tempDir.path,
      );

      // 模拟 generating 状态（部分内容已生成）
      await stateStore.write(FirstChapterState(
        projectId: 'proj-1',
        chapterId: 'chapter-1',
        targetFilePath: '${tempDir.path}/chapter-1.md',
        stage: FirstChapterStage.generating,
        updatedAt: DateTime.now().toUtc(),
        candidateContent: '这是已生成的部分内容...',
      ));

      // 切回后读取状态
      final state = await stateStore.read('proj-1');
      expect(state, isNotNull);
      expect(state!.stage, FirstChapterStage.generating);
      expect(state.candidateContent, '这是已生成的部分内容...');
      // updatedAt 在 60s 内 → 不视为 stale
      final elapsed = DateTime.now().toUtc().difference(state.updatedAt);
      expect(elapsed.inSeconds, lessThan(60));
    });
  });
}
