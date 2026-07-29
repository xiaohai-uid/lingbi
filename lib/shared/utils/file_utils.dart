import 'dart:io';

/// 文件系统工具函数
class FileUtils {
  /// 获取安全的文件名（替换非法字符）
  static String sanitizeFileName(String name) {
    final illegal = RegExp(r'[<>:"/\\|?*]');
    return name.replaceAll(illegal, '_');
  }

  /// 获取文件扩展名
  static String getExtension(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx).toLowerCase() : '';
  }

  /// 判断是否为 Markdown 文件
  static bool isMarkdownFile(String path) {
    final ext = getExtension(path);
    return ext == '.md' || ext == '.markdown';
  }

  /// 获取目录大小（字节）
  static Future<int> getDirectorySize(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
