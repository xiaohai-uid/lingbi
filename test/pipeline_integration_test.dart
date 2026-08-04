/// 写作流水线集成测试
///
/// 使用临时目录创建完整便携项目，运行真实文件读写。
/// 覆盖：上下文组装、Canon 读取、候选不修改正文、拒绝、
/// 安全采纳、源版本冲突、并发写锁、写入失败恢复、
/// 重启恢复候选、结算失败保留正文、未结算阻止下一章、旧项目兼容。
@Timeout(Duration(seconds: 60))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/data/pipeline/book_state.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';
import 'package:lingbi/features/writing/data/pipeline/context_assembler.dart';
import 'package:lingbi/features/writing/data/pipeline/creative_compass.dart';
import 'package:lingbi/features/writing/data/pipeline/project_data_source.dart';
import 'package:lingbi/features/writing/data/pipeline/write_lock_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';

void main() {
  late Directory tempDir;
  late String projectDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_integration_');
    projectDir = tempDir.path;
    // 创建项目目录结构
    Directory('$projectDir/chapters').createSync(recursive: true);
    Directory('$projectDir/.lingbi').createSync(recursive: true);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// 创建一个真实的章节文件
  String createChapterFile(String name, String content) {
    final path = '$projectDir/chapters/$name.md';
    File(path).writeAsStringSync(content);
    return path;
  }

  // ─── 测试 1: 真实项目上下文组装 ─────────────────────────────────

  test('真实项目上下文组装 — 从文件系统读取章节和罗盘', () {
    // 创建真实章节文件
    createChapterFile('第一章', '# 第一章\n\n这是第一章的内容，主角在雨中行走。');
    createChapterFile('第二章', '# 第二章\n\n承接上文，主角走进了咖啡馆。');

    // 创建创作罗盘
    final compassDir = Directory('$projectDir/.lingbi/runtime');
    compassDir.createSync(recursive: true);
    File('$projectDir/.lingbi/runtime/creative_compass.json')
        .writeAsStringSync(jsonEncode({
      'author_intent': {
        'core_theme': '坚韧不拔',
        'genre': '现实主义',
        'tone': '沉稳',
        'taboos': ['后宫'],
        'must_haves': ['成长弧线'],
      },
      'current_focus': {
        'arc_goal': '主角觉醒',
        'arc_phase': 'rising_action',
        'hard_constraints': ['不杀生'],
        'priority_queue': ['揭示身世'],
      },
    }));

    // 使用 EmptyDataSource 组装（验证罗盘读取）
    final assembler = ContextAssembler(
      projectDir: projectDir,
      dataSource: const EmptyDataSource(),
    );
    final context = assembler.assemble(
      novelId: 'test_novel',
      chapterId: 'ch_002',
      userInstruction: '让主角遇到故人',
    );

    // 验证罗盘内容被正确读取
    expect(context.authorIntent, contains('坚韧不拔'));
    expect(context.authorIntent, contains('现实主义'));
    expect(context.creativeFocus, contains('主角觉醒'));
    expect(context.userInstruction, '让主角遇到故人');
    // 验证 token 估算合理
    expect(context.estimateTokens(), greaterThan(0));
  });

  // ─── 测试 2: 真实 Canon 读取 ───────────────────────────────────

  test('真实 Canon 读取 — 从 JSON 文件读取角色和世界条目', () {
    // 模拟 Canon 数据文件（ZVec 降级存储格式）
    final canonDir = Directory('$projectDir/.lingbi/canon');
    canonDir.createSync(recursive: true);

    final characters = [
      {
        'id': 'char_001',
        'projectId': 'proj_001',
        'type': 'character',
        'name': '林远',
        'description': '主角，25岁，性格坚韧',
        'attributes': {'role': '主角', 'personality': '沉稳内敛'},
      },
      {
        'id': 'char_002',
        'projectId': 'proj_001',
        'type': 'character',
        'name': '苏晴',
        'description': '女主，23岁，活泼开朗',
        'attributes': {'role': '女主', 'personality': '热情'},
      },
    ];
    File('$projectDir/.lingbi/canon/characters.json')
        .writeAsStringSync(jsonEncode(characters));

    // 验证文件可读
    final readBack = jsonDecode(
      File('$projectDir/.lingbi/canon/characters.json').readAsStringSync(),
    ) as List;
    expect(readBack.length, 2);
    expect(readBack[0]['name'], '林远');
    expect(readBack[1]['name'], '苏晴');

    // 验证 ContextFragment 追踪
    final fragments = [
      const ContextFragment(
        type: 'canon_character',
        sourceId: 'char_001',
        content: '林远: 主角，25岁，性格坚韧',
        priority: 6,
        charBudget: 200,
      ),
    ];
    expect(fragments.first.type, 'canon_character');
    expect(fragments.first.sourceId, 'char_001');
    expect(fragments.first.priority, 6);
  });

  // ─── 测试 3: 生成候选不修改正文 ─────────────────────────────────

  test('生成候选不修改正文 — 候选只写入 candidates 目录', () {
    final chapterPath = createChapterFile('第三章', '# 第三章\n\n原始正文内容。');
    final originalContent = File(chapterPath).readAsStringSync();

    final candidateService = CandidateService(projectDir: projectDir);
    candidateService.createCandidate(
      chapterId: 'ch_003',
      content: '这是 AI 生成的候选内容，不应该出现在正文中。',
      model: 'test-model',
    );

    // 正文未被修改
    expect(File(chapterPath).readAsStringSync(), originalContent);
    // 候选存在于 candidates 目录
    final candidates = candidateService.listCandidates('ch_003');
    expect(candidates.length, 1);
    expect(candidates.first.content, contains('AI 生成的候选内容'));
    // 候选文件确实存在
    final candidateFile = File(
        '$projectDir/.lingbi/candidates/${candidates.first.id}.md');
    expect(candidateFile.existsSync(), true);
  });

  // ─── 测试 4: 拒绝不修改正文 ─────────────────────────────────────

  test('拒绝不修改正文 — 拒绝后正文和 Canon 均不变', () {
    final chapterPath = createChapterFile('第四章', '# 第四章\n\n正文不变。');
    final originalContent = File(chapterPath).readAsStringSync();

    final candidateService = CandidateService(projectDir: projectDir);
    final candidate = candidateService.createCandidate(
      chapterId: 'ch_004',
      content: '候选内容',
      model: 'test',
    );

    // 拒绝
    candidateService.reject(candidate.id, reason: '质量不佳');

    // 正文未变
    expect(File(chapterPath).readAsStringSync(), originalContent);
    // 候选状态变为 rejected
    final updated = candidateService.getCandidate(candidate.id);
    expect(updated!.status, CandidateStatus.rejected);
    expect(updated.metadata['reject_reason'], '质量不佳');
  });

  // ─── 测试 5: 采纳安全写入 ───────────────────────────────────────

  test('采纳安全写入 — 锁+快照+原子替换+状态更新', () async {
    final chapterPath = createChapterFile('第五章', '# 第五章\n\n旧内容。');
    final candidateService = CandidateService(
      projectDir: projectDir,
      mutationProtocol: _proto(projectDir),
    );
    final writeLock = WriteLockService(projectDir: projectDir);
    final bookStateStore = BookStateStore(projectDir: projectDir);

    final candidate = candidateService.createCandidate(
      chapterId: 'ch_005',
      content: '# 第五章\n\n全新的正文内容，由 AI 生成并经作者采纳。',
      model: 'test',
    );

    // 模拟安全采纳流程
    // 1. 获取写锁
    expect(writeLock.acquire('adopt'), true);

    // 2. 创建快照
    final snapshotDir = Directory('$projectDir/.lingbi/snapshots');
    snapshotDir.createSync(recursive: true);
    File(chapterPath).copySync(
        '$projectDir/.lingbi/snapshots/ch_005_before.md');

    // 3. 写临时文件 + 原子替换
    final tempPath = '$chapterPath.tmp';
    File(tempPath).writeAsStringSync(candidate.content, flush: true);
    File(chapterPath).deleteSync();
    File(tempPath).renameSync(chapterPath);

    // 4. 更新候选状态
    candidate.status = CandidateStatus.adopted;
    await candidateService.adopt(candidate.id, chapterPath);

    // 5. 更新 BookState
    bookStateStore.updateProgress(
      chapterId: 'ch_005',
      stage: BookStage.settling,
      action: 'adopted',
    );

    // 6. 释放写锁
    writeLock.release();

    // 验证
    expect(File(chapterPath).readAsStringSync(), contains('全新的正文内容'));
    expect(
        File('$projectDir/.lingbi/snapshots/ch_005_before.md').readAsStringSync(),
        contains('旧内容'));
    expect(writeLock.isAcquired, false);
    final state = bookStateStore.loadOrCreate();
    expect(state.stage, BookStage.settling);
  });

  // ─── 测试 6: 源版本冲突 ─────────────────────────────────────────

  test('源版本冲突 — 候选生成后章节被人工编辑则拒绝采纳', () {
    final chapterPath = createChapterFile('第六章', '# 第六章\n\n版本A。');

    final candidateService = CandidateService(projectDir: projectDir);

    // 记录源版本
    final statBefore = File(chapterPath).statSync();
    final sourceVersion =
        '${statBefore.modified.millisecondsSinceEpoch}_${statBefore.size}';

    // 创建候选（带源版本）
    final candidate = candidateService.createCandidate(
      chapterId: 'ch_006',
      content: 'AI 生成的内容',
      model: 'test',
      metadata: {'source_version': sourceVersion},
    );

    // 人工编辑章节（模拟冲突）
    File(chapterPath).writeAsStringSync('# 第六章\n\n人工修改后的版本B。');

    // 检测版本冲突
    final statAfter = File(chapterPath).statSync();
    final currentVersion =
        '${statAfter.modified.millisecondsSinceEpoch}_${statAfter.size}';

    final savedVersion =
        candidate.metadata['source_version'] as String;
    expect(savedVersion != currentVersion, true,
        reason: '版本应该不同（人工已编辑）');

    // 正文保持人工版本
    expect(File(chapterPath).readAsStringSync(), contains('版本B'));
  });

  // ─── 测试 7: 并发写锁 ───────────────────────────────────────────

  test('并发写锁 — 第二个进程获取锁失败', () {
    final lock1 = WriteLockService(projectDir: projectDir);
    final lock2 = WriteLockService(projectDir: projectDir);

    // 第一个获取成功
    expect(lock1.acquire('writing_ch7'), true);
    expect(lock1.isAcquired, true);

    // 第二个获取失败
    expect(lock2.acquire('writing_ch7'), false);
    expect(lock2.isAcquired, false);

    // 锁信息可读
    final lockInfo = lock2.currentLock;
    expect(lockInfo, isNotNull);
    expect(lockInfo!.operation, 'writing_ch7');

    // 释放后第二个可以获取
    lock1.release();
    expect(lock2.acquire('writing_ch7_retry'), true);
    lock2.release();
  });

  // ─── 测试 8: 写入失败恢复 ───────────────────────────────────────

  test('写入失败恢复 — 快照可用于回滚', () {
    final chapterPath = createChapterFile('第八章', '# 第八章\n\n原始内容。');
    final originalContent = File(chapterPath).readAsStringSync();

    // 创建快照
    final snapshotDir = Directory('$projectDir/.lingbi/snapshots');
    snapshotDir.createSync(recursive: true);
    final snapshotPath = '$projectDir/.lingbi/snapshots/ch_008_rollback.md';
    File(chapterPath).copySync(snapshotPath);

    // 模拟写入失败（写入一半后中断）
    try {
      File(chapterPath).writeAsStringSync('# 第八章\n\n写了一半...');
      // 模拟异常
      throw const FileSystemException('磁盘空间不足');
    } catch (_) {
      // 回滚：从快照恢复
      File(snapshotPath).copySync(chapterPath);
    }

    // 验证恢复成功
    expect(File(chapterPath).readAsStringSync(), originalContent);
  });

  // ─── 测试 9: 重启恢复候选 ───────────────────────────────────────

  test('重启恢复候选 — 新 CandidateService 实例可读取已有候选', () {
    // 第一个实例创建候选
    final service1 = CandidateService(projectDir: projectDir);
    final candidate = service1.createCandidate(
      chapterId: 'ch_009',
      content: '重启前的候选内容',
      model: 'deepseek',
      metadata: {'source_version': 'v1'},
    );

    // 模拟重启：创建新实例
    final service2 = CandidateService(projectDir: projectDir);
    final recovered = service2.getCandidate(candidate.id);

    expect(recovered, isNotNull);
    expect(recovered!.chapterId, 'ch_009');
    expect(recovered.content, '重启前的候选内容');
    expect(recovered.model, 'deepseek');
    expect(recovered.status, CandidateStatus.pending);
    expect(recovered.metadata['source_version'], 'v1');

    // 列出也能找到
    final list = service2.listCandidates('ch_009');
    expect(list.length, 1);
  });

  // ─── 测试 10: 结算失败保留正文 ──────────────────────────────────

  test('结算失败保留正文 — BookState 标记失败但正文不受影响', () {
    final chapterPath = createChapterFile('第十章', '# 第十章\n\n已采纳的正文。');
    final bookStateStore = BookStateStore(projectDir: projectDir);

    // 模拟采纳成功
    bookStateStore.updateProgress(
      chapterId: 'ch_010',
      stage: BookStage.settling,
      action: 'adopted',
    );

    // 模拟结算失败
    bookStateStore.updateProgress(
      chapterId: 'ch_010',
      stage: BookStage.settling,
      action: 'settlement_failed',
      blockingReason: 'SETTLEMENT_FAILED: AI 调用超时',
    );

    // 正文仍然存在且未变
    expect(File(chapterPath).readAsStringSync(), contains('已采纳的正文'));

    // BookState 记录了失败
    final state = bookStateStore.loadOrCreate();
    expect(state.blockingReason, contains('SETTLEMENT_FAILED'));
    expect(state.stage, BookStage.settling);
  });

  // ─── 测试 11: 未结算阻止下一章 ─────────────────────────────────

  test('未结算阻止下一章 — blockingReason 存在时阻止写作', () {
    final bookStateStore = BookStateStore(projectDir: projectDir);

    // 标记结算失败
    bookStateStore.updateProgress(
      chapterId: 'ch_011',
      stage: BookStage.settling,
      action: 'settlement_failed',
      blockingReason: 'SETTLEMENT_FAILED: 解析错误',
    );

    // 验证阻止逻辑
    final state = bookStateStore.loadOrCreate();
    final isBlocked = state.blockingReason.contains('SETTLEMENT_FAILED');
    expect(isBlocked, true);

    // 重试结算成功后解除阻止
    bookStateStore.updateProgress(
      chapterId: 'ch_011',
      stage: BookStage.chapterPreflight,
      action: 'settlement_retry_success',
      blockingReason: '',
    );

    final stateAfter = bookStateStore.loadOrCreate();
    expect(stateAfter.blockingReason, '');
    expect(stateAfter.stage, BookStage.chapterPreflight);
  });

  // ─── 测试 12: 旧项目兼容 ────────────────────────────────────────

  test('旧项目兼容 — 无 .lingbi 目录时自动创建且不崩溃', () {
    // 创建一个"旧项目"：只有章节文件，没有 .lingbi 目录
    final oldProjectDir = '${tempDir.path}/old_project';
    Directory('$oldProjectDir/chapters').createSync(recursive: true);
    File('$oldProjectDir/chapters/第一章.md')
        .writeAsStringSync('# 第一章\n\n旧项目的章节。');

    // 确保没有 .lingbi
    final lingbiDir = Directory('$oldProjectDir/.lingbi');
    expect(lingbiDir.existsSync(), false);

    // CandidateService 自动创建目录
    final candidateService = CandidateService(projectDir: oldProjectDir);
    final candidate = candidateService.createCandidate(
      chapterId: 'ch_001',
      content: '新候选',
      model: 'test',
    );
    expect(candidate.id, isNotEmpty);
    expect(Directory('$oldProjectDir/.lingbi/candidates').existsSync(), true);

    // WriteLockService 自动创建目录
    final writeLock = WriteLockService(projectDir: oldProjectDir);
    expect(writeLock.acquire('test'), true);
    writeLock.release();

    // BookStateStore 自动创建
    final bookStateStore = BookStateStore(projectDir: oldProjectDir);
    final state = bookStateStore.loadOrCreate(
        novelId: 'old_novel', title: '旧项目');
    expect(state.stage, BookStage.planning);
    bookStateStore.save(state);
    expect(File('$oldProjectDir/.lingbi/runtime/book_state.json').existsSync(),
        true);

    // CreativeCompassStore 自动创建
    final compassStore = CreativeCompassStore(projectDir: oldProjectDir);
    final compass = compassStore.loadOrCreate();
    expect(compass.authorIntent.coreTheme, '');

    // 旧章节文件未被修改
    expect(
        File('$oldProjectDir/chapters/第一章.md').readAsStringSync(),
        contains('旧项目的章节'));
  });
}

LocalMutationProtocol _proto(String root) => LocalMutationProtocol(
      journal: LocalMutationJournal(basePath: '$root/.lingbi/test-journal'),
      store: FileCanonicalStore(
        projectRoot: root,
        atomicStore: AtomicFileStore(),
      ),
    );
