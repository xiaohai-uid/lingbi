import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/chapter_review_workspace.dart';
import 'package:lingbi/services/six_dimension_review_service.dart';
import 'package:lingbi/ui_v2/components/six_dimension_review_panel.dart';

class _ReviewProvider implements AIProvider {
  @override
  String get name => 'review-test';

  @override
  String get displayName => 'Review Test';

  @override
  bool get isAvailable => true;

  @override
  String get currentModelId => 'review-test';

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      '{"scores":[],"overall_score":8,"summary":"可发布"}';

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield await chatSync(messages: messages);
  }

  @override
  Future<List<double>> embed(String text) async => const [];

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PanelWorkspace extends ChapterReviewWorkspace {
  _PanelWorkspace()
      : document = Document(
          id: 'chapter-1',
          projectId: 'project-1',
          title: '第1章',
          filePath: 'memory://chapter-1',
        ),
        super(
          projectId: 'project-1',
          projectDir: '.',
          fileService: FileService(),
          reviewService: SixDimensionReviewService(
            aiProvider: _ReviewProvider(),
          ),
        );

  final Document document;

  @override
  Future<List<Document>> listDocuments() async => [document];

  @override
  Future<String> readDocument(Document document) async => '# 第1章\n\n开篇内容';

  @override
  Future<PersistedChapterReview> reviewSelectedDocument(
    Document document, {
    String? content,
  }) async =>
      PersistedChapterReview(
        report: ReviewReport(
          chapterId: '章节内容/第1章.md',
          scores: ReviewDimension.values
              .map((dimension) => DimensionScore(
                    dimension: dimension,
                    score: 8,
                  ))
              .toList(),
          overallScore: 8,
          summary: '可发布',
        ),
        reportPath: '.lingbi/reviews/第1章-latest.json',
      );
}

void main() {
  late Directory projectDir;
  late ChapterReviewWorkspace workspace;

  setUp(() async {
    projectDir =
        await Directory.systemTemp.createTemp('lingbi-review-workspace-');
    await File('${projectDir.path}/小说资料/世界观.md')
        .create(recursive: true)
        .then((file) => file.writeAsString('# 世界观'));
    await File('${projectDir.path}/章节内容/第2章.md')
        .create(recursive: true)
        .then((file) => file.writeAsString('# 第2章\n\n后续内容'));
    await File('${projectDir.path}/章节内容/第1章.md')
        .create(recursive: true)
        .then((file) => file.writeAsString('# 第1章\n\n开篇内容'));

    workspace = ChapterReviewWorkspace(
      projectId: 'project-1',
      projectDir: projectDir.path,
      fileService: FileService(),
      reviewService: SixDimensionReviewService(aiProvider: _ReviewProvider()),
      store: AtomicFileStore(),
    );
  });

  tearDown(() async {
    if (await projectDir.exists()) await projectDir.delete(recursive: true);
  });

  test('lists chapter documents first and reads the selected source', () async {
    final documents = await workspace.listDocuments();

    expect(documents.map((document) => document.title), ['第1章', '第2章', '世界观']);
    expect(await workspace.readDocument(documents.first), contains('开篇内容'));
  });

  test('reviews with a restart-stable path id and persists a traceable report',
      () async {
    final document = (await workspace.listDocuments()).first;
    final result = await workspace.reviewSelectedDocument(document);

    expect(result.report.chapterId, '章节内容/第1章.md');
    expect(result.report.overallScore, 8);
    expect(File(result.reportPath).existsSync(), isTrue);

    final json = jsonDecode(await File(result.reportPath).readAsString())
        as Map<String, dynamic>;
    expect(json['project_id'], 'project-1');
    expect(json['document']['title'], '第1章');
    expect(json['document']['document_key'], '章节内容/第1章.md');
    expect(json['report']['chapter_id'], '章节内容/第1章.md');

    final rescannedDocument = (await workspace.listDocuments()).first;
    expect(rescannedDocument.id, isNot(document.id));
    final rescannedResult =
        await workspace.reviewSelectedDocument(rescannedDocument);
    expect(rescannedResult.report.chapterId, result.report.chapterId);
  });

  testWidgets('panel loads project documents and surfaces the saved report',
      (tester) async {
    final panelWorkspace = _PanelWorkspace();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SixDimensionReviewPanel(
            projectId: 'project-1',
            projectDirectoryPath: projectDir.path,
            workspace: panelWorkspace,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('第1章'), findsOneWidget);
    expect(find.textContaining('开篇内容'), findsOneWidget);

    await tester.tap(find.text('开始审稿'));
    await tester.pump();

    expect(find.textContaining('报告已保存'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
}
