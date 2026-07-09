/// ResolverCache — ContextResolver 查询结果缓存
///
/// LRU 策略，按章节ID缓存，用户编辑后失效。
library resolver_cache;

import 'writing_context.dart';

/// 上下文解析器缓存
class ResolverCache {
  ResolverCache({this.maxSize = 50});
  final int maxSize;
  final _cache = <String, _CacheEntry>{};
  final _order = <String>[];

  WritingContext? get(String workId, String volumeId, String chapterId) {
    final key = '$workId/$volumeId/$chapterId';
    final entry = _cache[key];
    if (entry == null) return null;
    _order.remove(key);
    _order.add(key);
    return entry.context;
  }

  void set(String workId, String volumeId, String chapterId,
      WritingContext context) {
    final key = '$workId/$volumeId/$chapterId';

    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      final oldest = _order.removeAt(0);
      _cache.remove(oldest);
    }

    _cache[key] = _CacheEntry(context: context);
    _order.remove(key);
    _order.add(key);
  }

  void invalidate(String workId, String volumeId, String chapterId) {
    final key = '$workId/$volumeId/$chapterId';
    _cache.remove(key);
    _order.remove(key);
  }

  void clear() {
    _cache.clear();
    _order.clear();
  }

  int get size => _cache.length;
}

class _CacheEntry {
  _CacheEntry({required this.context}) : cachedAt = DateTime.now();
  final WritingContext context;
  final DateTime cachedAt;
}
