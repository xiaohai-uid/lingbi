/// 风格蒸馏引擎 — 单元测试
///
/// 覆盖：提取/存储/注入/跨项目引用/编辑微调
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/models/style_profile.dart';
import 'package:lingbi/features/style/data/style_distillation_service.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';

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
  String mockResponse = '{}';

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
  late StyleDistillationService service;

  setUp(() {
    metaRepo = MockMetaRepository();
    aiProvider = MockAIProvider();
    service = StyleDistillationService(
      metaRepository: metaRepo,
      aiProvider: aiProvider,
    );
  });

  group('StyleProfile 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      final profile = StyleProfile(
        id: 'sp_001',
        name: '金庸武侠风',
        sentencePatterns: ['长短句交替', '善用排比'],
        vocabulary: const [
          VocabularyTrait(
            trait: '偏好古风用词',
            examples: ['拱手', '抱拳'],
            frequency: '高频',
          ),
        ],
        rhythm: const RhythmProfile(
          avgSentenceLength: 18,
          paragraphLength: '短段落',
          pacing: '张弛有度',
          tensionCurve: '波浪式',
        ),
        rhetoricPreferences: const [
          RhetoricPreference(name: '比喻', frequency: '高频'),
          RhetoricPreference(name: '排比', frequency: '中频'),
        ],
        samples: const [
          StyleSample(
            text: '他一刀劈出，如山洪暴发。',
            source: '第三章',
            highlight: '典型短句+比喻',
          ),
        ],
        description: '文风古朴，善用短句和武侠意象',
        sourceWordCount: 8000,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final json = profile.toJson();
      final restored = StyleProfile.fromJson(json);

      expect(restored.id, 'sp_001');
      expect(restored.name, '金庸武侠风');
      expect(restored.sentencePatterns.length, 2);
      expect(restored.vocabulary.length, 1);
      expect(restored.vocabulary[0].trait, '偏好古风用词');
      expect(restored.rhythm.avgSentenceLength, 18);
      expect(restored.rhetoricPreferences.length, 2);
      expect(restored.samples.length, 1);
      expect(restored.description, contains('古朴'));
    });

    test('toPromptText 生成约束文本', () {
      const profile = StyleProfile(
        id: 'sp_002',
        name: '测试风格',
        sentencePatterns: ['短句为主', '口语化'],
        description: '轻松幽默的都市风格',
        rhythm: RhythmProfile(avgSentenceLength: 12, paragraphLength: '短段落'),
        rhetoricPreferences: [
          RhetoricPreference(name: '夸张', frequency: '高频'),
        ],
      );

      final text = profile.toPromptText();
      expect(text, contains('风格约束'));
      expect(text, contains('轻松幽默'));
      expect(text, contains('短句为主'));
      expect(text, contains('平均句长12字'));
      expect(text, contains('夸张'));
    });
  });

  group('风格提取', () {
    test('源文本不足5000字时抛出异常', () async {
      expect(
        () => service.extractStyle(sourceText: '短文', name: '测试'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('AI 正常返回时提取成功', () async {
      aiProvider.mockResponse = '''
{
  "sentencePatterns": ["短句为主", "对话驱动"],
  "vocabulary": [{"trait": "口语化", "examples": ["得", "呗"], "frequency": "高频"}],
  "rhythm": {"avgSentenceLength": 10, "paragraphLength": "短段落", "pacing": "紧凑", "tensionCurve": "渐进式"},
  "rhetoricPreferences": [{"name": "反问", "frequency": "高频", "example": "难道不是吗？"}],
  "samples": [{"text": "他笑了笑，没说话。", "source": "第一章", "highlight": "典型留白"}],
  "description": "简洁明快的都市风格"
}''';

      final longText = '这是一段很长的测试文本。' * 500; // > 5000 字
      final profile = await service.extractStyle(
        sourceText: longText,
        name: '都市轻松风',
      );

      expect(profile.name, '都市轻松风');
      expect(profile.sentencePatterns, contains('短句为主'));
      expect(profile.vocabulary.length, 1);
      expect(profile.rhythm.avgSentenceLength, 10);
      expect(profile.rhetoricPreferences.length, 1);
      expect(profile.description, contains('简洁'));
      expect(profile.sourceWordCount, longText.length);
    });

    test('AI 异常时返回降级档案', () async {
      aiProvider.mockResponse = '这不是JSON';

      final longText = '测试文本内容。' * 1000;
      final profile = await service.extractStyle(
        sourceText: longText,
        name: '降级测试',
      );

      expect(profile.name, '降级测试');
      expect(profile.description, contains('未能完成'));
    });
  });

  group('存储与跨项目引用', () {
    test('saveProfile + listProfiles 往返一致', () async {
      final profile = StyleProfile(
        id: 'sp_100',
        name: '测试档案',
        description: '测试用',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.saveProfile('proj1', profile);
      final profiles = await service.listProfiles('proj1');

      expect(profiles.length, 1);
      expect(profiles[0].id, 'sp_100');
      expect(profiles[0].name, '测试档案');
    });

    test('更新已有档案不重复', () async {
      final profile = StyleProfile(
        id: 'sp_100',
        name: '原始名',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.saveProfile('proj1', profile);

      final updated = profile.copyWith(name: '修改后');
      await service.saveProfile('proj1', updated);

      final profiles = await service.listProfiles('proj1');
      expect(profiles.length, 1);
      expect(profiles[0].name, '修改后');
    });

    test('deleteProfile 删除档案', () async {
      final profile = StyleProfile(
        id: 'sp_100',
        name: '待删除',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.saveProfile('proj1', profile);
      await service.deleteProfile('proj1', 'sp_100');

      final profiles = await service.listProfiles('proj1');
      expect(profiles, isEmpty);
    });

    test('getProfile 获取指定档案', () async {
      final p1 = StyleProfile(
          id: 'sp_1', name: 'A', createdAt: DateTime.now(), updatedAt: DateTime.now());
      final p2 = StyleProfile(
          id: 'sp_2', name: 'B', createdAt: DateTime.now(), updatedAt: DateTime.now());
      await service.saveProfile('proj1', p1);
      await service.saveProfile('proj1', p2);

      final found = await service.getProfile('proj1', 'sp_2');
      expect(found, isNotNull);
      expect(found!.name, 'B');

      final notFound = await service.getProfile('proj1', 'sp_999');
      expect(notFound, isNull);
    });
  });

  group('项目绑定', () {
    test('bindProfile + getBoundProfile', () async {
      final profile = StyleProfile(
        id: 'sp_200',
        name: '绑定测试',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.saveProfile('proj1', profile);
      await service.bindProfile('proj1', 'sp_200');

      final bound = await service.getBoundProfile('proj1');
      expect(bound, isNotNull);
      expect(bound!.id, 'sp_200');
    });

    test('unbindProfile 解绑', () async {
      final profile = StyleProfile(
        id: 'sp_200',
        name: '解绑测试',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.saveProfile('proj1', profile);
      await service.bindProfile('proj1', 'sp_200');
      await service.unbindProfile('proj1');

      final bound = await service.getBoundProfile('proj1');
      expect(bound, isNull);
    });
  });

  group('ContextAssembler 注入', () {
    test('buildStyleConstraintText 有绑定时返回约束文本', () async {
      final profile = StyleProfile(
        id: 'sp_300',
        name: '注入测试',
        sentencePatterns: ['短句'],
        description: '简洁风格',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.saveProfile('proj1', profile);
      await service.bindProfile('proj1', 'sp_300');

      final text = await service.buildStyleConstraintText('proj1');
      expect(text, contains('风格约束'));
      expect(text, contains('简洁风格'));
      expect(text, contains('短句'));
    });

    test('buildStyleConstraintText 无绑定时返回空', () async {
      final text = await service.buildStyleConstraintText('empty_proj');
      expect(text, isEmpty);
    });
  });

  group('编辑微调', () {
    test('updateProfile 更新时间戳', () async {
      final profile = StyleProfile(
        id: 'sp_400',
        name: '原始',
        createdAt: DateTime(2020),
        updatedAt: DateTime(2020),
      );
      await service.saveProfile('proj1', profile);

      final updated = await service.updateProfile(
        'proj1',
        profile.copyWith(name: '微调后'),
      );

      expect(updated.name, '微调后');
      expect(updated.updatedAt!.isAfter(DateTime(2020)), true);

      // 验证持久化
      final loaded = await service.getProfile('proj1', 'sp_400');
      expect(loaded!.name, '微调后');
    });
  });
}
