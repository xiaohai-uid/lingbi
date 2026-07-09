import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 文件存储服务 — Windows 上 zvec 不可用时的降级方案
class StorageService {
  StorageService();
  String? _basePath;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize({String? dbPath}) async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _basePath = dbPath ?? '${dir.path}/lingbi_data';
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
    return items
        .where((item) {
          for (final f in filter.entries) {
            if (item[f.key] != f.value) return false;
          }
          return true;
        })
        .take(limit)
        .toList();
  }

  Future<Map<String, dynamic>?> get(String collection, String id) async {
    final items = await _loadCollection(collection);
    try {
      return items.firstWhere((item) => item['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(
      String collection, String id, Map<String, dynamic> data) async {
    final items = await _loadCollection(collection);
    final index = items.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      items[index] = data;
    } else {
      items.add(data);
    }
    await _saveCollection(collection, items);
  }

  Future<void> delete(String collection, String id) async {
    final items = await _loadCollection(collection);
    items.removeWhere((item) => item['id'] == id);
    await _saveCollection(collection, items);
  }

  Future<List<Map<String, dynamic>>> _loadCollection(String name) async {
    final file = File('$_basePath/$name.json');
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    return List<Map<String, dynamic>>.from(jsonDecode(content));
  }

  Future<void> _saveCollection(
      String name, List<Map<String, dynamic>> items) async {
    final file = File('$_basePath/$name.json');
    await file.writeAsString(jsonEncode(items));
  }
}
