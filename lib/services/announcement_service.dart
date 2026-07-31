/// 公告服务 — 复刻 OpenWrite 的 announcement API。
///
/// 启动时检查公告，本地缓存 + 未读计数。
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.createdAt = '',
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
  );

  final int id;
  final String title;
  final String content;
  final String createdAt;
}

class AnnouncementService {
  AnnouncementService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _apiUrl = 'http://111.170.163.42:4650/api/index.php?action=announcement';

  int _lastSeenId = 0;
  List<Announcement> _cache = [];

  /// 获取公告列表。
  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      final resp = await _client
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return _cache;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = json['data'] as List? ?? [];
      _cache = data.map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
      return _cache;
    } catch (_) {
      return _cache;
    }
  }

  /// 未读公告数。
  int get unreadCount => _cache.where((a) => a.id > _lastSeenId).length;

  /// 标记全部已读。
  void markAllRead() {
    if (_cache.isNotEmpty) _lastSeenId = _cache.first.id;
  }

  /// 获取最新一条未读公告。
  Announcement? get latestUnread {
    final unread = _cache.where((a) => a.id > _lastSeenId).toList();
    return unread.isEmpty ? null : unread.first;
  }

  void dispose() => _client.close();
}
