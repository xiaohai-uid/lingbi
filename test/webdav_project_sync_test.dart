import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/sync/data/sync/project_sync_manifest.dart';
import 'package:lingbi/features/sync/data/sync/three_way_merge_service.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_sync_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('project sync manifest', () {
    test('generates a manifest covering all portable assets', () {
      final manifest = ProjectSyncManifest.generate(
        projectId: 'proj-1',
        assets: const [
          SyncAsset(path: '.lingbi/project.json', hash: 'abc123'),
          SyncAsset(path: 'documents/ch001.md', hash: 'def456'),
          SyncAsset(path: 'canon/characters.json', hash: 'ghi789'),
          SyncAsset(path: 'candidates/cand-001.json', hash: 'jkl012'),
          SyncAsset(path: 'versions/v001.snapshot', hash: 'mno345'),
        ],
      );

      expect(manifest.projectId, 'proj-1');
      expect(manifest.assets, hasLength(5));
      expect(manifest.generatedAt, isNotNull);
      expect(manifest.schemaVersion, greaterThan(0));
    });

    test('excludes secrets and API keys from sync', () {
      final manifest = ProjectSyncManifest.generate(
        projectId: 'proj-1',
        assets: const [
          SyncAsset(path: '.lingbi/project.json', hash: 'abc'),
          SyncAsset(path: '.env', hash: 'secret'),
          SyncAsset(path: 'settings/api_keys.json', hash: 'keys'),
          SyncAsset(path: 'documents/ch001.md', hash: 'def'),
        ],
      );

      // Secrets are excluded
      expect(manifest.assets, hasLength(2));
      expect(
        manifest.assets.map((a) => a.path),
        isNot(contains('.env')),
      );
      expect(
        manifest.assets.map((a) => a.path),
        isNot(contains('settings/api_keys.json')),
      );
    });
  });

  group('three-way merge', () {
    test('detects no conflict when only one side changed', () {
      const service = ThreeWayMergeService();
      final result = service.merge(
        base: 'Original content',
        local: 'Local modified content',
        remote: 'Original content',
      );

      expect(result.hasConflict, isFalse);
      expect(result.merged, 'Local modified content');
    });

    test('detects conflict when both sides changed differently', () {
      const service = ThreeWayMergeService();
      final result = service.merge(
        base: 'Original content',
        local: 'Local version',
        remote: 'Remote version',
      );

      expect(result.hasConflict, isTrue);
      expect(result.base, 'Original content');
      expect(result.local, 'Local version');
      expect(result.remote, 'Remote version');
    });

    test('no conflict when both sides made identical changes', () {
      const service = ThreeWayMergeService();
      final result = service.merge(
        base: 'Original',
        local: 'Same change',
        remote: 'Same change',
      );

      expect(result.hasConflict, isFalse);
      expect(result.merged, 'Same change');
    });

    test('never auto-resolves content conflicts silently', () {
      const service = ThreeWayMergeService();
      final result = service.merge(
        base: 'Base text',
        local: 'Local edit',
        remote: 'Remote edit',
      );

      // Conflict must be presented, not silently resolved
      expect(result.hasConflict, isTrue);
      expect(result.autoResolved, isFalse);
    });
  });

  group('sync operations', () {
    test('interrupted upload can be resumed from manifest', () {
      final manifest = ProjectSyncManifest.generate(
        projectId: 'proj-1',
        assets: const [
          SyncAsset(path: 'documents/ch001.md', hash: 'a1'),
          SyncAsset(path: 'documents/ch002.md', hash: 'b2'),
          SyncAsset(path: 'documents/ch003.md', hash: 'c3'),
        ],
      );

      // Simulate: first asset was uploaded, then interrupted
      final uploaded = {'documents/ch001.md'};
      final remaining = manifest.assets
          .where((a) => !uploaded.contains(a.path))
          .toList();

      expect(remaining, hasLength(2));
      expect(remaining.first.path, 'documents/ch002.md');
    });

    test('remote deletion is detected via manifest diff', () {
      final localManifest = ProjectSyncManifest.generate(
        projectId: 'proj-1',
        assets: const [
          SyncAsset(path: 'documents/ch001.md', hash: 'a1'),
          SyncAsset(path: 'documents/ch002.md', hash: 'b2'),
        ],
      );
      final remoteManifest = ProjectSyncManifest.generate(
        projectId: 'proj-1',
        assets: const [
          SyncAsset(path: 'documents/ch001.md', hash: 'a1'),
        ],
      );

      final diff = ProjectSyncManifest.diff(localManifest, remoteManifest);
      expect(diff.deletedRemotely, contains('documents/ch002.md'));
    });

    test('candidate and version files are preserved during sync', () {
      final manifest = ProjectSyncManifest.generate(
        projectId: 'proj-1',
        assets: const [
          SyncAsset(path: 'candidates/cand-001.json', hash: 'x'),
          SyncAsset(path: 'versions/v001.snapshot', hash: 'y'),
          SyncAsset(path: 'documents/ch001.md', hash: 'z'),
        ],
      );

      // Candidates and versions are marked as protected
      final protected = manifest.assets.where((a) => a.isProtected).toList();
      expect(protected, hasLength(2));
      expect(
        protected.map((a) => a.path),
        containsAll(['candidates/cand-001.json', 'versions/v001.snapshot']),
      );
    });
  });
}
