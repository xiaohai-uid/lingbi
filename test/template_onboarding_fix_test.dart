// 对标 OpenWrite 发布级缺陷修复的回归测试。
//
// 覆盖：
// - R1 模板落地：TemplateSeeder 播种 + ProjectService.createPortableProject 消费 genreId
// - R2 题材键统一：GuidedFlowSkillLoader 按 genreId（英文 slug）匹配，长篇优先
// - R3 磁盘状态隔离：同名新建项目清理残留 project_meta/
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/core/models/guided_flow_definition.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/services/guided_flow_engine.dart';
import 'package:lingbi/services/guided_flow_defaults.dart';
import 'package:lingbi/services/genre_seed_data.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';
import 'package:lingbi/services/project_service.dart';
import 'package:lingbi/services/skill/guided_flow_skill_loader.dart';
import 'package:lingbi/services/skills/xuanhuan_flow_skill.dart';
import 'package:lingbi/services/template_seeder.dart';

// ─── Mock IProjectMetaRepository（内存实现，仅供 GuidedFlowEngine 构造）───
class _MockMetaRepository implements IProjectMetaRepository {
  final Map<String, Map<String, dynamic>> _store = {};
  String _key(String p, String f) => '$p/$f';

  @override
  Future<Map<String, dynamic>?> read(String p, String f) async =>
      _store[_key(p, f)];

  @override
  Future<void> write(String p, String f, Map<String, dynamic> data) async =>
      _store[_key(p, f)] = data;

  @override
  Future<List<String>> list(String p) async => _store.keys
      .where((k) => k.startsWith('$p/'))
      .map((k) => k.substring(p.length + 1))
      .toList();

  @override
  Future<void> delete(String p, String f) async => _store.remove(_key(p, f));

  @override
  Future<WorldConstitution?> readConstitution(String p) async => null;

  @override
  Future<void> writeConstitution(String p, WorldConstitution c) async {}

  @override
  Future<String> getMetaDirPath(String p) async => '/tmp/$p/project_meta';
}

// ─── Mock AIProvider（引导流程测试不需要真实调用）───
class _MockAIProvider extends AIProvider {
  @override
  String get name => 'mock';
  @override
  String get displayName => 'Mock';
  @override
  bool get isAvailable => true;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    yield '{}';
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async =>
      '{}';

  @override
  Future<List<double>> embed(String text) async => const [0.1, 0.2];

  @override
  Future<void> dispose() async {}
}

