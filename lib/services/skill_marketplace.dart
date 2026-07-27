import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:lingbi/services/skill/skill_manifest_verifier.dart';
import 'package:path_provider/path_provider.dart';

/// Skill 条目 — 代表一个可安装的 AI 技能
class SkillEntry {
  const SkillEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.version,
    required this.category,
    required this.downloadUrl,
    this.tags = const [],
    this.downloadCount = 0,
    this.isBuiltin = false,
  });

  factory SkillEntry.fromJson(Map<String, dynamic> json) {
    return SkillEntry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      author: json['author'] ?? '',
      version: json['version'] ?? '1.0.0',
      category: json['category'] ?? 'general',
      downloadUrl: json['download_url'] ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      downloadCount: json['download_count'] ?? 0,
      isBuiltin: json['builtin'] == true,
    );
  }

  final String id;
  final String name;
  final String description;
  final String author;
  final String version;
  final String category;
  final String downloadUrl;
  final List<String> tags;
  final int downloadCount;
  final bool isBuiltin;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'author': author,
        'version': version,
        'category': category,
        'download_url': downloadUrl,
        'tags': tags,
        'download_count': downloadCount,
        'builtin': isBuiltin,
      };
}

/// Skill 市场事件类型
enum SkillMarketEventType { installed, uninstalled }

/// Skill 市场事件 — 安装/卸载后通知 Runtime 刷新
class SkillMarketEvent {
  const SkillMarketEvent({required this.type, required this.skillId});

  final SkillMarketEventType type;
  final String skillId;
}

enum SkillInstallSource {
  registry,
  bundled,
  offlinePackage,
  distilled,
}

class SkillPermissionDiff {
  SkillPermissionDiff({
    required Set<String> added,
    required Set<String> removed,
  })  : added = Set.unmodifiable(added),
        removed = Set.unmodifiable(removed);

  final Set<String> added;
  final Set<String> removed;

  Map<String, Object> toJson() => {
        'added': added.toList()..sort(),
        'removed': removed.toList()..sort(),
      };

  factory SkillPermissionDiff.fromJson(Map<String, dynamic> json) {
    return SkillPermissionDiff(
      added: (json['added'] as List? ?? const [])
          .map((value) => value.toString())
          .toSet(),
      removed: (json['removed'] as List? ?? const [])
          .map((value) => value.toString())
          .toSet(),
    );
  }
}

class SkillInstallMetadata {
  SkillInstallMetadata({
    required this.skillId,
    required this.version,
    required this.source,
    required this.sourceUri,
    required this.signerId,
    required this.signatureStatus,
    required Set<String> permissions,
    required this.permissionDiff,
    required this.packageHash,
    required this.installedAt,
    required this.packageState,
  }) : permissions = Set.unmodifiable(permissions);

  final String skillId;
  final String version;
  final SkillInstallSource source;
  final String sourceUri;
  final String? signerId;
  final SkillSignatureStatus signatureStatus;
  final Set<String> permissions;
  final SkillPermissionDiff permissionDiff;
  final String packageHash;
  final DateTime installedAt;
  final SkillPackageState packageState;

  Map<String, Object?> toJson() => {
        'skill_id': skillId,
        'version': version,
        'source': source.name,
        'source_uri': sourceUri,
        'signer_id': signerId,
        'signature_status': signatureStatus.name,
        'permissions': permissions.toList()..sort(),
        'permission_diff': permissionDiff.toJson(),
        'package_hash': packageHash,
        'installed_at': installedAt.toUtc().toIso8601String(),
        'package_state': packageState.name,
      };

