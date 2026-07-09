import 'package:lingbi/core/models/character_edge.dart';

/// 角色关系图谱节点
class CharacterNode {
  // 'protagonist', 'supporter', 'antagonist'

  const CharacterNode({
    required this.id,
    required this.name,
    this.type = 'supporter',
  });
  factory CharacterNode.fromJson(Map<String, dynamic> json) => CharacterNode(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String? ?? 'supporter',
      );
  final String id;
  final String name;
  final String type;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type};
}

/// 角色关系图谱
class CharacterGraph {
  const CharacterGraph({this.nodes = const [], this.edges = const []});
  final List<CharacterNode> nodes;
  final List<CharacterEdge> edges;

  /// 获取指定角色的所有关系
  List<CharacterEdge> getEdgesFor(String characterId) => edges
      .where((e) => e.sourceId == characterId || e.targetId == characterId)
      .toList();

  /// 获取两个角色之间的关系
  CharacterEdge? getRelationship(String charA, String charB) {
    try {
      return edges.firstWhere(
        (e) =>
            (e.sourceId == charA && e.targetId == charB) ||
            (e.sourceId == charB && e.targetId == charA),
      );
    } catch (_) {
      return null;
    }
  }
}

/// 角色关系图谱服务
class CharacterGraphService {
  CharacterGraph _graph = const CharacterGraph();

  CharacterGraph get graph => _graph;

  void addNode(CharacterNode node) {
    _graph =
        CharacterGraph(nodes: [..._graph.nodes, node], edges: _graph.edges);
  }

  void addEdge(CharacterEdge edge) {
    _graph =
        CharacterGraph(nodes: _graph.nodes, edges: [..._graph.edges, edge]);
  }

  void removeNode(String id) {
    _graph = CharacterGraph(
      nodes: _graph.nodes.where((n) => n.id != id).toList(),
      edges: _graph.edges
          .where((e) => e.sourceId != id && e.targetId != id)
          .toList(),
    );
  }

  void removeEdge(String sourceId, String targetId) {
    _graph = CharacterGraph(
      nodes: _graph.nodes,
      edges: _graph.edges
          .where(
            (e) => !(e.sourceId == sourceId && e.targetId == targetId),
          )
          .toList(),
    );
  }
}
