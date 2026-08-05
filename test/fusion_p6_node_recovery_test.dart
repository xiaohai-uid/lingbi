import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/domain/runtime/node_recovery.dart';

void main() {
  test('recovery skips completed nodes and resumes last failed node', () {
    final state = NodeRecoveryState(
      runId: 'run-1',
      workflowVersion: 2,
      nodeIds: const ['context', 'draft', 'gate', 'candidate'],
      completedNodeIds: const {'context'},
      nodeAttempts: const {'draft': 1},
      frozenInputs: const {'document': '前文'},
    );

    expect(state.nextNodeId, 'draft');
  });

  test('per-node attempts stay independent', () {
    final state = NodeRecoveryState(
      runId: 'run-2',
      workflowVersion: 1,
      nodeIds: const ['draft', 'gate'],
    );

    state.recordAttempt('draft');
    state.recordAttempt('draft');
    state.recordAttempt('gate');

    expect(state.nodeAttempts['draft'], 2);
    expect(state.nodeAttempts['gate'], 1);
  });

  test('frozen inputs survive restart serialization', () {
    final state = NodeRecoveryState(
      runId: 'run-3',
      workflowVersion: 3,
      nodeIds: const ['context', 'draft'],
      completedNodeIds: const {'context'},
      nodeAttempts: const {'draft': 2},
      frozenInputs: const {'canon': '正典快照'},
    );

    final restored = NodeRecoveryState.fromJson(state.toJson());

    expect(restored.frozenInputs['canon'], '正典快照');
    expect(restored.workflowVersion, 3);
    expect(restored.nextNodeId, 'draft');
  });

  test('workflow version freeze survives definition changes', () {
    final frozen = NodeRecoveryState(
      runId: 'run-4',
      workflowVersion: 4,
      nodeIds: const ['context', 'draft'],
    );

    // Simulate a later workflow definition with different nodes.
    final changed = NodeRecoveryState(
      runId: 'run-4',
      workflowVersion: 5,
      nodeIds: const ['new-node'],
      frozenWorkflowVersion: frozen.workflowVersion,
    );

    expect(changed.frozenWorkflowVersion, 4);
  });
}
