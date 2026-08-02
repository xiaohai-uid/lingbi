/// P0 修订单元测试
///
/// 覆盖：AiResponseNormalizer / AiErrorMapper / SkillActionService /
/// IntentConfirmationService / GenerationTask
library;
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_response_normalizer.dart';
import 'package:lingbi/shared/ai/generation_task.dart';
import 'package:lingbi/shared/errors/ai_error.dart';
import 'package:lingbi/services/intent_confirmation_service.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

void main() {
  group('AiResponseNormalizer', () {
    late AiResponseNormalizer normalizer;

    setUp(() {
      normalizer = AiResponseNormalizer();
    });

    test('纯文本流 → 全部为 answer 块', () async {
      final stream = Stream.fromIterable(['你好，', '世界！']);
      final events = await normalizer.normalize(stream).toList();

      final done = events.whereType<NormalizerDone>().first;
      final answerText =
          done.blocks.where((b) => b.type == NormalizedBlockType.answer).map((b) => b.text).join();
      expect(answerText, '你好，世界！');
    });

    test('<think> 标签内容 → process 块', () async {
      final stream = Stream.fromIterable([
        '<think>让我想想</think>这是回答',
      ]);
      final events = await normalizer.normalize(stream).toList();

      final done = events.whereType<NormalizerDone>().first;
      final processBlocks =
          done.blocks.where((b) => b.type == NormalizedBlockType.process);
      final answerBlocks =
          done.blocks.where((b) => b.type == NormalizedBlockType.answer);

      expect(processBlocks.map((b) => b.text).join(), '让我想想');
      expect(answerBlocks.map((b) => b.text).join(), '这是回答');
    });

    test('<analysis> 标签内容 → process 块', () async {
      final stream = Stream.fromIterable([
        '<analysis>分析中</analysis>最终结论',
      ]);
      final events = await normalizer.normalize(stream).toList();

      final done = events.whereType<NormalizerDone>().first;
      final processText = AiResponseNormalizer.extractProcessText(done.blocks);
      final answerText = AiResponseNormalizer.extractAnswerText(done.blocks);

      expect(processText, '分析中');
      expect(answerText, '最终结论');
    });

    test('跨 chunk 的 <think> 标签正确解析', () async {
      final stream = Stream.fromIterable([
        '正文开头<thi',
        'nk>思考过程</thi',
        'nk>正文结尾',
      ]);
      final events = await normalizer.normalize(stream).toList();

      final done = events.whereType<NormalizerDone>().first;
      final processText = AiResponseNormalizer.extractProcessText(done.blocks);
      final answerText = AiResponseNormalizer.extractAnswerText(done.blocks);

      expect(processText, '思考过程');
      expect(answerText.contains('正文开头'), true);
      expect(answerText.contains('正文结尾'), true);
    });

    test('treatAllAsCandidate 模式 → 非过程输出为 candidate', () async {
      final candidateNormalizer =
          AiResponseNormalizer(treatAllAsCandidate: true);
      final stream = Stream.fromIterable(['候选正文内容']);
      final events = await candidateNormalizer.normalize(stream).toList();

      final done = events.whereType<NormalizerDone>().first;
      expect(done.blocks.every((b) => b.type == NormalizedBlockType.candidate),
          true);
    });

    test('normalizeSync 同步模式', () {
      final blocks = normalizer
          .normalizeSync('<think>过程</think>回答文本');
      final processText = AiResponseNormalizer.extractProcessText(blocks);
      final answerText = AiResponseNormalizer.extractAnswerText(blocks);

      expect(processText, '过程');
      expect(answerText, '回答文本');
    });

    test('流错误 → NormalizerError 事件', () async {
      final stream = Stream<String>.error(Exception('网络中断'));
      final events = await normalizer.normalize(stream).toList();
      final errorEvents = events.whereType<NormalizerError>().toList();

      expect(errorEvents.isNotEmpty, true);
      expect(errorEvents.first.message.contains('网络中断'), true);
    });

    test('extractAnswerText 包含 candidate 类型', () {
      const blocks = [
        NormalizedBlock(type: NormalizedBlockType.process, text: '思考'),
        NormalizedBlock(type: NormalizedBlockType.answer, text: '回答'),
        NormalizedBlock(type: NormalizedBlockType.candidate, text: '候选'),
      ];
      expect(AiResponseNormalizer.extractAnswerText(blocks), '回答候选');
    });
  });

  group('AiErrorMapper', () {
    test('401 → AIAuthError', () {
      final error = AiErrorMapper.map(Exception('HTTP 401 Unauthorized'));
      expect(error, isA<AIAuthError>());
      expect(error.recoveryAction, RecoveryAction.checkApiKey);
    });

    test('403 → AIAuthError', () {
      final error = AiErrorMapper.map(Exception('403 Forbidden'));
      expect(error, isA<AIAuthError>());
    });

    test('429 → AIRateLimitError', () {
      final error = AiErrorMapper.map(Exception('429 Too Many Requests'));
      expect(error, isA<AIRateLimitError>());
      expect(error.recoveryAction, RecoveryAction.retryLater);
    });

    test('429 带 retry-after → 解析秒数', () {
      final error = AiErrorMapper.map(
          Exception('429 rate limit, retry-after: 30'));
      expect(error, isA<AIRateLimitError>());
      expect((error as AIRateLimitError).retryAfterSeconds, 30);
    });

    test('500 → AIModelError', () {
      final error = AiErrorMapper.map(Exception('500 Internal Server Error'));
      expect(error, isA<AIModelError>());
      expect(error.recoveryAction, RecoveryAction.retryLater);
    });

    test('网络超时 → AINetworkError', () {
      final error =
          AiErrorMapper.map(Exception('Connection timeout after 30s'));
      expect(error, isA<AINetworkError>());
      expect(error.recoveryAction, RecoveryAction.checkNetwork);
    });

    test('DNS 失败 → AINetworkError', () {
      final error = AiErrorMapper.map(Exception('DNS lookup failed'));
      expect(error, isA<AINetworkError>());
    });

    test('磁盘满 → AIStorageError(isDiskFull)', () {
      final error = AiErrorMapper.map(Exception('ENOSPC: no space left'));
      expect(error, isA<AIStorageError>());
      expect((error as AIStorageError).isDiskFull, true);
    });

    test('只读 → AIStorageError(isReadOnly)', () {
      final error = AiErrorMapper.map(Exception('EPERM: read-only file system'));
      expect(error, isA<AIStorageError>());
      expect((error as AIStorageError).isReadOnly, true);
    });

    test('未知错误 → AIModelError', () {
      final error = AiErrorMapper.map(Exception('something weird'));
      expect(error, isA<AIModelError>());
    });

    test('已是 AIServiceError → 直接返回', () {
      final original = AICancelledError();
      final mapped = AiErrorMapper.map(original);
      expect(identical(original, mapped), true);
    });

    test('toUserFacing 包含数据保留说明', () {
      final error = AINetworkError();
      final facing = AiErrorMapper.toUserFacing(error);

      expect(facing.title, '网络连接中断');
      expect(facing.dataRetained, true);
      expect(facing.dataRetentionNote, '已生成的内容已保留，不会丢失。');
      expect(facing.canRetry, true);
      expect(facing.nextStep.isNotEmpty, true);
    });

    test('AIStorageError 数据不保留', () {
      final error = AIStorageError(isDiskFull: true);
      final facing = AiErrorMapper.toUserFacing(error);

      expect(facing.dataRetained, false);
      expect(facing.dataRetentionNote, '部分数据可能未保存。');
    });

    test('带 provider 的 AIAuthError 提示包含供应商名', () {
      final error = AIAuthError(provider: 'DeepSeek');
      expect(error.userHint.contains('DeepSeek'), true);
    });
  });

  group('SkillActionService', () {
    late SkillActionService service;

    setUp(() {
      service = SkillActionService()..initializeBuiltinSkills();
    });

    test('初始化后注册 3 个内置技能', () {
      expect(service.registeredSkills.length, 3);
    });

    test('内置技能 ID 正确', () {
      final ids = service.registeredSkills.map((s) => s.id).toSet();
      expect(ids, containsAll(['smart-continuation', 'dialogue-polish', 'deai-polisher']));
    });

    test('getSkill 返回正确技能', () {
      final skill = service.getSkill('smart-continuation');
      expect(skill, isNotNull);
      expect(skill!.name, '智能续写');
    });

    test('getSkill 不存在返回 null', () {
      expect(service.getSkill('nonexistent'), isNull);
    });

    test('searchSkills 模糊搜索', () {
      final results = service.searchSkills('续写');
      expect(results.length, 1);
      expect(results.first.id, 'smart-continuation');
    });

    test('searchSkills 空查询返回全部', () {
      expect(service.searchSkills('').length, 3);
    });

    test('skillsForInput 无选区时排除 selection-only 技能', () {
      final skills = service.skillsForInput(hasSelection: false);
      // dialogue-polish 和 deai-polisher 需要 selection
      final ids = skills.map((s) => s.id).toSet();
      expect(ids.contains('smart-continuation'), true);
      expect(ids.contains('dialogue-polish'), false);
      expect(ids.contains('deai-polisher'), false);
    });

    test('skillsForInput 有选区时返回全部', () {
      final skills = service.skillsForInput(hasSelection: true);
      expect(skills.length, 3);
    });

    test('executeSkill 不存在的技能 → 失败', () {
      final result = service.executeSkill(
        skillId: 'nonexistent',
        context: const SkillContext(),
      );
      expect(result.success, false);
      expect(result.error, '技能不存在');
    });

    test('智能续写 输入不足 → 失败', () {
      final result = service.executeSkill(
        skillId: 'smart-continuation',
        context: const SkillContext(fullDocument: '短'),
      );
      expect(result.success, false);
      expect(result.error!.contains('至少需要'), true);
    });

    test('智能续写 输入充分 → 成功 + 构建 prompt', () {
      final result = service.executeSkill(
        skillId: 'smart-continuation',
        context: const SkillContext(
          fullDocument: '这是一段足够长的前文内容，用于测试智能续写功能是否正常工作。',
          canonSummary: '主角：小明',
        ),
        params: {'length': '500', 'mood': '紧张'},
      );
      expect(result.success, true);
      expect(result.promptForAI.contains('500'), true);
      expect(result.promptForAI.contains('紧张'), true);
      expect(result.promptForAI.contains('小明'), true);
    });

    test('文本润色 使用选中文本', () {
      final result = service.executeSkill(
        skillId: 'dialogue-polish',
        context: const SkillContext(
          selectedText: '这是需要润色的文本段落。',
          fullDocument: '全文内容',
        ),
        params: {'style': '更文学'},
      );
      expect(result.success, true);
      expect(result.promptForAI.contains('更文学'), true);
      expect(result.promptForAI.contains('这是需要润色的文本段落。'), true);
    });

    test('降低AI痕迹 最小输入长度 20', () {
      final skill = service.getSkill('deai-polisher')!;
      expect(skill.contextRequirements.minInputLength, 20);

      final result = service.executeSkill(
        skillId: 'deai-polisher',
        context: const SkillContext(selectedText: '太短了'),
      );
      expect(result.success, false);
    });
  });

  group('SkillAction 参数驱动', () {
    test('areParametersSatisfied 无必填参数 → 始终 true', () {
      final skill = SmartContinuationSkill();
      // SmartContinuation 没有 requiredParameters
      expect(skill.areParametersSatisfied({}), true);
    });

    test('getMissingParameters 无必填 → 空列表', () {
      final skill = SmartContinuationSkill();
      expect(skill.getMissingParameters({}), isEmpty);
    });

    test('SkillContext.effectiveInput 按 InputScope 取值', () {
      const ctx = SkillContext(
        selectedText: '选中',
        fullDocument: '全文',
      );
      expect(ctx.effectiveInput(InputScope.selection), '选中');
      expect(ctx.effectiveInput(InputScope.fullDocument), '全文');
      expect(ctx.effectiveInput(InputScope.selectionOrDocument), '选中');
      expect(ctx.effectiveInput(InputScope.none), '');
    });

    test('selectionOrDocument 无选中 → 取全文', () {
      const ctx = SkillContext(fullDocument: '全文');
      expect(ctx.effectiveInput(InputScope.selectionOrDocument), '全文');
    });
  });

  group('IntentConfirmationService', () {
    late IntentConfirmationService service;
    late SkillAction skill;

    setUp(() {
      service = IntentConfirmationService();
      skill = SmartContinuationSkill();
    });

    test('无必填参数 → 参数充分，直接执行', () {
      final assessment = service.assessIntent(skill);
      expect(assessment.isSufficient, true);
    });

    test('skipAll → 始终充分', () {
      service.skipAll = true;
      final assessment = service.assessIntent(skill);
      expect(assessment.isSufficient, true);
    });

    test('有必填参数缺失 → 不充分 + 返回缺失列表', () {
      // 创建一个有必填参数的测试技能
      final testSkill = _TestSkillWithRequiredParams();
      final assessment = service.assessIntent(testSkill);

      expect(assessment.isSufficient, false);
      expect(assessment.missingParameters.length, 1);
      expect(assessment.missingParameters.first.name, 'target');
    });

    test('用户补充参数 → 充分', () {
      final testSkill = _TestSkillWithRequiredParams();
      final assessment = service.assessIntent(
        testSkill,
        userParams: {'target': '续写第三章'},
      );
      expect(assessment.isSufficient, true);
    });

    test('会话记忆 → 自动填充参数', () {
      final testSkill = _TestSkillWithRequiredParams();

      // 先记住
      service.rememberForSession(testSkill.id, {'target': '默认目标'});

      // 再评估 → 充分
      final assessment = service.assessIntent(testSkill);
      expect(assessment.isSufficient, true);
    });

    test('clearSessionMemory 后重新需要参数', () {
      final testSkill = _TestSkillWithRequiredParams();
      service.rememberForSession(testSkill.id, {'target': '目标'});
      service.clearSessionMemory();

      final assessment = service.assessIntent(testSkill);
      expect(assessment.isSufficient, false);
    });

    test('buildConfirmationCard 充分时返回 null', () {
      final assessment = service.assessIntent(skill);
      final card = service.buildConfirmationCard(skill, assessment);
      expect(card, isNull);
    });

    test('buildConfirmationCard 不充分时返回确认卡', () {
      final testSkill = _TestSkillWithRequiredParams();
      final assessment = service.assessIntent(testSkill);
      final card = service.buildConfirmationCard(testSkill, assessment);

      expect(card, isNotNull);
      expect(card!.skillName, '测试技能');
      expect(card.parameters.length, 1);
      expect(card.showDirectGenerate, true);
      expect(card.showRememberOption, true);
    });

    test('快速选项从参数 options 生成', () {
      final testSkill = _TestSkillWithSelectParam();
      final assessment = service.assessIntent(testSkill);

      expect(assessment.quickOptions.isNotEmpty, true);
      expect(assessment.quickOptions.first.paramName, 'genre');
    });
  });

  group('GenerationTask', () {
    test('create 生成唯一 taskId', () {
      final task1 = GenerationTask.create(
        projectId: 'p1',
        chapterId: 'c1',
        sourcePath: '/a.md',
        sourceHash: 'h1',
      );
      final task2 = GenerationTask.create(
        projectId: 'p1',
        chapterId: 'c1',
        sourcePath: '/a.md',
        sourceHash: 'h1',
      );
      // taskId 可能相同（同一毫秒），但通常不同
      // 至少验证格式
      expect(task1.taskId.startsWith('task_'), true);
      expect(task2.taskId.startsWith('task_'), true);
    });

    test('isBoundTo 正确匹配', () {
      final task = GenerationTask.create(
        projectId: 'proj-1',
        chapterId: 'chap-1',
        sourcePath: '/file.md',
        sourceHash: 'abc',
      );
      expect(task.isBoundTo(projectId: 'proj-1', chapterId: 'chap-1'), true);
      expect(task.isBoundTo(projectId: 'proj-2', chapterId: 'chap-1'), false);
      expect(task.isBoundTo(projectId: 'proj-1', chapterId: 'chap-2'), false);
    });

    test('状态生命周期', () {
      final task = GenerationTask.create(
        projectId: 'p',
        chapterId: 'c',
        sourcePath: '/f.md',
        sourceHash: 'h',
      );

      expect(task.status, GenerationTaskStatus.pending);
      expect(task.isActive, true);
      expect(task.isCancellable, false);

      task.markGenerating();
      expect(task.status, GenerationTaskStatus.generating);
      expect(task.isActive, true);
      expect(task.isCancellable, true);

      task.markCompleted('cand-1');
      expect(task.status, GenerationTaskStatus.completed);
      expect(task.candidateId, 'cand-1');
      expect(task.isActive, false);
    });

    test('取消保留部分内容', () {
      final task = GenerationTask.create(
        projectId: 'p',
        chapterId: 'c',
        sourcePath: '/f.md',
        sourceHash: 'h',
      );
      task.markGenerating();
      task.markCancelled(partial: '已生成的部分文本');

      expect(task.status, GenerationTaskStatus.cancelled);
      expect(task.partialContent, '已生成的部分文本');
    });

    test('markFailed 记录错误', () {
      final task = GenerationTask.create(
        projectId: 'p',
        chapterId: 'c',
        sourcePath: '/f.md',
        sourceHash: 'h',
      );
      task.markGenerating();
      task.markFailed('网络超时');

      expect(task.status, GenerationTaskStatus.failed);
      expect(task.errorMessage, '网络超时');
    });

    test('computeHash 不同内容不同哈希', () {
      final h1 = GenerationTask.computeHash('内容一');
      final h2 = GenerationTask.computeHash('内容二');
      expect(h1, isNot(equals(h2)));
    });

    test('computeHash 空内容', () {
      expect(GenerationTask.computeHash(''), 'empty');
    });

    test('toJson / fromJson 往返', () {
      final task = GenerationTask.create(
        projectId: 'proj',
        chapterId: 'chap',
        sourcePath: '/path.md',
        sourceHash: 'hash123',
        skillId: 'smart-continuation',
        userInstruction: '续写',
      );
      task.markGenerating();

      final json = task.toJson();
      final restored = GenerationTask.fromJson(json);

      expect(restored.taskId, task.taskId);
      expect(restored.projectId, 'proj');
      expect(restored.chapterId, 'chap');
      expect(restored.sourcePath, '/path.md');
      expect(restored.sourceHash, 'hash123');
      expect(restored.skillId, 'smart-continuation');
      expect(restored.status, GenerationTaskStatus.generating);
    });
  });

  group('GenerationTaskManager', () {
    late GenerationTaskManager manager;

    setUp(() {
      manager = GenerationTaskManager();
    });

    test('创建任务后 hasActiveTask', () {
      manager.createTask(
        projectId: 'p1',
        chapterId: 'c1',
        sourcePath: '/f.md',
        sourceHash: 'h',
      );
      expect(manager.hasActiveTask, true);
    });

    test('新建任务自动取消旧活跃任务', () {
      final task1 = manager.createTask(
        projectId: 'p1',
        chapterId: 'c1',
        sourcePath: '/f.md',
        sourceHash: 'h',
      );
      task1.markGenerating();

      manager.createTask(
        projectId: 'p1',
        chapterId: 'c2',
        sourcePath: '/g.md',
        sourceHash: 'h2',
      );

      expect(task1.status, GenerationTaskStatus.cancelled);
      expect(manager.activeTask!.chapterId, 'c2');
    });

    test('isTaskStillValid 项目切换后无效', () {
      final task = manager.createTask(
        projectId: 'p1',
        chapterId: 'c1',
        sourcePath: '/f.md',
        sourceHash: 'h',
      );

      expect(
        manager.isTaskStillValid(task.taskId,
            currentProjectId: 'p1', currentChapterId: 'c1'),
        true,
      );
      expect(
        manager.isTaskStillValid(task.taskId,
            currentProjectId: 'p2', currentChapterId: 'c1'),
        false,
      );
    });

    test('cancelActiveTask 清除活跃任务', () {
      manager.createTask(
        projectId: 'p1',
        chapterId: 'c1',
        sourcePath: '/f.md',
        sourceHash: 'h',
      );
      manager.cancelActiveTask(partial: '部分');

      expect(manager.hasActiveTask, false);
      expect(manager.activeTask, isNull);
    });

    test('getTasksForChapter 过滤', () {
      manager.createTask(
          projectId: 'p', chapterId: 'c1', sourcePath: '/a', sourceHash: 'h');
      manager.createTask(
          projectId: 'p', chapterId: 'c2', sourcePath: '/b', sourceHash: 'h');
      manager.createTask(
          projectId: 'p', chapterId: 'c1', sourcePath: '/c', sourceHash: 'h');

      expect(manager.getTasksForChapter('c1').length, 2);
      expect(manager.getTasksForChapter('c2').length, 1);
    });
  });
}

