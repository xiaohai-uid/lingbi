/// 生成缓存 — 30 分钟 TTL
///
/// 缓存 Layer1/Layer2 结果，避免重复调用 LLM。
/// Key = 请求参数的 MD5 hash，Value = (result, expiryTime)。
library generation_cache;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class _CacheEntry<T> {
  final T result;
  final DateTime expiresAt;

  _CacheEntry(this.result, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class GenerationCache {
  static const _defaultTtl = Duration(minutes: 30);
  final Map<String, _CacheEntry> _cache = {};

  /// 生成缓存 key
  String _key(String prefix, Map<String, dynamic> params) {
    final sorted = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    final raw = '$prefix:${jsonEncode(sorted)}';
    final hash = md5.convert(utf8.encode(raw));
    return '$prefix:$hash';
  }

  /// 获取缓存
  T? get<T>(String prefix, Map<String, dynamic> params) {
    final entry = _cache[_key(prefix, params)];
    if (entry == null || entry.isExpired) {
      _cache.remove(_key(prefix, params));
      return null;
    }
    return entry.result as T?;
  }

  /// 设置缓存
  void set<T>(String prefix, Map<String, dynamic> params, T result,
      {Duration? ttl}) {
    final key = _key(prefix, params);
    _cache[key] = _CacheEntry(result, DateTime.now().add(ttl ?? _defaultTtl));
  }

  /// 清理过期缓存
  void cleanExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }

  /// 获取缓存大小
  int get size => _cache.length;

  /// 清空所有缓存
  void clear() {
    _cache.clear();
  }
}
