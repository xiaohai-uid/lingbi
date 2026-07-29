import 'dart:convert';

import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/six_dimension_review_service.dart';

class PersistedChapterReview {
  const PersistedChapterReview({
    required this.report,
    required this.reportPath,
  });

  final ReviewReport report;
  final String reportPath;
}

/// Project-scoped document selection and durable six-dimension review reports.
class ChapterReviewWorkspace {
  ChapterReviewWorkspace({
    required this.projectId,
    required this.projectDir,
    required FileService fileService,
    required SixDimensionReviewService reviewService,
    AtomicFileStore? store,
  })  : _fileService = fileService,
        _reviewService = reviewService,
        _store = store ?? AtomicFileStore();

  final String projectId;
  final String projectDir;
  final FileService _fileService;
  final SixDimensionReviewService _reviewService;
  final AtomicFileStore _store;

  Future<List<Document>> listDocuments() async {
    final documents =
        await _fileService.scanMarkdownDocuments(projectDir, projectId);
    documents.sort((left, right) {
      final leftChapter = _isChapter(left.filePath);
      final rightChapter = _isChapter(right.filePath);
      if (leftChapter != rightChapter) return leftChapter ? -1 : 1;
      return _naturalTitle(left.title).compareTo(_naturalTitle(right.title));
    });
    return documents;
  }

  Future<String> readDocument(Document document) =>
      _fileService.readDocument(document.filePath);

  Future<PersistedChapterReview> reviewSelectedDocument(
    Document document, {
    String? content,
  }) async {
    final sourceContent = content ?? await readDocument(document);
    final documentKey = _documentKey(document);
    final report = await _reviewService.review(
      chapterId: documentKey,
      content: sourceContent,
    );
    final reviewedAt = report.reviewedAt.toUtc();
    final stamp = reviewedAt.toIso8601String().replaceAll(':', '-');
    final safeTitle = document.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final reportPath = '$projectDir/.lingbi/reviews/$safeTitle-$stamp.json';
    final payload = const JsonEncoder.withIndent('  ').convert({
      'schema_version': 1,
      'project_id': projectId,
      'document': {
        ...document.toJson(),
        'document_key': documentKey,
      },
      'report': report.toJson(),
    });
    await _store.writeString(reportPath, payload);
    await _store.writeString(
      '$projectDir/.lingbi/reviews/$safeTitle-latest.json',
      payload,
    );
    return PersistedChapterReview(report: report, reportPath: reportPath);
  }

  bool _isChapter(String path) => path.replaceAll(r'\', '/').contains('/章节内容/');

  String _naturalTitle(String title) => title.replaceAllMapped(
        RegExp(r'\d+'),
        (match) => match.group(0)!.padLeft(12, '0'),
      );

  String _documentKey(Document document) {
    final root =
        projectDir.replaceAll(r'\', '/').replaceFirst(RegExp(r'/$'), '');
    final path = document.filePath.replaceAll(r'\', '/');
    final prefix = '$root/';
    if (path.toLowerCase().startsWith(prefix.toLowerCase())) {
      return path.substring(prefix.length);
    }
    return path;
  }
}
