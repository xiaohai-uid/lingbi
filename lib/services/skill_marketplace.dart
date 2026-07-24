import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

/// Skill 市场服务 — 浏览、搜索、安装、卸载 Skill
class SkillMarketplace {
  SkillMarketplace({
    this.registryUrl =
        'https://raw.githubusercontent.com/xiaohai-uid/lingbi/main/community/skill-registry.json',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String registryUrl;
  final http.Client _client;
  List<SkillEntry> _cache = [];
  Set<String> _installedIds = {};
  String? _installDir;

  /// 获取技能安装目录
  Future<String> getInstallDir() async {
    if (_installDir != null) return _installDir!;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _installDir = '${appDir.path}/lingbi_skills';
    } catch (_) {
      _installDir = '${Platform.environment['USERPROFILE'] ?? '.'}/lingbi_skills';
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

  /// 安装 Skill (下载 SKILL.md 并保存到本地)
  Future<bool> install(SkillEntry skill) async {
    try {
      final dir = await getInstallDir();

      // 优先从本地 community/skills/ 目录读取
      final localFile = File('community/skills/${skill.id}/SKILL.md');
      String content;
      if (await localFile.exists()) {
        content = await localFile.readAsString();
      } else if (skill.downloadUrl.isNotEmpty) {
        final response = await _client
            .get(Uri.parse(skill.downloadUrl))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return false;
        content = response.body;
      } else {
        return false;
      }

      await _writeSkillFile(dir, skill.id, content);
      _installedIds.add(skill.id);
      return true;
    } catch (_) {
      return false;
    }
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
    _client.close();
  }
}
