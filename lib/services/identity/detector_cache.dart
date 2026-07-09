/// DetectorCache — 身份检测结果缓存
///
/// LRU 策略，按场景ID缓存，用户编辑后失效。
library detector_cache;

import 'identity_detector.dart';

/// 检测结果缓存
class DetectorCache {
  // LRU 顺序

  DetectorCache({this.maxSize = 50});
  final int maxSize;
  final _cache = <String, _CacheEntry>{};
  final _accessOrder = <String>[];

  /// 获取缓存
  DetectionResult? get(String sceneId) {
    final entry = _cache[sceneId];
    if (entry == null) return null;

    // 更新访问顺序
    _accessOrder.remove(sceneId);
    _accessOrder.add(sceneId);

    return entry.result;
  }

  /// 写入缓存
  void set(String sceneId, DetectionResult result) {
    if (_cache.length >= maxSize && !_cache.containsKey(sceneId)) {
      // 淘汰最久未使用的
      final oldest = _accessOrder.removeAt(0);
      _cache.remove(oldest);
    }

    _cache[sceneId] = _CacheEntry(result: result);
    _accessOrder.remove(sceneId);
    _accessOrder.add(sceneId);
  }

  /// 失效（用户编辑后调用）
  void invalidate(String sceneId) {
    _cache.remove(sceneId);
    _accessOrder.remove(sceneId);
  }

  /// 清空缓存
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// 当前缓存大小
  int get size => _cache.length;
}

class _CacheEntry {
  _CacheEntry({required this.result}) : cachedAt = DateTime.now();
  final DetectionResult result;
  final DateTime cachedAt;
}
