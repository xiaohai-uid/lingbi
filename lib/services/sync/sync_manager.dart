/// SyncManager — 云同步编排器
///
/// 职责：
/// - 管理同步状态机（idle → syncing → done/error）
/// - 协调 WebDavService 完成文件同步
/// - 冲突检测与解决策略
/// - 匿名数据贡献（opt-in）
library;

import 'package:uuid/uuid.dart';

import 'webdav_service.dart';

const _uuid = Uuid();

/// 同步状态
enum SyncState { idle, syncing, done, error }

/// 同步状态快照
class SyncStatus {
  const SyncStatus({
    required this.state,
    this.lastSyncAt,
    this.error,
    this.progress = '',
  });

  final SyncState state;
  final DateTime? lastSyncAt;
  final String? error;
  final String progress;

  bool get isIdle => state == SyncState.idle;
  bool get isSyncing => state == SyncState.syncing;
  bool get isDone => state == SyncState.done;
  bool get isError => state == SyncState.error;
}

/// 同步冲突条目
class SyncConflict {
  const SyncConflict({
    required this.filePath,
    required this.localModified,
    required this.remoteModified,
    this.resolution = ConflictResolution.unresolved,
  });

  final String filePath;
  final DateTime localModified;
  final DateTime remoteModified;
  final ConflictResolution resolution;

  /// 本地更新则本地优先
  bool get localIsNewer => localModified.isAfter(remoteModified);
}

/// 冲突解决策略
enum ConflictResolution { unresolved, keepLocal, keepRemote, merge }

/// 本地文件信息（增量同步用）
class LocalFileInfo {
  const LocalFileInfo({
    required this.content,
    required this.lastModified,
  });

  /// 文件内容
  final String content;

  /// 最后修改时间
  final DateTime lastModified;
}

/// 匿名数据贡献配置
class AnalyticsConsent {
  AnalyticsConsent({
    this.enabled = true,
    String? anonymousId,
  }) : anonymousId = (anonymousId == null || anonymousId.isEmpty)
            ? _uuid.v4()
            : anonymousId;

  factory AnalyticsConsent.fromJson(Map<String, dynamic> json) {
    return AnalyticsConsent(
      enabled: json['enabled'] as bool? ?? true,
      anonymousId: json['anonymousId'] as String? ?? '',
    );
  }

  /// 是否启用匿名数据贡献
  final bool enabled;

  /// 匿名标识（不含任何个人信息）
  final String anonymousId;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'anonymousId': anonymousId,
      };
}

/// 匿名统计载荷 — 仅包含不可逆聚合数据
class AnalyticsPayload {
  const AnalyticsPayload({
    required this.anonymousId,
    this.genre = '',
    this.platform = '',
    this.totalWords = 0,
    this.chapterCount = 0,
    this.skillUsageCount = const {},
  });

  final String anonymousId;
  final String genre;
  final String platform;
  final int totalWords;
  final int chapterCount;
  final Map<String, int> skillUsageCount;

  Map<String, dynamic> toJson() => {
        'anonymousId': anonymousId,
        'genre': genre,
        'platform': platform,
        'totalWords': totalWords,
        'chapterCount': chapterCount,
        'skillUsageCount': skillUsageCount,
      };
}

/// 同步编排器
///
/// 管理 WebDAV 同步生命周期：
/// 1. 检查配置完整性
/// 2. 扫描本地变更
/// 3. 与远端对比（冲突检测）
/// 4. 执行上传/下载
/// 5. 更新状态
class SyncManager {
  SyncManager({
    required WebDavConfig config,
    WebDavService? webDavService,
  })  : _config = config,
        _webDav = webDavService ??
            (config.isEnabled ? WebDavService(config: config) : null);

  final WebDavConfig _config;
  final WebDavService? _webDav;

  SyncStatus _status = const SyncStatus(state: SyncState.idle);

  /// 当前同步状态
  SyncStatus get status => _status;

  /// 配置是否完整可用
  bool get isConfigured => _config.isEnabled;

  /// 冲突列表（最近一次同步产生的）
  final List<SyncConflict> conflicts = [];

