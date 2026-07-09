import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:version/lib/version_service.dart';

void main() {
  late VersionService service;
  late String dbPath;

  setUp(() {
    dbPath = '/tmp/test_version_${DateTime.now().millisecondsSinceEpoch}.db';
    service = VersionService();
    service._dbPath = dbPath;
    service.init();
  });

  tearDown(() {
    service.dispose();
    try {
      File(dbPath).deleteSync();
    } catch (e) {}
  });

  test('createSnapshot creates and stores a version', () {
    final snapshot = service.createSnapshot(
      docId: 'doc-1',
      content: 'Hello World',
      comment: 'Initial version',
      author: 'test',
    );

    expect(snapshot.id, contains('doc-1'));
    expect(snapshot.docId, 'doc-1');
    expect(snapshot.content, 'Hello World');
    expect(snapshot.comment, 'Initial version');
    expect(snapshot.author, 'test');
  });

  test('getVersionHistory returns versions in descending order', () {
    service.createSnapshot(docId: 'doc-1', content: 'v1', author: 'test');
    service.createSnapshot(docId: 'doc-1', content: 'v2', author: 'test');
    service.createSnapshot(docId: 'doc-1', content: 'v3', author: 'test');

    final history = service.getVersionHistory('doc-1');
    expect(history.length, 3);
    expect(history[0].content, 'v3');
    expect(history[2].content, 'v1');
  });

  test('getVersionHistory returns empty for unknown doc', () {
    final history = service.getVersionHistory('nonexistent');
    expect(history, isEmpty);
  });

  test('getVersionSnapshot returns specific version', () {
    final snapshot =
        service.createSnapshot(docId: 'doc-1', content: 'v1', author: 'test');
    final result = service.getVersionSnapshot('doc-1', snapshot.id);

    expect(result, isNotNull);
    expect(result!.content, 'v1');
  });

  test('getVersionSnapshot returns null for unknown version', () {
    final result = service.getVersionSnapshot('doc-1', 'unknown');
    expect(result, isNull);
  });

  test('getDiff computes line-based diff', () {
    final v1 = service.createSnapshot(
        docId: 'doc-1', content: 'line1\nline2\nline3', author: 'test');
    final v2 = service.createSnapshot(
        docId: 'doc-1', content: 'line1\nmodified\nline3', author: 'test');

    final diff = service.getDiff('doc-1', v1.id, v2.id);
    expect(diff.changes.length, 1);
    expect(diff.changes[0]['type'], 'modified');
    expect(diff.changes[0]['old'], 'line2');
    expect(diff.changes[0]['new'], 'modified');
  });

  test('getDiff detects added lines', () {
    final v1 = service.createSnapshot(
        docId: 'doc-1', content: 'line1', author: 'test');
    final v2 = service.createSnapshot(
        docId: 'doc-1', content: 'line1\nline2', author: 'test');

    final diff = service.getDiff('doc-1', v1.id, v2.id);
    expect(diff.changes.length, 1);
    expect(diff.changes[0]['type'], 'added');
  });

  test('getDiff detects removed lines', () {
    final v1 = service.createSnapshot(
        docId: 'doc-1', content: 'line1\nline2', author: 'test');
    final v2 = service.createSnapshot(
        docId: 'doc-1', content: 'line1', author: 'test');

    final diff = service.getDiff('doc-1', v1.id, v2.id);
    expect(diff.changes.length, 1);
    expect(diff.changes[0]['type'], 'removed');
  });

  test('cleanupOldVersions keeps only recent versions', () {
    for (int i = 0; i < 15; i++) {
      service.createSnapshot(docId: 'doc-1', content: 'v$i', author: 'test');
    }

    final deleted = service.cleanupOldVersions('doc-1', keepCount: 5);
    expect(deleted, 10);

    final remaining = service.getVersionHistory('doc-1');
    expect(remaining.length, 5);
  });

  test('cleanupOldVersions returns 0 when not enough versions', () {
    service.createSnapshot(docId: 'doc-1', content: 'v1', author: 'test');
    service.createSnapshot(docId: 'doc-1', content: 'v2', author: 'test');

    final deleted = service.cleanupOldVersions('doc-1', keepCount: 10);
    expect(deleted, 0);
  });

  test('restoreVersion returns snapshot content', () {
    final v1 = service.createSnapshot(
        docId: 'doc-1', content: 'old content', author: 'test');
    final restored = service.restoreVersion('doc-1', v1.id);

    expect(restored.content, 'old content');
  });

  test('restoreVersion throws for unknown version', () {
    expect(
      () => service.restoreVersion('doc-1', 'unknown'),
      throwsException,
    );
  });
}
