/// GuidedFlowSkillLoader — 加载 guided_flow 类型 Skill 并注册到 GuidedFlowEngine
///
/// 扫描 Skill 安装目录，识别 `type: guided_flow` 的 Skill，
/// 读取其 flow_definition 文件（YAML/JSON），解析为 GuidedFlowDefinition
/// 并注册到 GuidedFlowEngine。支持按题材查找对应引导流程。
library;

import 'dart:io';

import 'package:lingbi/core/models/guided_flow_definition.dart';
import 'package:lingbi/services/guided_flow_engine.dart';
import 'package:lingbi/services/skill/skill_manifest.dart';

/// 引导流程 Skill 加载器
///
/// 职责：
/// 1. 扫描 Skill 目录中 type=guided_flow 的 Skill
/// 2. 解析其 flow_definition 文件为 GuidedFlowDefinition
/// 3. 注册到 GuidedFlowEngine
/// 4. 提供按题材查找已注册流程的能力
class GuidedFlowSkillLoader {
  GuidedFlowSkillLoader(this._engine);

  final GuidedFlowEngine _engine;

  /// 已加载的题材 → flowId 映射
  final Map<String, String> _genreToFlowId = {};

  /// 扫描安装目录，加载所有 guided_flow 类型 Skill
  ///
  /// 返回成功加载的数量。单个失败不阻断其他。
  Future<int> loadAll(String installDir) async {
    final dir = Directory(installDir);
    if (!await dir.exists()) return 0;

    int loaded = 0;
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        try {
          final ok = await _loadSingleDir(entity);
          if (ok) loaded++;
        } catch (_) {
          // 单个 Skill 加载失败不阻断
        }
      }
    }
    return loaded;
  }

  /// 加载单个 Skill 目录（仅处理 guided_flow 类型）
  Future<bool> _loadSingleDir(Directory dir) async {
    final skillMdFile = File('${dir.path}${Platform.pathSeparator}SKILL.md');
    if (!await skillMdFile.exists()) return false;

    final content = await skillMdFile.readAsString();
    final skillId = dir.path.split(Platform.pathSeparator).last;
    final manifest = SkillManifestParser.parse(content, skillId);

    // 仅处理 guided_flow 类型
    if (manifest.type != SkillType.guidedFlow) return false;

    final flowDefFile = manifest.flowDefinitionFile;
    if (flowDefFile == null || flowDefFile.isEmpty) return false;

    // 读取流程定义文件
    final flowFile = File('${dir.path}${Platform.pathSeparator}$flowDefFile');
    if (!await flowFile.exists()) return false;

    final flowContent = await flowFile.readAsString();
    final GuidedFlowDefinition definition;

    if (flowDefFile.endsWith('.json')) {
      definition = _engine.loadDefinitionFromJson(flowContent);
    } else {
      definition = _engine.loadDefinitionFromYaml(flowContent);
    }

    // 注册题材映射
    final genre = manifest.genre ?? definition.genre;
    if (genre.isNotEmpty) {
      _genreToFlowId[genre] = definition.id;
    }

    return true;
  }

  /// 注册内置引导流程定义（代码中硬编码的题材 Skill）
  ///
  /// 用于官方预装题材 Skill（无需文件系统）。
  void registerBuiltinFlow(GuidedFlowDefinition definition, String genre) {
    _engine.registerDefinition(definition);
    if (genre.isNotEmpty) {
      _genreToFlowId[genre] = definition.id;
    }
  }

  /// 按题材查找对应的 flowId
  ///
  /// 返回 null 表示该题材无专属 Skill，应降级到通用流程。
  String? findFlowIdByGenre(String genre) {
    if (genre.isEmpty) return null;
    return _genreToFlowId[genre];
  }

  /// 获取所有已注册的题材列表
  List<String> get registeredGenres => _genreToFlowId.keys.toList();

  /// 判断某题材是否有专属引导 Skill
  bool hasGenreSkill(String genre) => _genreToFlowId.containsKey(genre);
}
