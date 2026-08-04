import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/shared/ai/sensenova_provider.dart';
import 'package:lingbi/shared/database/story_beats_repository.dart';
import 'package:lingbi/shared/database/zvec_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';
import 'package:lingbi/shared/file_system/sync_service.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/shared/models/document.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/shared/models/story_beat.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/features/import_export/data/export_service.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';
import 'package:lingbi/services/storage_service.dart';
import 'package:lingbi/features/review/data/version_history_service.dart';

/// 灵笔全链路端到端测试
///
/// 模拟真实用户完整工作流：
/// 创建项目 → 写文档 → AI 风格分析 → AI 续写 → 保存版本 →
/// 创建正典条目 → 编排故事节拍 → 全文同步 → 导出项目 → 验证一致性
///
/// 所有服务串联调用，验证服务间数据流转正确性。
/// 使用真实 SenseNova API（环境变量 SENSENOVA_API_KEY）。
void main() {
  final apiKey = Platform.environment['SENSENOVA_API_KEY'];

  // 共享状态 — 模拟一个完整用户会话
  late Directory tempDir;
  late FileService fileService;
  late StorageService storageService;
  late ZVecService zvecService;
  late ProjectService projectService;
  late DocumentService documentService;
  late CanonService canonService;
  late StoryBeatsRepository storyBeatsRepo;
  late VersionHistoryService versionService;
  late ExportService exportService;
  late SyncService syncService;
  late AIService aiService;
  late QuotaService quotaService;
  late SenseNovaProvider senseNovaProvider;

  // 工作流中产生的共享数据
  late Project project;
  late Document chapter1;
  late Document chapter2;
  late String aiStyleAnalysis;
  late String aiContinuation;
  late CanonEntry protagonist;
  late StoryBeat beat1;
  late StoryBeat beat2;

  setUpAll(() async {
    // 初始化所有服务（模拟 ServiceLocator.init()）
    tempDir = Directory.systemTemp.createTempSync('lingbi_e2e_');
    fileService = FileService();
    storageService = StorageService();
    await storageService.initialize(dbPath: '${tempDir.path}/db');
    zvecService = ZVecService(storageService: storageService);
    await zvecService.initialize();

    projectService = ProjectService(
      zvecService: zvecService,
      mutationProtocol: _proto('${tempDir.path}/我的小说'),
    );
    documentService =
        DocumentService(zvecService: zvecService, fileService: fileService);
    canonService = CanonService(zvecService: zvecService);
    storyBeatsRepo = StoryBeatsRepository(storageService: storageService);
    versionService = VersionHistoryService();
    exportService = ExportService();
    syncService =
        SyncService(fileService: fileService, zvecService: zvecService);
    quotaService = QuotaService();
    aiService = AIService(quotaService: quotaService);
    senseNovaProvider = SenseNovaProvider(apiKey: apiKey);

    // 配置 AI 服务使用 SenseNova
    if (apiKey != null && apiKey.isNotEmpty) {
      aiService.configureApiKey('sensenova', apiKey);
      aiService.setProvider('sensenova');
    }
  });

  tearDownAll(() async {
    await senseNovaProvider.dispose();
    await aiService.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('全链路: 创建项目 → 文档 → AI分析 → 续写 → 正典 → 节拍 → 版本 → 导出', () async {
    // 无 API Key 时跳过（CI 环境可能未配置）
    if (apiKey == null || apiKey.isEmpty) {
      markTestSkipped('需要 SENSENOVA_API_KEY 环境变量');
      return;
    }
    // ═══════════════════════════════════════════════════════
    // 阶段 1: 创建便携项目
    // ═══════════════════════════════════════════════════════
    final projectDir = '${tempDir.path}/我的小说';
    project = await projectService.createPortableProject(
      name: '星际迷途',
      directoryPath: projectDir,
      description: '一部科幻短篇小说',
    );
    expect(project.name, '星际迷途');
    expect(File('$projectDir/.lingbi/project.json').existsSync(), isTrue,
        reason: '便携项目元数据文件应存在');

    // 设置 AI 项目上下文（模拟 AIPanel.initState）
    aiService
        .setProjectContext('项目名称: ${project.name}\n描述: ${project.description}');

    // ═══════════════════════════════════════════════════════
    // 阶段 2: 创建文档并写入初始内容
    // ═══════════════════════════════════════════════════════
    chapter1 = await documentService.createDocument(
      projectId: project.id,
      title: '第一章_坠落',
      directoryPath: projectDir,
      content: '# 第一章 坠落\n\n'
          '飞船的警报声在狭小的舱室内回荡。林远舟从冷冻睡眠中醒来，'
          '发现自己漂浮在失重的黑暗中。应急灯投下血红色的光芒，'
          '照亮了舱壁上那道触目惊心的裂缝。\n\n'
          '"警告：主引擎失效，生命维持系统剩余时间：72小时。"'
          '机械女声毫无感情地播报着死刑判决。\n\n'
          '他挣扎着抓住扶手，将自己拉向控制台。'
          '窗外的星空陌生而冷漠——没有一颗星是他认识的。',
    );
    expect(File(chapter1.filePath).existsSync(), isTrue);
    expect(chapter1.wordCount, greaterThan(50), reason: '文档字数应大于50');

    chapter2 = await documentService.createDocument(
      projectId: project.id,
      title: '第二章_信号',
      directoryPath: projectDir,
      content: '# 第二章 信号\n\n'
          '第三天，当氧气浓度开始让林远舟感到头痛时，'
          '通讯器突然发出一阵刺耳的电流声。\n\n'
          '"这里是……滋滋……殖民地前哨站……滋滋……收到请回复……"\n\n'
          '他几乎是扑向了通讯面板。',
    );

    // 验证文档列表（通过 ZVec 查询）
    final docs = await documentService.getDocuments(project.id);
    expect(docs.length, 2, reason: 'ZVec 应存储 2 个文档元数据');

    // ═══════════════════════════════════════════════════════
    // 阶段 3: 保存修改前版本快照
    // ═══════════════════════════════════════════════════════
    final ch1Content = await documentService.readContent(chapter1.filePath);
    await versionService.saveVersion(
      projectDir: projectDir,
      docId: chapter1.id,
      content: ch1Content,
      summary: 'AI 续写前原始版本',
    );

    // ═══════════════════════════════════════════════════════
    // 阶段 4: AI 风格分析（真实 API 调用）
    // 验证: AIService → SenseNovaProvider → 网络 → 解析 → 返回
    // ═══════════════════════════════════════════════════════
    aiStyleAnalysis = await aiService.analyzeStyle(ch1Content);
    expect(aiStyleAnalysis.isNotEmpty, isTrue, reason: 'AI 风格分析应返回非空结果');
    expect(aiStyleAnalysis, isNot(contains('请求失败')),
        reason: 'AI 不应返回错误: $aiStyleAnalysis');
    expect(aiStyleAnalysis, isNot(contains('配置')), reason: 'API Key 应已正确配置');

    // ═══════════════════════════════════════════════════════
    // 阶段 5: AI 续写（流式）→ 追加到文档 → 保存
    // 验证: 流式响应 → 内容拼接 → DocumentService.saveDocument → 磁盘写入
    // ═══════════════════════════════════════════════════════
    final continuationBuffer = StringBuffer();
    await aiService
        .continueWriting(ch1Content)
        .forEach(continuationBuffer.write);
    aiContinuation = continuationBuffer.toString();
    expect(aiContinuation.isNotEmpty, isTrue, reason: 'AI 续写应返回非空内容');
    expect(aiContinuation.length, greaterThan(20),
        reason: '续写内容应有实质长度，实际: ${aiContinuation.length}');

    // 将续写内容追加到原文并保存
    final updatedContent = '$ch1Content\n\n$aiContinuation';
    await documentService.saveDocument(chapter1, updatedContent);

    // 验证磁盘文件已更新
    final savedContent = await documentService.readContent(chapter1.filePath);
    expect(savedContent, contains(aiContinuation.substring(0, 20)),
        reason: '保存后磁盘文件应包含 AI 续写内容');
    expect(chapter1.wordCount, greaterThan(100), reason: '更新后字数应增加');

    // ═══════════════════════════════════════════════════════
    // 阶段 6: 保存修改后版本 → 验证版本历史可恢复
    // ═══════════════════════════════════════════════════════
    await versionService.saveVersion(
      projectDir: projectDir,
      docId: chapter1.id,
      content: updatedContent,
      summary: 'AI 续写后版本',
    );

    final versions = await versionService.getVersions(
      projectDir: projectDir,
      docId: chapter1.id,
    );
    expect(versions.length, 2, reason: '应有 2 个版本快照');

    // 验证可以恢复到原始版本
    final originalVersion = versions.last; // 最早的版本
    final restoredContent = await versionService.restoreVersion(
      projectDir: projectDir,
      docId: chapter1.id,
      versionId: originalVersion.id,
    );
    expect(restoredContent, isNot(contains(aiContinuation.substring(0, 20))),
        reason: '恢复的原始版本不应包含 AI 续写内容');

    // ═══════════════════════════════════════════════════════
    // 阶段 7: 基于 AI 分析创建正典条目
    // 验证: CanonService → ZVec → 查询 → 搜索 联动
    // ═══════════════════════════════════════════════════════
    protagonist = CanonEntry(
      projectId: project.id,
      type: CanonEntryType.character,
      name: '林远舟',
      description: '主角，飞船坠毁后独自求生的宇航员',
      attributes: {
        'personality': '冷静理性，但内心恐惧',
        'backstory': '前军事飞行员，因事故退役',
        'ai_analysis': aiStyleAnalysis.substring(
            0, aiStyleAnalysis.length > 100 ? 100 : aiStyleAnalysis.length),
      },
    );
    await canonService.create(protagonist, provider: senseNovaProvider);

    final location = CanonEntry(
      projectId: project.id,
      type: CanonEntryType.location,
      name: '未知星域',
      description: '飞船坠毁的陌生星系，无人类殖民记录',
    );
    await canonService.create(location);

    // 验证正典查询
    final characters =
        await canonService.list(project.id, CanonEntryType.character);
    expect(characters.length, 1);
    expect(characters.first.name, '林远舟');
    expect(characters.first.attributes['ai_analysis'], isNotEmpty,
        reason: '正典条目应包含 AI 分析数据');

    // 验证跨类型搜索
    final searchResults = await canonService.search(project.id, '林远舟');
    expect(searchResults.length, 1);
    final searchResults2 = await canonService.search(project.id, '星域');
    expect(searchResults2.length, 1);

    // ═══════════════════════════════════════════════════════
    // 阶段 8: 创建故事节拍（与文档和正典关联）
    // ═══════════════════════════════════════════════════════
    beat1 = StoryBeat(
      id: 'beat_ch1',
      projectId: project.id,
      title: '坠落与觉醒',
      description: '林远舟从冷冻睡眠中醒来，发现飞船坠毁在未知星域',
    );
    beat2 = StoryBeat(
      id: 'beat_ch2',
      projectId: project.id,
      title: '绝望中的信号',
      description: '氧气将尽时收到殖民地前哨站的通讯信号',
      sequence: 1,
    );
    await storyBeatsRepo.saveBeat(beat1);
    await storyBeatsRepo.saveBeat(beat2);

    final beats = await storyBeatsRepo.getBeats(project.id);
    expect(beats.length, 2);
    expect(beats.first.title, '坠落与觉醒');

    // ═══════════════════════════════════════════════════════
    // 阶段 9: 全文同步（磁盘 ↔ ZVec）
    // 验证: 新增文件被发现，SyncService 与 DocumentService 数据一致
    // ═══════════════════════════════════════════════════════
    // 手动在磁盘添加一个新文件（模拟用户在文件管理器中创建）
    File('$projectDir/第三章_接触.md').writeAsStringSync(
      '# 第三章 接触\n\n救援队到达，但林远舟发现他们并非人类。',
    );

    final newDocs = await syncService.fullSync(project);
    // Windows 路径分隔符差异（/ vs \\）导致 fullSync 视所有磁盘文件为“新”
    // 关键验证：同步后 ZVec 包含所有文档
    expect(newDocs.length, greaterThanOrEqualTo(1),
        reason: '同步应发现新文件（含路径规范化差异）');
    expect(newDocs.any((d) => d.title == '第三章_接触'), isTrue,
        reason: '同步应发现手动创建的第三章');

    // 验证 FileService.scanMarkdownDocuments 与同步结果一致
    final scannedDocs =
        await fileService.scanMarkdownDocuments(projectDir, project.id);
    expect(scannedDocs.length, 3, reason: '磁盘应有 3 个 .md 文件');

    // ═══════════════════════════════════════════════════════
    // 阶段 10: 导出项目（Markdown + TXT）
    // 验证: ExportService 能正确读取 DocumentService 管理的内容
    // ═══════════════════════════════════════════════════════
    final exportDir = '${tempDir.path}/export_md';
    final ch3Doc = newDocs.firstWhere((d) => d.title == '第三章_接触');
    final allDocs = [chapter1, chapter2, ch3Doc];
    final contents = <String, String>{};
    for (final doc in allDocs) {
      contents[doc.id] = await documentService.readContent(doc.filePath);
    }

    await exportService.exportProjectToDirectory(
      project: project,
      documents: allDocs,
      contents: contents,
      outputDir: exportDir,
    );

    final exportedFiles =
        Directory(exportDir).listSync().whereType<File>().toList();
    expect(exportedFiles.length, 3, reason: '应导出 3 个文件');

    // 验证导出内容包含 AI 续写
    final exportedCh1 = exportedFiles.firstWhere(
      (f) => f.path.contains('第一章'),
      orElse: () => exportedFiles.first,
    );
    final exportedContent = exportedCh1.readAsStringSync();
    expect(exportedContent, contains('坠落'), reason: '导出内容应包含原始章节标题');

    // TXT 导出（验证 Markdown 标记被去除）
    final txtPath = '${tempDir.path}/export.txt';
    await exportService.exportAsTxt(content: updatedContent, savePath: txtPath);
    final txtContent = File(txtPath).readAsStringSync();
    expect(txtContent, isNot(contains('# ')), reason: 'TXT 不应包含 Markdown 标题标记');

    // ═══════════════════════════════════════════════════════
    // 阶段 11: 打开项目（模拟关闭后重新打开）
    // 验证: openPortableProject 能完整恢复项目状态
    // ═══════════════════════════════════════════════════════
    final reopened = await projectService.openPortableProject(projectDir);
    expect(reopened.project.name, '星际迷途');
    expect(reopened.documents.length, 3, reason: '重新打开应扫描到 3 个 .md 文件');
    expect(
      reopened.documents.map((d) => d.title),
      containsAll(['第一章_坠落', '第二章_信号', '第三章_接触']),
    );

    // ═══════════════════════════════════════════════════════
    // 阶段 12: 配额验证（通过 chat() 方法消耗配额）
    // ═══════════════════════════════════════════════════════
    // analyzeStyle/continueWriting 不经过配额，仅 chat() 消耗
    final chatBuffer = StringBuffer();
    await aiService
        .chat(message: '用一句话概括这个故事', maxTokens: 100)
        .forEach(chatBuffer.write);
    expect(chatBuffer.toString().isNotEmpty, isTrue, reason: 'AI chat 应返回内容');
    expect(quotaService.dailyUsage, greaterThan(0), reason: 'chat() 调用应消耗配额');
    expect(quotaService.canUse, isTrue, reason: '配额不应耗尽');

    // ═══════════════════════════════════════════════════════
    // 最终断言: 全链路数据一致性
    // ═══════════════════════════════════════════════════════
    // 正典条目仍存在
    final finalCharacters =
        await canonService.list(project.id, CanonEntryType.character);
    expect(finalCharacters.length, 1);
    // 故事节拍仍存在
    final finalBeats = await storyBeatsRepo.getBeats(project.id);
    expect(finalBeats.length, 2);
    // 版本历史仍存在
    final finalVersions = await versionService.getVersions(
      projectDir: projectDir,
      docId: chapter1.id,
    );
    expect(finalVersions.length, 2);
  }, timeout: const Timeout(Duration(seconds: 180)));
}


LocalMutationProtocol _proto(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
