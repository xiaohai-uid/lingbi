/// 变更传播 — 单元测试
///
/// 覆盖：影响识别/修复建议/批量应用
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/canon/data/change_propagation_service.dart';
import 'package:lingbi/features/knowledge/data/vector_knowledge_service.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

// ─── Mocks ───

class MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<Map<String, dynamic>?> read(
      String projectId, String fileName) async {
    return _store['$projectId/$fileName'];
  }

  @override
  Future<void> write(
      String projectId, String fileName, Map<String, dynamic> data) async {
    _store['$projectId/$fileName'] = data;
  }

  @override
  Future<List<String>> list(String projectId) async {
    return _store.keys
        .where((k) => k.startsWith('$projectId/'))
        .map((k) => k.replaceFirst('$projectId/', ''))
        .toList();
  }

  @override
  Future<void> delete(String projectId, String fileName) async {
    _store.remove('$projectId/$fileName');
  }

  @override
  Future<WorldConstitution?> readConstitution(String projectId) async => null;

  @override
  Future<void> writeConstitution(
      String projectId, WorldConstitution constitution) async {}

  @override
  Future<String> getMetaDirPath(String projectId) async => '/mock/$projectId';
}

class MockAIProvider implements AIProvider {
  String mockResponse = '[]';

  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      mockResponse;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield mockResponse;
  }

  @override
  Future<List<double>> embed(String text) async {
    // 确定性嵌入
    final vec = List<double>.filled(8, 0);
    for (var i = 0; i < text.length && i < 50; i++) {
      vec[i % 8] += text.codeUnitAt(i).toDouble();
    }
    return vec;
  }

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ImpactLocation 数据模型', () {
    test('fromJson / toJson 往返', () {
      const loc = ImpactLocation(
        chapterId: 'ch1',
        paragraphIndex: 3,
        excerpt: '他拔出了灵剑',
        relevanceScore: 0.85,
      );

      final json = loc.toJson();
      final restored = ImpactLocation.fromJson(json);

      expect(restored.chapterId, 'ch1');
      expect(restored.paragraphIndex, 3);
      expect(restored.relevanceScore, 0.85);
    });
  });

  group('ChangeImpactReport', () {
    test('fromJson / toJson 往返', () {
      final report = ChangeImpactReport(
        settingId: 'canon_sword',
        settingName: '灵剑设定',
        changeDescription: '灵剑从金属改为玉质',
        affectedLocations: const [
          ImpactLocation(
              chapterId: 'ch1', paragraphIndex: 2, relevanceScore: 0.9),
        ],
        affectedChapterIds: const ['ch1', 'ch3'],
        totalAffected: 2,
      );

      final json = report.toJson();
      final restored = ChangeImpactReport.fromJson(json);

      expect(restored.settingName, '灵剑设定');
      expect(restored.affectedChapterIds.length, 2);
      expect(restored.totalAffected, 2);
    });
  });

  group('FixSuggestion', () {
    test('copyWith applied', () {
      const fix = FixSuggestion(
        chapterId: 'ch1',
        paragraphIndex: 0,
        originalText: '金属剑身',
        suggestedText: '玉质剑身',
        reason: '设定变更',
      );

      expect(fix.applied, isFalse);
      final applied = fix.copyWith(applied: true);
      expect(applied.applied, isTrue);
      expect(applied.originalText, '金属剑身');
    });
  });

  group('ChangePropagationService', () {
    late MockMetaRepository metaRepo;
    late MockAIProvider aiProvider;
    late VectorKnowledgeService vectorService;
    late ChangePropagationService service;

    setUp(() async {
      metaRepo = MockMetaRepository();
      aiProvider = MockAIProvider();
      vectorService = VectorKnowledgeService(
        metaRepository: metaRepo,
        aiProvider: aiProvider,
        similarityThreshold: 0,
      );
      service = ChangePropagationService(
        vectorKnowledgeService: vectorService,
        aiProvider: aiProvider,
      );

      // 预置向量索引
      await vectorService.indexContent(
        'proj1',
        id: 'ch1_p2',
        type: VectorEntryType.chapter,
        content: '他拔出了那柄金属长剑，剑身闪烁着寒光',
        metadata: {'chapter_id': 'ch1', 'paragraph_index': 2},
      );
      await vectorService.indexContent(
        'proj1',
        id: 'ch3_p5',
        type: VectorEntryType.chapter,
        content: '灵剑的金属质地让他感到沉重',
        metadata: {'chapter_id': 'ch3', 'paragraph_index': 5},
      );
      await vectorService.indexContent(
        'proj1',
        id: 'ch5_p1',
        type: VectorEntryType.chapter,
        content: '花园里的玫瑰盛开了',
        metadata: {'chapter_id': 'ch5', 'paragraph_index': 1},
      );
    });

    test('analyzeImpact 识别受影响章节', () async {
      final report = await service.analyzeImpact(
        projectId: 'proj1',
        settingId: 'canon_sword',
        settingName: '灵剑',
        changeDescription: '金属改为玉质',
      );

      expect(report.settingName, '灵剑');
      expect(report.affectedLocations, isNotEmpty);
      // 应该找到与剑相关的章节
      expect(report.affectedChapterIds, isNotEmpty);
    });

    test('generateFixSuggestions 生成修复建议', () async {
      aiProvider.mockResponse = '''
[{"paragraph_index": 2, "original_text": "金属长剑", "suggested_text": "玉质长剑", "reason": "设定已改为玉质"}]''';

      final report = ChangeImpactReport(
        settingId: 's1',
        settingName: '灵剑',
        changeDescription: '金属→玉质',
        affectedChapterIds: const ['ch1'],
      );

      final suggestions = await service.generateFixSuggestions(
        report: report,
        chapterContents: {
          'ch1': '他拔出了那柄金属长剑，剑身闪烁着寒光。',
        },
      );

      expect(suggestions.length, 1);
      expect(suggestions[0].originalText, '金属长剑');
      expect(suggestions[0].suggestedText, '玉质长剑');
      expect(suggestions[0].chapterId, 'ch1');
    });

    test('applyFixes 批量应用修复', () async {
      final persisted = <String, String>{};

      final suggestions = [
        const FixSuggestion(
          chapterId: 'ch1',
          paragraphIndex: 2,
          originalText: '金属长剑',
          suggestedText: '玉质长剑',
          reason: '设定变更',
        ).copyWith(applied: true),
        const FixSuggestion(
          chapterId: 'ch1',
          paragraphIndex: 5,
          originalText: '未应用的修改',
          suggestedText: '不应生效',
          reason: '未确认',
        ), // applied = false
      ];

      final result = await service.applyFixes(
        suggestions: suggestions,
        chapterContents: {
          'ch1': '他拔出了那柄金属长剑，剑身闪烁。',
        },
        persist: (id, content) async {
          persisted[id] = content;
        },
      );

      expect(result['ch1'], contains('玉质长剑'));
      expect(result['ch1'], isNot(contains('金属长剑')));
      expect(persisted['ch1'], contains('玉质长剑'));
    });

    test('applyFixes 无匹配原文时不修改', () async {
      final suggestions = [
        const FixSuggestion(
          chapterId: 'ch1',
          paragraphIndex: 0,
          originalText: '不存在的文本',
          suggestedText: '替换',
        ).copyWith(applied: true),
      ];

      final result = await service.applyFixes(
        suggestions: suggestions,
        chapterContents: {'ch1': '原始内容'},
      );

      expect(result['ch1'], '原始内容'); // 未变
    });
  });
}
