import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/features/writing/data/pipeline/generation_context.dart';
import 'package:lingbi/features/writing/data/pipeline/novel_application_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/ai/free_provider.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/errors/ai_error.dart';
import 'package:lingbi/shared/file_system/file_service.dart';

void main() {
  const context = GenerationContext(
    chapterId: 'chapter-1',
    userInstruction: '生成一个雨夜开场',
  );

  for (final failure in [
    aiExceptionFromHttp(401),
    aiExceptionFromHttp(429),
    const AIException(
      type: AIExceptionType.timeout,
      message: '请求超时',
      retryable: true,
    ),
    aiExceptionFromHttp(500),
  ]) {
    test('${failure.type.name} does not create a candidate', () async {
      final app = await _makeApplication(_ThrowingProvider(failure));

      final result = await app.generateCandidateSync(
        chapterId: 'chapter-1',
        context: context,
        sourceVersion: 'v1',
      );

      expect(result.isFailure, isTrue);
      expect(result.error!.message, isNotEmpty);
      expect(app.listCandidates('chapter-1'), isEmpty);
    });
  }

  test('empty stream does not create a candidate', () async {
    final app = await _makeApplication(_EmptyProvider());

    final result = await app.generateCandidateSync(
      chapterId: 'chapter-1',
      context: context,
      sourceVersion: 'v1',
    );

    expect(result.isFailure, isTrue);
    expect(app.listCandidates('chapter-1'), isEmpty);
  });

  test('streaming provider error does not create a candidate', () async {
    final app = await _makeApplication(
      _ThrowingProvider(aiExceptionFromHttp(401)),
    );

    final events = <PipelineResult<String>>[];
    await app
        .generateCandidate(
          chapterId: 'chapter-1',
          context: context,
          sourceVersion: 'v1',
        )
        .forEach(events.add);

    expect(events, isNotEmpty);
    expect(events.last.isFailure, isTrue);
    expect(app.listCandidates('chapter-1'), isEmpty);
  });

  test('unconfigured free provider does not create a candidate', () async {
    final app = await _makeApplication(FreeProvider());

    final result = await app.generateCandidateSync(
      chapterId: 'chapter-1',
      context: context,
      sourceVersion: 'v1',
    );

    expect(result.isFailure, isTrue);
    expect(result.error!.message, contains('配置 API Key'));
    expect(app.listCandidates('chapter-1'), isEmpty);
  });
}

Future<NovelApplicationService> _makeApplication(AIProvider provider) async {
  final temp = await Directory.systemTemp.createTemp('lingbi_ai_error_');
  addTearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  final storage = StorageService();
  await storage.initialize(dbPath: '${temp.path}/db');
  final zvec = ZVecService(storageService: storage);
  await zvec.initialize(dbPath: '${temp.path}/db');
  addTearDown(zvec.close);

  return NovelApplicationService(
    projectDir: temp.path,
    projectId: 'project-a',
    documentService: DocumentService(
      fileService: FileService(),
    ),
    canonService: CanonService(zvecService: zvec),
    aiService: AIService(
      quotaService: QuotaService(),
      freeProvider: provider,
    ),
  );
}

class _ThrowingProvider extends AIProvider {
  _ThrowingProvider(this.failure);

  final AIException failure;

  @override
  String get name => 'fake-error';

  @override
  String get displayName => 'Fake Error';

  @override
  bool get isAvailable => true;

  @override
  String get currentModelId => 'fake-model';

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    throw failure;
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    throw failure;
  }

  @override
  Future<List<double>> embed(String text) async => [];

  @override
  Future<void> dispose() async {}
}

class _EmptyProvider extends AIProvider {
  @override
  String get name => 'fake-empty';

  @override
  String get displayName => 'Fake Empty';

  @override
  bool get isAvailable => true;

  @override
  String get currentModelId => 'fake-model';

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {}

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    return '';
  }

  @override
  Future<List<double>> embed(String text) async => [];

  @override
  Future<void> dispose() async {}
}
