import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/atomic_file_store.dart';

void main() {
  test('atomic write replaces content and retains a readable backup', () async {
    final dir = await Directory.systemTemp.createTemp('lingbi_atomic_');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/chapter.md';
    await File(path).writeAsString('old');

    await AtomicFileStore().writeString(path, 'new');

    expect(await File(path).readAsString(), 'new');
    expect(await File('$path.bak').readAsString(), 'old');
  });

  test('failed replacement restores the original and removes temp data',
      () async {
    final dir = await Directory.systemTemp.createTemp('lingbi_atomic_fail_');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/chapter.md';
    await File(path).writeAsString('safe');
    final store = AtomicFileStore(
      replace: (_, __) async => throw const FileSystemException('injected'),
    );

    await expectLater(
      store.writeString(path, 'unsafe'),
      throwsA(isA<FileSystemException>()),
    );

    expect(await File(path).readAsString(), 'safe');
    expect(File('$path.tmp').existsSync(), isFalse);
  });

  test('readString recovers from backup when primary is unreadable json',
      () async {
    final dir = await Directory.systemTemp.createTemp('lingbi_atomic_recover_');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/state.json';
    await File(path).writeAsString('{broken');
    await File('$path.bak').writeAsString('{"ok":true}');

    final recovered = await AtomicFileStore().readString(
      path,
      validator: (value) => value.trim().endsWith('}'),
    );

    expect(recovered, '{"ok":true}');
  });
}
