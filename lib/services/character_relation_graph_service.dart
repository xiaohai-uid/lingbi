/// 角色关系图谱可视化
///
/// 力导向关系图数据层：
/// - CharacterRelation 数据模型
/// - 力导向布局算法（计算节点位置）
/// - 关系图管理（增删改查/自动更新）
/// - 关系类型可视化属性映射
library;

import 'dart:convert';
import 'dart:math';

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

// ─── 数据模型 ───

/// 关系类型
enum RelationType {
  family,
  enemy,
  mentor,
  lover,
  friend,
  rival,
  master,
  ally,
  stranger;

  String get label => switch (this) {
        RelationType.family => '亲属',
        RelationType.enemy => '敌对',
        RelationType.mentor => '师徒',
        RelationType.lover => '恋人',
        RelationType.friend => '友人',
        RelationType.rival => '对手',
        RelationType.master => '主仆',
        RelationType.ally => '同盟',
        RelationType.stranger => '陌生',
      };

  /// 可视化颜色（ARGB）
  int get color => switch (this) {
        RelationType.family => 0xFF4CAF50,
        RelationType.enemy => 0xFFF44336,
        RelationType.mentor => 0xFF2196F3,
        RelationType.lover => 0xFFE91E63,
        RelationType.friend => 0xFF8BC34A,
        RelationType.rival => 0xFFFF9800,
        RelationType.master => 0xFF9C27B0,
        RelationType.ally => 0xFF00BCD4,
        RelationType.stranger => 0xFF9E9E9E,
      };

  /// 是否虚线
  bool get isDashed =>
      this == RelationType.stranger || this == RelationType.rival;

  static RelationType fromString(String s) {
    return RelationType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => RelationType.stranger,
    );
  }
}

/// 角色关系
class CharacterRelation {
  const CharacterRelation({
    required this.fromId,
    required this.toId,
    required this.relationType,
    this.description = '',
    this.sinceChapter = 0,
    this.weight = 1.0,
  });

