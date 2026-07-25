/// WebDAV 同步服务 — 云同步基础设施
///
/// 提供 WebDAV 协议的基本操作（PROPFIND/GET/PUT/DELETE），
/// 支持坚果云/Nextcloud/ownCloud 等标准 WebDAV 服务。
///
/// 同步范围（4.4 决策）：
/// - 项目文件（.md 文档）
/// - Skill 配置（已安装 Skill 列表）
/// - 对话记录（可选）
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// WebDAV 配置
class WebDavConfig {
  const WebDavConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.enabled = true,
    this.syncProjects = true,
    this.syncSkills = true,
    this.syncConversations = false,
  });

  factory WebDavConfig.fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      serverUrl: json['serverUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      syncProjects: json['syncProjects'] as bool? ?? true,
      syncSkills: json['syncSkills'] as bool? ?? true,
      syncConversations: json['syncConversations'] as bool? ?? false,
    );
  }

  final String serverUrl;
  final String username;
  final String password;
  final bool enabled;
  final bool syncProjects;
  final bool syncSkills;
  final bool syncConversations;

  /// 是否启用（配置完整 + enabled=true）
  bool get isEnabled => enabled && serverUrl.isNotEmpty && username.isNotEmpty;

  /// 序列化为 JSON（不暴露密码，密码由安全存储管理）
  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'enabled': enabled,
        'syncProjects': syncProjects,
        'syncSkills': syncSkills,
        'syncConversations': syncConversations,
      };

  WebDavConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? enabled,
    bool? syncProjects,
    bool? syncSkills,
    bool? syncConversations,
  }) {
    return WebDavConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      enabled: enabled ?? this.enabled,
      syncProjects: syncProjects ?? this.syncProjects,
      syncSkills: syncSkills ?? this.syncSkills,
      syncConversations: syncConversations ?? this.syncConversations,
    );
  }
}

/// WebDAV 远程文件条目
class WebDavEntry {
  const WebDavEntry({
    required this.path,
    required this.isCollection,
    this.lastModified,
    this.contentLength = 0,
    this.etag = '',
  });

  final String path;
  final bool isCollection;
  final DateTime? lastModified;
  final int contentLength;
  final String etag;
}

/// WebDAV 协议客户端
///
/// 封装 HTTP 方法实现 WebDAV 基本操作。
/// 支持 Basic Auth 认证。
class WebDavService {
  WebDavService({
    required WebDavConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  final WebDavConfig _config;
  final http.Client _client;

  /// 构建认证 Header
  Map<String, String> get _authHeaders {
    final credentials = base64Encode(
      utf8.encode('${_config.username}:${_config.password}'),
    );
    return {
      'Authorization': 'Basic $credentials',
      'Depth': '1',
    };
  }

  /// 测试连接可用性
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse(_config.serverUrl);
      final request = http.Request('PROPFIND', uri);
      request.headers.addAll(_authHeaders);
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 207 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 列出目录内容（PROPFIND）
  Future<List<WebDavEntry>> listDirectory(String remotePath) async {
    try {
      final uri = Uri.parse('${_config.serverUrl}/$remotePath');
      final request = http.Request('PROPFIND', uri);
      request.headers.addAll({
        ..._authHeaders,
        'Content-Type': 'application/xml',
      });
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 207) return [];
      return _parsePropfindResponse(response.body);
    } catch (_) {
      return [];
    }
  }

  /// 上传文件（PUT）
  Future<bool> uploadFile(String remotePath, String content) async {
    try {
      final uri = Uri.parse('${_config.serverUrl}/$remotePath');
      final response = await _client
          .put(uri, headers: {
            ..._authHeaders,
            'Content-Type': 'text/plain; charset=utf-8',
          }, body: utf8.encode(content))
          .timeout(const Duration(seconds: 30));
      return response.statusCode == 201 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// 下载文件（GET）
  Future<String?> downloadFile(String remotePath) async {
    try {
      final uri = Uri.parse('${_config.serverUrl}/$remotePath');
      final response = await _client
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 删除文件（DELETE）
  Future<bool> deleteFile(String remotePath) async {
    try {
      final uri = Uri.parse('${_config.serverUrl}/$remotePath');
      final response = await _client
          .delete(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 创建目录（MKCOL）
  Future<bool> createDirectory(String remotePath) async {
    try {
      final uri = Uri.parse('${_config.serverUrl}/$remotePath');
      final request = http.Request('MKCOL', uri);
      request.headers.addAll(_authHeaders);
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 201 || response.statusCode == 405;
    } catch (_) {
      return false;
    }
  }

  /// 解析 PROPFIND XML 响应（简化版）
  List<WebDavEntry> _parsePropfindResponse(String xml) {
    final entries = <WebDavEntry>[];
    // 简化解析：提取 <D:href> 和 <D:collection/>
    final hrefRegex = RegExp(r'<[^:]*:href>([^<]+)</[^:]*:href>', caseSensitive: false);
    final matches = hrefRegex.allMatches(xml);
    for (final match in matches) {
      final path = match.group(1) ?? '';
      if (path.isNotEmpty) {
        entries.add(WebDavEntry(
          path: Uri.decodeComponent(path),
          isCollection: path.endsWith('/'),
        ));
      }
    }
    return entries;
  }

  void dispose() {
    _client.close();
  }
}
