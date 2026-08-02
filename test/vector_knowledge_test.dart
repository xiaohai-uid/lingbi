/// 向量知识库 (RAG) — 单元测试
///
/// 覆盖：索引/检索/重建/注入/余弦相似度
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/knowledge/data/vector_knowledge_service.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

// ─── Mocks ───

class MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<Map<String, dynamic>?> read(
      String projectId, String fileName) async {
    return _store['$projectId/$fileName'];
  }

  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
    _store['$projectId/$fileName'] = data;
  }

  @override
  Future<List<String>> list(String projectId) async {
    return _store.keys
        .where((k) => k.startsWith('$projectId/'))
        .map((k) => k.replaceFirst('$projectId/', ''))
        .toList();
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    _store.remove('$projectId/$fileName');
  }

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
      String projectId, WorldConstitution constitution) async {}

  @override
  Future<String> getMetaDirPath(String projectId) async => '/mock/$projectId';
}

/// 确定性 Mock AI — 根据文本内容生成固定向量
class DeterministicEmbedProvider implements AIProvider {
  @override
  String get name => 'mock_embed';
  @override
  String get displayName => 'Mock Embed';
  @override
  bool get isAvailable => true;

  @override
  Future<List<double>> embed(String text) async {
    // 简单确定性嵌入：基于字符码生成 8 维向量
    final vec = List<double>.filled(8, 0);
    for (var i = 0; i < text.length && i < 100; i++) {
      vec[i % 8] += text.codeUnitAt(i).toDouble();
    }
    // 归一化
    var norm = 0.0;
    for (final v in vec) {
      norm += v * v;
    }
    norm = norm == 0 ? 1 : norm;
    final sqrtNorm = norm;
    return vec.map((v) => v / sqrtNorm).toList();
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      '';

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield '';
  }

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VectorEntry 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      const entry = VectorEntry(
        id: 'v1',
        type: VectorEntryType.canon,
        content: '主角是一位剑客',
        embedding: [0.1, 0.2, 0.3],
        metadata: {'source': 'characters.json'},
        indexedAt: '2026-07-25T00:00:00.000',
      );

      final json = entry.toJson();
      final restored = VectorEntry.fromJson(json);

