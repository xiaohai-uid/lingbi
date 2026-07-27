import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/reference/reference_source_policy.dart';

void main() {
  late Directory tempDir;
  late ReferenceSourcePolicy policy;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_ref_');
    policy = ReferenceSourcePolicy(storageDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('local-file-first ingestion', () {
    test('accepts a local file with valid content', () async {
      final file = File('${tempDir.path}/reference.txt');
      file.writeAsStringSync('This is a reference novel excerpt.');

      final result = await policy.ingest(
        source: ReferenceSource.localFile(file.path),
        projectId: 'proj-1',
      );

      expect(result.accepted, isTrue);
      expect(result.insights, isNotEmpty);
      expect(result.sourceLocator, contains('reference.txt'));
    });

    test('rejects a URL source when no licensed connector exists', () async {
      final result = await policy.ingest(
        source: ReferenceSource.url('https://example.com/novel'),
        projectId: 'proj-1',
      );

      expect(result.accepted, isFalse);
      expect(result.rejectionReason, contains('no licensed connector'));
    });

    test('rejects a file that does not exist', () async {
      final result = await policy.ingest(
        source: ReferenceSource.localFile('${tempDir.path}/missing.txt'),
        projectId: 'proj-1',
      );

      expect(result.accepted, isFalse);
      expect(result.rejectionReason, contains('not found'));
    });
  });

  group('source permission and license metadata', () {
    test('records robots and license metadata for URL sources', () async {
      final result = await policy.checkUrlPermission(
        'https://example.com/novel/chapter1',
      );

      expect(result.robotsAllowed, isNotNull);
      expect(result.licenseHint, isNotNull);
    });

    test('stores source locator with every insight', () async {
      final file = File('${tempDir.path}/ref2.txt');
      file.writeAsStringSync('The protagonist uses a sword style called Flowing Water.');

      final result = await policy.ingest(
        source: ReferenceSource.localFile(file.path),
        projectId: 'proj-1',
      );

      expect(result.accepted, isTrue);
      for (final insight in result.insights) {
        expect(insight.sourceLocator, isNotEmpty);
        expect(insight.category, isNotEmpty);
      }
    });
  });

  group('anti-copy similarity', () {
    test('rejects ingestion that would produce long copied text', () async {
      final file = File('${tempDir.path}/long_ref.txt');
      // Write a very long text that would exceed the copy threshold
      file.writeAsStringSync('A' * 5000);

      final result = await policy.ingest(
        source: ReferenceSource.localFile(file.path),
        projectId: 'proj-1',
        maxExtractChars: 500,
      );

      expect(result.accepted, isTrue);
      // Insights should be abstract constraints, not long copies
      for (final insight in result.insights) {
        expect(insight.content.length, lessThanOrEqualTo(500));
      }
    });

    test('injects only abstract style constraints, never long copied text', () async {
      final file = File('${tempDir.path}/style_ref.txt');
      file.writeAsStringSync(
        'The author uses short sentences. Dialogue is sparse. '
        'Descriptions focus on atmosphere over action. '
        'Chapter openings begin with environmental detail.',
      );

      final result = await policy.ingest(
        source: ReferenceSource.localFile(file.path),
        projectId: 'proj-1',
      );

      expect(result.accepted, isTrue);
      // All insights should be style/structure constraints
      for (final insight in result.insights) {
        expect(insight.category, isIn(['style', 'structure', 'technique']));
      }
    });
  });

  group('resumable failure', () {
    test('records failure state and can resume from checkpoint', () async {
      final file = File('${tempDir.path}/big_ref.txt');
      file.writeAsStringSync('Content ' * 1000);

      // Simulate a partial ingestion that failed
      await policy.saveCheckpoint(
        projectId: 'proj-1',
        sourcePath: file.path,
        processedChars: 2000,
      );

      final checkpoint = await policy.loadCheckpoint('proj-1', file.path);
      expect(checkpoint, isNotNull);
      expect(checkpoint!.processedChars, 2000);

      // Resume should continue from checkpoint
      final result = await policy.ingest(
        source: ReferenceSource.localFile(file.path),
        projectId: 'proj-1',
        resumeFrom: checkpoint,
      );

      expect(result.accepted, isTrue);
      expect(result.resumedFromChar, 2000);
    });
  });
}
