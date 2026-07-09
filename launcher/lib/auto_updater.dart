import 'dart:io';

/// Auto Updater — 自动更新检查器
class AutoUpdater {
  static const _githubApi =
      'https://api.github.com/repos/lingbi-community/lingbi/releases/latest';

  static Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_githubApi));
      request.headers.add('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();
      final json = await response.json as Map<String, dynamic>;

      final latestTag = json['tag_name'] as String?;
      final latestVersion = latestTag?.replaceFirst('v', '');

      if (latestVersion == null) return null;

      final currentVersion = _getCurrentVersion();
      final isNewer = _compareVersions(latestVersion, currentVersion) > 0;

      return ReleaseInfo(
        version: latestVersion,
        tag: latestTag ?? '',
        name: json['name'] as String? ?? '',
        body: json['body'] as String? ?? '',
        url: json['html_url'] as String? ?? '',
        publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
        isNewer: isNewer,
        currentVersion: currentVersion,
      );
    } catch (e) {
      return null;
    }
  }

  static String _getCurrentVersion() {
    // 从 pubspec.yaml 或环境变量读取
    return '2.0.0';
  }

  static int _compareVersions(String a, String b) {
    final partsA =
        a.split('.').map(int.tryParse).where((e) => e != null).toList();
    final partsB =
        b.split('.').map(int.tryParse).where((e) => e != null).toList();

    for (int i = 0; i < partsA.length && i < partsB.length; i++) {
      if (partsA[i]! > partsB[i]!) return 1;
      if (partsA[i]! < partsB[i]!) return -1;
    }

    if (partsA.length > partsB.length) return 1;
    if (partsA.length < partsB.length) return -1;
    return 0;
  }
}

class ReleaseInfo {
  final String version;
  final String tag;
  final String name;
  final String body;
  final String url;
  final DateTime? publishedAt;
  final bool isNewer;
  final String currentVersion;

  ReleaseInfo({
    required this.version,
    required this.tag,
    required this.name,
    required this.body,
    required this.url,
    required this.publishedAt,
    required this.isNewer,
    required this.currentVersion,
  });
}
