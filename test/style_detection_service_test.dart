/// 测试: StyleDetectionService — 文风检测
library;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/database/database_manager.dart';
import 'package:lingbi/data/database/world_database.dart';
import 'package:lingbi/services/style_detection_service.dart';
import 'package:lingbi/services/interfaces/i_ai_service.dart';
import 'package:lingbi/services/interfaces/i_style_detection_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';

class _MemoryDatabaseManager extends DatabaseManager {
  final Map<String, WorldDatabase> _databases = {};
  @override
  Future<WorldDatabase> getDatabase(String worldId) async =>
      _databases.putIfAbsent(worldId, () => WorldDatabase(NativeDatabase.memory()));
  @override
  Future<void> closeAll() async {
    for (final db in _databases.values) await db.close();
    _databases.clear();
  }
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class MockAIService implements IAIService {
  final String mockResponse;

  MockAIService(this.mockResponse);

  @override
  String get currentProviderName => 'mock';

  @override
  List<String> get availableProviders => ['mock'];

  @override
  void setProvider(String name) {}

  @override
  void setProjectContext(String context) {}

  @override
  void configureApiKey(String provider, String key) {}

  @override
  Stream<String> chat({
    required String message,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    final chunkSize = (mockResponse.length / 3).ceil();
    for (var i = 0; i < mockResponse.length; i += chunkSize) {
      yield mockResponse.substring(i, (i + chunkSize).clamp(0, mockResponse.length));
    }
  }

  @override
  Future<String> analyzeStyle(String text) async => mockResponse;

  @override
  Future<String> analyzeNovel(String text) async => mockResponse;

  @override
  Stream<String> continueWriting(String text) async* {
    yield mockResponse;
  }

  @override
  Future<String> generateText(String prompt) async => mockResponse;
}

void main() {
  late _MemoryDatabaseManager databaseManager;
  late WorldDatabase db;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('lingbi_style_svc_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    databaseManager = _MemoryDatabaseManager();
    db = await databaseManager.getDatabase('test-world-1');
  });

  tearDown(() async {
    await databaseManager.closeAll();
  });

  group('StyleDetectionService', () {
    test('detectDrift parses LLM response', () async {
      final mockAi = MockAIService(jsonEncode({
        'driftScore': 0.75,
        'driftedDimensions': ['tone', 'dialogueRatio'],
        'details': 'First text is serious, second is humorous',
        'suggestions': 'Match tone to maintain consistency',
      }));

      // Construct with mock and null DocumentService since not used in detectDrift
      final service = StyleDetectionService(
        databaseManager: databaseManager,
        aiService: mockAi,
      );

      final report = await service.detectDrift('text A', 'text B');
      expect(report.driftScore, 0.75);
      expect(report.driftedDimensions, ['tone', 'dialogueRatio']);
      expect(report.details, contains('serious'));
      expect(report.suggestions, isNotEmpty);
    });

    test('buildStyleContext returns formatted style guide', () async {
      final now = DateTime.now();
      await db.into(db.styleProfiles).insert(StyleProfilesCompanion.insert(
        id: 'sp1', worldId: 'test-world-1',
        chapterId: Value('ch-1'),
        summary: 'Xianxia style', tone: 'serious',
        vocabularyLevel: 'literary', dialogueRatio: 0.3,
        sentenceComplexity: 0.7, pacing: 'balanced',
        rhetoricalDevices: '[metaphor]', paragraphLength: 0.5,
        keywords: 'xianxia', rawAnalysis: '{}',
        createdAt: now, updatedAt: now,
      ));

      final mockAi = MockAIService('{}');
      final service = StyleDetectionService(
        databaseManager: databaseManager,
        aiService: mockAi,
      );

      final context = await service.buildStyleContext('test-world-1', chapterId: 'ch-1');
      expect(context, contains('风格指南'));
      expect(context, contains('serious'));
      expect(context, contains('30%'));
      expect(context, contains('0.7'));
    });

    test('buildStyleContext returns empty string when no profile', () async {
      final mockAi = MockAIService('{}');
      final service = StyleDetectionService(
        databaseManager: databaseManager,
        aiService: mockAi,
      );

      final context = await service.buildStyleContext('test-world-1', chapterId: 'nonexistent');
      expect(context, isEmpty);
    });
  });
}
