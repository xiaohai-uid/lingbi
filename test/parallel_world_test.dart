/// 平行世界 — 单元测试
///
/// 覆盖：创建/继承/切换/成剧调用
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/parallel_world_service.dart';
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
  String mockResponse = '成剧方案输出';

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
  group('ContextSnapshot', () {
    test('fromJson / toJson 往返', () {
      const snap = ContextSnapshot(
        characters: ['林逸', '苏瑶'],
        settings: ['天柱山', '灵剑宗'],
        foreshadowing: ['神秘玉佩'],
        plotPoints: ['入门试炼'],
        chapterIndex: 5,
        summary: '主角通过试炼',
      );

      final json = snap.toJson();
      final restored = ContextSnapshot.fromJson(json);

      expect(restored.characters, ['林逸', '苏瑶']);
      expect(restored.settings, ['天柱山', '灵剑宗']);
      expect(restored.foreshadowing, ['神秘玉佩']);
      expect(restored.chapterIndex, 5);
      expect(restored.summary, '主角通过试炼');
    });
  });

  group('StoryBranch', () {
    test('fromJson / toJson 往返', () {
      const branch = StoryBranch(
        id: 'b1',
        name: '黑暗线',
        forkPoint: '第3章结尾',
        parentBranchId: 'main',
        tags: ['黑暗', '反转'],
      );

      final json = branch.toJson();
      final restored = StoryBranch.fromJson(json);

      expect(restored.id, 'b1');
      expect(restored.name, '黑暗线');
      expect(restored.forkPoint, '第3章结尾');
      expect(restored.parentBranchId, 'main');
      expect(restored.isMainLine, isFalse);
      expect(restored.tags, ['黑暗', '反转']);
    });

    test('isMainLine 主线判断', () {
      const main = StoryBranch(id: 'm', name: '主线', forkPoint: '');
      expect(main.isMainLine, isTrue);
    });

    test('copyWith 更新字段', () {
      const branch = StoryBranch(
        id: 'b1',
        name: '原线',
        forkPoint: 'ch1',
        chapters: ['第一章'],
      );

      final updated = branch.copyWith(
        name: '新名',
        chapters: ['第一章', '第二章'],
        status: BranchStatus.archived,
      );

      expect(updated.name, '新名');
      expect(updated.chapters.length, 2);
      expect(updated.status, BranchStatus.archived);
      expect(updated.id, 'b1'); // 不变
    });
  });

  group('BranchStatus', () {
    test('label 中文标签', () {
      expect(BranchStatus.active.label, '进行中');
      expect(BranchStatus.archived.label, '已归档');
      expect(BranchStatus.merged.label, '已合并');
    });
  });

  group('ParallelWorldService 分支管理', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late ParallelWorldService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = ParallelWorldService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('createBranch 创建并持久化', () async {
      final branch = await service.createBranch(
        projectId: 'p1',
        name: '分支A',
        forkPoint: '第2章末',
        snapshot: const ContextSnapshot(
          characters: ['林逸'],
          chapterIndex: 2,
        ),
      );

      expect(branch.name, '分支A');
      expect(branch.forkPoint, '第2章末');
      expect(branch.snapshot.characters, ['林逸']);

      final list = await service.listBranches('p1');
      expect(list.length, 1);
    });

    test('多分支并行', () async {
      await service.createBranch(
          projectId: 'p1', name: '线A', forkPoint: 'ch1');
      await service.createBranch(
          projectId: 'p1', name: '线B', forkPoint: 'ch1');
      await service.createBranch(
          projectId: 'p1', name: '线C', forkPoint: 'ch3');

      final list = await service.listBranches('p1');
      expect(list.length, 3);
    });

    test('getBranch 获取单个', () async {
      final created = await service.createBranch(
          projectId: 'p1', name: '测试', forkPoint: 'ch1');

      final fetched = await service.getBranch('p1', created.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, '测试');
    });

    test('addChapter 追加章节', () async {
      final branch = await service.createBranch(
          projectId: 'p1', name: '线A', forkPoint: 'ch1');

      final updated =
          await service.addChapter('p1', branch.id, '第一章内容');
      expect(updated!.chapters.length, 1);

      final updated2 =
          await service.addChapter('p1', branch.id, '第二章内容');
      expect(updated2!.chapters.length, 2);
    });

    test('deleteBranch 删除分支及子分支', () async {
      final parent = await service.createBranch(
          projectId: 'p1', name: '父', forkPoint: 'ch1');
      await service.createBranch(
        projectId: 'p1',
        name: '子',
        forkPoint: 'ch2',
        parentBranchId: parent.id,
      );

      final ok = await service.deleteBranch('p1', parent.id);
      expect(ok, isTrue);

      final list = await service.listBranches('p1');
      expect(list, isEmpty);
    });

    test('archiveBranch 归档', () async {
      final branch = await service.createBranch(
          projectId: 'p1', name: '线A', forkPoint: 'ch1');

      final archived = await service.archiveBranch('p1', branch.id);
      expect(archived!.status, BranchStatus.archived);
    });

    test('markMerged 标记合并', () async {
      final branch = await service.createBranch(
          projectId: 'p1', name: '线A', forkPoint: 'ch1');

      final merged = await service.markMerged('p1', branch.id);
      expect(merged!.status, BranchStatus.merged);
    });
  });

  group('分支树', () {
    test('buildTree 构建层级', () async {
      final service = ParallelWorldService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final main = await service.createBranch(
          projectId: 'p1', name: '主线', forkPoint: '');
      // 手动修改 parentBranchId 需要重新创建
      // 使用 parentBranchId 参数
      await service.createBranch(
        projectId: 'p1',
        name: '分支1',
        forkPoint: 'ch3',
        parentBranchId: main.id,
      );

      final tree = await service.buildTree('p1');
      // 主线 parentBranchId='' 是根
      expect(tree.length, 1);
      expect(tree.first.branch.name, '主线');
      expect(tree.first.children.length, 1);
      expect(tree.first.children.first.branch.name, '分支1');
    });
  });

  group('差异对比', () {
    test('diffBranches 对比章节', () async {
      final service = ParallelWorldService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final a = await service.createBranch(
          projectId: 'p1', name: 'A', forkPoint: 'ch1');
      final b = await service.createBranch(
          projectId: 'p1', name: 'B', forkPoint: 'ch1');

      await service.addChapter('p1', a.id, '相同内容');
      await service.addChapter('p1', a.id, 'A独有');

      await service.addChapter('p1', b.id, '相同内容');
      await service.addChapter('p1', b.id, 'B独有');
      await service.addChapter('p1', b.id, 'B第三章');

      final diffs = await service.diffBranches('p1', a.id, b.id);

      expect(diffs.length, 3);
      expect(diffs[0].type, DiffType.identical);
      expect(diffs[1].type, DiffType.modified);
      expect(diffs[2].type, DiffType.added);
    });
  });

  group('成剧下游', () {
    test('buildDramaPrompt 包含上下文', () async {
      final service = ParallelWorldService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final branch = await service.createBranch(
        projectId: 'p1',
        name: '黑暗线',
        forkPoint: '第5章',
        snapshot: const ContextSnapshot(
          characters: ['林逸（黑化）'],
          settings: ['魔界'],
          foreshadowing: ['玉佩碎裂'],
        ),
      );
      await service.addChapter('p1', branch.id, '林逸堕入魔道');

      final prompt =
          await service.buildDramaPrompt('p1', branch.id, styleHint: '日漫');

      expect(prompt, contains('黑暗线'));
      expect(prompt, contains('第5章'));
      expect(prompt, contains('日漫'));
      expect(prompt, contains('林逸（黑化）'));
      expect(prompt, contains('魔界'));
      expect(prompt, contains('玉佩碎裂'));
      expect(prompt, contains('林逸堕入魔道'));
    });

    test('generateDramaVersion 调用 AI', () async {
      final aiProvider = MockAIProvider();
      aiProvider.mockResponse = '角色卡+分镜+场景';

      final service = ParallelWorldService(
        metaRepository: MockMetaRepository(),
        aiProvider: aiProvider,
      );

      final branch = await service.createBranch(
          projectId: 'p1', name: '线A', forkPoint: 'ch1');
      await service.addChapter('p1', branch.id, '内容');

      final result = await service.generateDramaVersion('p1', branch.id);
      expect(result, '角色卡+分镜+场景');
    });

    test('buildDramaPrompt 分支不存在返回空', () async {
      final service = ParallelWorldService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final prompt = await service.buildDramaPrompt('p1', 'nonexist');
      expect(prompt, isEmpty);
    });
  });
}
