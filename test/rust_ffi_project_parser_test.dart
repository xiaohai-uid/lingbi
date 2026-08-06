import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ffi/rust_core.dart';

const rustLibraryPath = String.fromEnvironment('LINGBI_FFI_DLL');

void main() {
  test('Flutter opens Project V2 through Rust Core FFI', () async {
    final fixture = '${Directory.current.path}/test/fixtures/project_v2';
    final session = await RustCore.openProject(
      fixture,
      libraryPath: rustLibraryPath,
    );

    expect(session.project.name, 'V2兼容测试');
    expect(session.project.schemaVersion, 2);
    expect(session.currentDocument.title, '第一章');
    expect(session.currentDocument.revision, 0);
    expect(
      session.currentDocument.contentHash,
      'd0da102ac737390ab5fc1192ee43ae82d672c410cefcfa0366690d66833ea320',
    );
  }, skip: rustLibraryPath.isEmpty ? 'LINGBI_FFI_DLL 未设置' : false);
}
