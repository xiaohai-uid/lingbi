import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/shared/errors/result.dart';

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
  });
}