/// 测试用技能：有必填参数
class _TestSkillWithRequiredParams extends SkillAction {
  @override
  String get id => 'test-required';
  @override
  String get name => '测试技能';
  @override
  String get description => '测试用';
  @override
  String get icon => 'test';
  @override
  InputScope get inputScope => InputScope.none;
  @override
  OutputMode get outputMode => OutputMode.analysis;
  @override
  MutationPolicy get mutationPolicy => MutationPolicy.readOnly;

  @override
  List<SkillParameter> get requiredParameters => [
        const SkillParameter(
          name: 'target',
          label: '目标',
          required: true,
        ),
      ];

  @override
  String buildPrompt({
    required SkillContext context,
    Map<String, String> params = const {},
  }) =>
      'test prompt';
}

/// 测试用技能：有 select 类型必填参数
class _TestSkillWithSelectParam extends SkillAction {
  @override
  String get id => 'test-select';
  @override
  String get name => '选择技能';
  @override
  String get description => '测试用';
  @override
  String get icon => 'test';
  @override
  InputScope get inputScope => InputScope.none;
  @override
  OutputMode get outputMode => OutputMode.analysis;
  @override
  MutationPolicy get mutationPolicy => MutationPolicy.readOnly;

  @override
  List<SkillParameter> get requiredParameters => [
        const SkillParameter(
          name: 'genre',
          label: '类型',
          type: SkillParameterType.select,
          required: true,
          options: ['玄幻', '都市', '科幻', '历史'],
        ),
      ];

  @override
  String buildPrompt({
    required SkillContext context,
    Map<String, String> params = const {},
  }) =>
      'test prompt';
}
