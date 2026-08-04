/// 写作流水线模块单元测试
library;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/data/pipeline/pipeline.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';

void main() {
  group('GenerationContext', () {
    test('空上下文生成空 prompt', () {
      const ctx = GenerationContext();
      expect(ctx.toPromptSections(), isEmpty);
      expect(ctx.toPromptContext(), isEmpty);
    });

    test('含作者意图的上下文生成正确 prompt', () {
      const ctx = GenerationContext(
        authorIntent: '写一部关于成长的玄幻小说',
        creativeFocus: '当前篇章: 主角觉醒',
        chapterGoals: ['揭示主角身世', '引入导师角色'],
      );
      final sections = ctx.toPromptSections();
      expect(sections['作者意图'], '写一部关于成长的玄幻小说');
      expect(sections['创作罗盘（当前最高优先级）'], '当前篇章: 主角觉醒');
      expect(sections['本章目标'], contains('揭示主角身世'));
    });

    test('toJson 序列化完整', () {
      const ctx = GenerationContext(
        novelId: 'novel_001',
        chapterId: 'ch_001',
        targetWords: 5000,
        tokenBudget: 6000,
      );
      final json = ctx.toJson();
      expect(json['novel_id'], 'novel_001');
      expect(json['chapter_id'], 'ch_001');
      expect(json['target_words'], 5000);
      expect(json['token_budget'], 6000);
    });

    test('estimateTokens 返回合理估算', () {
      final ctx = GenerationContext(
        authorIntent: '这是一段测试文本' * 100,
        recentText: '上文内容' * 200,
      );
      final tokens = ctx.estimateTokens();
      expect(tokens, greaterThan(0));
    });

    test('CharacterCard toContextText 截断', () {
      final card = CharacterCard(
        name: '张三',
        role: '主角',
        currentState: '正在修炼',
        personality: '坚韧不拔' * 50,
      );
      final text = card.toContextText(maxChars: 50);
      expect(text.length, lessThanOrEqualTo(51)); // 50 + '…'
    });

    test('ForeshadowingState 序列化/反序列化', () {
      const state = ForeshadowingState(
        pending: [
          ForeshadowingItem(id: 'f1', description: '神秘剑的来历'),
        ],
        planted: [
          ForeshadowingItem(id: 'f2', description: '导师的暗伤'),
        ],
      );
      final json = state.toJson();
      final restored = ForeshadowingState.fromJson(json);
      expect(restored.pending.length, 1);
      expect(restored.planted.length, 1);
      expect(restored.pending.first.description, '神秘剑的来历');
    });
  });

  group('WritingPipelineStateMachine', () {
    late WritingPipelineStateMachine sm;

    setUp(() {
      sm = WritingPipelineStateMachine(projectDir: '.');
    });

    test('初始状态为空闲', () {
      expect(sm.isIdle, isTrue);
      expect(sm.isBusy, isFalse);
      expect(sm.activeWorkflow, isNull);
    });

    test('正常流程: idle → preflight → writing → reviewing → '
        'awaitingAdoption → adopted → settling → settled → idle', () {
      sm.startWorkflow('ch_001');
      expect(sm.activeWorkflow!.currentStage, PipelineStage.preflight);

      sm.advance(PipelineStage.writing);
      expect(sm.activeWorkflow!.currentStage, PipelineStage.writing);

      sm.advance(PipelineStage.reviewing);
      sm.advance(PipelineStage.awaitingAdoption);
      sm.advance(PipelineStage.adopted);
      sm.advance(PipelineStage.settling);
      sm.advance(PipelineStage.settled);
      sm.complete(); // settled → idle

      expect(sm.isIdle, isTrue);
    });

    test('拒绝流程: awaitingAdoption → rejected → idle', () {
      sm.startWorkflow('ch_002');
      sm.advance(PipelineStage.writing);
      sm.advance(PipelineStage.reviewing);
      sm.advance(PipelineStage.awaitingAdoption);
      sm.advance(PipelineStage.rejected);
      sm.advance(PipelineStage.idle);

      expect(sm.isIdle, isTrue);
    });

    test('非法转换抛出 StateError', () {
      sm.startWorkflow('ch_003');
      // preflight 不能直接到 reviewing
      expect(
        () => sm.advance(PipelineStage.reviewing),
        throwsStateError,
      );
    });

    test('忙碌时不能开始新工作流', () {
      sm.startWorkflow('ch_004');
      expect(
        () => sm.startWorkflow('ch_005'),
        throwsStateError,
      );
    });

    test('failAndRollback 清理工作流', () {
      sm.startWorkflow('ch_006');
      sm.advance(PipelineStage.writing);
      sm.failAndRollback('AI 超时');
      expect(sm.isIdle, isTrue);
    });

    test('canTransition 正确判断', () {
      expect(
        sm.canTransition(PipelineStage.idle, PipelineStage.preflight),
        isTrue,
      );
      expect(
        sm.canTransition(PipelineStage.idle, PipelineStage.writing),
        isFalse,
      );
      expect(
        sm.canTransition(PipelineStage.writing, PipelineStage.rollback),
        isTrue,
      );
    });
  });

  group('WriteLockService', () {
    late Directory tempDir;
    late WriteLockService lockService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('lingbi_test_');
      lockService = WriteLockService(projectDir: tempDir.path);
    });

    tearDown(() {
      try {
        lockService.release();
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('初始未持有锁', () {
      expect(lockService.isAcquired, isFalse);
      expect(lockService.currentLock, isNull);
    });

    test('获取和释放锁', () {
      final acquired = lockService.acquire('测试写作');
      expect(acquired, isTrue);
      expect(lockService.isAcquired, isTrue);
      expect(lockService.currentLock, isNotNull);
      expect(lockService.currentLock!.operation, '测试写作');

      lockService.release();
      expect(lockService.isAcquired, isFalse);
      expect(lockService.currentLock, isNull);
    });

    test('第二个锁服务获取失败', () {
      lockService.acquire('任务A');
      final lockService2 = WriteLockService(projectDir: tempDir.path);
      final acquired = lockService2.acquire('任务B');
      expect(acquired, isFalse);
    });

    test('acquireOrThrow 抛出 ProjectBusyError', () {
      lockService.acquire('任务A');
      final lockService2 = WriteLockService(projectDir: tempDir.path);
      expect(
        () => lockService2.acquireOrThrow('任务B'),
        throwsA(isA<ProjectBusyError>()),
      );
    });

    test('withLock 执行操作并自动释放', () {
      final result = lockService.withLock('计算', () => 42);
      expect(result, 42);
      expect(lockService.isAcquired, isFalse);
    });

    test('LockInfo 序列化/反序列化', () {
      final info = LockInfo(
        token: 'abc123',
        pid: 1234,
        operation: '写作',
        createdAt: DateTime(2026, 7, 24),
      );
      final json = info.toJson();
      final restored = LockInfo.fromJson(json);
      expect(restored.token, 'abc123');
      expect(restored.pid, 1234);
      expect(restored.operation, '写作');
    });
  });

  group('CandidateService', () {
    late Directory tempDir;
    late CandidateService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('lingbi_cand_');
      service = CandidateService(
        projectDir: tempDir.path,
        mutationProtocol: _proto(tempDir.path),
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('创建候选', () {
      final entry = service.createCandidate(
        chapterId: 'ch_001',
        content: '这是 AI 生成的内容。',
        model: 'deepseek-chat',
      );
      expect(entry.id, contains('ch_001'));
      expect(entry.status, CandidateStatus.pending);
      expect(entry.content, '这是 AI 生成的内容。');
    });

    test('获取候选', () {
      final created = service.createCandidate(
        chapterId: 'ch_002',
        content: '测试内容',
      );
      final fetched = service.getCandidate(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.content, '测试内容');
      expect(fetched.chapterId, 'ch_002');
    });

    test('列出章节候选', () {
      service.createCandidate(chapterId: 'ch_003', content: 'A');
      service.createCandidate(chapterId: 'ch_003', content: 'B');
      service.createCandidate(chapterId: 'ch_004', content: 'C');

      final list = service.listCandidates('ch_003');
      expect(list.length, 2);
    });

    test('采纳候选', () async {
      final entry = service.createCandidate(
        chapterId: 'ch_005',
        content: '正式正文内容',
      );
      final targetPath = '${tempDir.path}/output/ch005.md';
      await service.adopt(entry.id, targetPath);

      // 验证正文写入
      expect(File(targetPath).readAsStringSync(), '正式正文内容');

      // 验证状态更新
      final updated = service.getCandidate(entry.id);
      expect(updated!.status, CandidateStatus.adopted);
    });

    test('拒绝候选', () {
      final entry = service.createCandidate(
        chapterId: 'ch_006',
        content: '被拒绝的内容',
      );
      service.reject(entry.id, reason: '质量不达标');

      final updated = service.getCandidate(entry.id);
      expect(updated!.status, CandidateStatus.rejected);
      expect(updated.metadata['reject_reason'], '质量不达标');
    });

    test('不能采纳已拒绝的候选', () async {
      final entry = service.createCandidate(
        chapterId: 'ch_007',
        content: '内容',
      );
      service.reject(entry.id);
      await expectLater(
        service.adopt(entry.id, '${tempDir.path}/out.md'),
        throwsStateError,
      );
    });

    test('审稿更新', () {
      final entry = service.createCandidate(
        chapterId: 'ch_008',
        content: '待审内容',
      );
      service.updateReview(entry.id, {'passed': true, 'score': 85});

      final updated = service.getCandidate(entry.id);
      expect(updated!.status, CandidateStatus.approved);
      expect(updated.reviewReport!['score'], 85);
    });
  });

  group('BookState', () {
    test('序列化/反序列化', () {
      final state = BookState(
        novelId: 'novel_001',
        title: '测试小说',
        currentChapter: 'ch_003',
        stage: BookStage.writing,
        totalChapters: 10,
        totalWords: 50000,
      );
      final json = state.toJson();
      final restored = BookState.fromJson(json);
      expect(restored.novelId, 'novel_001');
      expect(restored.title, '测试小说');
      expect(restored.stage, BookStage.writing);
      expect(restored.totalWords, 50000);
    });

    test('BookStateStore 持久化', () {
      final tempDir = Directory.systemTemp.createTempSync('lingbi_bs_');
      try {
        final store = BookStateStore(projectDir: tempDir.path);
        final state = store.loadOrCreate(
          novelId: 'n1',
          title: '我的小说',
        );
        expect(state.novelId, 'n1');

        store.updateProgress(
          chapterId: 'ch_001',
          stage: BookStage.writing,
          action: 'start_writing',
        );

        final reloaded = store.loadOrCreate();
        expect(reloaded.currentChapter, 'ch_001');
        expect(reloaded.stage, BookStage.writing);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('CreativeCompass', () {
    test('空罗盘生成空 prompt', () {
      const compass = CreativeCompass();
      expect(compass.toPromptText(), isEmpty);
    });

    test('完整罗盘生成 prompt', () {
      const compass = CreativeCompass(
        authorIntent: AuthorIntent(
          coreTheme: '少年成长',
          genre: '玄幻',
          tone: '热血',
          taboos: ['不写后宫'],
        ),
        currentFocus: CurrentFocus(
          arcGoal: '主角突破瓶颈',
          arcPhase: '高潮期',
          hardConstraints: ['导师不能死'],
        ),
      );
      final text = compass.toPromptText();
      expect(text, contains('少年成长'));
      expect(text, contains('玄幻'));
      expect(text, contains('主角突破瓶颈'));
      expect(text, contains('导师不能死'));
    });

    test('序列化/反序列化', () {
      const compass = CreativeCompass(
        authorIntent: AuthorIntent(coreTheme: '复仇'),
        currentFocus: CurrentFocus(arcGoal: '揭露真相'),
      );
      final json = compass.toJson();
      final restored = CreativeCompass.fromJson(json);
      expect(restored.authorIntent.coreTheme, '复仇');
      expect(restored.currentFocus.arcGoal, '揭露真相');
    });

    test('CreativeCompassStore 持久化', () {
      final tempDir = Directory.systemTemp.createTempSync('lingbi_cc_');
      try {
        final store = CreativeCompassStore(projectDir: tempDir.path);
        store.updateIntent(const AuthorIntent(
          coreTheme: '命运抗争',
          genre: '仙侠',
        ));
        store.updateFocus(const CurrentFocus(
          arcGoal: '渡劫',
          arcPhase: '高潮',
        ));

        final loaded = store.loadOrCreate();
        expect(loaded.authorIntent.coreTheme, '命运抗争');
        expect(loaded.currentFocus.arcGoal, '渡劫');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('ContextAssembler', () {
    test('使用 EmptyDataSource 组装空上下文', () {
      final tempDir = Directory.systemTemp.createTempSync('lingbi_asm_');
      try {
        final assembler = ContextAssembler(
          projectDir: tempDir.path,
          dataSource: const EmptyDataSource(),
        );
        final ctx = assembler.assemble(
          novelId: 'novel_001',
          chapterId: 'ch_001',
          userInstruction: '写一段打斗场景',
        );
        expect(ctx.novelId, 'novel_001');
        expect(ctx.chapterId, 'ch_001');
        expect(ctx.userInstruction, '写一段打斗场景');
        // 空数据源 → 大部分字段为空
        expect(ctx.recentText, isEmpty);
        expect(ctx.activeCharacters, isEmpty);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('AssemblerConfig 默认值合理', () {
      const config = AssemblerConfig();
      expect(config.tokenBudget, 8000);
      expect(config.recentTextMaxChars, 3000);
      expect(config.maxCharacters, 8);
    });
  });

  group('ChapterWorkflow', () {
    test('序列化/反序列化', () {
      final workflow = ChapterWorkflow(
        chapterId: 'ch_010',
        currentStage: PipelineStage.writing,
        createdAt: DateTime(2026, 7, 24),
      );
      workflow.advanceTo(PipelineStage.reviewing, message: '生成完毕');

      final json = workflow.toJson();
      final restored = ChapterWorkflow.fromJson(json);
      expect(restored.chapterId, 'ch_010');
      expect(restored.currentStage, PipelineStage.reviewing);
      expect(restored.stages.length, 1);
      expect(restored.stages.first.message, '生成完毕');
    });
  });
}

LocalMutationProtocol _proto(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
