import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/ai/sensenova_provider.dart';
import 'package:lingbi/shared/database/story_beats_repository.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/shared/file_system/sync_service.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/story_beat.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/services/export_service.dart';
import 'package:lingbi/services/project_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/services/version_history_service.dart';
import 'package:lingbi/shared/utils/paths.dart';

/// 灵笔全功能集成测试
///
/// 覆盖：便携项目 CRUD、文档管理、AI 真实调用（SenseNova）、
/// Canon 正典、StoryBeat 故事节拍、版本历史、导出、设置/配额、
/// 存储持久化、文件同步、降级模式。
///
/// AI 测试使用环境变量 SENSENOVA_API_KEY；无 key 时自动跳过。
void main() {
  final apiKey = Platform.environment['SENSENOVA_API_KEY'];
  final skipAi = apiKey == null || apiKey.isEmpty;

  late Directory tempDir;
  late FileService fileService;
  late StorageService storageService;
  late ZVecService zvecService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('lingbi_integration_');
    fileService = FileService();
    storageService = StorageService();
    await storageService.initialize(dbPath: '${tempDir.path}/db');
    zvecService = ZVecService(storageService: storageService);
    await zvecService.initialize();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ═══════════════════════════════════════════════════════
  // 1. 便携项目 CRUD
  // ═══════════════════════════════════════════════════════
  group('Project & Document CRUD', () {
    test('createPortableProject 创建 .lingbi/project.json', () async {
      final svc = ProjectService(zvecService: zvecService);
      final dir = '${tempDir.path}/my_novel';
      final project = await svc.createPortableProject(
        name: '测试小说',
        directoryPath: dir,
        description: '集成测试项目',
      );

      expect(project.name, '测试小说');
      expect(Directory(dir).existsSync(), isTrue);
      final metaFile = File('$dir/.lingbi/project.json');
      expect(metaFile.existsSync(), isTrue);
      final json = jsonDecode(metaFile.readAsStringSync());
      expect(json['name'], '测试小说');
    });

    test('openPortableProject 扫描磁盘 .md 文件', () async {
      final svc = ProjectService(zvecService: zvecService);
      final dir = '${tempDir.path}/open_test';
      await svc.createPortableProject(name: '打开测试', directoryPath: dir);

      // 手动写入 .md 文件
      File('$dir/第一章.md').writeAsStringSync('# 第一章\n\n内容...');
      File('$dir/第二章.md').writeAsStringSync('# 第二章\n\n内容...');
      File('$dir/.lingbi/notes.md').writeAsStringSync('应被跳过');

      final result = await svc.openPortableProject(dir);
      expect(result.project.name, '打开测试');
      expect(result.documents.length, 2);
      expect(result.documents.map((d) => d.title), containsAll(['第一章', '第二章']));
    });

    test('DocumentService CRUD 完整流程', () async {
      final docSvc =
          DocumentService(zvecService: zvecService, fileService: fileService);
      final dir = '${tempDir.path}/docs';
      Directory(dir).createSync(recursive: true);

      // Create
      final doc = await docSvc.createDocument(
        projectId: 'p1',
        title: '测试章节',
        directoryPath: dir,
        content: '# 测试\n\n这是内容',
      );
      expect(doc.title, '测试章节');
      expect(File(doc.filePath).existsSync(), isTrue);

      // Read
      final content = await docSvc.readContent(doc.filePath);
      expect(content, contains('这是内容'));

      // Rename
      await docSvc.renameDocument(doc, '重命名章节');
      expect(doc.title, '重命名章节');
      expect(File(doc.filePath).existsSync(), isTrue);

      // Delete
      await docSvc.deleteDocument(doc);
      expect(File(doc.filePath).existsSync(), isFalse);
    });

    test('FileService.scanMarkdownDocuments 跳过 .lingbi', () async {
      final dir = '${tempDir.path}/scan_test';
      Directory('$dir/.lingbi').createSync(recursive: true);
      File('$dir/a.md').writeAsStringSync('A');
      File('$dir/.lingbi/hidden.md').writeAsStringSync('hidden');

      final docs = await fileService.scanMarkdownDocuments(dir, 'proj1');
      expect(docs.length, 1);
      expect(docs.first.title, 'a');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 2. AI 功能（真实 SenseNova API）
  // ═══════════════════════════════════════════════════════
  group('AI Features', () {
    late SenseNovaProvider provider;

    setUp(() {
      provider = SenseNovaProvider(apiKey: apiKey);
    });

    tearDown(() async {
      await provider.dispose();
    });

    test('流式聊天返回非空内容', () async {
      final buffer = StringBuffer();
      await provider.chat(
        messages: [const ChatMessage(role: 'user', content: '用一句话介绍自己')],
        maxTokens: 200,
      ).forEach(buffer.write);
      final result = buffer.toString();
      // 应返回有效内容（非错误提示）
      expect(result.isNotEmpty, isTrue, reason: 'AI 流式响应为空，请检查 API Key 和网络');
    }, timeout: const Timeout(Duration(seconds: 60)), skip: skipAi);

    test('同步聊天返回有效响应', () async {
      final result = await provider.chatSync(
        messages: [const ChatMessage(role: 'user', content: '回答:1+1等于?')],
        maxTokens: 200,
      );
      expect(result.isNotEmpty, isTrue, reason: 'AI 同步响应为空，请检查 API Key 和网络');
      // 不应包含错误提示
      expect(result, isNot(contains('请求失败')), reason: 'AI 返回错误: $result');
    }, timeout: const Timeout(Duration(seconds: 60)), skip: skipAi);

    test('无 Key 时返回友好提示', () async {
      final noKeyProvider = SenseNovaProvider();
      final result = await noKeyProvider.chatSync(
        messages: [const ChatMessage(role: 'user', content: 'hello')],
      );
      expect(result, contains('配置'));
      await noKeyProvider.dispose();
    });

    test('embed 返回 128 维向量', () async {
      final vec = await provider.embed('测试文本');
      expect(vec.length, 128);
      expect(vec.every((v) => v >= 0 && v <= 1), isTrue);
    });
  }, skip: skipAi ? 'SENSENOVA_API_KEY 未设置' : false);

  // ═══════════════════════════════════════════════════════
  // 3. Canon 正典 & StoryBeat 故事节拍
  // ═══════════════════════════════════════════════════════
  group('Canon & StoryBeat', () {
    test('CanonService 创建/查询/删除', () async {
      final canonSvc = CanonService(zvecService: zvecService);
      final entry = CanonEntry(
        projectId: 'p1',
        type: CanonEntryType.character,
        name: '林黛玉',
        description: '红楼梦女主角',
        attributes: {'personality': '多愁善感'},
      );

      await canonSvc.create(entry);
      final list = await canonSvc.list('p1', CanonEntryType.character);
      expect(list.length, 1);
      expect(list.first.name, '林黛玉');

      // 搜索
      final found = await canonSvc.search('p1', '黛玉');
      expect(found.length, 1);

      // 删除
      await canonSvc.delete(entry);
      final afterDelete = await canonSvc.list('p1', CanonEntryType.character);
      expect(afterDelete, isEmpty);
    });

    test('StoryBeatsRepository 创建/排序/删除', () async {
      final repo = StoryBeatsRepository(storageService: storageService);
      final beat1 = StoryBeat(id: 'beat_1', projectId: 'p1', title: '开端');
      final beat2 =
          StoryBeat(id: 'beat_2', projectId: 'p1', title: '高潮', sequence: 1);

      await repo.saveBeat(beat1);
      await repo.saveBeat(beat2);

      var beats = await repo.getBeats('p1');
      expect(beats.length, 2);
      expect(beats.first.title, '开端');

      // 重排
      await repo.reorderBeats('p1', [beat2.id, beat1.id]);
      beats = await repo.getBeats('p1');
      expect(beats.first.title, '高潮');

      // 删除
      await repo.deleteBeat(beat1.id);
      beats = await repo.getBeats('p1');
      expect(beats.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 4. 版本历史
  // ═══════════════════════════════════════════════════════
  group('Version History', () {
    test('saveVersion → getVersions → restoreVersion', () async {
      final vhs = VersionHistoryService();
      final projectDir = '${tempDir.path}/versioned';
      Directory('$projectDir/.lingbi').createSync(recursive: true);

      await vhs.saveVersion(
        projectDir: projectDir,
        docId: 'doc1',
        content: '# 第一版\n\n初始内容',
        summary: '初始版本',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await vhs.saveVersion(
        projectDir: projectDir,
        docId: 'doc1',
        content: '# 第二版\n\n修改后内容',
      );

      final versions =
          await vhs.getVersions(projectDir: projectDir, docId: 'doc1');
      expect(versions.length, 2);
      expect(versions.first.wordCount, greaterThan(0));

      // 恢复最早版本
      final oldest = versions.last;
      final restored = await vhs.restoreVersion(
        projectDir: projectDir,
        docId: 'doc1',
        versionId: oldest.id,
      );
      expect(restored, contains('第一版'));
    });
  });

  // ═══════════════════════════════════════════════════════
  // 5. 导出
  // ═══════════════════════════════════════════════════════
  group('Export', () {
    test('exportAsMarkdown 写入文件', () async {
      final svc = ExportService();
      final path = '${tempDir.path}/export.md';
      await svc.exportAsMarkdown(content: '# Hello\n\nWorld', savePath: path);
      expect(File(path).readAsStringSync(), contains('# Hello'));
    });

    test('exportAsTxt 去除 Markdown 标记', () async {
      final svc = ExportService();
      final path = '${tempDir.path}/export.txt';
      await svc.exportAsTxt(
          content: '# Title\n\n**bold** text', savePath: path);
      final text = File(path).readAsStringSync();
      expect(text, isNot(contains('#')));
      expect(text, isNot(contains('**')));
      expect(text, contains('Title'));
    });

    test('exportProjectToDirectory 批量导出', () async {
      final svc = ExportService();
      final outDir = '${tempDir.path}/project_export';
      final project = Project(name: '导出项目', directoryPath: tempDir.path);
      final docs = [
        Document(projectId: project.id, title: '章节A', filePath: 'a.md'),
        Document(projectId: project.id, title: '章节B', filePath: 'b.md'),
      ];
      await svc.exportProjectToDirectory(
        project: project,
        documents: docs,
        contents: {docs[0].id: '# A', docs[1].id: '# B'},
        outputDir: outDir,
      );
      expect(Directory(outDir).existsSync(), isTrue);
      expect(Directory(outDir).listSync().length, 2);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 6. 配额 & 设置
  // ═══════════════════════════════════════════════════════
  group('Settings & Quota', () {
    test('QuotaService 限额控制', () {
      final quota = QuotaService();
      expect(quota.canUse, isTrue);
      expect(quota.remaining, 100);

      for (var i = 0; i < 100; i++) {
        expect(quota.tryConsume(), isTrue);
      }
      expect(quota.tryConsume(), isFalse);
      expect(quota.remaining, 0);

      quota.reset();
      expect(quota.canUse, isTrue);
    });

    test('resolveDefaultProjectRoot 返回正确路径', () {
      final root = resolveDefaultProjectRoot(userProfile: r'C:\Users\Test');
      expect(root, r'C:\Users\Test\Documents\灵笔');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 7. 存储 & 同步
  // ═══════════════════════════════════════════════════════
  group('Storage & Sync', () {
    test('StorageService CRUD 持久化到 JSON', () async {
      await storageService.upsert('test_col', 'id1', {'id': 'id1', 'val': 42});
      final item = await storageService.get('test_col', 'id1');
      expect(item?['val'], 42);

      await storageService.upsert('test_col', 'id1', {'id': 'id1', 'val': 99});
      final updated = await storageService.get('test_col', 'id1');
      expect(updated?['val'], 99);

      await storageService.delete('test_col', 'id1');
      final deleted = await storageService.get('test_col', 'id1');
      expect(deleted, isNull);

      // 验证 JSON 文件存在
      final jsonFile = File('${tempDir.path}/db/test_col.json');
      expect(jsonFile.existsSync(), isTrue);
    });

    test('SyncService.fullSync 发现新文件', () async {
      final syncSvc =
          SyncService(fileService: fileService, zvecService: zvecService);
      final projectDir = '${tempDir.path}/sync_proj';
      Directory(projectDir).createSync(recursive: true);
      File('$projectDir/new_chapter.md').writeAsStringSync('# 新章节');

      final project = Project(name: '同步项目', directoryPath: projectDir);
      await zvecService.upsert('projects', project.id, project.toJson());

      final added = await syncSvc.fullSync(project);
      expect(added.length, 1);
      expect(added.first.title, 'new_chapter');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 8. 降级模式
  // ═══════════════════════════════════════════════════════
  group('Degraded Mode', () {
    test('ServiceLocator.failed() 进入降级模式', () {
      final locator = ServiceLocator.failed(error: '测试降级');
      expect(locator.initSucceeded, isFalse);
      expect(locator.initError, '测试降级');
    });
  });
}