  /// 执行全量同步
  ///
  /// [localFiles] 为本地文件路径→内容映射。
  /// 返回同步成功的文件数。
  Future<int> syncAll(Map<String, String> localFiles) async {
    if (!isConfigured || _webDav == null) return 0;

    _status = const SyncStatus(state: SyncState.syncing, progress: '准备同步...');
    conflicts.clear();

    try {
      var synced = 0;
      final total = localFiles.length;

      for (final entry in localFiles.entries) {
        _status = SyncStatus(
          state: SyncState.syncing,
          progress: '正在上传 ${synced + 1}/$total 个文件...',
        );

        final success = await _webDav.uploadFile(entry.key, entry.value);
        if (success) synced++;
      }

      _status = SyncStatus(
        state: SyncState.done,
        lastSyncAt: DateTime.now(),
        progress: '同步完成: $synced/$total 个文件',
      );
      return synced;
    } catch (e) {
      _status = SyncStatus(
        state: SyncState.error,
        error: e.toString(),
      );
      return 0;
    }
  }

  /// 增量同步 — 基于文件修改时间戳，只传变更文件
  ///
  /// [localFiles] — 本地文件路径→(content, lastModified) 映射
  /// [lastSyncTimestamps] — 上次同步时各文件的修改时间
  /// 返回同步成功的文件数。
  Future<int> syncIncremental({
    required Map<String, LocalFileInfo> localFiles,
    required Map<String, DateTime> lastSyncTimestamps,
  }) async {
    if (!isConfigured || _webDav == null) return 0;

    _status = const SyncStatus(state: SyncState.syncing, progress: '扫描变更...');
    conflicts.clear();

    try {
      // 筛选变更文件
      final changedFiles = <String, LocalFileInfo>{};
      for (final entry in localFiles.entries) {
        final lastSync = lastSyncTimestamps[entry.key];
        if (lastSync == null ||
            entry.value.lastModified.isAfter(lastSync)) {
          changedFiles[entry.key] = entry.value;
        }
      }

      if (changedFiles.isEmpty) {
        _status = SyncStatus(
          state: SyncState.done,
          lastSyncAt: DateTime.now(),
          progress: '无变更文件',
        );
        return 0;
      }

      // 检测冲突（远端也修改了）
      final remoteEntries = await _webDav.listDirectory('lingbi');
      for (final remote in remoteEntries) {
        if (remote.isCollection || remote.lastModified == null) continue;
        final local = changedFiles[remote.path];
        if (local != null) {
          final lastSync = lastSyncTimestamps[remote.path];
          if (lastSync != null &&
              remote.lastModified!.isAfter(lastSync) &&
              local.lastModified.isAfter(lastSync)) {
            // 双方都修改了 — 冲突
            conflicts.add(SyncConflict(
              filePath: remote.path,
              localModified: local.lastModified,
              remoteModified: remote.lastModified!,
              resolution: local.lastModified.isAfter(remote.lastModified!)
                  ? ConflictResolution.keepLocal
                  : ConflictResolution.keepRemote,
            ));
          }
        }
      }

      // 上传变更文件（跳过冲突中远端更新的）
      var synced = 0;
      final conflictRemoteWins = conflicts
          .where((c) => c.resolution == ConflictResolution.keepRemote)
          .map((c) => c.filePath)
          .toSet();

      for (final entry in changedFiles.entries) {
        if (conflictRemoteWins.contains(entry.key)) continue;

        _status = SyncStatus(
          state: SyncState.syncing,
          progress: '同步 ${synced + 1}/${changedFiles.length}...',
        );

        final success =
            await _webDav.uploadFile(entry.key, entry.value.content);
        if (success) synced++;
      }

      _status = SyncStatus(
        state: SyncState.done,
        lastSyncAt: DateTime.now(),
        progress: '增量同步完成: $synced 个文件'
            '${conflicts.isNotEmpty ? ", ${conflicts.length} 个冲突" : ""}',
      );
      return synced;
    } catch (e) {
      _status = SyncStatus(
        state: SyncState.error,
        error: e.toString(),
      );
      return 0;
    }
  }

  /// 测试连接
  Future<bool> testConnection() async {
    if (_webDav == null) return false;
    return _webDav.testConnection();
  }

  void dispose() {
    _webDav?.dispose();
  }
}
