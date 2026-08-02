/// Interface for verified backup restore pipeline.
///
/// See ADR-010 (origin: restore) and StagedRestoreService for implementation.
library;

import 'package:lingbi/shared/errors/result.dart';

/// Receipt proving a verified restore completed.
abstract interface class RestoreReceiptBase {
  String get packageId;
  String get manifestHash;
  List<String> get appliedPaths;
  DateTime get restoredAt;
}

/// The interface through which project restore from backup flows.
abstract interface class StagedRestore {
  /// Full restore pipeline: download → verify → stage → apply → receipt.
  Future<Result<RestoreReceiptBase>> restore({
    required String packageId,
    required String expectedManifestHash,
    required String projectId,
  });
}
