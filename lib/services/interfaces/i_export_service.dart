import 'package:lingbi/core/models/world.dart';
import 'package:lingbi/core/models/document.dart';

/// 导出服务接口
abstract class IExportService {
  Future<void> exportAsMarkdown({
    required String content,
    required String savePath,
  });

  Future<void> exportAsTxt({
    required String content,
    required String savePath,
  });

  Future<void> exportAsPdf({
    required String title,
    required String content,
    required String savePath,
  });

  Future<void> exportAsDocx({
    required String title,
    required String content,
    required String savePath,
  });

  Future<void> exportAsEpub({
    required String title,
    required String content,
    required String savePath,
  });

  Future<void> exportProjectToDirectory({
    required World project,
    required List<Document> documents,
    required Map<String, String> contents,
    required String outputDir,
    String format = 'md',
  });
}
