import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/project/data/project_service.dart';

void main() {
  late Directory sandbox;
  late Directory oldRoot;
  late Directory newRoot;
  late ProjectService service;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('lingbi_storage_');
    oldRoot = Directory('${sandbox.path}${Platform.pathSeparator}old');
    newRoot = Directory('${sandbox.path}${Platform.pathSeparator}new');
    await oldRoot.create(recursive: true);
    service = ProjectService();
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test('discovers portable projects without ZVec and updates portable metadata',
      () async {
    final projectDir = '${oldRoot.path}${Platform.pathSeparator}novel';
    final project = await service.createPortableProject(
      name: '迁移测试',
      directoryPath: projectDir,
    );
    final chapter = File(
      '$projectDir${Platform.pathSeparator}chapter.md',
    );
    await chapter.writeAsString('# 第一章');

    final result = await service.migratePortableProjects(
      oldRoot: oldRoot.path,
      newRoot: newRoot.path,
    );

    final migratedDir = '${newRoot.path}${Platform.pathSeparator}novel';
    result.when(
      success: (summary) {
        expect(summary.migrated, 1);
        expect(summary.failed, 0);
      },
      failure: (error) => fail(error.message),
    );
    expect(await Directory(projectDir).exists(), isFalse);
    expect(
        await File('$migratedDir${Platform.pathSeparator}chapter.md').exists(),
        isTrue);

    final metadata = jsonDecode(await File(
      '$migratedDir${Platform.pathSeparator}.lingbi'
      '${Platform.pathSeparator}project.json',
    ).readAsString()) as Map<String, dynamic>;
    expect(metadata['directoryPath'], migratedDir);

    final reopened = await service.openPortableProject(migratedDir);
    expect(reopened.project.id, project.id);
    expect(reopened.project.directoryPath, migratedDir);
  });

  test('does not overwrite a collision and keeps the source project intact',
      () async {
    final projectDir = '${oldRoot.path}${Platform.pathSeparator}novel';
    await service.createPortableProject(
      name: '迁移测试',
      directoryPath: projectDir,
    );
    final targetDir = '${newRoot.path}${Platform.pathSeparator}novel';
    await Directory(targetDir).create(recursive: true);
    await File('$targetDir${Platform.pathSeparator}keep.txt')
        .writeAsString('keep');

    final result = await service.migratePortableProjects(
      oldRoot: oldRoot.path,
      newRoot: newRoot.path,
    );

    result.when(
      success: (summary) {
        expect(summary.migrated, 0);
        expect(summary.failed, 1);
      },
      failure: (error) => fail(error.message),
    );
    expect(await Directory(projectDir).exists(), isTrue);
    expect(
      await File('$targetDir${Platform.pathSeparator}keep.txt').readAsString(),
      'keep',
    );
  });

  test('opens a directory with stale metadata after an interrupted move',
      () async {
    final projectDir = '${oldRoot.path}${Platform.pathSeparator}novel';
    final project = await service.createPortableProject(
      name: '中断恢复测试',
      directoryPath: projectDir,
    );
    final targetDir = '${newRoot.path}${Platform.pathSeparator}novel';
    await newRoot.create(recursive: true);
    // Simulate a process exit after rename but before project.json update.
    await Directory(projectDir).rename(targetDir);

    final reopened = await service.openPortableProject(targetDir);
    expect(reopened.project.id, project.id);
    expect(reopened.project.directoryPath, targetDir);
    final discovered = await service.discoverPortableProjects(newRoot.path);
    expect(discovered.single.directoryPath, targetDir);
  });
}
