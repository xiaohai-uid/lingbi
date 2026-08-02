/// Pure Run status transition function.
///
/// Domain-layer — no Flutter, no dart:io, no side effects.
library;

import 'package:lingbi/domain/runtime/run_models.dart';

/// Triggers that may be applied to a Run status.
enum RunTrigger {
  start,
  awaitProvider,
  awaitApproval,
  beginCommit,
  resume,
  succeed,
  fail,
  cancel,
  interrupt,
}

/// Result of a Run status transition attempt.
final class RunTransitionResult {
  const RunTransitionResult._({
    required this.success,
    this.status,
    this.error,
  });

  factory RunTransitionResult.ok(RunStatus status) =>
      RunTransitionResult._(success: true, status: status);

  factory RunTransitionResult.fail(String error) =>
      RunTransitionResult._(success: false, error: error);

  final bool success;
  final RunStatus? status;
  final String? error;
}

/// Legal transition table per the plan specification.
const Map<RunStatus, Map<RunTrigger, RunStatus>> _transitions = {
  RunStatus.queued: {
    RunTrigger.start: RunStatus.running,
    RunTrigger.cancel: RunStatus.cancelled,
  },
  RunStatus.running: {
    RunTrigger.awaitProvider: RunStatus.waitingProvider,
    RunTrigger.awaitApproval: RunStatus.waitingApproval,
    RunTrigger.beginCommit: RunStatus.committing,
    RunTrigger.fail: RunStatus.failed,
    RunTrigger.cancel: RunStatus.cancelled,
    RunTrigger.interrupt: RunStatus.interrupted,
  },
  RunStatus.waitingProvider: {
    RunTrigger.resume: RunStatus.running,
    RunTrigger.fail: RunStatus.failed,
    RunTrigger.cancel: RunStatus.cancelled,
    RunTrigger.interrupt: RunStatus.interrupted,
  },
  RunStatus.waitingApproval: {
    RunTrigger.resume: RunStatus.running,
    RunTrigger.beginCommit: RunStatus.committing,
    RunTrigger.cancel: RunStatus.cancelled,
    RunTrigger.interrupt: RunStatus.interrupted,
  },
  RunStatus.committing: {
    RunTrigger.succeed: RunStatus.succeeded,
    RunTrigger.fail: RunStatus.failed,
    RunTrigger.interrupt: RunStatus.interrupted,
  },
  RunStatus.interrupted: {
    RunTrigger.resume: RunStatus.running,
    RunTrigger.fail: RunStatus.failed,
    RunTrigger.cancel: RunStatus.cancelled,
  },
  RunStatus.succeeded: {},
  RunStatus.failed: {},
  RunStatus.cancelled: {},
};

/// Attempts a pure Run status transition.
RunTransitionResult transitionRun(RunStatus current, RunTrigger trigger) {
  final allowed = _transitions[current] ?? {};
  final target = allowed[trigger];

  if (target == null) {
    return RunTransitionResult.fail(
      'ILLEGAL_TRANSITION: ${current.wireName} + ${trigger.name}',
    );
  }

  return RunTransitionResult.ok(target);
}
