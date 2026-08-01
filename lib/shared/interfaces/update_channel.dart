/// Update channel port — upgrade seam for signed remote updates.
///
/// Local pilot: reports manual update available.
/// Future: SignedRemoteUpdateChannel replaces this.
library;

import 'package:lingbi/shared/errors/result.dart';

/// Information about an available update.
final class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    this.releaseNotes,
    this.downloadUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final String? releaseNotes;
  final String? downloadUrl;
}

/// Checks for application updates.
abstract interface class UpdateChannel {
  /// Check if an update is available.
  Future<Result<UpdateInfo>> checkForUpdate();

  /// Get the current app version.
  String get currentVersion;
}
