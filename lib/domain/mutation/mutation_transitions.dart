/// Pure state-machine transitions for CandidateChange.
///
/// Domain-layer — no Flutter, no dart:io, no side effects.
/// See ADR-010 for legal transitions and terminal-state rules.
library;

import 'package:lingbi/domain/mutation/mutation_models.dart';

/// Events that may be applied to a CandidateChange.
enum CandidateEvent {
  approve,
  reject,
  commit,
  supersede,
}

/// Result of a transition attempt. Pure value — no exceptions thrown.
final class MutationTransitionResult {
  const MutationTransitionResult._({
    required this.success,
    this.candidate,
    this.error,
  });

  factory MutationTransitionResult.ok(CandidateChange candidate) =>
      MutationTransitionResult._(success: true, candidate: candidate);

  factory MutationTransitionResult.fail(String error) =>
      MutationTransitionResult._(success: false, error: error);

  final bool success;

  /// The new candidate record if the transition succeeded.
  final CandidateChange? candidate;

  /// A typed error code if the transition was rejected.
  final String? error;
}

/// Legal transition table:
///   proposed  → approved, rejected, superseded
///   approved  → committed, superseded
///   rejected  → (terminal)
///   committed → (terminal)
///   superseded → (terminal)
const Map<CandidateState, Set<CandidateState>> _legalTransitions = {
  CandidateState.proposed: {
    CandidateState.approved,
    CandidateState.rejected,
    CandidateState.superseded,
  },
  CandidateState.approved: {
    CandidateState.committed,
    CandidateState.superseded,
  },
  CandidateState.rejected: {},
  CandidateState.committed: {},
  CandidateState.superseded: {},
};

/// Maps an event to its target state.
CandidateState _targetState(CandidateEvent event) => switch (event) {
      CandidateEvent.approve => CandidateState.approved,
      CandidateEvent.reject => CandidateState.rejected,
      CandidateEvent.commit => CandidateState.committed,
      CandidateEvent.supersede => CandidateState.superseded,
    };

/// Attempts a pure state transition on a CandidateChange.
///
/// Returns a new immutable record on success; the original is unchanged.
/// Returns a typed failure on illegal transitions without throwing.
MutationTransitionResult transitionCandidate(
  CandidateChange current,
  CandidateEvent event,
) {
  final target = _targetState(event);
  final allowed = _legalTransitions[current.state] ?? {};

  if (!allowed.contains(target)) {
    return MutationTransitionResult.fail(
      'ILLEGAL_TRANSITION: ${current.state.wireName} → ${target.wireName}',
    );
  }

  return MutationTransitionResult.ok(current.withState(target));
}
