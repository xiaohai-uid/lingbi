import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ffi/rust_core.dart';
import 'package:lingbi/src/rust/api/project.dart';

const rustLibraryPath = String.fromEnvironment('LINGBI_FFI_DLL');

void main() {
  test('Flutter stores documents through Rust Core FFI', () async {
    final fixture = '${Directory.current.path}/test/fixtures/project_v2';
    final temp = Directory.systemTemp.createTempSync('lingbi_rust_storage_');
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });
    _copyDirectory(fixture, temp.path);

    final documents = await RustCore.listDocuments(
      temp.path,
      libraryPath: rustLibraryPath,
    );
    expect(documents.length, 1);
    final document = documents.single;
    expect(document.title, '第一章');
    expect(document.revision, 0);
    expect(
      await RustCore.readDocument(
        temp.path,
        document.id,
        libraryPath: rustLibraryPath,
      ),
      '# 第一章\n\nV2 fixture content.\n',
    );

    final saved = await RustCore.saveDocument(
      temp.path,
      document.id,
      document.revision,
      '# 第一章\n\nRust bridge storage update.\n',
      libraryPath: rustLibraryPath,
    );
    expect(saved.revision, 1);
    expect(saved.contentHash, isNot(document.contentHash));
    expect(
      await RustCore.readDocument(
        temp.path,
        saved.id,
        libraryPath: rustLibraryPath,
      ),
      '# 第一章\n\nRust bridge storage update.\n',
    );

    final reopened = await RustCore.openProject(
      temp.path,
      libraryPath: rustLibraryPath,
    );
    expect(reopened.currentDocument.contentHash, saved.contentHash);

    final created = await RustCore.createDocument(
      temp.path,
      reopened.project.id,
      '第二章',
      '# 第二章\n\nNew document.\n',
      libraryPath: rustLibraryPath,
    );
    expect(created.title, '第二章');
    expect(created.order, 1);
    expect(created.revision, 0);

    final allDocuments = await RustCore.listDocuments(
      temp.path,
      libraryPath: rustLibraryPath,
    );
    expect(allDocuments.length, 2);

    await expectLater(
      RustCore.saveDocument(
        temp.path,
        saved.id,
        0,
        'stale revision',
        libraryPath: rustLibraryPath,
      ),
      throwsA(
        isA<RustAppError>().having((error) => error.code, 'code', 'DocumentConflict'),
      ),
    );
  }, skip: rustLibraryPath.isEmpty ? 'LINGBI_FFI_DLL 未设置' : false);
}

void _copyDirectory(String source, String destination) {
  Directory(destination).createSync(recursive: true);
  for (final entity in Directory(source).listSync(recursive: true)) {
    final relative = entity.path.substring(source.length + 1);
    final target = '$destination/$relative';
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      File(entity.path).copySync(target);
    }
  }
}
