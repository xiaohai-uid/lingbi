/// Node-level recovery state for Fusion module F.
///
/// This is a semantic layer over the existing checkpoint/event sequence:
/// it freezes the workflow version and inputs, tracks per-node attempts,
/// and determines the next node to resume.
final class NodeRecoveryState {
  NodeRecoveryState({
    required this.runId,
    required this.workflowVersion,
    required this.nodeIds,
    this.completedNodeIds = const {},
    Map<String, int> nodeAttempts = const {},
    this.frozenInputs = const {},
    int? frozenWorkflowVersion,
  })  : frozenWorkflowVersion = frozenWorkflowVersion ?? workflowVersion,
        nodeAttempts = Map<String, int>.from(nodeAttempts);

  factory NodeRecoveryState.fromJson(Map<String, dynamic> json) {
    return NodeRecoveryState(
      runId: json['runId'] as String,
      workflowVersion: json['workflowVersion'] as int,
      frozenWorkflowVersion: json['frozenWorkflowVersion'] as int?,
      nodeIds: (json['nodeIds'] as List<dynamic>).cast<String>(),
      completedNodeIds: (json['completedNodeIds'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      nodeAttempts: (json['nodeAttempts'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as int)),
      frozenInputs: json['frozenInputs'] as Map<String, dynamic>? ?? {},
    );
  }

  final String runId;

  /// Current workflow definition version.
  final int workflowVersion;

  /// Workflow definition version frozen when this run started.
  final int frozenWorkflowVersion;

  final List<String> nodeIds;
  final Set<String> completedNodeIds;
  final Map<String, int> nodeAttempts;
  final Map<String, dynamic> frozenInputs;

  /// First node that has not completed; null when all nodes are done.
  String? get nextNodeId {
    for (final nodeId in nodeIds) {
      if (!completedNodeIds.contains(nodeId)) return nodeId;
    }
    return null;
  }

  void recordAttempt(String nodeId) {
    nodeAttempts[nodeId] = (nodeAttempts[nodeId] ?? 0) + 1;
  }

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'workflowVersion': workflowVersion,
        'frozenWorkflowVersion': frozenWorkflowVersion,
        'nodeIds': nodeIds,
        'completedNodeIds': completedNodeIds.toList(),
        'nodeAttempts': nodeAttempts,
        'frozenInputs': frozenInputs,
      };
}
