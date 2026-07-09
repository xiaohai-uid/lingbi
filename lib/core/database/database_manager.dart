/// 数据库管理器 — 管理多世界数据库实例
///
/// 每个 World 有独立的 Drift 数据库文件，DatabaseManager 负责创建、缓存和生命周期管理。
library database_manager;

import 'package:lingbi/data/database/world_database.dart';

/// 数据库管理器
class DatabaseManager {
  /// 已打开的数据库缓存（worldId → WorldDatabase）
  final Map<String, WorldDatabase> _databases = {};

  /// 获取或创建指定世界的数据库
  Future<WorldDatabase> getDatabase(String worldId) async {
    if (_databases.containsKey(worldId)) {
      return _databases[worldId]!;
    }

    final executor = await openWorldDatabase(worldId);
    final db = WorldDatabase(executor);
    _databases[worldId] = db;

    return db;
  }

  /// 获取默认世界数据库
  Future<WorldDatabase> getDefaultDatabase() async {
    return getDatabase('default');
  }

  /// 关闭指定世界的数据库
  Future<void> closeDatabase(String worldId) async {
    final db = _databases.remove(worldId);
    if (db != null) {
      await db.close();
    }
  }

  /// 关闭所有数据库
  Future<void> closeAll() async {
    for (final db in _databases.values) {
      await db.close();
    }
    _databases.clear();
  }

  /// 获取当前打开的数据库数量
  int get openCount => _databases.length;

  /// 获取所有已打开的世界 ID
  List<String> get openWorldIds => _databases.keys.toList();
}
