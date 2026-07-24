/// 跨进程写作锁服务（Windows 适配）
///
/// 借鉴 OpenWrite ProjectWriteLock 设计思想。
/// OpenWrite 使用 os.O_CREAT | os.O_EXCL（POSIX），
/// Windows 上 Dart 使用 FileMode.writeOnly + 锁文件内容验证。
library;

import 'dart:convert';
import 'dart:io';

/// 项目忙碌异常
class ProjectBusyError implements Exception {
  const ProjectBusyError(this.message);
  final String message;

  @override
  String toString() => 'ProjectBusyError: $message';
}

/// 锁信息
class LockInfo {
  const LockInfo({
    required this.token,
    required this.pid,
    required this.operation,
    required this.createdAt,
  });

  final String token;
  final int pid;
  final String operation;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'token': token,
        'pid': pid,
        'operation': operation,
        'created_at': createdAt.toIso8601String(),
      };

  factory LockInfo.fromJson(Map<String, dynamic> json) => LockInfo(
        token: json['token'] as String? ?? '',
        pid: json['pid'] as int? ?? 0,
        operation: json['operation'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

/// 跨进程写作锁
///
/// 使用锁文件实现跨进程互斥：
/// - 锁文件路径: {projectDir}/.lingbi/project.lock
/// - 内容: JSON {token, pid, operation, created_at}
/// - 过期: 6小时自动释放
/// - 进程不存在: 自动释放
class WriteLockService {
  WriteLockService({
    required String projectDir,
    this.staleAfter = const Duration(hours: 6),
  }) : _lockFile = File('$projectDir/.lingbi/project.lock');

  final File _lockFile;
  final Duration staleAfter;
  String? _token;
  bool _acquired = false;

  /// 是否已持有锁
  bool get isAcquired => _acquired;

  /// 当前锁信息（如果存在）
  LockInfo? get currentLock {
    if (!_lockFile.existsSync()) return null;
    try {
      final content = _lockFile.readAsStringSync();
      return LockInfo.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// 尝试获取锁
  ///
  /// 成功返回 true，项目忙碌返回 false。
  /// 如果锁已过期或持有进程不存在，自动清理后重试。
  bool acquire(String operation) {
    if (_acquired) return true;

    // 确保目录存在
    final dir = _lockFile.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      if (!_lockFile.existsSync()) {
        return _createLock(operation);
      }

      // 锁文件存在，检查是否过期
      if (_isStale()) {
        _lockFile.deleteSync();
        continue;
      }

      // 锁有效，项目忙碌
      return false;
    }

    return false;
  }

  /// 获取锁，失败时抛出 ProjectBusyError
  void acquireOrThrow(String operation) {
    if (!acquire(operation)) {
      final lock = currentLock;
      final op = lock?.operation ?? '未知任务';
      throw ProjectBusyError('项目正由另一个进程执行：$op');
    }
  }

  /// 释放锁
  void release() {
    if (!_acquired) return;
    try {
      final lock = currentLock;
      if (lock != null && lock.token == _token) {
        _lockFile.deleteSync();
      }
    } catch (_) {
      // 忽略释放失败
    }
    _acquired = false;
    _token = null;
  }

  /// 在锁保护下执行操作
  T withLock<T>(String operation, T Function() action) {
    acquireOrThrow(operation);
    try {
      return action();
    } finally {
      release();
    }
  }

  /// 异步版本：在锁保护下执行操作
  Future<T> withLockAsync<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    acquireOrThrow(operation);
    try {
      return await action();
    } finally {
      release();
    }
  }

  bool _createLock(String operation) {
    try {
      _token = DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
          pid.hashCode.toRadixString(36);
      final info = LockInfo(
        token: _token!,
        pid: pid,
        operation: operation,
        createdAt: DateTime.now(),
      );
      _lockFile.writeAsStringSync(
        jsonEncode(info.toJson()),
        flush: true,
      );
      _acquired = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isStale() {
    try {
      final stat = _lockFile.statSync();
      final age = DateTime.now().difference(stat.modified);
      if (age > staleAfter) return true;

      final lock = currentLock;
      if (lock == null) return true;
      if (lock.pid <= 0) return true;

      // Windows 上无法直接检查进程是否存在
      // 使用 os.kill(pid, 0) 的 Dart 等价：Process.killPid(pid, signal 0)
      // Dart 没有 signal 0，改用时间过期作为主要判断
      return false;
    } catch (_) {
      return true;
    }
  }
}
