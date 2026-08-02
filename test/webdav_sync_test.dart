/// WebDAV 云同步 — 单元测试
///
/// 覆盖：上传/下载/冲突/增量/MutationProtocol 集成
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/sync/data/sync/webdav_service.dart';
import 'package:lingbi/features/sync/data/sync/sync_manager.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';

void main() {
  group('WebDavConfig', () {
    test('isEnabled 配置完整时为 true', () {
      const config = WebDavConfig(
        serverUrl: 'https://dav.jianguoyun.com/dav',
        username: 'user@example.com',
        password: 'token123',
      );
      expect(config.isEnabled, true);
    });

    test('isEnabled 缺少配置时为 false', () {
      const config = WebDavConfig(
        serverUrl: '',
        username: '',
        password: '',
      );
      expect(config.isEnabled, false);
    });

    test('fromJson / toJson 往返一致', () {
      const config = WebDavConfig(
        serverUrl: 'https://nextcloud.local/remote.php/dav/files/user',
        username: 'admin',
        password: 'secret',
        syncSkills: false,
        syncConversations: true,
      );

      final json = config.toJson();
      final restored = WebDavConfig.fromJson(json);

      expect(restored.serverUrl, config.serverUrl);
      expect(restored.username, 'admin');
      expect(restored.syncProjects, true);
      expect(restored.syncSkills, false);
      expect(restored.syncConversations, true);
    });

    test('copyWith 正确更新字段', () {
      const config = WebDavConfig(
        serverUrl: 'https://a.com',
        username: 'u1',
        password: 'p1',
      );
      final updated = config.copyWith(username: 'u2', enabled: false);
      expect(updated.username, 'u2');
      expect(updated.enabled, false);
      expect(updated.serverUrl, 'https://a.com');
    });
  });

  group('SyncManager 状态机', () {
    test('未配置时 isConfigured 为 false', () {
      final manager = SyncManager(
        config: const WebDavConfig(
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      expect(manager.isConfigured, false);
      expect(manager.status.isIdle, true);
    });

    test('未配置时 syncAll 返回 0', () async {
      final manager = SyncManager(
        config: const WebDavConfig(
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      final count = await manager.syncAll({'file.md': 'content'});
      expect(count, 0);
    });

    test('未配置时 syncIncremental 返回 0', () async {
      final manager = SyncManager(
        config: const WebDavConfig(
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      final count = await manager.syncIncremental(
        localFiles: {
          'a.md': LocalFileInfo(
            content: 'hello',
            lastModified: DateTime.now(),
          ),
        },
        lastSyncTimestamps: {},
      );
      expect(count, 0);
    });
  });

  group('SyncConflict 冲突检测', () {
    test('localIsNewer 正确判断', () {
      final conflict = SyncConflict(
        filePath: 'test.md',
        localModified: DateTime(2026, 7, 20),
        remoteModified: DateTime(2026, 7, 15),
      );
      expect(conflict.localIsNewer, true);
    });

    test('远端更新时 localIsNewer 为 false', () {
      final conflict = SyncConflict(
        filePath: 'test.md',
        localModified: DateTime(2026, 7, 10),
        remoteModified: DateTime(2026, 7, 20),
      );
      expect(conflict.localIsNewer, false);
    });
  });

  group('LocalFileInfo', () {
    test('正确存储内容和时间戳', () {
      final info = LocalFileInfo(
        content: '# 标题\n内容',
        lastModified: DateTime(2026, 7, 25, 10, 30),
      );
      expect(info.content, contains('标题'));
      expect(info.lastModified.hour, 10);
    });
  });

  group('SyncStatus', () {
    test('状态判断方法正确', () {
      const idle = SyncStatus(state: SyncState.idle);
      expect(idle.isIdle, true);
      expect(idle.isSyncing, false);

      const syncing = SyncStatus(state: SyncState.syncing, progress: '50%');
      expect(syncing.isSyncing, true);

      const done = SyncStatus(state: SyncState.done);
      expect(done.isDone, true);

      const error = SyncStatus(state: SyncState.error, error: 'timeout');
      expect(error.isError, true);
      expect(error.error, 'timeout');
    });
  });

  group('WebDavEntry', () {
    test('正确表示文件和目录', () {
      const file = WebDavEntry(
        path: '/lingbi/project1/ch1.md',
        isCollection: false,
        contentLength: 1024,
      );
      expect(file.isCollection, false);
      expect(file.contentLength, 1024);

      const dir = WebDavEntry(
        path: '/lingbi/project1/',
        isCollection: true,
      );
      expect(dir.isCollection, true);
    });
  });

  group('SyncManager applyIncoming MutationProtocol', () {
    test('applyIncoming 经 MutationProtocol 创建 journal 记录', () async {
      final temp = Directory.systemTemp.createTempSync('lingbi_sync_mutation_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final journalDir = Directory('${temp.path}/journal')..createSync();
      final protocol = LocalMutationProtocol(
        journal: LocalMutationJournal(basePath: journalDir.path),
        store: FileCanonicalStore(
          projectRoot: temp.path,
          atomicStore: AtomicFileStore(),
        ),
      );
      final manager = SyncManager(
        config: const WebDavConfig(serverUrl: '', username: '', password: ''),
        mutationProtocol: protocol,
      );

      // Apply incoming file from remote
      await manager.applyIncoming(
        relativePath: 'chapters/ch1.md',
        content: '# 第1章\n\n远端内容',
        projectDir: temp.path,
      );

      // T01: batchImport origin uses propose-only (explicit approval required)
      // File is NOT written until user approves the candidate
      final file = File('${temp.path}/chapters/ch1.md');
      expect(file.existsSync(), isFalse,
          reason: 'sync incoming must not auto-write; requires approval');

      // Journal has proposed event only (no auto-commit)
      final journal = LocalMutationJournal(basePath: journalDir.path);
      final events = await journal.readAll();
      final types = events.map((e) => e.eventType).toList();
      expect(types, contains('candidate_proposed'));
      expect(types, isNot(contains('candidate_committed')));
    });
  });
}
