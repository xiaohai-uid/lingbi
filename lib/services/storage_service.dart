import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 文件存储服务 — Windows 上 zvec 不可用时的降级方案
class StorageService {

  StorageService();
  String? _basePath;
  bool _initialized = false;

  /// 写操作串行化锁，防止并发读-改-写丢数据
  Future<void> _writeLock = Future.value();

  bool get isInitialized => _initialized;

  Future<void> initialize({String? dbPath}) async {
    if (_initialized) return;
    if (dbPath != null) {
      _basePath = dbPath;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _basePath = '${dir.path}/lingbi_data';
    }
    await Directory(_basePath!).create(recursive: true);
    _initialized = true;
  }

  Future<List<Map<String, dynamic>>> query(
    String collection, {
    Map<String, dynamic>? filter,
    int limit = 50,
  }) async {
    final items = await _loadCollection(collection);
    if (filter == null) return items.take(limit).toList();
    return items.where((item) {
      for (final f in filter.entries) {
        if (item[f.key] != f.value) return false;
      }
      return true;
    }).take(limit).toList();
  }

  Future<Map<String, dynamic>?> get(String collection, String id) async {
    final items = await _loadCollection(collection);
    try {
      return items.firstWhere((item) => item['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(String collection, String id, Map<String, dynamic> data) {
    // 串行化：每个写操作等待前一个完成，防止并发读-改-写丢数据
    final future = _writeLock.then((_) => _doUpsert(collection, id, data));
    _writeLock = future.then((_) {}, onError: (_) {});
    return future;
  }

  Future<void> _doUpsert(String collection, String id, Map<String, dynamic> data) async {
    final items = await _loadCollection(collection);
    final index = items.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      items[index] = data;
    } else {
      items.add(data);
    }
    await _saveCollection(collection, items);
  }

  Future<void> delete(String collection, String id) {
    final future = _writeLock.then((_) => _doDelete(collection, id));
    _writeLock = future.then((_) {}, onError: (_) {});
    return future;
  }

  Future<void> _doDelete(String collection, String id) async {
    final items = await _loadCollection(collection);
    items.removeWhere((item) => item['id'] == id);
    await _saveCollection(collection, items);
  }

  Future<List<Map<String, dynamic>>> _loadCollection(String name) async {
    final file = File('$_basePath/$name.json');
    if (!await file.exists()) return [];
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      debugPrint('StorageService: $name.json 内容不是 List，返回空列表');
      return [];
    } catch (e) {
      debugPrint('StorageService: 损坏的 JSON 文件 $name.json，返回空列表 — $e');
      return [];
    }
  }

  Future<void> _saveCollection(String name, List<Map<String, dynamic>> items) async {
    final file = File('$_basePath/$name.json');
    final tmpFile = File('$_basePath/$name.json.tmp');
    try {
      // 先写临时文件
      await tmpFile.writeAsString(jsonEncode(items));
      // 原子重命名覆盖目标文件（Windows 同盘 rename 是原子操作）
      await tmpFile.rename(file.path);
    } catch (e) {
      // 临时文件写/重命名失败，清理后 fallback 到直接写
      debugPrint('StorageService: 原子写失败，回退到直接写 — $e');
      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
      await file.writeAsString(jsonEncode(items));
    }
  }
}
