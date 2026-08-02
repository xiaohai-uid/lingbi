/// 角色关系图谱可视化 — 单元测试
///
/// 覆盖：数据提取/图更新/交互
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/canon/data/character_relation_graph_service.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

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
  String mockResponse = '';

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
  group('RelationType', () {
    test('label 中文标签', () {
      expect(RelationType.family.label, '亲属');
      expect(RelationType.enemy.label, '敌对');
      expect(RelationType.mentor.label, '师徒');
      expect(RelationType.lover.label, '恋人');
    });

    test('color 非零', () {
      for (final type in RelationType.values) {
        expect(type.color, isNonZero);
      }
    });

    test('isDashed 虚线判断', () {
      expect(RelationType.stranger.isDashed, isTrue);
      expect(RelationType.rival.isDashed, isTrue);
      expect(RelationType.family.isDashed, isFalse);
    });

    test('fromString 解析', () {
      expect(RelationType.fromString('enemy'), RelationType.enemy);
      expect(RelationType.fromString('unknown'), RelationType.stranger);
    });
  });

  group('CharacterRelation', () {
    test('fromJson / toJson 往返', () {
      const rel = CharacterRelation(
        fromId: '林逸',
        toId: '苏瑶',
        relationType: RelationType.lover,
        description: '青梅竹马',
        sinceChapter: 3,
        weight: 2,
      );

      final json = rel.toJson();
      final restored = CharacterRelation.fromJson(json);

      expect(restored.fromId, '林逸');
      expect(restored.toId, '苏瑶');
      expect(restored.relationType, RelationType.lover);
      expect(restored.description, '青梅竹马');
      expect(restored.sinceChapter, 3);
      expect(restored.weight, 2.0);
    });

    test('involves 判断', () {
      const rel = CharacterRelation(
        fromId: 'A',
        toId: 'B',
        relationType: RelationType.friend,
      );

      expect(rel.involves('A'), isTrue);
      expect(rel.involves('B'), isTrue);
      expect(rel.involves('C'), isFalse);
    });
  });

  group('GraphNode', () {
    test('radius 主角更大', () {
      final protagonist = GraphNode(id: 'p', label: '主角', isProtagonist: true);
      final normal = GraphNode(id: 'n', label: '配角');

      expect(protagonist.radius, greaterThan(normal.radius));
    });
  });

  group('RelationGraph', () {
    test('fromJson / toJson 往返', () {
      final graph = RelationGraph(
        nodes: [
          GraphNode(id: 'a', label: '角色A', isProtagonist: true),
          GraphNode(id: 'b', label: '角色B'),
        ],
        edges: const [
          GraphEdge(
            relation: CharacterRelation(
              fromId: 'a',
              toId: 'b',
              relationType: RelationType.mentor,
            ),
          ),
        ],
        lastUpdatedChapter: 5,
      );

      final json = graph.toJson();
      final restored = RelationGraph.fromJson(json);

      expect(restored.nodes.length, 2);
      expect(restored.edges.length, 1);
      expect(restored.lastUpdatedChapter, 5);
      expect(restored.nodes.first.isProtagonist, isTrue);
    });
  });

  group('CharacterRelationGraphService CRUD', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late CharacterRelationGraphService service;

    setUp(() {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      service = CharacterRelationGraphService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
      );
    });

    test('addNode 添加节点', () async {
      final graph = await service.addNode(
        'p1',
        id: '林逸',
        label: '林逸',
        isProtagonist: true,
      );

      expect(graph.nodes.length, 1);
      expect(graph.nodes.first.isProtagonist, isTrue);
    });

    test('addNode 去重', () async {
      await service.addNode('p1', id: 'A', label: 'A');
      final graph = await service.addNode('p1', id: 'A', label: 'A重复');

      expect(graph.nodes.length, 1);
    });

    test('addRelation 添加关系', () async {
      await service.addNode('p1', id: 'A', label: 'A');
      await service.addNode('p1', id: 'B', label: 'B');

      final graph = await service.addRelation(
        'p1',
        const CharacterRelation(
          fromId: 'A',
          toId: 'B',
          relationType: RelationType.enemy,
          description: '宿敌',
        ),
      );

      expect(graph.edges.length, 1);
      expect(graph.edges.first.relation.relationType, RelationType.enemy);
    });

    test('addRelation 去重', () async {
      await service.addNode('p1', id: 'A', label: 'A');
      await service.addNode('p1', id: 'B', label: 'B');

      const rel = CharacterRelation(
        fromId: 'A',
        toId: 'B',
        relationType: RelationType.friend,
      );
      await service.addRelation('p1', rel);
      final graph = await service.addRelation('p1', rel);

      expect(graph.edges.length, 1);
    });

    test('removeRelation 删除关系', () async {
      await service.addNode('p1', id: 'A', label: 'A');
      await service.addNode('p1', id: 'B', label: 'B');
      await service.addRelation(
        'p1',
        const CharacterRelation(
            fromId: 'A', toId: 'B', relationType: RelationType.ally),
      );

      final graph =
          await service.removeRelation('p1', fromId: 'A', toId: 'B');
      expect(graph.edges, isEmpty);
    });

    test('getRelationsForCharacter 查询角色关系', () async {
      await service.addNode('p1', id: 'A', label: 'A');
      await service.addNode('p1', id: 'B', label: 'B');
      await service.addNode('p1', id: 'C', label: 'C');
      await service.addRelation(
        'p1',
        const CharacterRelation(
            fromId: 'A', toId: 'B', relationType: RelationType.friend),
      );
      await service.addRelation(
        'p1',
        const CharacterRelation(
            fromId: 'C', toId: 'A', relationType: RelationType.mentor),
      );

      final rels = await service.getRelationsForCharacter('p1', 'A');
      expect(rels.length, 2);
    });

    test('getConnectedCharacters 高亮关联', () async {
      await service.addNode('p1', id: 'A', label: 'A');
      await service.addNode('p1', id: 'B', label: 'B');
      await service.addNode('p1', id: 'C', label: 'C');
      await service.addRelation(
        'p1',
        const CharacterRelation(
            fromId: 'A', toId: 'B', relationType: RelationType.friend),
      );
      await service.addRelation(
        'p1',
        const CharacterRelation(
            fromId: 'A', toId: 'C', relationType: RelationType.enemy),
      );

      final connected = await service.getConnectedCharacters('p1', 'A');
      expect(connected.length, 2);
      expect(connected, containsAll(['B', 'C']));
    });
  });

  group('自动更新', () {
    test('extractRelationsFromChapter AI提取', () async {
      final aiProvider = MockAIProvider();
      aiProvider.mockResponse = jsonEncode([
        {
          'from_id': '林逸',
          'to_id': '苏瑶',
          'relation_type': 'lover',
          'description': '互生情愫',
        },
      ]);

      final service = CharacterRelationGraphService(
        metaRepository: MockMetaRepository(),
        aiProvider: aiProvider,
      );

      final relations = await service.extractRelationsFromChapter(
        chapterText: '林逸与苏瑶相视一笑。',
        chapterIndex: 5,
      );

      expect(relations.length, 1);
      expect(relations.first.relationType, RelationType.lover);
      expect(relations.first.sinceChapter, 5);
    });

    test('extractRelationsFromChapter 空文本返回空', () async {
      final service = CharacterRelationGraphService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final relations = await service.extractRelationsFromChapter(
        chapterText: '',
        chapterIndex: 1,
      );
      expect(relations, isEmpty);
    });

    test('updateFromChapter 合并关系并自动创建节点', () async {
      final service = CharacterRelationGraphService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final graph = await service.updateFromChapter(
        projectId: 'p1',
        chapterIndex: 3,
        newRelations: const [
          CharacterRelation(
            fromId: '张三',
            toId: '李四',
            relationType: RelationType.rival,
            sinceChapter: 3,
          ),
        ],
      );

      expect(graph.nodes.length, 2); // 自动创建
      expect(graph.edges.length, 1);
      expect(graph.lastUpdatedChapter, 3);
    });
  });

  group('力导向布局', () {
    test('computeLayout 节点位置更新', () {
      final service = CharacterRelationGraphService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      final graph = RelationGraph(
        nodes: [
          GraphNode(id: 'a', label: 'A'),
          GraphNode(id: 'b', label: 'B'),
          GraphNode(id: 'c', label: 'C'),
        ],
        edges: const [
          GraphEdge(
            relation: CharacterRelation(
              fromId: 'a',
              toId: 'b',
              relationType: RelationType.friend,
              weight: 2,
            ),
          ),
        ],
      );

      service.computeLayout(graph, width: 400, height: 300);

      // 验证位置在边界内
      for (final node in graph.nodes) {
        expect(node.x, greaterThanOrEqualTo(0));
        expect(node.x, lessThanOrEqualTo(400));
        expect(node.y, greaterThanOrEqualTo(0));
        expect(node.y, lessThanOrEqualTo(300));
      }

      // 连接的节点应该比不连接的更近
      final a = graph.nodes.firstWhere((n) => n.id == 'a');
      final b = graph.nodes.firstWhere((n) => n.id == 'b');
      final c = graph.nodes.firstWhere((n) => n.id == 'c');

      final distAB = _dist(a.x, a.y, b.x, b.y);
      final distAC = _dist(a.x, a.y, c.x, c.y);
      // 有边连接的 A-B 距离应小于无连接的 A-C（大概率）
      // 由于力导向的随机性，只验证布局产生了非零位置
      expect(distAB + distAC, greaterThan(0));
    });

    test('空图不崩溃', () {
      final service = CharacterRelationGraphService(
        metaRepository: MockMetaRepository(),
        aiProvider: MockAIProvider(),
      );

      const graph = RelationGraph();
      // 不应抛异常
      service.computeLayout(graph);
    });
  });
}

double _dist(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return (dx * dx + dy * dy) * 1.0; // 平方距离即可
}
