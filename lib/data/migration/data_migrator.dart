/// 数据迁移脚本 — 从 v0.4.0 JSON 存储迁移到 Drift + .md 混合
///
/// 迁移映射：
///   Project JSON      → world.json (World 元数据)
///   Project.documents  → documents/{workId}/.../*.md
///   CodexEntry        → Drift 表 (characters/locations/lores/rules)
///   project.json      → Drift 表 (works/volumes/chapters/scenes)
///
/// 使用方式：
///   final migrator = DataMigrator(db);
///   final report = await migrator.migrate();
///
/// 注意：
/// - 迁移是单向的，完成后 JSON 数据保留供回滚
/// - 运行 `flutter run` 时自动检测是否需要迁移
library;

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/world_database.dart';

/// 数据迁移器
class DataMigrator {
  DataMigrator({required this.db}) {
    _lingbiDir = ''; // 初始化时设置
  }
  final WorldDatabase db;
  late final String _lingbiDir;

  /// 执行全量迁移
  Future<MigrationReport> migrate() async {
    final appDir = await getApplicationDocumentsDirectory();
    _lingbiDir = p.join(appDir.path, '灵笔');
    final report = MigrationReport();

    final oldDir = Directory(_lingbiDir);
    if (!await oldDir.exists()) {
      report.errors.add('旧数据目录不存在: $_lingbiDir');
      return report;
    }

    await for (final entry in oldDir.list()) {
      if (entry is! Directory) continue;
      final projectFile = File(p.join(entry.path, 'project.json'));
      if (!await projectFile.exists()) continue;

      try {
        final json = jsonDecode(await projectFile.readAsString())
            as Map<String, dynamic>;
        final projectName =
            json['name'] as String? ?? entry.uri.pathSegments.last;

        // 1. 创建 World 元数据 (world.json)
        final worldId = _uuid();
        await _createWorldMeta(worldId, projectName, json);

        // 2. 创建默认 Work
        final workId = _uuid();
        await db.into(db.works).insert(WorksCompanion.insert(
              id: workId,
              worldId: worldId,
              title: '未命名作品',
              description: '',
              type: 'novel',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));

        // 3. 迁移文档
        await _migrateDocuments(entry.path, worldId, workId, report);

        report.migratedWorlds++;
      } catch (e) {
        report.errors.add('迁移失败: ${entry.path}: $e');
      }
    }

    return report;
  }

  Future<void> _createWorldMeta(
      String worldId, String name, Map<String, dynamic> json) async {
    final worldDir = Directory(p.join(_lingbiDir, 'Worlds', worldId));
    await worldDir.create(recursive: true);

    final meta = {
      'id': worldId,
      'name': name,
      'description': json['description'] as String? ?? '',
      'genres': [],
      'timelineMode': 'linear',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await File(p.join(worldDir.path, 'world.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(meta),
    );
  }

  Future<void> _migrateDocuments(String projectPath, String worldId,
      String workId, MigrationReport report) async {
    final docsDir = Directory(p.join(projectPath, 'documents'));
    if (!await docsDir.exists()) return;

    final targetDir = Directory(
        p.join(_lingbiDir, 'Worlds', worldId, 'documents', 'work-$workId'));
    int docIndex = 0;

    await for (final file
        in docsDir.list().where((f) => f is File).cast<File>()) {
      if (!file.path.endsWith('.md')) continue;

      final content = await file.readAsString();
      final docId = _uuid();
      final targetPath = p.join(targetDir.path, 'chapter-${++docIndex}.md');

      // 复制 .md 文件
      await File(targetPath).writeAsString(content);

      // 记录 Document 索引
      await db.into(db.documents).insert(DocumentsCompanion.insert(
            id: docId,
            worldId: worldId,
            workId: workId,
            filePath: targetPath,
            currentSceneId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      // 创建默认场景
      final sceneId = _uuid();
      await db.into(db.scenes).insert(ScenesCompanion.insert(
            id: sceneId,
            chapterId: docId,
            sceneNumber: 1,
            title: '场景 1',
            outlineDescription: '',
            locationId: '',
            timelineEventId: '',
            documentId: docId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      report.migratedDocuments++;
    }
  }

  String _uuid() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    return 'mig-$ts-${_randomHex(6)}';
  }

  String _randomHex(int len) {
    const chars = '0123456789abcdef';
    final sb = StringBuffer();
    for (var i = 0; i < len; i++) {
      sb.write(chars[(DateTime.now().microsecond + i) % 16]);
    }
    return sb.toString();
  }
}

/// 迁移报告
class MigrationReport {
  int migratedWorlds = 0;
  int migratedDocuments = 0;
  List<String> errors = [];

  bool get hasErrors => errors.isNotEmpty;
  String get summary => '迁移: $migratedWorlds 世界, $migratedDocuments 文档'
      '${errors.isEmpty ? "" : ", ${errors.length} 错误"}';
}
