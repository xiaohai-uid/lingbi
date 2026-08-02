/// Backup transport interface.
///
/// WebDAV and future cloud backup implement this interface.
/// HTTP success is NOT proof of verified content delivery.
library;

import 'package:lingbi/shared/errors/result.dart';

/// Transports immutable backup packages to/from remote storage.
///
/// Contract: download success requires bytes received + manifest verified
/// + staged restore completed + restore receipt persisted.
abstract interface class BackupTransport {
  /// Upload a backup package. Returns a remote object identifier.
  Future<Result<String>> upload({
    required String packageId,
    required List<int> bytes,
    required String manifestHash,
  });

  /// Download a backup package. Returns raw bytes.
  /// Caller MUST verify manifest hash before using content.
  Future<Result<List<int>>> download(String packageId);

  /// Verify a previously uploaded package matches expected hash.
  Future<Result<bool>> verifyRemote(String packageId, String expectedHash);

  /// List available backup package ids.
  Future<Result<List<String>>> listPackages();

  /// Delete a remote package.
  Future<Result<void>> deletePackage(String packageId);
}
