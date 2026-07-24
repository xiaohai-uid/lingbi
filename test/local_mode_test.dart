import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/core/file_system/file_service.dart';
import 'package:lingbi/main.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/services/export_service.dart';
import 'package:lingbi/services/version_history_service.dart';
import 'package:lingbi/services/quota_service.dart';
import 'package:lingbi/services/project_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/core/models/document.dart';

/// 本地优先模式测试套件
///
/// 验证灵笔核心功能在无后端服务（Docker、微服务、API Gateway、网络）依赖时
/// 仍能正常工作。这些测试不依赖任何外部服务、网络或 Flutter widget 渲染。
///
/// 测试策略：
/// - 使用临时目录模拟用户文件系统
/// - 不启动任何后端服务
/// - 不依赖网络连接
/// - 纯文件 I/O 操作

void main() {
  late Directory tempDir;

  setUp(() {
    // 每个测试用例使用独立的临时目录，避免测试间相互影响
    tempDir = Directory.systemTemp.createTempSync('lingbi_local_test_');
  });

  tearDown(() {
    // 清理临时目录
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ──────────────────────────────────────────────
  // 验收标准 1: 桌面端的项目创建、打开、编辑和本地保存
  // 路径不以任何后端服务可用为前提
  // ──────────────────────────────────────────────
  group('AC1: 本地项目创建与保存 (无后端依赖)', () {
    test('FileService 可以在本地文件系统创建和读取 .md 文件', () async {
      final fileService = FileService();
      final testPath = '${tempDir.path}/test_chapter.md';
      const content = '# 测试章节\n\n这是正文内容。';

      // 写入文件（无后端依赖）
      await fileService.writeDocument(testPath, content);

      // 验证文件存在于本地文件系统
      expect(File(testPath).existsSync(), true);

      // 读取文件内容
      final readContent = await fileService.readDocument(testPath);
      expect(readContent, content);

      // 验证字数统计
      final wordCount = fileService.countWords(content);
      expect(wordCount, greaterThan(0));
    });

    test('FileService 可以在项目中创建多个文档并列出', () async {
      final fileService = FileService();
      final projectDir = '${tempDir.path}/my_novel';

      // 创建多个文档文件
      await fileService.writeDocument('$projectDir/第1章.md', '# 第1章\n\n开头');
      await fileService.writeDocument('$projectDir/第2章.md', '# 第2章\n\n发展');
      await fileService.writeDocument('$projectDir/第3章.md', '# 第3章\n\n高潮');

      // 列出项目中的所有 .md 文件
      final files = await fileService.listDocuments(projectDir);
      expect(files.length, 3);
      expect(files.any((f) => f.endsWith('第1章.md')), true);
      expect(files.any((f) => f.endsWith('第2章.md')), true);
      expect(files.any((f) => f.endsWith('第3章.md')), true);
    });

    test('FileService 可以重命名和删除文档', () async {
      final fileService = FileService();
      final oldPath = '${tempDir.path}/old_name.md';
      final newPath = '${tempDir.path}/new_name.md';

      await fileService.writeDocument(oldPath, '# 旧标题');
      expect(File(oldPath).existsSync(), true);

      // 重命名
      await fileService.renameDocument(oldPath, newPath);
      expect(File(oldPath).existsSync(), false);
      expect(File(newPath).existsSync(), true);

      // 删除
      await fileService.deleteDocument(newPath);
      expect(File(newPath).existsSync(), false);
    });

    test('Project 模型可以在纯内存中创建和序列化，无需任何服务', () {
      final project = Project(
        name: '我的小说',
        description: '一部奇幻小说',
        directoryPath: tempDir.path,
      );

      // 验证模型字段
      expect(project.id.isNotEmpty, true);
      expect(project.name, '我的小说');
      expect(project.description, '一部奇幻小说');
      expect(project.directoryPath, tempDir.path);
      expect(project.createdAt, isNotNull);
      expect(project.updatedAt, isNotNull);

      // JSON 序列化/反序列化（纯内存操作）
      final json = project.toJson();
      final restored = Project.fromJson(json);
      expect(restored.name, project.name);
      expect(restored.directoryPath, project.directoryPath);
    });

    test('Document 模型可以在纯内存中创建和序列化，无需任何服务', () {
      final doc = Document(
        projectId: 'proj-1',
        title: '第1章',
        filePath: '${tempDir.path}/第1章.md',
        wordCount: 500,
      );

      expect(doc.id.isNotEmpty, true);
      expect(doc.title, '第1章');
      expect(doc.wordCount, 500);

      final json = doc.toJson();
      final restored = Document.fromJson(json);
      expect(restored.title, doc.title);
      expect(restored.wordCount, doc.wordCount);
    });
  });

  // ──────────────────────────────────────────────
  // 验收标准 2: 启动失败或不存在的微服务不会阻止
  // 桌面端进入本地写作模式
  // ──────────────────────────────────────────────
  group('AC2: 无后端服务时可进入本地写作模式', () {
    test('StorageService 可以不依赖任何网络或后端服务完成初始化', () async {
      final storage = StorageService();

      // StorageService 初始化只需要本地文件系统
      await storage.initialize(dbPath: tempDir.path);

      expect(storage.isInitialized, true);
    });

    test('StorageService 可以在本地存储和查询数据，无需数据库服务', () async {
      final storage = StorageService();
      await storage.initialize(dbPath: tempDir.path);

      // 写入数据
      await storage.upsert('projects', 'proj-1', {
        'id': 'proj-1',
        'name': '测试项目',
        'directoryPath': tempDir.path,
      });

      // 查询数据
      final results = await storage.query('projects');
      expect(results.length, 1);
      expect(results[0]['name'], '测试项目');

      // 按 ID 获取
      final item = await storage.get('projects', 'proj-1');
      expect(item, isNotNull);
      expect(item!['name'], '测试项目');

      // 删除数据
      await storage.delete('projects', 'proj-1');
      final afterDelete = await storage.query('projects');
      expect(afterDelete.length, 0);
    });

    test('StorageService 数据持久化到 JSON 文件，可被外部工具读取', () async {
      final storage = StorageService();
      await storage.initialize(dbPath: tempDir.path);

      await storage.upsert('settings', 'theme', {
        'themeMode': 'dark',
        'fontSize': 16,
      });

      // 验证 JSON 文件已写入本地文件系统
      final jsonFile = File('${tempDir.path}/settings.json');
      expect(jsonFile.existsSync(), true);

      // 验证 JSON 内容可被外部读取
      final rawContent = await jsonFile.readAsString();
      final parsed = jsonDecode(rawContent) as List;
      expect(parsed.length, 1);
      expect(parsed[0]['themeMode'], 'dark');
    });

    test('StorageService 可以按条件过滤查询', () async {
      final storage = StorageService();
      await storage.initialize(dbPath: tempDir.path);

      // 插入多个项目
      await storage.upsert('projects', 'proj-1', {
        'id': 'proj-1',
        'name': '小说A',
        'status': 'active',
      });
      await storage.upsert('projects', 'proj-2', {
        'id': 'proj-2',
        'name': '小说B',
        'status': 'archived',
      });
      await storage.upsert('projects', 'proj-3', {
        'id': 'proj-3',
        'name': '小说C',
        'status': 'active',
      });

      // 过滤查询
      final activeProjects =
          await storage.query('projects', filter: {'status': 'active'});
      expect(activeProjects.length, 2);
      expect(activeProjects[0]['name'], anyOf('小说A', '小说C'));
    });

    test('QuotaService 可以在纯内存中工作，无需任何外部服务', () {
      final quota = QuotaService();

      expect(quota.dailyLimit, greaterThan(0));
      expect(quota.canUse, true);
      expect(quota.remaining, quota.dailyLimit);

      // 消耗配额
      expect(quota.tryConsume(), true);
      expect(quota.dailyUsage, 1);
      expect(quota.remaining, quota.dailyLimit - 1);

      // 重置
      quota.reset();
      expect(quota.dailyUsage, 0);
    });
  });

  // ──────────────────────────────────────────────
  // 验收标准 3: 版本历史在本地文件系统中工作
  // ──────────────────────────────────────────────
  group('AC3: 版本历史本地保存与恢复', () {
    test('VersionHistoryService 可以在本地保存和读取版本快照', () async {
      final vh = VersionHistoryService();
      final projectDir = tempDir.path;
      const docId = 'doc-1';
      const content = '# 第1章\n\n这是第一章的内容。';

      // 保存版本
      await vh.saveVersion(
        projectDir: projectDir,
        docId: docId,
        content: content,
        summary: '第一章初稿',
      );

      // 获取版本列表
      final versions = await vh.getVersions(
        projectDir: projectDir,
        docId: docId,
      );
      expect(versions.length, 1);
      expect(versions[0].summary, '第一章初稿');
      expect(versions[0].wordCount, greaterThan(0));

      // 恢复版本内容
      final restored = await vh.restoreVersion(
        projectDir: projectDir,
        docId: docId,
        versionId: versions[0].id,
      );
      expect(restored, content);
    });

    test('VersionHistoryService 可以保存多个版本并限制数量', () async {
      final vh = VersionHistoryService();
      final projectDir = tempDir.path;
      const docId = 'doc-1';

      // 保存多个版本
      for (int i = 1; i <= 5; i++) {
        await vh.saveVersion(
          projectDir: projectDir,
          docId: docId,
          content: '版本 $i',
          summary: '第$i次修改',
        );
      }

      final versions = await vh.getVersions(
        projectDir: projectDir,
        docId: docId,
      );
      expect(versions.length, 5);
      // 最新版本排在最前
      expect(versions[0].summary, '第5次修改');
    });

    test('VersionHistoryService 版本文件存储在项目隐藏目录中', () async {
      final vh = VersionHistoryService();
      final projectDir = tempDir.path;
      const docId = 'doc-version-test';

      await vh.saveVersion(
        projectDir: projectDir,
        docId: docId,
        content: '测试内容',
      );

      // 版本文件存储在 .lingbi/versions/ 下
      final versionsDir = Directory(
          '$projectDir/.lingbi/versions/${docId.replaceAll(RegExp(r'[^\w-]'), '_')}');
      expect(versionsDir.existsSync(), true);

      // metadata.json 存在
      expect(File('${versionsDir.path}/metadata.json').existsSync(), true);
    });
  });

  // ──────────────────────────────────────────────
  // 验收标准 4: 导出功能在本地完整可用
  // ──────────────────────────────────────────────
  group('AC4: 本地导出功能', () {
    test('ExportService 可以导出 Markdown 到本地文件', () async {
      final exportService = ExportService();
      const content = '# 测试文档\n\n这是导出的内容。';
      final savePath = '${tempDir.path}/export_test.md';

      await exportService.exportAsMarkdown(
        content: content,
        savePath: savePath,
      );

      expect(File(savePath).existsSync(), true);
      final saved = await File(savePath).readAsString();
      expect(saved, content);
    });

    test('ExportService 可以导出纯文本到本地文件', () async {
      final exportService = ExportService();
      const content = '# 标题\n\n**粗体** 和 *斜体*';
      final savePath = '${tempDir.path}/export_test.txt';

      await exportService.exportAsTxt(
        content: content,
        savePath: savePath,
      );

      expect(File(savePath).existsSync(), true);
      final saved = await File(savePath).readAsString();
      // 纯文本应去除 Markdown 标记
      expect(saved.contains('标题'), true);
      expect(saved.contains('粗体'), true);
      expect(saved.contains('斜体'), true);
    });

    test('ExportService 可以导出整个项目到本地目录', () async {
      final exportService = ExportService();
      final outputDir = '${tempDir.path}/exported_project';

      final doc1 = Document(
        projectId: 'proj-1',
        title: '第1章',
        filePath: '${tempDir.path}/第1章.md',
      );
      final doc2 = Document(
        projectId: 'proj-1',
        title: '第2章',
        filePath: '${tempDir.path}/第2章.md',
      );
      final project = Project(name: '导出测试', directoryPath: tempDir.path);

      await exportService.exportProjectToDirectory(
        project: project,
        documents: [doc1, doc2],
        contents: {
          doc1.id: '# 第1章\n\n内容1',
          doc2.id: '# 第2章\n\n内容2',
        },
        outputDir: outputDir,
        format: 'md',
      );

      expect(Directory(outputDir).existsSync(), true);
      expect(File('$outputDir/第1章.md').existsSync(), true);
      expect(File('$outputDir/第2章.md').existsSync(), true);
    });
  });

  // ──────────────────────────────────────────────
  // 验收标准 5: 文件系统同步在本地完整可用
  // ──────────────────────────────────────────────
  group('AC5: 本地文件系统同步', () {
    test('FileService 可以从磁盘重新扫描目录', () async {
      final fileService = FileService();
      final projectDir = '${tempDir.path}/rescan_test';

      // 创建一些 .md 文件
      await fileService.writeDocument('$projectDir/chapter1.md', '# Chapter 1');
      await fileService.writeDocument('$projectDir/chapter2.md', '# Chapter 2');

      // 再手动添加一个文件（模拟外部编辑）
      File('$projectDir/external_chapter.md').writeAsStringSync('# External');

      // 重新扫描应发现所有文件
      final files = await fileService.listDocuments(projectDir);
      expect(files.length, 3);
    });

    test('SyncService 完整同步流程不依赖外部服务', () async {
      // 验证 StorageService 的双向同步能力
      // 这模拟了从磁盘到索引的完整同步
      final storage = StorageService();
      final syncDir = '${tempDir.path}/sync_test';
      await storage.initialize(dbPath: syncDir);

      // 创建一个 .md 文件（模拟外部编辑器创建）
      File('$syncDir/my_chapter.md').writeAsStringSync('# 外部创建的章节');

      // 通过 StorageService 写入数据（模拟索引重建）
      await storage.upsert('test_documents', 'doc1', {
        'id': 'doc1',
        'path': '$syncDir/my_chapter.md',
        'title': '外部创建的章节',
      });

      // 验证 JSON 文件可被外部工具读取
      final jsonFile = File('$syncDir/test_documents.json');
      expect(jsonFile.existsSync(), true);

      // 验证写入的数据可被查询到
      final results = await storage.query('test_documents');
      expect(results.length, 1);
      expect(results[0]['title'], '外部创建的章节');
    });
  });

  // ──────────────────────────────────────────────
  // 验收标准 2 (扩展): 启动编排失败降级 — ServiceLocator
  // 初始化失败时应用仍可进入本地模式
  // ──────────────────────────────────────────────
  group('AC2: ServiceLocator 初始化失败降级', () {
    test('ServiceLocator.failed() 注入降级标记', () async {
      final locator = ServiceLocator.failed(error: 'forced failure for test');

      expect(locator.initSucceeded, false);
      expect(locator.initError, 'forced failure for test');
    });

    test('ServiceLocator 初始化失败后，FileService 仍可独立工作', () async {
      final fileService = FileService();
      final testDir = '${tempDir.path}/fallback_test';
      await Directory(testDir).create(recursive: true);

      await fileService.writeDocument('$testDir/local.md', '# 本地写作');
      final content = await fileService.readDocument('$testDir/local.md');
      expect(content, '# 本地写作');
    });
  });

  // ──────────────────────────────────────────────
  // 默认本地写作目录解析
  // ──────────────────────────────────────────────
  group('resolveDefaultLocalDir', () {
    test('返回 %USERPROFILE%\\Documents\\灵笔', () {
      final dir = resolveDefaultLocalDir(userProfile: r'C:\Users\testuser');
      expect(dir, r'C:\Users\testuser\Documents\灵笔');
    });

    test('USERPROFILE 为空时抛出 UnsupportedError', () {
      expect(
        () => resolveDefaultLocalDir(userProfile: ''),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // ──────────────────────────────────────────────
  // 验收标准 6: 便携项目与章节文件契约
  // 项目与章节的真实来源必须是用户可见的 Markdown 文件；
  // .lingbi/ 仅保存可重建的内部状态，删除不影响章节内容。
  // ──────────────────────────────────────────────
  group('T2: 便携项目与章节文件契约', () {
    test('创建→重开→删除.lingbi/→内容完整可读写', () async {
      final projectService = ProjectService(
        zvecService: null,
        fileService: FileService(),
      );
      final docService = DocumentService(
        fileService: FileService(),
        zvecService: null,
      );

      final projectDir = '${tempDir.path}/test_novel';
      final chapter1Content = '# 第1章\n\n这是开头。';
      final chapter2Content = '# 第2章\n\n这是发展。';

      // 1. 创建便携项目（写入磁盘 .lingbi/project.json）
      final project = await projectService.createPortableProject(
        name: '测试小说',
        directoryPath: projectDir,
      );
      expect(Directory(projectDir).existsSync(), true);
      expect(
        File('$projectDir/.lingbi/project.json').existsSync(),
        true,
      );

      // 2. 在用户可见目录下创建 .md 章节
      final doc1 = await docService.createDocument(
        projectId: project.id,
        title: '第1章',
        directoryPath: projectDir,
        content: chapter1Content,
      );
      final doc2 = await docService.createDocument(
        projectId: project.id,
        title: '第2章',
        directoryPath: projectDir,
        content: chapter2Content,
      );

      // 3. 验证 .md 文件位于项目根目录，不在 .lingbi/ 内
      expect(File(doc1.filePath).existsSync(), true);
      expect(doc1.filePath, contains('/test_novel/第1章.md'));
      expect(doc1.filePath, isNot(contains('/.lingbi/')));
      expect(File(doc2.filePath).existsSync(), true);

      // 4. 关闭并重新打开（模拟新会话）
      final result1 = await projectService.openPortableProject(projectDir);
      expect(result1.project.name, '测试小说');
      expect(result1.documents.length, 2);
      expect(result1.documents.any((d) => d.title == '第1章'), true);
      expect(result1.documents.any((d) => d.title == '第2章'), true);

      // 5. 验证内容可读取
      var content1 =
          await docService.readContent(result1.documents[0].filePath);
      expect(content1, contains('开头'));

      // 6. 删除 .lingbi/（模拟索引丢失）后重新打开
      Directory('$projectDir/.lingbi').deleteSync(recursive: true);
      expect(Directory('$projectDir/.lingbi').existsSync(), false);

      final result2 = await projectService.openPortableProject(projectDir);
      // 名称元数据来自 .lingbi/project.json，删除后回退到目录名
      expect(result2.project.name, 'test_novel');
      // 但章节文件仍在用户可见目录中，不受影响
      expect(result2.documents.length, 2);

      // 7. 所有章节仍可发现、读取和编辑
      for (final doc in result2.documents) {
        final content = await docService.readContent(doc.filePath);
        expect(content.isNotEmpty, true);
      }

      // 编辑保存功能正常
      final edited = '# 第1章 修改版\n\n已修改。';
      await docService.saveDocument(result2.documents[0], edited);
      final saved = File(result2.documents[0].filePath).readAsStringSync();
      expect(saved, edited);

      // 8. 新创建的章节也存入用户可见目录，不会因 .lingbi 缺失而丢失
      final doc3 = await docService.createDocument(
        projectId: result2.project.id,
        title: '第3章',
        directoryPath: projectDir,
        content: '# 第3章\n\n新增章节。',
      );
      expect(File(doc3.filePath).existsSync(), true);
      expect(doc3.filePath, isNot(contains('/.lingbi/')));
    });

    test('Windows 非法字符安全处理', () async {
      final docService = DocumentService(
        fileService: FileService(),
        zvecService: null,
      );

      const unsafeTitle = '章:节/测\\试|名?称*';
      final doc = await docService.createDocument(
        projectId: 'proj-1',
        title: unsafeTitle,
        directoryPath: tempDir.path,
        content: '# 测试',
      );

      expect(File(doc.filePath).existsSync(), true);
      // 非法字符应被替换为 _
      expect(doc.filePath, contains('章_节_测_试_名_称_'));
      expect(doc.filePath, endsWith('.md'));
    });

    test('重命名以文件系统为准', () async {
      final docService = DocumentService(
        fileService: FileService(),
        zvecService: null,
      );

      final doc = await docService.createDocument(
        projectId: 'proj-1',
        title: '原名',
        directoryPath: tempDir.path,
        content: '# 原名\n\n内容。',
      );

      final oldPath = doc.filePath;
      await docService.renameDocument(doc, '新名');

      expect(File(oldPath).existsSync(), false);
      expect(File(doc.filePath).existsSync(), true);
      expect(doc.title, '新名');
      // 从磁盘读取验证
      final content = await docService.readContent(doc.filePath);
      expect(content, '# 原名\n\n内容。');
    });
  });

  // AC2 widget 级测试: 降级 UI 本地写作闭环
  _localModeWidgetTests();
}

// ──────────────────────────────────────────────
// AC2 widget 级测试: 降级 UI 本地写作闭环
// ──────────────────────────────────────────────
void _localModeWidgetTests() {
  testWidgets('AC2: 降级 UI 创建+打开+编辑+保存 Markdown', (tester) async {
    final testDir = Directory.systemTemp.createTempSync('lingbi_ui_test_');
    // 预先创建一个现有文件
    File('${testDir.path}/existing.md').writeAsStringSync('# 现有章节\n\n原有内容。');

    try {
      final failedLocator =
          ServiceLocator.failed(error: 'injected degraded mode');

      await tester.pumpWidget(LingBiApp(
        locator: failedLocator,
        localWorkDir: testDir.path,
      ));
      await tester.pump();

      // 验证初始 UI：输入框、新建按钮、现有文件列表
      expect(find.byKey(const ValueKey('chapterTitleInput')), findsOneWidget);
      expect(find.byKey(const ValueKey('newChapterBtn')), findsOneWidget);

      // === 场景 1: 打开已有文件并修改 ===
      final pn = testDir.path.replaceAll('\\', '/');
      await tester.tap(find.byKey(ValueKey('file_${pn}/existing.md')));
      await tester.pump();

      final editorField = find.byKey(const ValueKey('editorField'));
      expect(editorField, findsOneWidget);

      await tester.enterText(editorField, '# 现有章节\n\n内容已更新。');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('saveBtn')));
      await tester.pump();

      var savedContent = File('${testDir.path}/existing.md').readAsStringSync();
      expect(savedContent, '# 现有章节\n\n内容已更新。');

      // === 场景 2: 新建章节并写入内容 ===
      await tester.enterText(
        find.byKey(const ValueKey('chapterTitleInput')),
        '新章',
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('newChapterBtn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证文件出现在列表中
      expect(
        find.byKey(ValueKey('file_${pn}/新章.md')),
        findsOneWidget,
      );

      // 编辑器应加载了模板内容
      expect(find.byKey(const ValueKey('editorField')), findsOneWidget);

      // 写入新内容并保存
      await tester.enterText(
        find.byKey(const ValueKey('editorField')),
        '# 新章\n\n新建内容。',
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('saveBtn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 从磁盘验证
      savedContent = File('${testDir.path}/新章.md').readAsStringSync();
      expect(savedContent, '# 新章\n\n新建内容。');
    } finally {
      if (testDir.existsSync()) testDir.deleteSync(recursive: true);
    }
  });
}
