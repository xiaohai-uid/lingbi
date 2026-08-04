import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/features/project/data/project_root_resolver.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/migration/migration_candidate_service.dart';
import 'package:lingbi/services/migrations/legacy_canonical_reader.dart';
import 'package:lingbi/services/migrations/schema_versions.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

/// MP-09: explicit legacy migration flows.
///
/// Covers: legacy read-only open, migration baseline, one-time explicit
/// upgrade decision, ambiguous/lossy migration refusal.
void main() {
  late Directory tempDir;
  late String rootPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_migration_');
    rootPath = tempDir.path;
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  LocalMutationProtocol projectBoundFor(Map<String, String> roots) {
    final resolver = _RootMapResolver(roots);
    return LocalMutationProtocol.projectBound(
      resolver: resolver,
      journalFactory: ProjectMutationJournalFactory(resolver: resolver),
      storeForRoot: (root) => FileCanonicalStore.projectOwned(
        root,
        atomicStore: AtomicFileStore(),
      ),
    );
  }

  ({ProjectService service, LocalMutationProtocol protocol}) boundService(
    ZVecService zvec,
  ) {
    final service = ProjectService(zvecService: zvec);
    final resolver = ProjectRootResolverAdapter(
      projectService: service,
      allowMissingMetadata: true,
    );
    final protocol = LocalMutationProtocol.projectBound(
      resolver: resolver,
      journalFactory: ProjectMutationJournalFactory(resolver: resolver),
      storeForRoot: (root) => FileCanonicalStore.projectOwned(
        root,
        atomicStore: AtomicFileStore(),
      ),
    );
    service.mutationProtocol = protocol;
    return (service: service, protocol: protocol);
  }

  group('legacy read-only open', () {
    test('canonical project is classified canonical and opens normally',
        () async {
      final dir = '$rootPath/canonical_novel';
      final storage = StorageService();
      await storage.initialize(dbPath: '$rootPath/db');
      final zvec = ZVecService(storageService: storage);
      await zvec.initialize(dbPath: '$rootPath/db');
      final svc = boundService(zvec).service;
      await svc.createPortableProject(
        name: '正典小说',
        directoryPath: dir,
        brief: const ProjectBrief(
          title: '正典小说',
          genreId: '都市',
          templateId: 'genre:都市',
        ),
      );

      expect(await LegacyCanonicalReader.inspect(dir),
          ProjectMetadataKind.canonical);

      final opened = await svc.openPortableProject(dir);
      expect(opened.project.name, '正典小说');
    });

    test('legacy project.json without schemaVersion opens read-only', () async {
      final dir = '$rootPath/legacy_novel';
      Directory('$dir/.lingbi').createSync(recursive: true);
      final legacyJson = {
        'id': 'legacy-proj-1',
        'name': '旧版小说',
        'directoryPath': dir,
        'createdAt': DateTime(2026, 6, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 6, 1).toIso8601String(),
      };
      File('$dir/.lingbi/project.json').writeAsStringSync(
        jsonEncode(legacyJson),
        flush: true,
      );
      File('$dir/第一章.md').writeAsStringSync('# 第一章\n\n旧版章节。');

      expect(
        await LegacyCanonicalReader.inspect(dir),
        ProjectMetadataKind.legacy,
      );

      final before = File('$dir/.lingbi/project.json')
          .statSync()
          .modified
          .millisecondsSinceEpoch;

      final storage = StorageService();
      await storage.initialize(dbPath: '$rootPath/db');
      final zvec = ZVecService(storageService: storage);
      await zvec.initialize(dbPath: '$rootPath/db');
      final svc = boundService(zvec).service;
      final opened = await svc.openPortableProject(dir);

      // Read-only: the legacy metadata file is never rewritten on open.
      expect(opened.project.id, 'legacy-proj-1');
      expect(opened.project.name, '旧版小说');
      expect(opened.documents.length, 1);
      final after = File('$dir/.lingbi/project.json')
          .statSync()
          .modified
          .millisecondsSinceEpoch;
      expect(after, before);
      expect(
        File('$dir/.lingbi/project.json').readAsStringSync(),
        isNot(contains('"schemaVersion"')),
        reason: '只读打开不得改写 legacy 元数据',
      );
    });
  });

  group('migration baseline and one-time explicit upgrade', () {
    test('baseline discovers legacy projects without touching them', () async {
      final legacyDir = '$rootPath/legacy_novel';
      Directory('$legacyDir/.lingbi').createSync(recursive: true);
      File('$legacyDir/.lingbi/project.json').writeAsStringSync(jsonEncode({
        'id': 'legacy-proj-1',
        'name': '旧版小说',
        'directoryPath': legacyDir,
        'createdAt': DateTime(2026, 6, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 6, 1).toIso8601String(),
      }));
      final canonicalDir = '$rootPath/canonical_novel';
      final storage = StorageService();
      await storage.initialize(dbPath: '$rootPath/db');
      final zvec = ZVecService(storageService: storage);
      await zvec.initialize(dbPath: '$rootPath/db');
      final svc = boundService(zvec).service;
      await svc.createPortableProject(name: '新小说', directoryPath: canonicalDir);

      final baseline =
          MigrationCandidateService(projectRoot: rootPath).buildBaseline();
      final result = await baseline;
      expect(result.errorOrNull(), isNull);
      final candidates = result.getOrNull()!.candidates;
      expect(candidates.length, 1);
      expect(candidates.single.directoryPath, contains('legacy_novel'));
      expect(candidates.single.status, MigrationCandidateStatus.pending);

      // Baseline build is side-effect free.
      expect(
        File('$legacyDir/.lingbi/project.json').readAsStringSync(),
        isNot(contains('schemaVersion')),
      );
    });

    test(
        'accept migrates legacy metadata to canonical once, then refuses repeat',
        () async {
      final legacyDir = '$rootPath/legacy_novel';
      Directory('$legacyDir/.lingbi').createSync(recursive: true);
      File('$legacyDir/.lingbi/project.json').writeAsStringSync(jsonEncode({
        'id': 'legacy-proj-1',
        'name': '旧版小说',
        'directoryPath': legacyDir,
        'createdAt': DateTime(2026, 6, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 6, 1).toIso8601String(),
      }));

      final service = MigrationCandidateService(
        projectRoot: rootPath,
        mutationProtocol: projectBoundFor({'legacy-proj-1': legacyDir}),
      );
      final baseline = (await service.buildBaseline()).getOrNull()!;
      final candidateId = baseline.candidates.single.id;

      final accepted = await service.accept(candidateId);
      expect(accepted.getOrNull(), isNotNull,
          reason: '${accepted.errorOrNull()}');
      expect(accepted.getOrNull()!.status, MigrationCandidateStatus.completed);

      // Now canonical: schemaVersion present and readable.
      expect(await LegacyCanonicalReader.inspect(legacyDir),
          ProjectMetadataKind.canonical);
      final raw =
          jsonDecode(File('$legacyDir/.lingbi/project.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(raw['schemaVersion'], SchemaVersions.project);

      // One-time: a second accept on the same candidate refuses.
      final repeat = await service.accept(candidateId);
      expect(repeat.errorOrNull(), isNotNull);
      expect(repeat.errorOrNull()!.code, contains('ALREADY'));

      // A fresh baseline reports the project as migrated (no candidate).
      final baseline2 = (await service.buildBaseline()).getOrNull()!;
      expect(baseline2.candidates, isEmpty);
    });

    test('ambiguous/lossy metadata is refused, not migrated', () async {
      final brokenDir = '$rootPath/broken_novel';
      Directory('$brokenDir/.lingbi').createSync(recursive: true);
      File('$brokenDir/.lingbi/project.json')
          .writeAsStringSync('{not-json-at-all');

      final service = MigrationCandidateService(
        projectRoot: rootPath,
        mutationProtocol: projectBoundFor({}),
      );
      final baseline = (await service.buildBaseline()).getOrNull()!;
      expect(baseline.ambiguousDirectories.single, contains('broken_novel'));

      final accepted = await service.accept(baseline.candidates.first.id);
      expect(accepted.errorOrNull(), isNotNull);
      expect(accepted.errorOrNull()!.code, contains('LOSSY'));

      // The broken file is left untouched for manual recovery.
      expect(
        File('$brokenDir/.lingbi/project.json').readAsStringSync(),
        '{not-json-at-all',
      );
    });
  });
}

class _RootMapResolver implements ProjectRootResolver {
  _RootMapResolver(this.roots);

  final Map<String, String> roots;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String projectId) async =>
      Result.success(ResolvedProjectRoot(
        projectId: projectId,
        rootPath: roots[projectId] ?? projectId,
      ));
}
