import 'dart:convert';
import 'package:http/http.dart' as http;

/// GitHub Release 信息
class ReleaseInfo {

  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.publishedAt,
    required this.prerelease,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      htmlUrl: json['html_url'] ?? '',
      publishedAt: DateTime.parse(json['published_at'] ?? DateTime.now().toIso8601String()),
      prerelease: json['prerelease'] ?? false,
    );
  }
  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final DateTime publishedAt;
  final bool prerelease;

  String get version => tagName.replaceFirst(RegExp(r'^v'), '');
}

/// 自动更新检查器 — 通过 GitHub Releases API 检查新版本
class UpdateChecker {

  UpdateChecker({
    required this.owner,
    required this.repo,
    required this.currentVersion,
    http.Client? client,
  }) : _client = client ?? http.Client();
  final String owner;
  final String repo;
  final String currentVersion;
  final http.Client _client;

  /// GitHub API URL
  String get _releasesUrl =>
      'https://api.github.com/repos/$owner/$repo/releases';

  /// 检查是否有新版本
  Future<UpdateResult> checkForUpdate() async {
    try {
      final response = await _client.get(
        Uri.parse('$_releasesUrl?per_page=5'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        return UpdateResult(
          hasUpdate: false,
          error: 'HTTP ${response.statusCode}',
        );
      }

      final releases = (jsonDecode(response.body) as List)
          .map((r) => ReleaseInfo.fromJson(r))
          .where((r) => !r.prerelease)
          .toList();

      if (releases.isEmpty) {
        return const UpdateResult(hasUpdate: false);
      }

      final latest = releases.first;
      final hasUpdate = _compareVersions(latest.version, currentVersion) > 0;

      return UpdateResult(
        hasUpdate: hasUpdate,
        latestRelease: latest,
      );
    } catch (e) {
      return UpdateResult(hasUpdate: false, error: e.toString());
    }
  }

  /// 语义化版本比较: 返回正数表示 a > b
  static int _compareVersions(String a, String b) {
    final partsA = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final partsB = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  void dispose() {
    _client.close();
  }
}

/// 更新检查结果
class UpdateResult {

  const UpdateResult({
    required this.hasUpdate,
    this.latestRelease,
    this.error,
  });
  final bool hasUpdate;
  final ReleaseInfo? latestRelease;
  final String? error;
}
