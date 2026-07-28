/// 工作流审批 — 单元测试
///
/// 覆盖：状态流转/拒绝重生成/门禁
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/workflow_approval_service.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/core/ai/ai_provider.dart';

// ─── Mock ───

class MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};

  @override
  Future<Map<String, dynamic>?> read(String projectId, String key) async {
    return _store[projectId]?[key];
  }

  @override
  Future<void> write(
      String projectId, String key, Map<String, dynamic> value) async {
    _store.putIfAbsent(projectId, () => {});
    _store[projectId]![key] = value;
  }

  @override
  Future<void> delete(String projectId, String key) async {
    _store[projectId]?.remove(key);
  }

  @override
  Future<List<String>> list(String projectId) async {
    return _store[projectId]?.keys.toList() ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAIProvider implements AIProvider {
  String mockResponse = '重新生成的内容';

  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      mockResponse;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield mockResponse;
  }

  @override
  Future<List<double>> embed(String text) async => [];
  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ApprovalStatus', () {
    test('label 中文标签', () {
      expect(ApprovalStatus.draft.label, '草稿');
      expect(ApprovalStatus.pending.label, '待审');
      expect(ApprovalStatus.approved.label, '已通过');
      expect(ApprovalStatus.rejected.label, '已拒绝');
    });

    test('isTerminal 终态判断', () {
      expect(ApprovalStatus.approved.isTerminal, isTrue);
      expect(ApprovalStatus.rejected.isTerminal, isTrue);
      expect(ApprovalStatus.draft.isTerminal, isFalse);
      expect(ApprovalStatus.pending.isTerminal, isFalse);
    });
  });

  group('ApprovalTargetType', () {
    test('label 中文标签', () {
      expect(ApprovalTargetType.blueprint.label, '蓝图');
      expect(ApprovalTargetType.volume.label, '卷');
      expect(ApprovalTargetType.chapter.label, '章节');
    });
  });

  group('ApprovalRecord', () {
    test('fromJson / toJson 往返', () {
      const record = ApprovalRecord(
        targetId: 'ch_001',
        targetType: ApprovalTargetType.chapter,
        status: ApprovalStatus.pending,
        content: '第一章内容',
        createdAt: '2026-01-01',
        updatedAt: '2026-01-02',
      );

      final json = record.toJson();
      final restored = ApprovalRecord.fromJson(json);

      expect(restored.targetId, 'ch_001');
      expect(restored.targetType, ApprovalTargetType.chapter);
      expect(restored.status, ApprovalStatus.pending);
      expect(restored.content, '第一章内容');
    });

    test('isApproved 判断', () {
      const approved = ApprovalRecord(
        targetId: 'a',
        targetType: ApprovalTargetType.blueprint,
        status: ApprovalStatus.approved,
      );
      const draft = ApprovalRecord(
        targetId: 'b',
        targetType: ApprovalTargetType.blueprint,
      );

      expect(approved.isApproved, isTrue);
      expect(draft.isApproved, isFalse);
    });
  });

  group('状态流转', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late WorkflowApprovalService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = WorkflowApprovalService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('draft → pending → approved 正常流', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
        content: '内容',
      );

      final submitted = await service.submitForReview('p1', 'ch1');
      expect(submitted.status, ApprovalStatus.pending);

      final approved = await service.approve('p1', 'ch1');
      expect(approved.status, ApprovalStatus.approved);
      expect(approved.isApproved, isTrue);
    });

    test('draft → pending → rejected 拒绝流', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
      );

      await service.submitForReview('p1', 'ch1');
      final rejected = await service.reject(
        'p1',
        'ch1',
        feedback: '节奏太慢，需要加快开头',
      );

      expect(rejected.status, ApprovalStatus.rejected);
      expect(rejected.feedback, '节奏太慢，需要加快开头');
    });

    test('rejected → pending 重新提交', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
      );

      await service.submitForReview('p1', 'ch1');
      await service.reject('p1', 'ch1', feedback: '修改');

      final resubmitted = await service.submitForReview('p1', 'ch1');
      expect(resubmitted.status, ApprovalStatus.pending);
    });

    test('非法转换抛异常', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
      );

      // draft 不能直接 approved
      expect(
        () => service.approve('p1', 'ch1'),
        throwsA(isA<InvalidTransitionException>()),
      );
    });

    test('拒绝无意见抛异常', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
      );
      await service.submitForReview('p1', 'ch1');

      expect(
        () => service.reject('p1', 'ch1', feedback: ''),
        throwsA(isA<MissingFeedbackException>()),
      );
    });

    test('approved 不能再转换', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
      );
      await service.submitForReview('p1', 'ch1');
      await service.approve('p1', 'ch1');

      expect(
        () => service.submitForReview('p1', 'ch1'),
        throwsA(isA<InvalidTransitionException>()),
      );
    });

    test('审批历史记录', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
      );
      await service.submitForReview('p1', 'ch1');
      final approved = await service.approve('p1', 'ch1');

      // draft + pending + approved = 3 条历史
      expect(approved.history.length, 3);
      expect(approved.history.last.action, ApprovalStatus.approved);
    });
  });

  group('门禁', () {
    late WorkflowApprovalService service;

    setUp(() {
      service = WorkflowApprovalService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );
    });

    test('isApprovedForPipeline 通过检查', () async {
      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
      );

      expect(await service.isApprovedForPipeline('p1', 'ch1'), isFalse);

      await service.submitForReview('p1', 'ch1');
      expect(await service.isApprovedForPipeline('p1', 'ch1'), isFalse);

      await service.approve('p1', 'ch1');
      expect(await service.isApprovedForPipeline('p1', 'ch1'), isTrue);
    });

    test('checkPipelineGate 批量检查', () async {
      await service.createRecord(
          projectId: 'p1',
          targetId: 'a',
          targetType: ApprovalTargetType.chapter);
      await service.createRecord(
          projectId: 'p1',
          targetId: 'b',
          targetType: ApprovalTargetType.volume);

      await service.submitForReview('p1', 'a');
      await service.approve('p1', 'a');

      final gate = await service.checkPipelineGate('p1', ['a', 'b', 'c']);
      expect(gate['a'], isTrue);
      expect(gate['b'], isFalse);
      expect(gate['c'], isFalse); // 不存在
    });
  });

  group('拒绝重生成', () {
    test('regenerateWithFeedback 调用 AI', () async {
      final aiProvider = MockAIProvider();
      aiProvider.mockResponse = '修改后的新内容';

      final service = WorkflowApprovalService(
        metaRepository: MockMetaRepository(),
        aiProvider: aiProvider,
      );

      final result = await service.regenerateWithFeedback(
        originalContent: '原始内容',
        feedback: '加快节奏',
      );

      expect(result, '修改后的新内容');
    });

    test('rejectAndRegenerate 拒绝并自动重生成', () async {
      final aiProvider = MockAIProvider();
      aiProvider.mockResponse = 'AI重新生成的章节';

      final service = WorkflowApprovalService(
        metaRepository: MockMetaRepository(),
        aiProvider: aiProvider,
      );

      await service.createRecord(
        projectId: 'p1',
        targetId: 'ch1',
        targetType: ApprovalTargetType.chapter,
        content: '原始章节',
      );
      await service.submitForReview('p1', 'ch1');

      final result = await service.rejectAndRegenerate(
        'p1',
        'ch1',
        feedback: '对话太生硬',
      );

      // 拒绝后自动重生成并重新提交
      expect(result.status, ApprovalStatus.pending);
      expect(result.content, 'AI重新生成的章节');
    });
  });

  group('待审列表', () {
    test('getPendingList 筛选待审', () async {
      final service = WorkflowApprovalService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      await service.createRecord(
          projectId: 'p1',
          targetId: 'a',
          targetType: ApprovalTargetType.chapter);
      await service.createRecord(
          projectId: 'p1',
          targetId: 'b',
          targetType: ApprovalTargetType.chapter);
      await service.createRecord(
          projectId: 'p1',
          targetId: 'c',
          targetType: ApprovalTargetType.chapter);

      await service.submitForReview('p1', 'a');
      await service.submitForReview('p1', 'b');

      final pending = await service.getPendingList('p1');
      expect(pending.length, 2);
      expect(pending.map((r) => r.targetId), containsAll(['a', 'b']));
    });
  });
}
