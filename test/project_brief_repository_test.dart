import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/project/data/project_brief_repository.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_project_brief_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('round trip preserves template genre and increments revision', () async {
    final repository = ProjectBriefRepository(
      tempDir.path,
      mutationProtocol: _briefProtocol(tempDir.path),
    );
    const brief = ProjectBrief(
      title: '长夜',
      genreId: 'xuanhuan',
      templateId: 'genre:xuanhuan',
      targetPlatform: '起点',
      targetLength: 1200000,
      audience: '男频长篇读者',
      premise: '凡人守住一座会移动的城。',
    );

    final saved = await repository.write(brief, expectedRevision: 0);
    final loaded = await repository.read();

    expect(saved.revision, 1);
    expect(loaded, brief.copyWith(revision: 1));
  });

  test('stale expected revision cannot overwrite a newer brief', () async {
    final repository = ProjectBriefRepository(
      tempDir.path,
      mutationProtocol: _briefProtocol(tempDir.path),
    );
    const brief = ProjectBrief(
      title: '长夜',
      genreId: 'xuanhuan',
      templateId: 'genre:xuanhuan',
    );
    await repository.write(brief, expectedRevision: 0);

    expect(
      () => repository.write(
        brief.copyWith(title: '错误覆盖'),
        expectedRevision: 0,
      ),
      throwsA(isA<ProjectBriefConflict>()),
    );
  });

  test('legacy project metadata is readable as a project brief', () async {
    final metadata = File('${tempDir.path}/.lingbi/project.json');
    metadata.createSync(recursive: true);
    metadata.writeAsStringSync(jsonEncode({
      'id': 'legacy-id',
      'name': '旧项目',
      'genre': '玄幻',
      'targetPlatform': '番茄',
      'description': '旧版一句话创意',
    }));

    final loaded = await ProjectBriefRepository(tempDir.path).read();

    expect(loaded.title, '旧项目');
    expect(loaded.genreId, '玄幻');
    expect(loaded.targetPlatform, '番茄');
    expect(loaded.premise, '旧版一句话创意');
    expect(loaded.revision, 0);
  });

  test('write via MutationProtocol creates journal records', () async {
    final journalDir =
        Directory.systemTemp.createTempSync('lingbi_brief_journal_');
    final protocol = LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: journalDir.path),
      store: FileCanonicalStore(
        projectRoot: tempDir.path,
        atomicStore: AtomicFileStore(),
      ),
    );
    final repository = ProjectBriefRepository(
      tempDir.path,
      mutationProtocol: protocol,
    );
    const brief = ProjectBrief(
      title: '协议之路',
      genreId: 'xuanhuan',
      templateId: 'genre:xuanhuan',
    );

    final saved = await repository.write(brief, expectedRevision: 0);
    expect(saved.revision, 1);

    // Verify journal has propose + approve + commit records
    final journal = LocalMutationJournal(basePath: journalDir.path);
    final events = await journal.readAll();
    final types = events.map((e) => e.eventType).toList();
    expect(types, contains('candidate_proposed'));
    expect(types, contains('candidate_approved'));
    expect(types, contains('candidate_committed'));

    journalDir.deleteSync(recursive: true);
  });

  test('portable project writes the complete brief on first persistence',
      () async {
    final projectDir = '${tempDir.path}/novel';
    const brief = ProjectBrief(
      title: '一次写对',
      genreId: 'suspense',
      templateId: 'genre:suspense',
      targetPlatform: '起点',
      audience: '悬疑读者',
      premise: '失踪者每天寄回一封信。',
    );

    final project = await ProjectService(
      mutationProtocol: _briefProtocol(projectDir),
    ).createPortableProject(
      directoryPath: projectDir,
      brief: brief,
    );
    final json = jsonDecode(
      File('$projectDir/.lingbi/project.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(project.genre, 'suspense');
    expect(json['genre'], 'suspense');
    expect(json['projectBrief']['templateId'], 'genre:suspense');
    expect(json['projectBrief']['revision'], 1);
  });
}


LocalMutationProtocol _briefProtocol(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
