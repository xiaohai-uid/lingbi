import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/project_mutation_journal_factory.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('project_journal_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ResolvedProjectRoot root(String projectId, String rootPath) =>
      ResolvedProjectRoot(projectId: projectId, rootPath: rootPath);

  group('project-owned journal placement', () {
    test('factory derives the journal inside .lingbi/mutations of the root',
        () async {
      final projectRoot = '${tempDir.path}/project-a';
      Directory(projectRoot).createSync(recursive: true);
      final factory = ProjectMutationJournalFactory(
        resolver: _FakeResolver(
            Result.success(root('proj-1', projectRoot))),
      );

      final result = await factory.forProject('proj-1');
      final journal = result.getOrNull();
      expect(journal, isNotNull);
      expect(
        journal!.eventsFilePath,
        '$projectRoot/.lingbi/mutations/events.jsonl',
      );
      expect(File(journal.eventsFilePath).existsSync(), isFalse);
    });

    test('journal path comes only from root resolution, never a raw path',
        () async {
      final projectRoot = '${tempDir.path}/project-b';
      Directory(projectRoot).createSync(recursive: true);
      final factory = ProjectMutationJournalFactory(
        resolver: _FakeResolver(
            Result.success(root('proj-2', projectRoot))),
      );

      final journal = (await factory.forProject('proj-2')).getOrNull();
      expect(journal, isNotNull);
      expect(
        journal!.eventsFilePath,
        startsWith('$projectRoot/.lingbi/mutations/'),
      );
      expect(journal.eventsFilePath, endsWith('events.jsonl'));
    });

    test('zero-root resolution fails closed with a typed error, no journal',
        () async {
      final factory = ProjectMutationJournalFactory(
        resolver: _FakeResolver(
          Result.failure(FileError(
            'no root for project',
            typedCode: MutationErrorCode.projectRootAmbiguity,
          )),
        ),
      );

      final result = await factory.forProject('missing');
      expect(result.errorOrNull(), isNotNull);
      expect(
        result.errorOrNull()!.typedCode,
        MutationErrorCode.projectRootAmbiguity,
      );
      expect(
        File('${tempDir.path}/missing/.lingbi/mutations/events.jsonl')
            .existsSync(),
        isFalse,
      );
    });

    test('ambiguous root resolution fails closed with typed ambiguity error',
        () async {
      final factory = ProjectMutationJournalFactory(
        resolver: _FakeResolver(
          Result.failure(FileError(
            'two roots claim the same project id',
            typedCode: MutationErrorCode.projectRootAmbiguity,
          )),
        ),
      );

      final result = await factory.forProject('dup');
      expect(result.errorOrNull(), isNotNull);
      expect(
        result.errorOrNull()!.typedCode,
        MutationErrorCode.projectRootAmbiguity,
      );
    });
  });

  group('project copy portability', () {
    test('copying the project keeps the journal readable at the new root',
        () async {
      final originalRoot = '${tempDir.path}/original';
      final copyRoot = '${tempDir.path}/copy';
      Directory(originalRoot).createSync(recursive: true);

      final journal =
          LocalMutationJournal.projectOwned(root('proj-copy', originalRoot));
      await journal.append(JournalEvent(
        eventId: 'evt-1',
        eventType: 'candidate_proposed',
        aggregateId: 'cand-1',
        payload: {'a': 1},
      ));
      await journal.append(JournalEvent(
        eventId: 'evt-2',
        eventType: 'candidate_committed',
        aggregateId: 'cand-1',
        payload: {'a': 2},
      ));

      // Simulate a raw copy of the project folder.
      final sourceMutations = Directory('$originalRoot/.lingbi/mutations');
      final targetMutations = Directory('$copyRoot/.lingbi/mutations')
        ..createSync(recursive: true);
      for (final entity in sourceMutations.listSync()) {
        if (entity is File) {
          entity.copySync(
            '${targetMutations.path}/${entity.path.split(Platform.pathSeparator).last}',
          );
        }
      }

      final copied =
          LocalMutationJournal.projectOwned(root('proj-copy', copyRoot));
      final events = await copied.readAll();
      expect(events.length, 2);
      expect(events[0].eventId, 'evt-1');
      expect(events[1].eventId, 'evt-2');
      expect(await copied.validateChain(), isTrue);
    });
  });

  group('project journal integrity', () {
    test('hash-chain corruption is detected', () async {
      final journal =
          LocalMutationJournal.projectOwned(root('proj-3', '${tempDir.path}/p3'));
      await journal.append(
          JournalEvent(eventId: 'a', eventType: 'proposed', aggregateId: 'x', payload: {'k': 'v'}));
      await journal.append(
          JournalEvent(eventId: 'b', eventType: 'proposed', aggregateId: 'x', payload: {'k': 'v'}));
      await journal.append(
          JournalEvent(eventId: 'c', eventType: 'proposed', aggregateId: 'x', payload: {'k': 'v'}));

      final file = File(journal.eventsFilePath);
      final lines = await file.readAsLines();
      final corrupted =
          Map<String, dynamic>.from(jsonDecode(lines[1]) as Map<String, dynamic>);
      corrupted['event_type'] = 'TAMPERED';
      lines[1] = jsonEncode(corrupted);
      await file.writeAsString(lines.join('\n'));

      final reopened =
          LocalMutationJournal.projectOwned(root('proj-3', '${tempDir.path}/p3'));
      expect(await reopened.validateChain(), isFalse);
    });

    test('truncated final line is discarded, earlier events survive', () async {
      final journal =
          LocalMutationJournal.projectOwned(root('proj-4', '${tempDir.path}/p4'));
      await journal.append(
          JournalEvent(eventId: 'good-1', eventType: 'proposed', aggregateId: 'x', payload: {'k': 'v'}));
      await journal.append(
          JournalEvent(eventId: 'good-2', eventType: 'proposed', aggregateId: 'x', payload: {'k': 'v'}));

      final file = File(journal.eventsFilePath);
      await file.writeAsString(
        '{"schema_version":1,"sequence":3,"event_id":"bad',
        mode: FileMode.append,
      );

      final reopened =
          LocalMutationJournal.projectOwned(root('proj-4', '${tempDir.path}/p4'));
      final events = await reopened.readAll();
      expect(events.length, 2);
      expect(events[0].eventId, 'good-1');
      expect(events[1].eventId, 'good-2');
    });

    test('duplicate idempotency key returns the existing event', () async {
      final journal =
          LocalMutationJournal.projectOwned(root('proj-5', '${tempDir.path}/p5'));
      final first = await journal.append(JournalEvent(
        eventId: 'evt-a',
        eventType: 'commit',
        aggregateId: 'cand-1',
        payload: {'data': 'first'},
        idempotencyKey: 'idem-001',
      ));
      final second = await journal.append(JournalEvent(
        eventId: 'evt-b',
        eventType: 'commit',
        aggregateId: 'cand-1',
        payload: {'data': 'second'},
        idempotencyKey: 'idem-001',
      ));

      expect(first.duplicate, isFalse);
      expect(second.duplicate, isTrue);
      expect(second.event.eventId, 'evt-a');
      expect(await journal.readAll(), hasLength(1));
    });
  });

  group('serialized concurrent append', () {
    test('concurrent appends are serialized with an intact chain', () async {
      final journal =
          LocalMutationJournal.projectOwned(root('proj-s', '${tempDir.path}/s'));

      final futures = [
        for (var i = 0; i < 20; i++)
          journal.append(JournalEvent(
            eventId: 'evt-$i',
            eventType: 'proposed',
            aggregateId: 'cand-$i',
            payload: {'i': i},
          )),
      ];
      final results = await Future.wait(futures);
      expect(results.every((r) => !r.duplicate), isTrue);

      final events = await journal.readAll();
      expect(events.length, 20);
      expect(
        events.map((e) => e.sequence).toList(),
        List.generate(20, (i) => i + 1),
      );
      expect(await journal.validateChain(), isTrue);
    });
  });
}

class _FakeResolver implements ProjectRootResolver {
  _FakeResolver(this._result);

  final Result<ResolvedProjectRoot> _result;

  @override
  Future<Result<ResolvedProjectRoot>> resolve(String projectId) async =>
      _result;
}
