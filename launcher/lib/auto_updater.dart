import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// 版本检查结果
///
/// [hasUpdate] 是否存在新版本；[version] 最新版本号（来自 GitHub release tag_name）；
/// [downloadUrl] 下载地址（优先首个资源直链，回退到 release 页面）；
/// [releaseNotes] 发布说明（release body）。
typedef UpdateCheckResult = ({
  bool hasUpdate,
  String? version,
  String? downloadUrl,
  String? releaseNotes,
});

/// 自动更新检查器 — 调用 GitHub Releases API 与当前版本比较
///
/// 仅检查、不下载。当前版本通过 [PackageInfo] 运行时读取，其值源自
/// `launcher/pubspec.yaml` 的 `version` 字段（构建时由 Flutter 注入）。
class AutoUpdater {
  static const _owner = 'xiaohai-uid';
  static const _repo = 'lingbi';

  /// GitHub Releases latest API
  static Uri get _apiUri =>
      Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');

  /// 检查是否有新版本发布。
  ///
  /// 网络/解析异常时返回 `hasUpdate=false` 的安全结果，不抛异常，以免阻断 UI。
  static Future<UpdateCheckResult> checkForUpdate() async {
    final current = await _currentVersion();
    try {
      final response = await http.get(_apiUri, headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'lingbi-launcher',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return _noUpdate();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = data['tag_name'] as String?;
      final htmlUrl = data['html_url'] as String?;
      final body = data['body'] as String?;

      // 下载地址：优先首个资源直链，回退到 release 页面
      final assets = data['assets'] as List<dynamic>?;
      String? downloadUrl;
      if (assets != null && assets.isNotEmpty) {
        downloadUrl =
            (assets.first as Map<String, dynamic>)['browser_download_url']
                as String?;
      }
      downloadUrl ??= htmlUrl;

      if (tag == null) return _noUpdate();

      final hasUpdate = _compareSemver(tag, current) > 0;
      return (
        hasUpdate: hasUpdate,
        version: tag,
        downloadUrl: downloadUrl,
        releaseNotes: body,
      );
    } catch (_) {
      // 网络/解析异常：安全降级，不阻断 UI
      return _noUpdate();
    }
  }

  /// 当前启动器版本（来自 launcher/pubspec.yaml 的 version 字段）。
  static Future<String> _currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// semver 三段比较：a > b 返回正数，相等返回 0，a < b 返回负数。
  static int _compareSemver(String a, String b) {
    final pa = _parseSemver(a);
    final pb = _parseSemver(b);
    for (var i = 0; i < 3; i++) {
      final r = pa[i].compareTo(pb[i]);
      if (r != 0) return r;
    }
    return 0;
  }

  /// 解析 `v1.2.3` / `1.2.3+build` / `1.2.3-beta` 为 [major, minor, patch]。
  static List<int> _parseSemver(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    // 仅保留三段：去除构建元数据(+build)与预发布标识(-beta)
    s = s.split('+').first.split('-').first;
    final parts = s.split('.');
    int at(int i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0;
    return [at(0), at(1), at(2)];
  }

  static UpdateCheckResult _noUpdate() => (
        hasUpdate: false,
        version: null,
        downloadUrl: null,
        releaseNotes: null,
      );
}
