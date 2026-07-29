import 'dart:io';

import 'package:lingbi/shared/models/document.dart';

class FileService {
  FileService();

  /// 读取 .md 文件内容
  Future<String> readDocument(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', filePath);
    }
    return file.readAsString();
  }

  /// 写入 .md 文件内容
  Future<void> writeDocument(String filePath, String content) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  /// 删除文件
  Future<void> deleteDocument(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 重命名文件
  Future<void> renameDocument(String oldPath, String newPath) async {
    final file = File(oldPath);
    if (await file.exists()) {
      await file.rename(newPath);
    }
  }

  /// 列出目录下所有 .md 文件
  Future<List<String>> listDocuments(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];
    final files = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        files.add(entity.path);
      }
    }
    files.sort();
    return files;
  }

  /// 创建目录
  Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    await dir.create(recursive: true);
  }

  /// 检查目录是否存在
  Future<bool> directoryExists(String path) async {
    return Directory(path).exists();
  }

  /// 获取文件统计信息
  Future<FileStat> getFileStat(String filePath) async {
    return File(filePath).stat();
  }

  /// 扫描目录中所有 .md 文件（跳过 .lingbi/），返回 Document 列表。
  ///
  /// 统一实现，供 DocumentService 和 ProjectService 共同委托。
  Future<List<Document>> scanMarkdownDocuments(
    String directoryPath,
    String projectId,
  ) async {
    final files = await listDocuments(directoryPath);
    final documents = <Document>[];
    for (final rawPath in files) {
      final path = rawPath.replaceAll(r'\', '/');
      if (path.contains('/.lingbi/')) continue;
      final content = await readDocument(path);
      final fileName = path.split('/').last;
      final title = fileName.endsWith('.md')
          ? fileName.substring(0, fileName.length - 3)
          : fileName;
      documents.add(Document(
        projectId: projectId,
        title: title,
        filePath: path,
        wordCount: countWords(content),
      ));
    }
    return documents;
  }

  /// 计算文档字数（中英文混合）
  int countWords(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;

    // 中文字数：每个汉字算1字
    final chineseChars = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]');
    final chineseCount = chineseChars.allMatches(trimmed).length;

    // 英文单词数：按空白分割
    final englishText = trimmed.replaceAll(chineseChars, ' ');
    final englishWords = englishText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(w))
        .length;

    // 标点符号数
    final punctuation = RegExp(r'[\p{P}\p{S}]', unicode: true);
    final puncCount = punctuation.allMatches(trimmed).length;

    return chineseCount + englishWords + puncCount;
  }
}