  factory SkillInstallMetadata.fromJson(Map<String, dynamic> json) {
    return SkillInstallMetadata(
      skillId: json['skill_id'] as String,
      version: json['version'] as String,
      source: SkillInstallSource.values.byName(json['source'] as String),
      sourceUri: json['source_uri'] as String? ?? '',
      signerId: json['signer_id'] as String?,
      signatureStatus: SkillSignatureStatus.values
          .byName(json['signature_status'] as String),
      permissions: (json['permissions'] as List)
          .map((value) => value.toString())
          .toSet(),
      permissionDiff: SkillPermissionDiff.fromJson(
        Map<String, dynamic>.from(json['permission_diff'] as Map),
      ),
      packageHash: json['package_hash'] as String,
      installedAt: DateTime.parse(json['installed_at'] as String).toUtc(),
      packageState: SkillPackageState.values
          .byName(json['package_state'] as String),
    );
  }
}

class OfflineSkillPackage {
  OfflineSkillPackage({
    required this.manifest,
    required Map<String, List<int>> files,
    required this.packagePath,
  }) : files = Map.unmodifiable(
          files.map(
            (name, bytes) => MapEntry(name, List<int>.unmodifiable(bytes)),
          ),
        );

  final SkillPackageManifest manifest;
  final Map<String, List<int>> files;
  final String packagePath;
}

