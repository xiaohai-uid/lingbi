/// 导入服务 — 把外部 Markdown/TXT 文件写入当前项目。
library;

import 'dart:io';

import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:path/path.dart' as p;

/// 支持拖放/选择导入的文本格式。
const supportedImportExtensions = {'.md', '.txt'};

/// 将外部文本文件导入为项目章节。
///
/// 文件会被读取后通过 [DocumentService] 创建为项目内文档，调用方负责
/// 在 UI 中刷新当前项目与编辑器状态。
Future<Document> importTextFileIntoProject({
  required Project project,
  required DocumentService documentService,
  required String filePath,
}) async {
  final ext = p.extension(filePath).toLowerCase();
  if (!supportedImportExtensions.contains(ext)) {
    throw ArgumentError.value(
      filePath,
      'filePath',
      '仅支持导入 Markdown (.md) 或纯文本 (.txt) 文件',
    );
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    throw FileSystemException('导入文件不存在', filePath);
  }

  final content = await file.readAsString();
  final title = p.basenameWithoutExtension(filePath).trim();
  if (title.isEmpty) {
    throw ArgumentError.value(filePath, 'filePath', '文件名不能为空');
  }

  return documentService.createDocument(
    projectId: project.id,
    title: title,
    directoryPath: project.directoryPath,
    content: content,
  );
}
