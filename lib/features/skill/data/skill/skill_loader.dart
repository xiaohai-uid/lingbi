/// SkillLoader — 扫描安装目录，解析 SKILL.md，构造 DynamicPromptSkill 并注册
library;

import 'dart:async';
import 'dart:io';

import 'package:lingbi/features/skill/data/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/features/skill/data/skill/skill_manifest.dart';
import 'package:lingbi/features/skill/data/skill/skill_permission.dart';
import 'package:lingbi/features/skill/data/skill/skill_resource_loader.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';
import 'package:lingbi/features/skill/data/skill_marketplace.dart';

/// 动态 Skill 加载器
///
/// 扫描指定安装目录下的子目录，解析每个子目录中的 SKILL.md 文件，
/// 构建 [DynamicPromptSkill] 并注册到 [SkillActionService]。
/// 支持监听 [SkillMarketplace.events] 实现安装/卸载后实时刷新。
class SkillLoader {
  SkillLoader(this._actionService);

  final SkillActionService _actionService;
  StreamSubscription<SkillMarketEvent>? _marketSubscription;
  String? _installDir;

  /// 开始监听 SkillMarketplace 事件（安装/卸载后自动刷新）
  void listenToMarketplace(SkillMarketplace marketplace) {
    _marketSubscription?.cancel();
    _marketSubscription = marketplace.events.listen(_onMarketEvent);
  }

  /// 处理市场事件
  void _onMarketEvent(SkillMarketEvent event) {
    switch (event.type) {
      case SkillMarketEventType.installed:
        _reloadSingle(event.skillId);
      case SkillMarketEventType.uninstalled:
        unloadSingle(event.skillId);
    }
  }

  /// 重新加载单个 Skill（安装后实时注册）
  Future<void> _reloadSingle(String skillId) async {
    if (_installDir == null) return;
    final dir = Directory('$_installDir${Platform.pathSeparator}$skillId');
    try {
      final skill = await _loadSingleDir(dir);
      if (skill != null) {
        _actionService.registerSkill(skill);
      }
    } catch (_) {
      // 单个 Skill 加载失败不阻断
    }
  }

  /// 扫描安装目录，加载所有 Skill
  ///
  /// 返回成功加载的 Skill 数量。
  /// 单个 Skill 加载失败不阻断其他 Skill。
  Future<int> loadAll(String installDir) async {
    _installDir = installDir;
    final dir = Directory(installDir);
    if (!await dir.exists()) return 0;

    int loaded = 0;
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        try {
          final skill = await _loadSingleDir(entity);
          if (skill != null) {
            _actionService.registerSkill(skill);
            loaded++;
          }
        } catch (_) {
          // 单个 Skill 加载失败不阻断其他
        }
      }
    }
    return loaded;
  }

  /// 加载单个 Skill 目录
  Future<DynamicPromptSkill?> _loadSingleDir(Directory dir) async {
    final skillMdFile = File('${dir.path}${Platform.pathSeparator}SKILL.md');
    if (!await skillMdFile.exists()) return null;

    final content = await skillMdFile.readAsString();
    // 目录名作为 skillId
    final skillId = dir.path.split(Platform.pathSeparator).last;
    final manifest = SkillManifestParser.parse(content, skillId);

    // 检查是否有 manifest.yaml（重量 Skill）
    final manifestFile =
        File('${dir.path}${Platform.pathSeparator}manifest.yaml');
    PermissionSet permissions;
    if (await manifestFile.exists()) {
      final yamlContent = await manifestFile.readAsString();
      permissions = _parsePermissions(yamlContent);
    } else {
      permissions = PermissionSet.defaultLightweight();
    }

    const resourceLoader = SkillResourceLoader();
    final referenceFiles = await resourceLoader.listReferences(dir.path);

    return DynamicPromptSkill(
      manifest: manifest,
      permissions: permissions,
      skillDir: dir.path,
      referenceFiles: referenceFiles,
      resourceLoader: resourceLoader,
    );
  }

  /// 卸载单个 Skill
  void unloadSingle(String skillId) {
    _actionService.unregisterSkill(skillId);
  }

  /// 释放资源（取消事件订阅）
  void dispose() {
    _marketSubscription?.cancel();
    _marketSubscription = null;
  }

  /// 从 manifest.yaml 内容中解析权限列表
  ///
  /// 支持格式：
  /// ```yaml
  /// requires:
  ///   - canon.read
  ///   - canon.write
  /// ```
  PermissionSet _parsePermissions(String yamlContent) {
    final regex = RegExp(r'^\s*-\s*(.+)$', multiLine: true);
    final requiresSection = _extractRequiresSection(yamlContent);
    if (requiresSection == null) return PermissionSet.defaultLightweight();

    final matches = regex.allMatches(requiresSection);
    if (matches.isEmpty) return PermissionSet.defaultLightweight();

    final permissionStrings = matches.map((m) => m.group(1)!.trim()).toList();
    return PermissionSet.fromStrings(permissionStrings);
  }

  /// 提取 requires: 下的 YAML 列表内容
  String? _extractRequiresSection(String yaml) {
    final lines = yaml.split('\n');
    bool inRequires = false;
    final buffer = StringBuffer();

    for (final line in lines) {
      if (line.trimLeft().startsWith('requires:')) {
        inRequires = true;
        continue;
      }
      if (inRequires) {
        // 遇到非缩进行说明 requires 块结束
        if (line.isNotEmpty &&
            !line.startsWith(' ') &&
            !line.startsWith('\t')) {
          break;
        }
        buffer.writeln(line);
      }
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }
}
