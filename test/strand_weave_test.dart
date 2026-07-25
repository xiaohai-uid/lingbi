/// StrandWeave 多线叙事节奏控制 — 单元测试
///
/// 覆盖：配比注入 / 红线检测 / 分布记录 / 标注解析
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/strand_weave_config.dart';
import 'package:lingbi/core/models/chapter_state_snapshot.dart';
import 'package:lingbi/services/strand_weave_service.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/core/ai/ai_provider.dart';

// ─── Mock IProjectMetaRepository ───

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

// ─── Mock AIProvider ───

class MockAIProvider implements AIProvider {
  String mockResponse = '[]';

  @override
  String get name => 'mock';

  @override
  String get displayName => 'Mock Provider';

  @override
  bool get isAvailable => true;

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    return mockResponse;
  }

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield mockResponse;
  }

  @override
  Future<List<double>> embed(String text) async => [];

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockMetaRepository metaRepo;
  late MockAIProvider aiProvider;
  late StrandWeaveService service;

  setUp(() {
    metaRepo = MockMetaRepository();
    aiProvider = MockAIProvider();
    service = StrandWeaveService(
      metaRepository: metaRepo,
      aiProvider: aiProvider,
    );
  });

  group('StrandWeaveConfig 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      const config = StrandWeaveConfig(
        strands: [
          Strand(name: '主线', ratio: 0.5, description: '核心情节'),
          Strand(name: '感情线', ratio: 0.3),
          Strand(name: '世界观线', ratio: 0.2),
        ],
        redLines: [
          RedLine(
            id: 'rl_1',
            description: '连续3章不得无主线推进',
            strandName: '主线',
            maxConsecutiveAbsence: 3,
          ),
        ],
        enabled: true,
      );

      final json = config.toJson();
      final restored = StrandWeaveConfig.fromJson(json);

      expect(restored.strands.length, 3);
      expect(restored.strands[0].name, '主线');
      expect(restored.strands[0].ratio, 0.5);
      expect(restored.redLines.length, 1);
      expect(restored.redLines[0].maxConsecutiveAbsence, 3);
      expect(restored.enabled, true);
    });

    test('totalRatio 计算正确', () {
      const config = StrandWeaveConfig(
        strands: [
          Strand(name: 'A', ratio: 0.6),
          Strand(name: 'B', ratio: 0.4),
        ],
      );
      expect(config.totalRatio, closeTo(1.0, 0.001));
      expect(config.isRatioValid, true);
    });

    test('isRatioValid 检测非法比例', () {
      const config = StrandWeaveConfig(
        strands: [
          Strand(name: 'A', ratio: 0.6),
          Strand(name: 'B', ratio: 0.6),
        ],
      );
      expect(config.isRatioValid, false);
    });
  });

  group('配比约束 prompt 注入', () {
    test('buildConstraintText 生成正确的约束文本', () async {
      // 先写入配置
      await metaRepo.write('proj1', 'strand_weave.json', const StrandWeaveConfig(
        strands: [
          Strand(name: '主线', ratio: 0.5, description: '核心情节推进'),
          Strand(name: '感情线', ratio: 0.3),
          Strand(name: '世界观线', ratio: 0.2),
        ],
        redLines: [
          RedLine(
            id: 'rl_1',
            description: '连续3章不得无主线推进',
            strandName: '主线',
            maxConsecutiveAbsence: 3,
          ),
        ],
      ).toJson());

      final text = await service.buildConstraintText('proj1');

      expect(text, contains('多线叙事配比约束'));
      expect(text, contains('主线: 50%'));
      expect(text, contains('感情线: 30%'));
      expect(text, contains('世界观线: 20%'));
      expect(text, contains('[线:叙事线名称]'));
      expect(text, contains('红线约束'));
      expect(text, contains('连续3章不得无主线推进'));
    });

    test('未启用时返回空字符串', () async {
      await metaRepo.write('proj1', 'strand_weave.json', const StrandWeaveConfig(
        strands: [Strand(name: '主线', ratio: 1.0)],
        enabled: false,
      ).toJson());

      final text = await service.buildConstraintText('proj1');
      expect(text, isEmpty);
    });

    test('无配置时返回空字符串', () async {
      final text = await service.buildConstraintText('empty_proj');
      expect(text, isEmpty);
    });
  });

  group('叙事线标注解析', () {
    test('parseAnnotations 正确解析 [线:xxx] 标注', () {
      const output = '''
他握紧了剑柄，目光坚定。[线:主线]

她轻轻叹了口气，望向远方。[线:感情线]

远处的山脉笼罩在迷雾中，传说那里有上古遗迹。[线:世界观线]

他终于迈出了那一步。[线:主线]''';

      final annotations = service.parseAnnotations(output);

      expect(annotations.length, 4);
      expect(annotations[0].strandName, '主线');
      expect(annotations[0].paragraphIndex, 0);
      expect(annotations[1].strandName, '感情线');
      expect(annotations[2].strandName, '世界观线');
      expect(annotations[3].strandName, '主线');
    });

    test('无标注时返回空列表', () {
      const output = '普通文本没有标注。\n另一段也没有。';
      final annotations = service.parseAnnotations(output);
      expect(annotations, isEmpty);
    });
  });

  group('分布计算', () {
    test('computeDistribution 正确计算各线占比', () {
      const annotations = [
        StrandAnnotation(paragraphIndex: 0, strandName: '主线'),
        StrandAnnotation(paragraphIndex: 1, strandName: '感情线'),
        StrandAnnotation(paragraphIndex: 2, strandName: '主线'),
        StrandAnnotation(paragraphIndex: 3, strandName: '主线'),
        StrandAnnotation(paragraphIndex: 4, strandName: '世界观线'),
      ];

      final dist = service.computeDistribution(annotations, 5);

      expect(dist.distribution['主线'], closeTo(0.6, 0.01));
      expect(dist.distribution['感情线'], closeTo(0.2, 0.01));
      expect(dist.distribution['世界观线'], closeTo(0.2, 0.01));
      expect(dist.totalParagraphs, 5);
    });

    test('空标注返回空分布', () {
      final dist = service.computeDistribution([], 0);
      expect(dist.isEmpty, true);
    });
  });

  group('红线约束检测', () {
    test('检测到红线违反', () {
      const config = StrandWeaveConfig(
        strands: [
          Strand(name: '主线', ratio: 0.5),
          Strand(name: '感情线', ratio: 0.5),
        ],
        redLines: [
          RedLine(
            id: 'rl_1',
            description: '连续3章不得无主线推进',
            strandName: '主线',
            maxConsecutiveAbsence: 3,
          ),
        ],
      );

      // 最近 4 章都没有主线
      final distributions = List.generate(
        4,
        (_) => const StrandDistribution(
          distribution: {'感情线': 1.0},
          totalParagraphs: 10,
        ),
      );

      final violations = service.detectRedLineViolations(
        config: config,
        recentDistributions: distributions,
        chapterIds: ['ch1', 'ch2', 'ch3', 'ch4'],
      );

      expect(violations.length, 1);
      expect(violations[0].redLine.strandName, '主线');
      expect(violations[0].consecutiveAbsence, greaterThanOrEqualTo(3));
    });

    test('未违反红线时返回空列表', () {
      const config = StrandWeaveConfig(
        redLines: [
          RedLine(
            id: 'rl_1',
            description: '连续3章不得无主线推进',
            strandName: '主线',
            maxConsecutiveAbsence: 3,
          ),
        ],
      );

      // 最近章节有主线出现
      final distributions = [
        const StrandDistribution(
          distribution: {'主线': 0.5, '感情线': 0.5},
          totalParagraphs: 10,
        ),
        const StrandDistribution(
          distribution: {'感情线': 1.0},
          totalParagraphs: 10,
        ),
      ];

      final violations = service.detectRedLineViolations(
        config: config,
        recentDistributions: distributions,
        chapterIds: ['ch1', 'ch2'],
      );

      expect(violations, isEmpty);
    });
  });

  group('分布记录持久化', () {
    test('recordDistribution + loadDistribution 往返一致', () async {
      const dist = StrandDistribution(
        distribution: {'主线': 0.6, '感情线': 0.4},
        annotations: [
          StrandAnnotation(paragraphIndex: 0, strandName: '主线'),
          StrandAnnotation(paragraphIndex: 1, strandName: '感情线'),
        ],
        totalParagraphs: 2,
      );

      await service.recordDistribution(
        projectId: 'proj1',
        chapterId: 'ch_001',
        distribution: dist,
      );

      final loaded = await service.loadDistribution(
        projectId: 'proj1',
        chapterId: 'ch_001',
      );

      expect(loaded, isNotNull);
      expect(loaded!.distribution['主线'], closeTo(0.6, 0.01));
      expect(loaded.distribution['感情线'], closeTo(0.4, 0.01));
      expect(loaded.annotations.length, 2);
      expect(loaded.totalParagraphs, 2);
    });

    test('加载不存在的记录返回 null', () async {
      final loaded = await service.loadDistribution(
        projectId: 'proj1',
        chapterId: 'nonexistent',
      );
      expect(loaded, isNull);
    });
  });

  group('ChapterStateSnapshot 集成', () {
    test('快照包含 strandDistribution 字段', () {
      const snapshot = ChapterStateSnapshot(
        chapterId: 'ch_001',
        projectId: 'proj1',
        strandDistribution: StrandDistribution(
          distribution: {'主线': 0.7, '感情线': 0.3},
          totalParagraphs: 10,
        ),
      );

      final json = snapshot.toJson();
      expect(json['strandDistribution'], isNotNull);

      final restored = ChapterStateSnapshot.fromJson(json);
      expect(restored.strandDistribution, isNotNull);
      expect(
        restored.strandDistribution!.distribution['主线'],
        closeTo(0.7, 0.01),
      );
    });

    test('无 strandDistribution 时序列化正常', () {
      const snapshot = ChapterStateSnapshot(
        chapterId: 'ch_002',
        projectId: 'proj1',
      );

      final json = snapshot.toJson();
      expect(json['strandDistribution'], isNull);

      final restored = ChapterStateSnapshot.fromJson(json);
      expect(restored.strandDistribution, isNull);
    });
  });

  group('配置 CRUD', () {
    test('addStrand 添加叙事线', () async {
      final config = await service.addStrand(
        'proj1',
        name: '主线',
        ratio: 0.6,
        description: '核心情节',
      );

      expect(config.strands.length, 1);
      expect(config.strands[0].name, '主线');
      expect(config.strands[0].ratio, 0.6);
    });

    test('updateStrandRatio 更新比例', () async {
      await service.addStrand('proj1', name: '主线', ratio: 0.6);
      final updated = await service.updateStrandRatio(
        'proj1',
        strandName: '主线',
        newRatio: 0.8,
      );

      expect(updated.strands[0].ratio, 0.8);
    });

    test('removeStrand 删除叙事线', () async {
      await service.addStrand('proj1', name: '主线', ratio: 0.6);
      await service.addStrand('proj1', name: '感情线', ratio: 0.4);
      final updated = await service.removeStrand('proj1', '主线');

      expect(updated.strands.length, 1);
      expect(updated.strands[0].name, '感情线');
    });

    test('addRedLine + removeRedLine', () async {
      final config = await service.addRedLine(
        'proj1',
        strandName: '主线',
        description: '连续3章不得无主线推进',
        maxConsecutiveAbsence: 3,
      );
      expect(config.redLines.length, 1);

      final redLineId = config.redLines[0].id;
      final updated = await service.removeRedLine('proj1', redLineId);
      expect(updated.redLines, isEmpty);
    });
  });
}
