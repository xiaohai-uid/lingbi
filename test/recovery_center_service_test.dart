import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/recovery_center_service.dart';

void main() {
  test('soft delete is discoverable and can be restored', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_recovery_');
    addTearDown(() => root.delete(recursive: true));
    final original = File('${root.path}/chapter.md');
    await original.writeAsString('chapter');
    final service = RecoveryCenterService();

    final deleted = await service.softDelete(root.path, original.path);
    expect(original.existsSync(), isFalse);

    final items = await service.scan(root.path);
    expect(items.map((item) => item.path), contains(deleted.path));
    final trash =
        items.firstWhere((item) => item.type == RecoveryItemType.trash);
    await service.restore(trash);

    expect(await original.readAsString(), 'chapter');
  });

  test('scan unifies candidates versions snapshots and trash', () async {
    final root = await Directory.systemTemp.createTemp('lingbi_recovery_scan_');
    addTearDown(() => root.delete(recursive: true));
    for (final path in [
      '.lingbi/candidates/a.md',
      '.lingbi/versions/doc/v1.md',
      '.lingbi/snapshots/s1.md',
    ]) {
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(path);
    }

    final types = (await RecoveryCenterService().scan(root.path))
        .map((item) => item.type)
        .toSet();
    expect(
        types,
        containsAll(<RecoveryItemType>{
          RecoveryItemType.candidate,
          RecoveryItemType.version,
          RecoveryItemType.snapshot,
        }));
  });
}