void main() {
  group('R1 TemplateSeeder 播种', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('seeder_test_');
    });

    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('玄幻题材播种世界观与人物库骨架，且建章节内容目录', () async {
      const seeder = TemplateSeeder();
      final written = await seeder.seedProject(
        projectDir: tmp.path,
        genreId: 'xuanhuan',
      );

      expect(written, isNotEmpty);
      final sep = Platform.pathSeparator;
      final world = File('${tmp.path}${sep}小说资料${sep}世界观.md');
      final chars = File('${tmp.path}${sep}小说资料${sep}人物库.md');
      expect(await world.exists(), isTrue);
      expect(await chars.exists(), isTrue);
      expect(await world.readAsString(), contains('修炼体系'));
      expect(await chars.readAsString(), contains('主角'));
      expect(await Directory('${tmp.path}${sep}章节内容').exists(), isTrue);
    });

    test('未收录题材（自由创作）不播种', () async {
      const seeder = TemplateSeeder();
      final written = await seeder.seedProject(
        projectDir: tmp.path,
        genreId: '',
      );
      expect(written, isEmpty);
    });

    test('幂等：已存在的文件不被覆盖', () async {
      const seeder = TemplateSeeder();
      final sep = Platform.pathSeparator;
      final settingsDir = Directory('${tmp.path}${sep}小说资料');
      await settingsDir.create(recursive: true);
      final world = File('${settingsDir.path}${sep}世界观.md');
      await world.writeAsString('用户自定义世界观');

      await seeder.seedProject(projectDir: tmp.path, genreId: 'xuanhuan');

      expect(await world.readAsString(), '用户自定义世界观');
    });

    test('所有模板题材均有种子数据', () {
      // 与 ProjectTemplate.values 的 genreId 保持一致。
      for (final genreId in [
        'xuanhuan',
        'urban',
        'suspense',
        'romance',
        'scifi',
        'history',
      ]) {
        expect(genreSeedTable.containsKey(genreId), isTrue,
            reason: '缺少题材种子: $genreId');
        expect(genreSeedTable[genreId]!.worldbuildingMarkdown, isNotEmpty);
        expect(genreSeedTable[genreId]!.charactersMarkdown, isNotEmpty);
      }
    });
  });

  group('R1+R3 ProjectService.createPortableProject', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('project_service_test_');
    });

    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('创建玄幻项目会播种设定文件', () async {
      final service = ProjectService();
      final dir = '${tmp.path}${Platform.pathSeparator}万界守夜人';
      final project = await service.createPortableProject(
        directoryPath: dir,
        brief: const ProjectBrief(
          title: '万界守夜人',
          genreId: 'xuanhuan',
          templateId: 'genre:xuanhuan',
        ),
      );

      expect(project.genre, 'xuanhuan');
      final sep = Platform.pathSeparator;
      expect(await File('$dir${sep}小说资料${sep}世界观.md').exists(), isTrue);
      expect(await File('$dir${sep}小说资料${sep}人物库.md').exists(), isTrue);
    });

    test('R3：同名新建项目清理残留 project_meta/（不继承旧状态）', () async {
      final service = ProjectService();
      final dir = '${tmp.path}${Platform.pathSeparator}同名作品';
      final sep = Platform.pathSeparator;

      // 第一次创建，并模拟旧项目残留的引导状态。
      await service.createPortableProject(
        directoryPath: dir,
        brief: const ProjectBrief(
          title: '同名作品',
          genreId: 'xuanhuan',
          templateId: 'genre:xuanhuan',
        ),
      );
      final staleMeta = Directory('$dir${sep}project_meta');
      await staleMeta.create(recursive: true);
      final staleState = File('${staleMeta.path}${sep}guided_flow_state.json');
      await staleState.writeAsString('{"flowId":"old","conversationHistory":[]}');
      expect(await staleState.exists(), isTrue);

      // 第二次以同目录（同名）新建 —— 应清理残留 project_meta/。
      await service.createPortableProject(
        directoryPath: dir,
        brief: const ProjectBrief(
          title: '同名作品',
          genreId: 'xuanhuan',
          templateId: 'genre:xuanhuan',
        ),
      );
      expect(await staleState.exists(), isFalse,
          reason: '新建项目不应继承旧项目的引导状态');
    });
  });

  group('R2 GuidedFlowSkillLoader 题材键匹配', () {
    late GuidedFlowEngine engine;
    late GuidedFlowSkillLoader loader;

    setUp(() {
      engine = GuidedFlowEngine(
        metaRepository: _MockMetaRepository(),
        aiProvider: _MockAIProvider(),
      );
      loader = GuidedFlowSkillLoader(engine);
      // 与 service_locator 一致：长篇在前、短篇在后，同题材键。
      loader.registerBuiltinFlow(xuanhuanLongFlowDefinition, 'xuanhuan');
      loader.registerBuiltinFlow(xuanhuanShortFlowDefinition, 'xuanhuan');
      loader.registerBuiltinFlow(defaultLongFlowDefinition, '');
    });

    test('按 genreId（英文 slug）可匹配，中文标签不再匹配', () {
      expect(loader.findFlowIdByGenre('xuanhuan'), isNotNull);
      expect(loader.findFlowIdByGenre('玄幻'), isNull,
          reason: '注册键已统一为 genreId，中文标签应查不到');
    });

    test('同题材默认返回长篇，可按 type 精确选择', () {
      expect(loader.findFlowIdByGenre('xuanhuan'), 'xuanhuan-long');
      expect(
        loader.findFlowIdByGenre('xuanhuan', type: GuidedFlowType.short),
        'xuanhuan-short',
      );
      expect(
        loader.findFlowIdByGenre('xuanhuan', type: GuidedFlowType.long),
        'xuanhuan-long',
      );
    });

    test('空题材返回 null（降级通用流程）', () {
      expect(loader.findFlowIdByGenre(''), isNull);
      expect(loader.findFlowIdByGenre('unknown'), isNull);
    });
  });
}
