import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';
import 'package:lingbi/shared/models/project.dart';

/// MP-09: duplicate project identity classification.
///
/// Covers: duplicate-ID block, move rebind, and independent-copy new
/// ID/provenance.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_duplicate_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  LocalMutationProtocol _projectBound() => LocalMutationProtocol.projectBound(
        resolver: _ResolveToId(),
        journalFactory: ProjectMutationJournalFactory(resolver: _ResolveToId()),
        storeForRoot: (root) => FileCanonicalStore.projectOwned(
          root,
          atomicStore: AtomicFileStore(),
        ),
      );

  ProjectService _service() => ProjectService(mutationProtocol: _projectBound());

  group('duplicate identity classification', () {
    test('a unique id on disk is classified unique', () async {
      final project = Project(name: '唯一小说', directoryPath: '${tempDir.path}/novel');
      final identity = _service().classifyIdentity(
        project,
        knownProjects: [
          Project(name: '其他', directoryPath: '${tempDir.path}/other_novel'),
        ],
      );
      expect(identity.kind, ProjectIdentityKind.unique);
    });

    test('same id with the old directory gone classifies as moved', () async {
      final project = Project(
        id: 'proj-move-1',
        name: '移动小说',
        directoryPath: '${tempDir.path}/new_location/novel',
      );
      final identity = _service().classifyIdentity(
        project,
        knownProjects: [
          Project(
            id: 'proj-move-1',
            name: '移动小说',
            directoryPath: '${tempDir.path}/old_location/novel',
          ),
        ],
      );
      expect(identity.kind, ProjectIdentityKind.moved);
      expect(identity.existingDirectory, '${tempDir.path}/old_location/novel');
    });

    test('same id with both directories present is a duplicate copy', () async {
      final project = Project(
        id: 'proj-copy-1',
        name: '副本小说',
        directoryPath: '${tempDir.path}/copy_location/novel',
      );
      Directory('${tempDir.path}/original_location/novel')
          .createSync(recursive: true);
      final identity = _service().classifyIdentity(
        project,
        knownProjects: [
          Project(
            id: 'proj-copy-1',
            name: '副本小说',
            directoryPath: '${tempDir.path}/original_location/novel',
          ),
        ],
      );
      expect(identity.kind, ProjectIdentityKind.duplicateCopy);
      expect(identity.existingDirectory, '${tempDir.path}/original_location/novel');
    });
  });

  group('duplicate-ID block and independent copy', () {
    test('opening a duplicate copy does not silently adopt the original id',
        () async {
      final originalDir = '${tempDir.path}/original_novel';
      final copyDir = '${tempDir.path}/copy_novel';

      // 创建原始项目（zvec 注册 originalDir，供身份分类使用）。
      final storage = StorageService();
      await storage.initialize(dbPath: '${tempDir.path}/db');
      final zvec = ZVecService(storageService: storage);
      await zvec.initialize(dbPath: '${tempDir.path}/db');
      final svc = ProjectService(
        zvecService: zvec,
        mutationProtocol: _projectBound(),
      );
      final original = await svc.createPortableProject(
        name: '原创小说',
        directoryPath: originalDir,
        brief: const ProjectBrief(
          title: '原创小说',
          genreId: '玄幻',
          templateId: 'genre:玄幻',
        ),
      );

      // 复制目录 = 独立副本（相同的 id 出现在两个目录）。
      Directory(copyDir).createSync(recursive: true);
      Directory('$copyDir/.lingbi').createSync(recursive: true);
      File('$originalDir/.lingbi/project.json')
          .copySync('$copyDir/.lingbi/project.json');
      final copyJson = jsonDecode(
          File('$copyDir/.lingbi/project.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(copyJson['id'], original.id);

      // 打开副本：身份必须被标记为 duplicateCopy，且不自动改写副本元数据。
      final opened = await svc.openPortableProject(copyDir);
      expect(opened.identity.kind, ProjectIdentityKind.duplicateCopy);
      final reopenedJson = jsonDecode(
          File('$copyDir/.lingbi/project.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(reopenedJson['id'], original.id,
          reason: 'block：不得静默采用新身份');
    });

    test('adoptIndependentCopy assigns a new id and provenance via protocol',
        () async {
      final originalDir = '${tempDir.path}/original_novel';
      final copyDir = '${tempDir.path}/copy_novel';

      final svc = _service();
      final original = await svc.createPortableProject(
        name: '原创小说',
        directoryPath: originalDir,
        brief: const ProjectBrief(
          title: '原创小说',
          genreId: '玄幻',
          templateId: 'genre:玄幻',
        ),
      );
      Directory(copyDir).createSync(recursive: true);
      Directory('$copyDir/.lingbi').createSync(recursive: true);
      File('$originalDir/.lingbi/project.json')
          .copySync('$copyDir/.lingbi/project.json');

      final adopted = await svc.adoptIndependentCopy(copyDir);
      expect(adopted.errorOrNull(), isNull, reason: '${adopted.errorOrNull()}');
      final copy = adopted.getOrNull()!;

      expect(copy.id, isNot(original.id), reason: '独立副本必须获得新 ID');
      expect(copy.provenance, 'copy-of:${original.id}');
      expect(copy.name, '原创小说');

      // 新身份已经协议持久化到副本的 project.json。
      final onDisk = jsonDecode(
          File('$copyDir/.lingbi/project.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(onDisk['id'], copy.id);
      expect(onDisk['provenance'], 'copy-of:${original.id}');
    });
  });
  group('move rebind', () {
    test('opening a moved project rebinds the directory path and keeps id',
        () async {
      final oldDir = '${tempDir.path}/old_location/novel';
      final newDir = '${tempDir.path}/new_location/novel';

      // zvec 注册 oldDir；移动后在新位置打开应分类为 moved。
      final storage = StorageService();
      await storage.initialize(dbPath: '${tempDir.path}/db');
      final zvec = ZVecService(storageService: storage);
      await zvec.initialize(dbPath: '${tempDir.path}/db');
      final svc = ProjectService(
        zvecService: zvec,
        mutationProtocol: _projectBound(),
      );
      final project = await svc.createPortableProject(
        name: '移动小说',
        directoryPath: oldDir,
      );

      // 移动目录后在新位置打开。
      Directory('${tempDir.path}/new_location').createSync(recursive: true);
      await Directory(oldDir).rename(newDir);
      final opened = await svc.openPortableProject(newDir);

      expect(opened.project.id, project.id, reason: '移动保留原 ID');
      expect(opened.identity.kind, ProjectIdentityKind.moved,
          reason: '原注册目录已不存在 → 移动重绑');
      expect(opened.project.directoryPath, newDir, reason: 'rebind 到新位置');
    });
  });
}

/// 把 projectId 直接解析为同名目录（测试用）：projectId == 项目目录。
class _ResolveToId implements ProjectRootResolver {
  @override
  Future<Result<ResolvedProjectRoot>> resolve(String projectId) async =>
      Result.success(
          ResolvedProjectRoot(projectId: projectId, rootPath: projectId));
}
