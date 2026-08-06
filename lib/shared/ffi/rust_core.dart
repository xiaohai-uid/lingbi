import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import '../../src/rust/api/project.dart' as rust_project;
import '../../src/rust/frb_generated.dart';

/// Thin Flutter entrypoint for the Rust Core bridge.
///
/// The first call initializes flutter_rust_bridge. Tests and development
/// builds may pass an explicit DLL path; production builds will use the
/// bundled library loader once Cargokit is wired into the Windows build.
class RustCore {
  RustCore._();

  static bool _initialized = false;

  static Future<void> ensureInitialized({String? libraryPath}) async {
    if (_initialized) return;
    await RustLib.init(
      externalLibrary:
          libraryPath == null ? null : ExternalLibrary.open(libraryPath),
    );
    _initialized = true;
  }

  static Future<rust_project.RustProjectSession> openProject(
    String root, {
    String? libraryPath,
  }) async {
    await ensureInitialized(libraryPath: libraryPath);
    return rust_project.openProject(root: root);
  }

  static Future<int> schemaVersion({String? libraryPath}) async {
    await ensureInitialized(libraryPath: libraryPath);
    return rust_project.projectV2SchemaVersion();
  }
}