      expect(restored.id, 'v1');
      expect(restored.type, VectorEntryType.canon);
      expect(restored.content, '主角是一位剑客');
      expect(restored.embedding.length, 3);
      expect(restored.metadata['source'], 'characters.json');
    });
  });

  group('VectorIndex 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      final index = VectorIndex(
        projectId: 'proj1',
        entries: const [
          VectorEntry(
            id: 'e1',
            type: VectorEntryType.chapter,
            content: '第一章内容',
            embedding: [0.5, 0.6],
          ),
        ],
        lastRebuiltAt: DateTime(2026, 7, 25),
      );

      final json = index.toJson();
      final restored = VectorIndex.fromJson(json);

      expect(restored.projectId, 'proj1');
      expect(restored.entries.length, 1);
      expect(restored.entries[0].type, VectorEntryType.chapter);
    });
  });

  group('cosineSimilarity', () {
    test('相同向量相似度为 1', () {
      final score =
          VectorKnowledgeService.cosineSimilarity([1, 0, 0], [1, 0, 0]);
      expect(score, closeTo(1.0, 0.001));
    });

    test('正交向量相似度为 0', () {
      final score =
          VectorKnowledgeService.cosineSimilarity([1, 0], [0, 1]);
      expect(score, closeTo(0.0, 0.001));
    });

    test('相反向量相似度为 -1', () {
      final score =
          VectorKnowledgeService.cosineSimilarity([1, 0], [-1, 0]);
      expect(score, closeTo(-1.0, 0.001));
    });

    test('空向量返回 0', () {
      final score = VectorKnowledgeService.cosineSimilarity([], []);
      expect(score, 0);
    });

    test('长度不同返回 0', () {
      final score = VectorKnowledgeService.cosineSimilarity([1, 2], [1]);
      expect(score, 0);
    });
  });

  group('VectorKnowledgeService', () {
    late MockMetaRepository metaRepo;
    late DeterministicEmbedProvider aiProvider;
    late VectorKnowledgeService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = DeterministicEmbedProvider();
      service = VectorKnowledgeService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
        topK: 3,
        similarityThreshold: 0,
      );
    });

    test('indexContent 写入后可通过 loadIndex 读取', () async {
      await service.indexContent(
        'proj1',
        id: 'canon_1',
        type: VectorEntryType.canon,
        content: '世界观：这是一个修仙世界',
      );

      final index = await service.loadIndex('proj1');
      expect(index.entries.length, 1);
      expect(index.entries[0].id, 'canon_1');
      expect(index.entries[0].type, VectorEntryType.canon);
      expect(index.entries[0].embedding, isNotEmpty);
    });

    test('indexContent 同 id 覆盖更新', () async {
      await service.indexContent(
        'proj1',
        id: 'canon_1',
        type: VectorEntryType.canon,
        content: '旧内容',
      );
      await service.indexContent(
        'proj1',
        id: 'canon_1',
        type: VectorEntryType.canon,
        content: '新内容',
      );

      final index = await service.loadIndex('proj1');
      expect(index.entries.length, 1);
      expect(index.entries[0].content, '新内容');
    });

    test('indexContent 空内容不写入', () async {
      await service.indexContent(
        'proj1',
        id: 'empty',
        type: VectorEntryType.custom,
        content: '   ',
      );

      final index = await service.loadIndex('proj1');
      expect(index.entries, isEmpty);
    });

    test('removeEntry 删除指定条目', () async {
      await service.indexContent(
        'proj1',
        id: 'a',
        type: VectorEntryType.canon,
        content: '条目A',
      );
      await service.indexContent(
        'proj1',
        id: 'b',
        type: VectorEntryType.canon,
        content: '条目B',
      );
      await service.removeEntry('proj1', 'a');

      final index = await service.loadIndex('proj1');
      expect(index.entries.length, 1);
      expect(index.entries[0].id, 'b');
    });

    test('search 语义检索返回相关结果', () async {
      await service.indexContent(
        'proj1',
        id: 'c1',
        type: VectorEntryType.canon,
        content: '主角修炼剑道，性格冷峻',
      );
      await service.indexContent(
        'proj1',
        id: 'c2',
        type: VectorEntryType.canon,
        content: '女主角是医仙，温柔善良',
      );
      await service.indexContent(
        'proj1',
        id: 'c3',
        type: VectorEntryType.chapter,
        content: '主角修炼剑道突破第三层',
      );

      // 查询与剑道相关的内容
      final results = await service.search('proj1', '主角修炼剑道');
      expect(results, isNotEmpty);
      // 结果应按相似度降序
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].score, greaterThanOrEqualTo(results[i].score));
      }
    });

    test('search 支持 typeFilter', () async {
      await service.indexContent(
        'proj1',
        id: 'c1',
        type: VectorEntryType.canon,
        content: '设定内容',
      );
      await service.indexContent(
        'proj1',
        id: 'ch1',
        type: VectorEntryType.chapter,
        content: '章节内容',
      );

      final results = await service.search(
        'proj1',
        '内容',
        typeFilter: VectorEntryType.canon,
      );
      expect(results.every((r) => r.entry.type == VectorEntryType.canon),
          isTrue);
    });

    test('indexBatch 批量索引', () async {
      await service.indexBatch('proj1', [
        (id: 'b1', type: VectorEntryType.canon, content: '批量条目1'),
        (id: 'b2', type: VectorEntryType.outline, content: '批量条目2'),
        (id: 'b3', type: VectorEntryType.reference, content: '批量条目3'),
      ]);

      final index = await service.loadIndex('proj1');
      expect(index.entries.length, 3);
    });

    test('rebuildIndex 从 project_meta 重建', () async {
      // 预置 meta 数据
      await metaRepo.write('proj1', 'characters.json', {
        'content': '角色设定：主角李逍遥',
      });
      await metaRepo.write('proj1', 'outline.json', {
        'content': '大纲：三幕结构',
      });

      final index = await service.rebuildIndex('proj1');
      expect(index.entries.length, 2);
      expect(index.entries.any((e) => e.id == 'meta_characters.json'),
          isTrue);
      expect(index.entries.any((e) => e.id == 'meta_outline.json'), isTrue);
    });

    test('buildRagContext 生成格式化上下文', () async {
      await service.indexContent(
        'proj1',
        id: 'c1',
        type: VectorEntryType.canon,
        content: '世界观：修仙世界有九大境界',
      );

      final context =
          await service.buildRagContext('proj1', '修仙世界境界划分');
      expect(context, contains('知识库语义召回'));
      expect(context, contains('设定'));
    });

    test('buildRagContext 空查询返回空', () async {
      final context = await service.buildRagContext('proj1', '');
      expect(context, isEmpty);
    });

    test('getStats 返回正确统计', () async {
      await service.indexContent(
        'proj1',
        id: 'c1',
        type: VectorEntryType.canon,
        content: '设定1',
      );
      await service.indexContent(
        'proj1',
        id: 'c2',
        type: VectorEntryType.canon,
        content: '设定2',
      );
      await service.indexContent(
        'proj1',
        id: 'ch1',
        type: VectorEntryType.chapter,
        content: '章节1',
      );

      final stats = await service.getStats('proj1');
      expect(stats['total'], 3);
      expect(stats['canon'], 2);
      expect(stats['chapter'], 1);
    });
  });
}
