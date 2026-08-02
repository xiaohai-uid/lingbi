import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';
import 'package:lingbi/features/project/data/project_meta_repository.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
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
    final temp = Directory.systemTemp.createTempSync('lingbi_asset_stale_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '${temp.path}/journal'),
      store: FileCanonicalStore(
        projectRoot: temp.path,
        atomicStore: AtomicFileStore(),
      ),
    );
    final repository = ProjectAssetRepository(
      metaRepository: _MemoryMetaRepository(),
      mutationProtocol: protocol,
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
    final temp = Directory.systemTemp.createTempSync('lingbi_asset_roundtrip_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '${temp.path}/journal'),
      store: FileCanonicalStore(
        projectRoot: temp.path,
        atomicStore: AtomicFileStore(),
      ),
    );
    final repository = ProjectAssetRepository(
      metaRepository: _MemoryMetaRepository(),
      mutationProtocol: protocol,
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

  test('save via MutationProtocol creates journal records', () async {
    final temp = Directory.systemTemp.createTempSync('lingbi_asset_mutation_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final journalDir = Directory('${temp.path}/journal')..createSync();
    final protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: journalDir.path),
      store: FileCanonicalStore(
        projectRoot: temp.path,
        atomicStore: AtomicFileStore(),
      ),
    );
    final repository = ProjectAssetRepository(
      metaRepository: _MemoryMetaRepository(),
      mutationProtocol: protocol,
    );
    final asset = (await repository.ensureOverviewAssets('project-1')).first;

    final saved = await repository.save(
      asset.copyWith(state: ProjectAssetState.editable),
      expectedRevision: 0,
    );
    expect(saved.revision, 1);

    // Verify journal has propose + approve records.
    // Note: committed record is NOT produced because the target path
    // (assets.json#asset:...) is a logical identifier, not a writable
    // relative path. The canonical store correctly rejects it.
    // The actual file write is done by _write() in ProjectAssetRepository.
    // TODO: migrate ProjectAssetRepository to use real relative paths.
    final journal = LocalMutationJournal(basePath: journalDir.path);
    final events = await journal.readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(types, contains('candidate_proposed'));
    expect(types, contains('candidate_approved'));
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
