import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/mutation/canonical_envelope.dart';
import 'package:lingbi/domain/mutation/canonical_revision.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';

void main() {
  late Directory tempDir;
  late FileCanonicalStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('canonical_store_test_');
    store = FileCanonicalStore(
      projectRoot: tempDir.path,
      atomicStore: AtomicFileStore(),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('read', () {
    test('reads existing file and returns snapshot with hash', () async {
      final file = File('${tempDir.path}/chapters/ch01.md');
      await file.parent.create(recursive: true);
      await file.writeAsString('Hello chapter one');

      final result = await store.read('chapters/ch01.md');
      expect(result, isA<Success<CanonicalSnapshot>>());
      final snapshot = (result as Success).value;
      expect(snapshot.content, 'Hello chapter one');
      expect(snapshot.hash, hasLength(64));
      expect(snapshot.relativePath, 'chapters/ch01.md');
    });

    test('returns failure for missing file', () async {
      final result = await store.read('nonexistent.md');
      expect(result, isA<Failure>());
    });
  });

  group('prepare and apply single file', () {
    test('single file commit produces receipt with correct paths', () async {
      final file = File('${tempDir.path}/chapters/ch01.md');
      await file.parent.create(recursive: true);
      await file.writeAsString('version 1');

      final plan = CommitPlan(
        transactionId: 'txn-001',
        targets: [
          CommitTarget(
            relativePath: 'chapters/ch01.md',
            newContent: 'version 2',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Success<PreparedCommit>>());

      final receipt = await store.apply((prepared as Success).value);
      expect(receipt, isA<Success<CommitResult>>());
      final result = (receipt as Success).value;
      expect(result.affectedPaths, contains('chapters/ch01.md'));

      final updated =
          await File('${tempDir.path}/chapters/ch01.md').readAsString();
      expect(updated, 'version 2');
    });

    test('new file creation works', () async {
      final plan = CommitPlan(
        transactionId: 'txn-002',
        targets: [
          CommitTarget(
            relativePath: 'chapters/ch02.md',
            newContent: 'brand new chapter',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Success<PreparedCommit>>());

      final receipt = await store.apply((prepared as Success).value);
      expect(receipt, isA<Success<CommitResult>>());

      final content =
          await File('${tempDir.path}/chapters/ch02.md').readAsString();
      expect(content, 'brand new chapter');
    });
  });

  group('revision conflict', () {
    test('REVISION_CONFLICT when expected hash does not match', () async {
      final file = File('${tempDir.path}/chapters/ch01.md');
      await file.parent.create(recursive: true);
      await file.writeAsString('actual content');

      final plan = CommitPlan(
        transactionId: 'txn-003',
        targets: [
          CommitTarget(
            relativePath: 'chapters/ch01.md',
            newContent: 'new content',
            expectedHash:
                'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Failure>());
      final error = (prepared as Failure).error;
      expect(error.message, contains('REVISION_CONFLICT'));
    });
  });

  group('multi-file deterministic order', () {
    test('applies paths in lexical order', () async {
      for (final name in ['b.txt', 'a.txt', 'c.txt']) {
        await File('${tempDir.path}/$name').writeAsString('old $name');
      }

      final plan = CommitPlan(
        transactionId: 'txn-004',
        targets: [
          CommitTarget(
              relativePath: 'c.txt', newContent: 'new c', expectedHash: null),
          CommitTarget(
              relativePath: 'a.txt', newContent: 'new a', expectedHash: null),
          CommitTarget(
              relativePath: 'b.txt', newContent: 'new b', expectedHash: null),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Success<PreparedCommit>>());

      final receipt = await store.apply((prepared as Success).value);
      expect(receipt, isA<Success<CommitResult>>());
      final result = (receipt as Success).value;
      expect(result.affectedPaths, ['a.txt', 'b.txt', 'c.txt']);
    });
  });

  group('path safety', () {
    test('rejects path with ..', () async {
      final plan = CommitPlan(
        transactionId: 'txn-005',
        targets: [
          CommitTarget(
            relativePath: '../escape.txt',
            newContent: 'malicious',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Failure>());
      final error = (prepared as Failure).error;
      expect(error.message, contains('PATH_ESCAPE'));
    });

    test('rejects absolute path', () async {
      final plan = CommitPlan(
        transactionId: 'txn-006',
        targets: [
          CommitTarget(
            relativePath: 'C:/Windows/system32/evil.dll',
            newContent: 'malicious',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Failure>());
      final error = (prepared as Failure).error;
      expect(error.message, contains('PATH_ESCAPE'));
    });

    test('rejects UNC path', () async {
      final plan = CommitPlan(
        transactionId: 'txn-007',
        targets: [
          CommitTarget(
            relativePath: r'\\server\share\evil.txt',
            newContent: 'malicious',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Failure>());
      final error = (prepared as Failure).error;
      expect(error.message, contains('PATH_ESCAPE'));
    });

    test('rejects empty and NUL paths', () async {
      for (final bad in ['', 'a\u0000b.txt']) {
        final plan = CommitPlan(
          transactionId: 'txn-008',
          targets: [
            CommitTarget(
              relativePath: bad,
              newContent: 'x',
              expectedHash: null,
            ),
          ],
        );
        final prepared = await store.prepare(plan);
        expect(prepared, isA<Failure>(), reason: 'path: $bad');
      }
    });

    test('accepts normalized backslash separators', () async {
      final plan = CommitPlan(
        transactionId: 'txn-009',
        targets: [
          CommitTarget(
            relativePath: r'chapters\ch01.md',
            newContent: 'hello',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Success<PreparedCommit>>());
      final applied = await store.apply((prepared as Success).value);
      expect(applied, isA<Success<CommitResult>>());
      expect(
        await File('${tempDir.path}/chapters/ch01.md').readAsString(),
        'hello',
      );
    });
  });

  group('canonical JSON envelope', () {
    CanonicalJsonEnvelope makeEnvelope(
      Map<String, dynamic> payload, {
      required int revision,
    }) =>
        CanonicalJsonEnvelope(
          schemaVersion: 1,
          revision: revision,
          contentHash: canonicalPayloadHash(payload),
          payload: payload,
        );

    test('read verifies envelope content hash and returns revision', () async {
      final payload = {'title': '序章', 'assets': <Object>[]};
      await File('${tempDir.path}/assets.json')
          .writeAsString(makeEnvelope(payload, revision: 3).encode());

      final result = await store.read('assets.json');
      expect(result, isA<Success<CanonicalSnapshot>>());
      final snapshot = (result as Success<CanonicalSnapshot>).value;
      expect(snapshot.revision, 3);
      expect(snapshot.hash, hasLength(64));
      expect(snapshot.hash, canonicalPayloadHash(payload));
    });

    test('read rejects a canonical JSON file with a stale content hash',
        () async {
      final stale = '{"schema_version":1,"revision":2,'
          '"content_hash":"${'a' * 64}","payload":{"k":"v"}}';
      await File('${tempDir.path}/assets.json').writeAsString(stale);

      final result = await store.read('assets.json');
      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error.message, contains('INVALID_CANONICAL'));
    });

    test('prepare rejects an expectedRevision mismatch', () async {
      final payload = {'k': 'v'};
      await File('${tempDir.path}/assets.json')
          .writeAsString(makeEnvelope(payload, revision: 5).encode());
      final next = makeEnvelope({'k': 'v2'}, revision: 6);

      final plan = CommitPlan(
        transactionId: 'txn-010',
        targets: [
          CommitTarget(
            relativePath: 'assets.json',
            newContent: next.encode(),
            expectedRevision: 4,
            expectedHash: canonicalPayloadHash(payload),
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Failure>());
      final error = (prepared as Failure).error;
      expect(error.message, contains('REVISION_CONFLICT'));
    });

    test('prepare rejects an expectedHash mismatch on an envelope target',
        () async {
      final payload = {'k': 'v'};
      await File('${tempDir.path}/assets.json')
          .writeAsString(makeEnvelope(payload, revision: 5).encode());
      final next = makeEnvelope({'k': 'v2'}, revision: 6);

      final plan = CommitPlan(
        transactionId: 'txn-011',
        targets: [
          CommitTarget(
            relativePath: 'assets.json',
            newContent: next.encode(),
            expectedRevision: 5,
            expectedHash: 'b' * 64,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Failure>());
      final error = (prepared as Failure).error;
      expect(error.message, contains('REVISION_CONFLICT'));
    });

    test('prepare computes after revision and apply returns actual hash',
        () async {
      final payload = {'k': 'v'};
      await File('${tempDir.path}/assets.json')
          .writeAsString(makeEnvelope(payload, revision: 5).encode());
      final next = makeEnvelope({'k': 'v2'}, revision: 6);

      final plan = CommitPlan(
        transactionId: 'txn-012',
        targets: [
          CommitTarget(
            relativePath: 'assets.json',
            newContent: next.encode(),
            expectedRevision: 5,
            expectedHash: canonicalPayloadHash(payload),
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Success<PreparedCommit>>());
      final entry = ((prepared as Success<PreparedCommit>).value).entries.single;
      expect(entry.beforeRevision, 5);
      expect(entry.afterRevision, 6);

      final applied = await store.apply((prepared as Success<PreparedCommit>).value);
      expect(applied, isA<Success<CommitResult>>());
      final result = (applied as Success).value;
      expect(result.afterHashes['assets.json'], canonicalPayloadHash({'k': 'v2'}));
      expect(result.afterRevisions['assets.json'], 6);

      // Complete payload equality after replacement.
      final onDisk =
          CanonicalJsonEnvelope.decode(await File('${tempDir.path}/assets.json').readAsString());
      expect(onDisk, next);
    });
  });

  group('apply-time revalidation', () {
    test('apply rejects a prepared entry whose path became unsafe', () async {
      final unsafe = PreparedCommit(
        transactionId: 'txn-013',
        entries: [
          PreparedEntry(
            relativePath: '../escape.md',
            beforeHash: '',
            afterHash: '',
            newContent: 'x',
            existed: false,
          ),
        ],
      );

      final applied = await store.apply(unsafe);
      expect(applied, isA<Failure>());
      final error = (applied as Failure).error;
      expect(error.message, contains('PATH_ESCAPE'));
      expect(File('${tempDir.path}/../escape.md').existsSync(), isFalse);
    });
  });

  group('project-owned store', () {
    test('projectOwned binds the store to the resolved root', () async {
      final rootDir = Directory('${tempDir.path}/sub/root')
        ..createSync(recursive: true);
      final owned = FileCanonicalStore.projectOwned(
        ResolvedProjectRoot(
          projectId: 'proj-1',
          rootPath: rootDir.path,
        ),
        atomicStore: AtomicFileStore(),
      );

      final plan = CommitPlan(
        transactionId: 'txn-014',
        targets: [
          CommitTarget(
            relativePath: 'chapters/ch01.md',
            newContent: 'owned content',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await owned.prepare(plan);
      expect(prepared, isA<Success<PreparedCommit>>());
      final applied = await owned.apply((prepared as Success).value);
      expect(applied, isA<Success<CommitResult>>());
      expect(
        await File('${tempDir.path}/sub/root/chapters/ch01.md').readAsString(),
        'owned content',
      );
    });
  });

  group('complete payload equality', () {
    test('disk bytes equal the committed payload after replacement', () async {
      const payload = '# 第一章\n\n第一段内容。\r\n第二段。';
      final plan = CommitPlan(
        transactionId: 'txn-015',
        targets: [
          CommitTarget(
            relativePath: 'chapters/ch01.md',
            newContent: payload,
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      final applied = await store.apply((prepared as Success).value);
      expect(applied, isA<Success<CommitResult>>());

      final onDisk = await File('${tempDir.path}/chapters/ch01.md').readAsString();
      expect(onDisk, payload);
    });
  });

  group('symlink/junction escape', () {
    test('prepare rejects a target escaping the root via junction', () async {
      final outside = Directory('${tempDir.path}-outside')..createSync();
      addTearDown(() {
        if (outside.existsSync()) outside.deleteSync(recursive: true);
      });
      final junction = '${tempDir.path}/escape-junction';
      final proc = await Process.run(
        'cmd',
        ['/c', 'mklink', '/J', junction, outside.path],
      );
      if (proc.exitCode != 0) {
        // Host without junction privileges: deterministic rejection tests
        // cover the guard; the host check is marked in the QA report.
        // ignore: avoid_print
        print('SKIP junction escape: mklink unavailable (${proc.stderr})');
        return;
      }
      addTearDown(() {
        if (Directory(junction).existsSync()) Directory(junction).deleteSync();
      });

      final plan = CommitPlan(
        transactionId: 'txn-016',
        targets: [
          CommitTarget(
            relativePath: 'escape-junction/evil.md',
            newContent: 'x',
            expectedHash: null,
          ),
        ],
      );

      final prepared = await store.prepare(plan);
      expect(prepared, isA<Failure>());
      final error = (prepared as Failure).error;
      expect(error.message, contains('PATH_ESCAPE'));
    });
  });
}
