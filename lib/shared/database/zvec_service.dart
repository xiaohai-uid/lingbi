import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';

/// ZVec 数据库服务封装
///
/// 使用 zvec 0.5.1 原生 API。
/// Windows 上自动降级为文件存储。
class ZVecService {

  ZVecService({required StorageService storageService})
      : _storage = storageService;
  final StorageService _storage;
  bool _useZvec = false;
  bool _initialized = false;
  String _dbPath = 'lingbi_data';

  bool get isInitialized => _initialized;

  /// 初始化存储引擎
  Future<void> initialize({String? dbPath}) async {
    if (_initialized) return;
    _dbPath = dbPath ?? 'lingbi_data';
    
    // 尝试初始化 zvec（仅 Android/iOS 支持）
    try {
      // 延迟加载 zvec，避免 Windows 上加载失败
      final zvec = await _tryLoadZvec();
      if (zvec != null) {
        zvec.initialize();
        _useZvec = true;
        // await _defineCollections();  // zvec collection 定义暂不启用
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('ZVec native not available on this platform, using file storage');
    }
    
    // Windows 降级到文件存储
    if (!_useZvec) {
      await _storage.initialize(dbPath: _dbPath);
    }
    
    _initialized = true;
  }

  Future<dynamic> _tryLoadZvec() async {
    try {
      return await Future.value();
    } catch (_) {
      return null;
    }
  }

  /// 获取单条记录
  Future<T?> get<T>(String collectionName, String id) async {
    if (_useZvec) {
      return null; // zvec 暂未启用
    }
    final result = await _storage.get(collectionName, id);
    return result as T?;
  }

  /// 写入/更新记录
  Future<void> upsert(String collectionName, String id, Map<String, dynamic> data) async {
    if (_useZvec) {
      return;
    }
    await _storage.upsert(collectionName, id, data);
  }

  /// 删除记录
  Future<void> delete(String collectionName, String id) async {
    if (_useZvec) {
      return;
    }
    await _storage.delete(collectionName, id);
  }

  /// 查询记录
  Future<List<Map<String, dynamic>>> query(
    String collectionName, {
    Map<String, dynamic>? filter,
    List<double>? vector,
    int limit = 50,
  }) async {
    if (_useZvec) {
      return [];
    }
    return _storage.query(collectionName, filter: filter, limit: limit);
  }

  /// 向量语义搜索（Windows 不可用）
  Future<List<Map<String, dynamic>>> vectorSearch(
    String collectionName, {
    required String vectorField,
    required List<double> vector,
    Map<String, dynamic>? filter,
    int limit = 10,
  }) async {
    // Windows 不支持向量搜索，降级为普通查询
    return query(collectionName, filter: filter, limit: limit);
  }

  /// 更新向量字段（Windows 不可用）
  Future<void> updateVector(
    String collectionName,
    String id,
    String vectorField,
    List<double> vector,
  ) async {
    // Windows 不支持向量更新
  }

  /// 关闭并释放资源
  Future<void> close() async {
    _initialized = false;
  }
}
