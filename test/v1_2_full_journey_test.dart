import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/import_export/data/export_service.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/features/onboarding/data/wizard_completion_workflow.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/models/project.dart';

import 'support/mutation_test_harness.dart';

void main() {
  test(
    'v1.2 first-user journey: wizard to project/canon/candidate/export',
    () async {
      final temp = await Directory.systemTemp.createTemp('lingbi_v12_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });

      final machine = _completedWizard();
      final state = _ProjectState();

      final workflow = WizardCompletionWorkflow(
        projectCreator: _PersistentProjectCreator(state),
        canonWriter: _PersistentCanonWriter(state),
        projectRootResolver: () => temp.path,
      );

      final result = await workflow.execute(machine);

      expect(await Directory(result.project.directoryPath).exists(), isTrue);
      expect(
        File(
          '${result.project.directoryPath}/.lingbi/project.json',
        ).existsSync(),
        isTrue,
      );

      final canonDir = Directory(
        '${result.project.directoryPath}/.lingbi/canon',
      );
      final canonFiles = canonDir
          .listSync()
          .whereType<File>()
          .map((f) => f.readAsStringSync())
          .toList();
      expect(canonFiles.length, greaterThanOrEqualTo(2));
      expect(canonFiles.any((json) => json.contains('主角')), isTrue);
      expect(canonFiles.any((json) => json.contains('题材类型')), isTrue);

      final protocol = boundProtocol(
        result.project.id,
        result.project.directoryPath,
      );
      final candidates = CandidateService(
        projectDir: result.project.directoryPath,
        mutationProtocol: protocol,
        projectId: result.project.id,
      );
      final candidate = candidates.createCandidate(
        chapterId: 'chapter-1',
        content: '# 第一章\n\n林渊在灵气复苏的夜晚醒来。',
      );
      expect(candidate.status, CandidateStatus.pending);

      final chapterPath =
          '${result.project.directoryPath}/chapters/chapter-1.md';
      await candidates.adopt(candidate.id, chapterPath);

      final adoptedText = File(chapterPath).readAsStringSync();
      expect(adoptedText, contains('林渊'));

      final restarted = CandidateService(
        projectDir: result.project.directoryPath,
        mutationProtocol: protocol,
        projectId: result.project.id,
      );
      final restoredCandidate = restarted.getCandidate(candidate.id);
      expect(restoredCandidate, isNotNull);
      expect(restoredCandidate!.status, CandidateStatus.adopted);
      expect(restoredCandidate.content, adoptedText);
      expect(File(chapterPath).existsSync(), isTrue);

      final exportPath = '${temp.path}/export/chapter-1.docx';
      await ExportService().exportAsDocx(
        title: '第一章',
        content: adoptedText,
        savePath: exportPath,
      );

      final exportFile = File(exportPath);
      expect(await exportFile.exists(), isTrue);
      final archive = ZipDecoder().decodeBytes(await exportFile.readAsBytes());
      expect(archive.files.map((f) => f.name), contains('word/document.xml'));
    },
  );
}

GuidedWizardStateMachine _completedWizard() {
  final machine = GuidedWizardStateMachine();
  machine.setDimension(
    WizardDimension.genre,
    const WizardStepValue(selected: ['玄幻', '都市']),
  );
  machine.setDimension(
    WizardDimension.wordCount,
    const WizardStepValue(selected: ['长篇(50万+)']),
  );
  machine.setDimension(
    WizardDimension.platform,
    const WizardStepValue(selected: ['起点']),
  );
  machine.setDimension(
    WizardDimension.title,
    const WizardStepValue(selected: ['万界守夜人']),
  );
  machine.setDimension(
    WizardDimension.protagonist,
    const WizardStepValue(selected: ['主角林渊']),
  );
  machine.setDimension(
    WizardDimension.worldview,
    const WizardStepValue(selected: ['灵气复苏的现代都市']),
  );
  machine.setDimension(
    WizardDimension.creativeDirection,
    const WizardStepValue(selected: ['爽文升级']),
  );
  machine.setDimension(
    WizardDimension.firstChapterGoal,
    const WizardStepValue(selected: ['主角首次觉醒']),
  );
  machine.markCompleted();
  return machine;
}

class _ProjectState {
  String? directoryPath;
}

class _PersistentProjectCreator implements ProjectCreator {
  _PersistentProjectCreator(this._state);

  final _ProjectState _state;

  @override
  Future<Project> createProject({
    required String directoryPath,
    required ProjectBrief brief,
  }) async {
    _state.directoryPath = directoryPath;
    final dir = Directory(directoryPath)..createSync(recursive: true);
    final project = Project(
      name: brief.title,
      directoryPath: directoryPath,
      genre: brief.genreId,
    );
    final metaDir = Directory('${dir.path}/.lingbi')
      ..createSync(recursive: true);
    File('${metaDir.path}/project.json').writeAsStringSync(
      jsonEncode({
        'id': project.id,
        'name': project.name,
        'genre': project.genre,
        'directoryPath': project.directoryPath,
      }),
    );
    return project;
  }
}

class _PersistentCanonWriter implements CanonWriter {
  _PersistentCanonWriter(this._state);

  final _ProjectState _state;

  @override
  Future<void> createEntry(CanonEntry entry) async {
    final dir = Directory('${_state.directoryPath!}/.lingbi/canon')
      ..createSync(recursive: true);
    File(
      '${dir.path}/${entry.name}.json',
    ).writeAsStringSync(jsonEncode(entry.toJson()));
  }
}
