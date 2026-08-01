/// Checkpoint storage interface.
library;

import 'package:lingbi/domain/runtime/checkpoint.dart';
import 'package:lingbi/shared/errors/result.dart';

/// Persists and retrieves Run checkpoints for crash recovery.
abstract interface class CheckpointStore {
  /// Save a checkpoint for a Run (overwrites previous).
  Future<Result<void>> save(Checkpoint checkpoint);

  /// Load the latest checkpoint for a Run.
  Future<Result<Checkpoint?>> load(String runId);

  /// Delete checkpoint after successful Run completion.
  Future<Result<void>> delete(String runId);
}
