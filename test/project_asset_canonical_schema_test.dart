/// MP-07: the asset repository commits one complete canonical file.
///
/// The candidate payload, the receipt evidence and the final disk bytes must
/// be the same envelope; legacy `{assets: [...]}` files stay readable without
/// rewriting; file revision is the mutation conflict authority.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_envelope.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/domain/project/project_asset.dart';
import 'package:lingbi/features/project/data/project_asset_repository.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';

void main() {
  late Directory tempDir;
  late ProjectAssetRepository repository;
  late LocalMutationJournal journal;
  late _FileBackedMeta meta;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asset_schema_test_');
    journal = LocalMutationJournal(
      basePath: '${tempDir.path}/journal',
    );
    Directory('${tempDir.path}/project').createSync(recursive: true);
    final protocol = LocalMutationProtocol(
      journal: journal,
      store: FileCanonicalStore(
        projectRoot: '${tempDir.path}/project',
        atomicStore: AtomicFileStore(),
      ),
    );
    meta = _FileBackedMeta(Directory('${tempDir.path}/project'));
    repository = ProjectAssetRepository(
      metaRepository: meta,
      mutationProtocol: protocol,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<ProjectAsset> saveFirstAsset({String projectId = 'project-1'}) async {
    final asset =
        (await repository.ensureOverviewAssets(projectId)).first;
    final result = await repository.save(
      asset.copyWith(state: ProjectAssetState.editable),
      expectedRevision: 1,
    );
    expect(result, isA<Success<ProjectAsset>>());
    return (result as Success<ProjectAsset>).value;
  }

  test('save writes one complete canonical envelope to disk', () async {
    final saved = await saveFirstAsset();
    expect(saved.revision, 1);

    final onDisk = await File('${tempDir.path}/project/project_meta/assets.json')
        .readAsString();
    final envelope = CanonicalJsonEnvelope.decode(onDisk);
    expect(envelope.schemaVersion, 1);
    expect(envelope.revision, 2);
    final assets = (envelope.payload['assets'] as List)
        .map((e) => ProjectAsset.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    expect(assets, hasLength(5));
    expect(
      assets.firstWhere((a) => a.id == saved.id).state,
      ProjectAssetState.editable,
    );
  });

  test('candidate payload equals the final disk payload byte-for-byte',
      () async {
    await saveFirstAsset();

    final events = await journal.readAll();
    final proposal = events.lastWhere(
      (e) => e.eventType == 'candidate_proposed',
    );
    final diskContent =
        await File('${tempDir.path}/project/project_meta/assets.json')
            .readAsString();

    expect(proposal.payload['content'], diskContent);
    expect(
      canonicalTextHash(proposal.payload['content'] as String),
      hasLength(64),
    );
  });

  test('commit produces all three journal records and writes the file',
      () async {
    await saveFirstAsset();

    final events = await journal.readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(types, containsAll([
      'candidate_proposed',
      'candidate_approved',
      'candidate_committed',
    ]));

    final file = File('${tempDir.path}/project/project_meta/assets.json');
    expect(file.existsSync(), isTrue);
  });

  test('file revision conflict rejects a stale expectedRevision', () async {
    await saveFirstAsset();

    final result = await repository.save(
      (await repository.list('project-1')).first
          .copyWith(state: ProjectAssetState.failed),
      expectedRevision: 1,
    );
    expect(result, isA<Failure>());
    final error = (result as Failure).error;
    expect(error.typedCode, MutationErrorCode.revisionConflict);
  });

  test('legacy {assets: [...]} file stays readable without rewriting',
      () async {
    final legacy = {
      '_schemaVersion': 1,
      'assets': [
        ProjectAsset.initial(projectId: 'project-1', type: ProjectAssetType.protagonist)
            .copyWith(state: ProjectAssetState.editable, revision: 3)
            .toJson(),
      ],
    };
    final metaDir = Directory('${tempDir.path}/project/project_meta')
      ..createSync(recursive: true);
    await File('${metaDir.path}/assets.json').writeAsString(jsonEncode(legacy));

    final assets = await repository.list('project-1');
    expect(assets, hasLength(1));
    expect(assets.single.revision, 3);
    expect(assets.single.state, ProjectAssetState.editable);

    // The file was not rewritten by reading.
    final onDisk = await File('${metaDir.path}/assets.json').readAsString();
    expect(onDisk, jsonEncode(legacy));
  });

  test('asset display revision advances independently of file revision',
      () async {
    final first = await saveFirstAsset();
    final result = await repository.save(
      (await repository.list('project-1'))
          .firstWhere((a) => a.id == first.id)
          .copyWith(state: ProjectAssetState.awaitingConfirmation),
      expectedRevision: 2,
    );
    final second = (result as Success<ProjectAsset>).value;
    expect(second.revision, 2);

    final onDisk = await File('${tempDir.path}/project/project_meta/assets.json')
        .readAsString();
    final envelope = CanonicalJsonEnvelope.decode(onDisk);
    expect(envelope.revision, 3);
    final assets = (envelope.payload['assets'] as List)
        .map((e) => ProjectAsset.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    expect(
      assets.firstWhere((a) => a.id == first.id).revision,
      2,
    );
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
