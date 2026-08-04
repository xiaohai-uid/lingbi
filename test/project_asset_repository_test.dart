import 'dart:convert';
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
import 'package:lingbi/shared/errors/result.dart';

void main() {
  late Directory tempDir;
  late LocalMutationProtocol protocol;
  late _FileBackedMeta meta;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asset_repo_test_');
    Directory('${tempDir.path}/project').createSync(recursive: true);
    protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '${tempDir.path}/journal'),
      store: FileCanonicalStore(
        projectRoot: '${tempDir.path}/project',
        atomicStore: AtomicFileStore(),
      ),
    );
    meta = _FileBackedMeta(Directory('${tempDir.path}/project'));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProjectAssetRepository buildRepository() => ProjectAssetRepository(
        metaRepository: meta,
        mutationProtocol: protocol,
      );

  test('overview assets have stable IDs and are initialized idempotently',
      () async {
    final repository = buildRepository();

    final first = await repository.ensureOverviewAssets('project-1');
    final second = await repository.ensureOverviewAssets('project-1');

    expect(first, hasLength(5));
    expect(second.map((asset) => asset.id), first.map((asset) => asset.id));
    expect(first.map((asset) => asset.type), ProjectAssetType.values);
    expect(first.every((asset) => asset.state == ProjectAssetState.notStarted),
        isTrue);
    // One canonical file exists on disk; the second call reads it back.
    final file = File('${tempDir.path}/project/project_meta/assets.json');
    expect(file.existsSync(), isTrue);
    expect(jsonDecode(await file.readAsString())['revision'], 1);
  });

  test('stale file revision cannot overwrite newer work', () async {
    final repository = buildRepository();
    final asset = (await repository.ensureOverviewAssets('project-1')).first;

    final saved = await repository.save(
      asset.copyWith(state: ProjectAssetState.editable),
      expectedRevision: 1,
    );
    expect((saved as Success<ProjectAsset>).value.revision, 1);

    final stale = await repository.save(
      asset.copyWith(state: ProjectAssetState.failed),
      expectedRevision: 1,
    );
    expect(stale, isA<Failure>());
  });

  test('round trip preserves source path and state', () async {
    final repository = buildRepository();
    final asset = (await repository.ensureOverviewAssets('project-1')).last;

    await repository.save(
      asset.copyWith(
        state: ProjectAssetState.awaitingConfirmation,
        source: ProjectAssetSource.ai,
      ),
      expectedRevision: 1,
    );
    final loaded = await repository.list('project-1');

    expect(loaded.last.storagePath, 'chapters/first-chapter.md');
    expect(loaded.last.state, ProjectAssetState.awaitingConfirmation);
    expect(loaded.last.source, ProjectAssetSource.ai);
  });

  test('save via MutationProtocol creates all three journal records',
      () async {
    final repository = buildRepository();
    final asset = (await repository.ensureOverviewAssets('project-1')).first;

    final saved = await repository.save(
      asset.copyWith(state: ProjectAssetState.editable),
      expectedRevision: 1,
    );
    expect((saved as Success<ProjectAsset>).value.revision, 1);

    final events = await LocalMutationJournal(
      basePath: '${tempDir.path}/journal',
    ).readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(types, contains('candidate_proposed'));
    expect(types, contains('candidate_approved'));
    expect(types, contains('candidate_committed'));
  });

  test('rewriting a meta asset keeps one Canon index entry', () async {
    final storage = StorageService();
    final zvec = ZVecService(storageService: storage);
    await zvec.initialize(dbPath: '${tempDir.path}/db');
    final projects = ProjectService(
      zvecService: zvec,
      mutationProtocol: protocol,
    );
    final project = await projects.createPortableProject(
      name: '幂等项目',
      directoryPath: '${tempDir.path}/project',
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

class _FileBackedMeta implements IProjectMetaRepository {
  _FileBackedMeta(this.root);

  final Directory root;

  File _file(String projectId, String fileName) =>
      File('${root.path}/project_meta/$fileName');

  @override
  Future<Map<String, dynamic>?> read(String projectId, String fileName) async {
    final file = _file(projectId, fileName);
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  @override
  Future<({Map<String, dynamic>? payload, int fileRevision})> readCanonical(
    String projectId,
    String fileName,
  ) async {
    final raw = await read(projectId, fileName);
    if (raw == null) return (payload: null, fileRevision: 0);
    final payload = raw['payload'];
    if (payload is Map<String, dynamic>) {
      return (
        payload: payload,
        fileRevision: raw['revision'] is int ? raw['revision'] as int : 0,
      );
    }
    return (payload: raw, fileRevision: 0);
  }

  @override
  Future<void> write(
    String projectId,
    String fileName,
    Map<String, dynamic> data,
  ) async {
    final file = _file(projectId, fileName);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    final file = _file(projectId, fileName);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<List<String>> list(String projectId) async {
    final dir = Directory('${root.path}/project_meta');
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.json'))
        .toList();
  }

  @override
  Future<String> getMetaDirPath(String projectId) async =>
      '${root.path}/project_meta';

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
    String projectId,
    WorldConstitution constitution,
  ) async {}
}