  factory CharacterRelation.fromJson(Map<String, dynamic> json) {
    return CharacterRelation(
      fromId: json['from_id'] as String? ?? '',
      toId: json['to_id'] as String? ?? '',
      relationType:
          RelationType.fromString(json['relation_type'] as String? ?? ''),
      description: json['description'] as String? ?? '',
      sinceChapter: json['since_chapter'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  final String fromId;
  final String toId;
  final RelationType relationType;
  final String description;
  final int sinceChapter;

  /// 关系强度（影响力导向布局中的弹簧刚度）
  final double weight;

  Map<String, dynamic> toJson() => {
        'from_id': fromId,
        'to_id': toId,
        'relation_type': relationType.name,
        'description': description,
        'since_chapter': sinceChapter,
        'weight': weight,
      };

  /// 关系是否涉及指定角色
  bool involves(String characterId) =>
      fromId == characterId || toId == characterId;
}

/// 图节点（含布局位置）
class GraphNode {
  GraphNode({
    required this.id,
    required this.label,
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
    this.isProtagonist = false,
    this.group = '',
  });

  final String id;
  final String label;
  double x;
  double y;
  double vx;
  double vy;
  final bool isProtagonist;
  final String group;

  /// 节点半径（主角更大）
  double get radius => isProtagonist ? 24 : 16;
}

/// 图边
class GraphEdge {
  const GraphEdge({
    required this.relation,
  });

  final CharacterRelation relation;

  String get fromId => relation.fromId;
  String get toId => relation.toId;
}

/// 关系图谱快照
class RelationGraph {
  const RelationGraph({
    this.nodes = const [],
    this.edges = const [],
    this.lastUpdatedChapter = 0,
  });

  factory RelationGraph.fromJson(Map<String, dynamic> json) {
    return RelationGraph(
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => _nodeFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => GraphEdge(
                  relation:
                      CharacterRelation.fromJson(e as Map<String, dynamic>)))
              .toList() ??
          [],
      lastUpdatedChapter: json['last_updated_chapter'] as int? ?? 0,
    );
  }

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final int lastUpdatedChapter;

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map(_nodeToJson).toList(),
        'edges': edges.map((e) => e.relation.toJson()).toList(),
        'last_updated_chapter': lastUpdatedChapter,
      };

  static GraphNode _nodeFromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      isProtagonist: json['is_protagonist'] as bool? ?? false,
      group: json['group'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _nodeToJson(GraphNode n) => {
        'id': n.id,
        'label': n.label,
        'x': n.x,
        'y': n.y,
        'is_protagonist': n.isProtagonist,
        'group': n.group,
      };
}

// ─── 力导向布局 ───

/// 力导向布局参数
class ForceLayoutConfig {
  const ForceLayoutConfig({
    this.repulsionStrength = 5000,
    this.attractionStrength = 0.01,
    this.damping = 0.9,
    this.iterations = 100,
    this.minDistance = 50,
  });

  /// 斥力强度（节点间）
  final double repulsionStrength;

  /// 引力强度（边连接的节点间）
  final double attractionStrength;

  /// 速度衰减
  final double damping;

  /// 迭代次数
  final int iterations;

  /// 最小节点间距
  final double minDistance;
}

// ─── 服务 ───

/// 角色关系图谱服务
class CharacterRelationGraphService {
  CharacterRelationGraphService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  set aiProvider(AIProvider provider) => _aiProvider = provider;

  static const _storageKey = 'relation_graph';

  // ─── 1. 图谱 CRUD ───

  /// 加载项目关系图
  Future<RelationGraph> loadGraph(String projectId) async {
    final data = await _metaRepository.read(projectId, _storageKey);
    if (data == null) return const RelationGraph();
    return RelationGraph.fromJson(data);
  }

  /// 保存关系图
  Future<void> saveGraph(String projectId, RelationGraph graph) async {
    await _metaRepository.write(projectId, _storageKey, graph.toJson());
  }

  /// 添加角色节点
  Future<RelationGraph> addNode(
    String projectId, {
    required String id,
    required String label,
    bool isProtagonist = false,
    String group = '',
  }) async {
    final graph = await loadGraph(projectId);
    if (graph.nodes.any((n) => n.id == id)) return graph;

    final nodes = [
      ...graph.nodes,
      GraphNode(
        id: id,
        label: label,
        isProtagonist: isProtagonist,
        group: group,
      ),
    ];

    final updated = RelationGraph(
      nodes: nodes,
      edges: graph.edges,
      lastUpdatedChapter: graph.lastUpdatedChapter,
    );
    await saveGraph(projectId, updated);
    return updated;
  }

  /// 添加关系边
  Future<RelationGraph> addRelation(
    String projectId,
    CharacterRelation relation,
  ) async {
    final graph = await loadGraph(projectId);

    // 去重：同一对角色的同类型关系不重复添加
    final exists = graph.edges.any((e) =>
        e.relation.fromId == relation.fromId &&
        e.relation.toId == relation.toId &&
        e.relation.relationType == relation.relationType);
    if (exists) return graph;

    final edges = [...graph.edges, GraphEdge(relation: relation)];
    final updated = RelationGraph(
      nodes: graph.nodes,
      edges: edges,
      lastUpdatedChapter: graph.lastUpdatedChapter,
    );
    await saveGraph(projectId, updated);
    return updated;
  }

  /// 移除关系
  Future<RelationGraph> removeRelation(
    String projectId, {
    required String fromId,
    required String toId,
  }) async {
    final graph = await loadGraph(projectId);
    final edges = graph.edges
        .where((e) => !(e.relation.fromId == fromId && e.relation.toId == toId))
        .toList();

    final updated = RelationGraph(
      nodes: graph.nodes,
      edges: edges,
      lastUpdatedChapter: graph.lastUpdatedChapter,
    );
    await saveGraph(projectId, updated);
    return updated;
  }

  /// 获取角色所有关系
  Future<List<CharacterRelation>> getRelationsForCharacter(
    String projectId,
    String characterId,
  ) async {
    final graph = await loadGraph(projectId);
    return graph.edges
        .where((e) => e.relation.involves(characterId))
        .map((e) => e.relation)
        .toList();
  }

  /// 获取高亮关联角色（点击节点时）
  Future<List<String>> getConnectedCharacters(
    String projectId,
    String characterId,
  ) async {
    final graph = await loadGraph(projectId);
    final connected = <String>{};
    for (final edge in graph.edges) {
      if (edge.relation.fromId == characterId) {
        connected.add(edge.relation.toId);
      } else if (edge.relation.toId == characterId) {
        connected.add(edge.relation.fromId);
      }
    }
    return connected.toList();
  }

  // ─── 2. 自动更新（从章节提取） ───

  /// 从章节文本中提取角色关系变化
  Future<List<CharacterRelation>> extractRelationsFromChapter({
    required String chapterText,
    required int chapterIndex,
    List<String> knownCharacters = const [],
  }) async {
    if (chapterText.trim().isEmpty) return [];

    try {
      final charHint = knownCharacters.isNotEmpty
          ? '已知角色: ${knownCharacters.join(", ")}'
          : '';

      final response = await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
            role: 'system',
            content: '你是小说分析专家。从章节文本中提取角色间关系。'
                '输出 JSON 数组，每项含 from_id/to_id/relation_type/description 字段。'
                'relation_type 可选: family/enemy/mentor/lover/friend/rival/master/ally/stranger。',
          ),
          ChatMessage(
            role: 'user',
            content: '$charHint\n\n分析第$chapterIndex章:\n$chapterText',
          ),
        ],
      );

      return _parseRelations(response, chapterIndex);
    } catch (_) {
      return [];
    }
  }

  /// 更新图谱（合并新提取的关系）
  Future<RelationGraph> updateFromChapter({
    required String projectId,
    required int chapterIndex,
    required List<CharacterRelation> newRelations,
  }) async {
    var graph = await loadGraph(projectId);

    for (final rel in newRelations) {
      // 确保节点存在
      if (!graph.nodes.any((n) => n.id == rel.fromId)) {
        graph = RelationGraph(
          nodes: [...graph.nodes, GraphNode(id: rel.fromId, label: rel.fromId)],
          edges: graph.edges,
          lastUpdatedChapter: graph.lastUpdatedChapter,
        );
      }
      if (!graph.nodes.any((n) => n.id == rel.toId)) {
        graph = RelationGraph(
          nodes: [...graph.nodes, GraphNode(id: rel.toId, label: rel.toId)],
          edges: graph.edges,
          lastUpdatedChapter: graph.lastUpdatedChapter,
        );
      }

      // 添加边（去重）
      final exists = graph.edges.any((e) =>
          e.relation.fromId == rel.fromId &&
          e.relation.toId == rel.toId &&
          e.relation.relationType == rel.relationType);
      if (!exists) {
        graph = RelationGraph(
          nodes: graph.nodes,
          edges: [...graph.edges, GraphEdge(relation: rel)],
          lastUpdatedChapter: graph.lastUpdatedChapter,
        );
      }
    }

    // 更新章节标记
    final updated = RelationGraph(
      nodes: graph.nodes,
      edges: graph.edges,
      lastUpdatedChapter: chapterIndex,
    );
    await saveGraph(projectId, updated);
    return updated;
  }

  // ─── 3. 力导向布局 ───

  /// 计算力导向布局位置
  void computeLayout(
    RelationGraph graph, {
    ForceLayoutConfig config = const ForceLayoutConfig(),
    double width = 800,
    double height = 600,
  }) {
    final nodes = graph.nodes;
    if (nodes.isEmpty) return;

    final rng = Random(42); // 固定种子保证确定性

    // 初始化随机位置
    for (final node in nodes) {
      if (node.x == 0 && node.y == 0) {
        node.x = rng.nextDouble() * width;
        node.y = rng.nextDouble() * height;
      }
    }

    // 迭代
    for (var iter = 0; iter < config.iterations; iter++) {
      // 斥力（所有节点对）
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          _applyRepulsion(nodes[i], nodes[j], config);
        }
      }

      // 引力（边连接的节点）
      for (final edge in graph.edges) {
        final from = nodes.where((n) => n.id == edge.fromId).firstOrNull;
        final to = nodes.where((n) => n.id == edge.toId).firstOrNull;
        if (from != null && to != null) {
          _applyAttraction(from, to, config, edge.relation.weight);
        }
      }

      // 更新位置
      for (final node in nodes) {
        node.vx *= config.damping;
        node.vy *= config.damping;
        node.x += node.vx;
        node.y += node.vy;

        // 边界约束
        node.x = node.x.clamp(0, width);
        node.y = node.y.clamp(0, height);
      }
    }
  }

  void _applyRepulsion(GraphNode a, GraphNode b, ForceLayoutConfig config) {
    var dx = a.x - b.x;
    var dy = a.y - b.y;
    var dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) {
      dx = 1;
      dy = 0;
      dist = 1;
    }
    if (dist < config.minDistance) dist = config.minDistance;

    final force = config.repulsionStrength / (dist * dist);
    final fx = (dx / dist) * force;
    final fy = (dy / dist) * force;

    a.vx += fx;
    a.vy += fy;
    b.vx -= fx;
    b.vy -= fy;
  }

  void _applyAttraction(
      GraphNode a, GraphNode b, ForceLayoutConfig config, double weight) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    final force = config.attractionStrength * dist * weight;
    final fx = (dx / dist) * force;
    final fy = (dy / dist) * force;

    a.vx += fx;
    a.vy += fy;
    b.vx -= fx;
    b.vy -= fy;
  }

  // ─── 辅助 ───

  List<CharacterRelation> _parseRelations(String response, int chapter) {
    try {
      var cleaned = response.trim();
      if (cleaned.startsWith('```')) {
        final firstNewline = cleaned.indexOf('\n');
        if (firstNewline != -1) cleaned = cleaned.substring(firstNewline + 1);
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.length - 3);
        }
        cleaned = cleaned.trim();
      }

      final list = jsonDecode(cleaned) as List<dynamic>;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        return CharacterRelation(
          fromId: map['from_id'] as String? ?? '',
          toId: map['to_id'] as String? ?? '',
          relationType:
              RelationType.fromString(map['relation_type'] as String? ?? ''),
          description: map['description'] as String? ?? '',
          sinceChapter: chapter,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
