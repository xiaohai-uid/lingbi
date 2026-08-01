/// Run event storage interface.
///
/// Defines the contract for persisting and querying Run events.
library;

import 'package:lingbi/domain/runtime/run_models.dart';
import 'package:lingbi/shared/errors/result.dart';

/// Abstract storage for Run events.
abstract interface class RunStore {
  /// Append an event to a Run's history.
  Future<Result<RunEvent>> append(RunEvent event);

  /// Read all events for a Run in sequence order.
  Future<Result<List<RunEvent>>> readAll(String runId);

  /// Read events for a Run starting from a sequence number.
  Future<Result<List<RunEvent>>> readFrom(String runId, int fromSequence);

  /// Validate the hash chain for a Run.
  Future<Result<bool>> validateChain(String runId);

  /// List all known Run ids.
  Future<Result<List<String>>> listRuns();
}
