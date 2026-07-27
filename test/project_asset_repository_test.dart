import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/zvec_service.dart';
import 'package:lingbi/core/models/canon_entry.dart';
import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/services/canon_service.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/services/project_asset_repository.dart';
import 'package:lingbi/services/project_meta_repository.dart';
import 'package:lingbi/services/project_service.dart';
import 'package:lingbi/services/storage_service.dart';

class _MemoryMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> values = {};
  int writes = 0;

  String _key(String projectId, String fileName) => '$projectId/$fileName';

  @override
  Future<Map<String, dynamic>?> read(String projectId, String fileName) async {
    final value = values[_key(projectId, fileName)];
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  @override
  Future<void> write(
    String projectId,
    String fileName,
    Map<String, dynamic> data,
  ) async {
    writes++;
    values[_key(projectId, fileName)] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    values.remove(_key(projectId, fileName));
  }

  @override
  Future<List<String>> list(String projectId) async => values.keys
      .where((key) => key.startsWith('$projectId/'))
      .map((key) => key.split('/').last)
      .toList();

  @override
  Future<String> getMetaDirPath(String projectId) async => projectId;

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
    String projectId,
    WorldConstitution constitution,
  ) async {}
}

void main() {
  test('overview assets have stable IDs and are initialized idempotently',
      () async {
    final meta = _MemoryMetaRepository();
    final repository = ProjectAssetRepository(metaRepository: meta);

    final first = await repository.ensureOverviewAssets('project-1');
    final second = await repository.ensureOverviewAssets('project-1');

    expect(first, hasLength(5));
    expect(second.map((asset) => asset.id), first.map((asset) => asset.id));
    expect(first.map((asset) => asset.type), ProjectAssetType.values);
    expect(first.every((asset) => asset.state == ProjectAssetState.notStarted),
        isTrue);
    expect(meta.writes, 1);
  });

  test('stale asset revision cannot overwrite newer work', () async {
    final repository = ProjectAssetRepository(
      metaRepository: _MemoryMetaRepository(),
    );
    final asset = (await repository.ensureOverviewAssets('project-1')).first;

    final saved = await repository.save(
      asset.copyWith(state: ProjectAssetState.editable),
      expectedRevision: 0,
    );

    expect(saved.revision, 1);
    expect(
      () => repository.save(
        asset.copyWith(state: ProjectAssetState.failed),
        expectedRevision: 0,
      ),
      throwsA(isA<ProjectAssetConflict>()),
    );
  });

  test('round trip preserves source path and state', () async {
    final repository = ProjectAssetRepository(
      metaRepository: _MemoryMetaRepository(),
    );
    final asset = (await repository.ensureOverviewAssets('project-1')).last;

    await repository.save(
      asset.copyWith(
        state: ProjectAssetState.awaitingConfirmation,
        source: ProjectAssetSource.ai,
      ),
      expectedRevision: 0,
    );
    final loaded = await repository.list('project-1');

    expect(loaded.last.storagePath, 'chapters/first-chapter.md');
    expect(loaded.last.state, ProjectAssetState.awaitingConfirmation);
    expect(loaded.last.source, ProjectAssetSource.ai);
  });

  test('rewriting a meta asset keeps one Canon index entry', () async {
    final temp = Directory.systemTemp.createTempSync('lingbi_asset_canon_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final storage = StorageService();
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: '${temp.path}/db');
    final projects = ProjectService(zvecService: zvec);
    final project = await projects.createPortableProject(
      name: '幂等项目',
      directoryPath: '${temp.path}/project',
    );
    final canon = CanonService(zvecService: zvec);
    final meta = ProjectMetaRepository(
      projectService: projects,
      canonService: canon,
    );

    await meta.write(project.id, 'worldbuilding.json', {'summary': '初版'});
    await meta.write(project.id, 'worldbuilding.json', {'summary': '修订版'});
    final indexes = await canon.list(project.id, CanonEntryType.lore);

    expect(indexes.where((entry) => entry.name == 'meta: worldbuilding.json'),
        hasLength(1));
    expect(indexes.single.description, '修订版');
  });
}