/// Skill 市场服务 — 浏览、搜索、安装、卸载 Skill
class SkillMarketplace {
  SkillMarketplace({
    this.registryUrl =
        'https://raw.githubusercontent.com/xiaohai-uid/lingbi/main/community/skill-registry.json',
    http.Client? client,
    String? installDir,
    SkillManifestVerifier? manifestVerifier,
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _installDir = installDir,
        _manifestVerifier =
            manifestVerifier ?? const SkillManifestVerifier.production(),
        _clock = clock ?? DateTime.now;

  final String registryUrl;
  final http.Client _client;
  final SkillManifestVerifier _manifestVerifier;
  final DateTime Function() _clock;
  List<SkillEntry> _cache = [];
  Set<String> _installedIds = {};
  String? _installDir;

  /// 安装/卸载事件流 — SkillLoader 监听此流实现实时刷新
  final StreamController<SkillMarketEvent> _eventController =
      StreamController<SkillMarketEvent>.broadcast();

  /// 事件流（供 SkillLoader 订阅）
  Stream<SkillMarketEvent> get events => _eventController.stream;

  /// 获取技能安装目录
  Future<String> getInstallDir() async {
    if (_installDir == null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _installDir = '${appDir.path}/lingbi_skills';
      } catch (_) {
        _installDir =
            '${Platform.environment['USERPROFILE'] ?? '.'}/lingbi_skills';
      }
    }
    final dir = Directory(_installDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _installDir!;
  }

  /// 初始化：加载已安装列表 + 自动安装内置技能
  Future<void> initialize() async {
    final dir = await getInstallDir();
    _installedIds = (await listInstalled(dir)).toSet();
    await _installBuiltinSkills(dir);
  }

  /// 自动安装内置技能（首次启动时）
  Future<void> _installBuiltinSkills(String dir) async {
    const builtinSkills = [
      'smart-continuation',
      'style-distiller',
      'inspiration-seed',
    ];
    for (final id in builtinSkills) {
      if (_installedIds.contains(id)) continue;
      // 尝试从本地 community/skills/ 目录复制
      final localSource = File('community/skills/$id/SKILL.md');
      if (await localSource.exists()) {
        final content = await localSource.readAsString();
        await _writeSkillFile(dir, id, content);
        _installedIds.add(id);
      }
    }
  }

  /// 获取可用 Skill 列表
  Future<List<SkillEntry>> fetchSkills() async {
    try {
      final response = await _client
          .get(Uri.parse(registryUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _cache = data.map((s) => SkillEntry.fromJson(s)).toList();
        return _cache;
      }
      return _cache;
    } catch (_) {
      return _cache;
    }
  }

  /// 从本地 JSON 加载技能列表
  Future<List<SkillEntry>> loadLocalRegistry() async {
    final candidates = [
      'community/skill-registry.json',
      '${_exeParent()}/community/skill-registry.json',
      '${_exeParent()}/data/community/skill-registry.json',
    ];
    for (final path in candidates) {
      final f = File(path);
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List;
        _cache = data.map((s) => SkillEntry.fromJson(s)).toList();
        return _cache;
      }
    }
    return [];
  }

  String _exeParent() {
    try {
      return File(Platform.resolvedExecutable).parent.path;
    } catch (_) {
      return '.';
    }
  }

  /// 按关键词搜索 Skill
  List<SkillEntry> search(String query) {
    if (query.isEmpty) return _cache;
    final q = query.toLowerCase();
    return _cache
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  /// 按分类筛选
  List<SkillEntry> filterByCategory(String category) {
    if (category.isEmpty || category == 'all') return _cache;
    return _cache.where((s) => s.category == category).toList();
  }

  /// 检查是否已安装
  bool isInstalled(String skillId) => _installedIds.contains(skillId);

  /// 通知外部安装（蒸馏服务写入磁盘后调用，触发事件流）
  void notifyInstalled(String skillId) {
    _installedIds.add(skillId);
    _eventController.add(
      SkillMarketEvent(type: SkillMarketEventType.installed, skillId: skillId),
    );
  }

  /// 安装 Skill (下载 SKILL.md 并保存到本地)
  Future<bool> install(SkillEntry skill) async {
    // Legacy registry entries do not carry a signed package manifest. They are
    // deliberately refused instead of treating a URL or author string as trust.
    return false;
  }

  Future<bool> installOfflinePackage(OfflineSkillPackage package) {
    return _installPackage(
      manifest: package.manifest,
      files: package.files,
      source: SkillInstallSource.offlinePackage,
      sourceUri: package.packagePath,
      verifier: _manifestVerifier,
    );
  }

  Future<bool> installDistilledSkill({
    required String skillId,
    required String projectId,
    required String content,
    String version = '0.1.0-dev',
  }) {
    final bytes = utf8.encode(content);
    final manifest = SkillPackageManifest(
      skillId: skillId,
      version: version,
      files: {'SKILL.md': sha256.convert(bytes).toString()},
      capabilities: {
        'project:$projectId',
        'canon.read',
        'document.read',
      },
      signerId: null,
      signature: null,
      state: SkillPackageState.development,
    );
    return _installPackage(
      manifest: manifest,
      files: {'SKILL.md': bytes},
      source: SkillInstallSource.distilled,
      sourceUri: 'project:$projectId',
      verifier: const SkillManifestVerifier.development(),
    );
  }

  Future<bool> _installPackage({
    required SkillPackageManifest manifest,
    required Map<String, List<int>> files,
    required SkillInstallSource source,
    required String sourceUri,
    required SkillManifestVerifier verifier,
  }) async {
    try {
      final current = await readInstallMetadata(manifest.skillId);
      final verification = verifier.verify(
        manifest: manifest,
        packageFiles: files,
        installedVersion: current?.version,
      );
      if (!verification.isValid) return false;

      final installDir = await getInstallDir();
      final skillDir = Directory('$installDir/${manifest.skillId}');
      final stagingDir = Directory('$installDir/.${manifest.skillId}.staging');
      if (await stagingDir.exists()) await stagingDir.delete(recursive: true);
      await stagingDir.create(recursive: true);
      for (final entry in files.entries) {
        final target = File('${stagingDir.path}/${entry.key}');
        await target.parent.create(recursive: true);
        await target.writeAsBytes(entry.value, flush: true);
      }
      await File('${stagingDir.path}/manifest.json').writeAsString(
        jsonEncode(manifest.toJson()),
        flush: true,
      );

      final previousPermissions = current?.permissions ?? const <String>{};
      final metadata = SkillInstallMetadata(
        skillId: manifest.skillId,
        version: manifest.version,
        source: source,
        sourceUri: sourceUri,
        signerId: manifest.signerId,
        signatureStatus: verification.signatureStatus,
        permissions: manifest.capabilities,
        permissionDiff: SkillPermissionDiff(
          added: manifest.capabilities.difference(previousPermissions),
          removed: previousPermissions.difference(manifest.capabilities),
        ),
        packageHash: _packageHash(manifest),
        installedAt: _clock().toUtc(),
        packageState: manifest.state,
      );
      await File('${stagingDir.path}/install-metadata.json').writeAsString(
        jsonEncode(metadata.toJson()),
        flush: true,
      );

      if (await skillDir.exists()) {
        final rollbackDir = Directory(
          '$installDir/.rollback/${manifest.skillId}/${current!.version}',
        );
        if (await rollbackDir.exists()) {
          await rollbackDir.delete(recursive: true);
        }
        await _copyDirectory(skillDir, rollbackDir);
        await skillDir.delete(recursive: true);
      }
      await stagingDir.rename(skillDir.path);
      notifyInstalled(manifest.skillId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SkillInstallMetadata?> readInstallMetadata(String skillId) async {
    try {
      final dir = await getInstallDir();
      final file = File('$dir/$skillId/install-metadata.json');
      if (!await file.exists()) return null;
      return SkillInstallMetadata.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> rollback(String skillId) async {
    try {
      final installDir = await getInstallDir();
      final root = Directory('$installDir/.rollback/$skillId');
      if (!await root.exists()) return false;
      final snapshots = await root
          .list()
          .where((entry) => entry is Directory)
          .cast<Directory>()
          .toList();
      if (snapshots.isEmpty) return false;
      snapshots.sort((a, b) => a.path.compareTo(b.path));
      final snapshot = snapshots.last;
      final current = Directory('$installDir/$skillId');
      if (await current.exists()) await current.delete(recursive: true);
      await snapshot.rename(current.path);
      notifyInstalled(skillId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final name = entity.path.split(RegExp(r'[/\\]')).last;
      if (entity is Directory) {
        await _copyDirectory(entity, Directory('${destination.path}/$name'));
      } else if (entity is File) {
        await entity.copy('${destination.path}/$name');
      }
    }
  }

  static String _packageHash(SkillPackageManifest manifest) {
    return sha256.convert(utf8.encode(manifest.canonicalPayload)).toString();
  }

  /// 写入技能文件（原子写）
  Future<void> _writeSkillFile(
      String dir, String skillId, String content) async {
    final skillDir = Directory('$dir/$skillId');
    await skillDir.create(recursive: true);
    final targetFile = File('${skillDir.path}/SKILL.md');
    final tmpFile = File('${skillDir.path}/SKILL.md.tmp');
    try {
      await tmpFile.writeAsString(content);
      await tmpFile.rename(targetFile.path);
    } catch (_) {
      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
      await targetFile.writeAsString(content);
    }
  }

  /// 卸载 Skill
  Future<bool> uninstall(String skillId) async {
    try {
      final dir = await getInstallDir();
      final skillDir = Directory('$dir/$skillId');
      if (await skillDir.exists()) {
        await skillDir.delete(recursive: true);
      }
      _installedIds.remove(skillId);
      _eventController.add(
        SkillMarketEvent(type: SkillMarketEventType.uninstalled, skillId: skillId),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 读取已安装技能的 SKILL.md 内容
  Future<String?> readSkillContent(String skillId) async {
    try {
      final dir = await getInstallDir();
      final file = File('$dir/$skillId/SKILL.md');
      if (await file.exists()) {
        return await file.readAsString();
      }
      // 回退到本地 community 目录
      final localFile = File('community/skills/$skillId/SKILL.md');
      if (await localFile.exists()) {
        return await localFile.readAsString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 列出已安装的 Skill ID
  Future<List<String>> listInstalled(String installDir) async {
    try {
      final dir = Directory(installDir);
      if (!await dir.exists()) return [];
      final result = <String>[];
      await for (final entry in dir.list()) {
        if (entry is Directory) {
          final skillFile = File('${entry.path}/SKILL.md');
          if (await skillFile.exists()) {
            result.add(entry.path.split(RegExp(r'[/\\]')).last);
          }
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _eventController.close();
    _client.close();
  }
}
