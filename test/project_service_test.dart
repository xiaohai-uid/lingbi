import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/database/zvec_service.dart';

void main() {
  test('opening a moved project refreshes its registered current directory',
      () async {
    final sandbox = await Directory.systemTemp.createTemp('lingbi_project_');
    addTearDown(() async {
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
    });

    final storage = StorageService();
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: '${sandbox.path}/registry');
    final service = ProjectService(zvecService: zvec);
    final oldRoot = Directory('${sandbox.path}/old-project');
    final newRoot = Directory('${sandbox.path}/new-project');
    final project = await service.createPortableProject(
      name: '可移动项目',
      directoryPath: oldRoot.path,
    );

    await oldRoot.rename(newRoot.path);
    final opened = await service.openPortableProject(newRoot.path);
    final registered = await service.getProject(project.id);

    expect(opened.project.id, project.id);
    expect(registered, isNotNull);
    expect(registered!.directoryPath, newRoot.path);
  });
}
