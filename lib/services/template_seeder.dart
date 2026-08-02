import 'dart:io';

import 'package:lingbi/services/genre_seed_data.dart';

/// 模板播种器 — 新建项目时按 genreId 预填创作资料骨架。
///
/// 解决"选了模板却一点用都没有"的问题：在 `ProjectService.createPortableProject`
/// 创建目录后调用，把题材骨架写入 `小说资料/世界观.md`、`小说资料/人物库.md`，
/// 路径与 `NovelWritingLoop` 读取的设定目录一致，使新项目"打开即有用"，
/// 并为引导流程 / AI 续写提供 mandatory 上下文。
///
/// 播种是幂等且非破坏性的：仅当目标文件不存在时写入，绝不覆盖用户已有内容。
class TemplateSeeder {
  const TemplateSeeder();

  /// 按 [genreId] 播种初始创作资料。
  ///
  /// - [projectDir]：项目根目录。
  /// - [genreId]：题材 ID（如 `xuanhuan`）；为空或未收录时不播种。
  ///
  /// 返回实际写入的文件路径列表（用于日志 / 提示）。
  Future<List<String>> seedProject({
    required String projectDir,
    required String genreId,
  }) async {
    final seed = genreSeedTable[genreId];
    if (seed == null) return const [];

    final sep = Platform.pathSeparator;
    final settingsDir = Directory('$projectDir$sep小说资料');
    if (!await settingsDir.exists()) {
      await settingsDir.create(recursive: true);
    }
    // 确保章节内容目录存在（NovelWritingLoop 落盘目标）。
    final chaptersDir = Directory('$projectDir$sep章节内容');
    if (!await chaptersDir.exists()) {
      await chaptersDir.create(recursive: true);
    }

    final written = <String>[];
    written.addAll(await _writeIfAbsent(
      '${settingsDir.path}$sep世界观.md',
      seed.worldbuildingMarkdown.trimLeft(),
    ));
    written.addAll(await _writeIfAbsent(
      '${settingsDir.path}$sep人物库.md',
      seed.charactersMarkdown.trimLeft(),
    ));
    return written;
  }

  /// 仅当文件不存在时写入，返回 [path]（写入）或空列表（已存在）。
  Future<List<String>> _writeIfAbsent(String path, String content) async {
    final file = File(path);
    if (await file.exists()) return const [];
    await file.writeAsString(content);
    return [path];
  }
}
