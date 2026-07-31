import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/project/project_brief.dart';
import 'package:lingbi/features/project/data/project_brief_repository.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';

/// #46 验证：重启恢复（数据持久化）
///
/// 模拟完整用户链路后"重启"（重新实例化服务），验证数据完整。
/// 不依赖网络，使用真实文件系统（tempDir）。
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_persist_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('重启后数据完整性', () {
    test('ProjectBrief 重启后所有字段完整', () async {
      // 模拟向导完成 → 写入 ProjectBrief
      final repo = ProjectBriefRepository(tempDir.path);
      const brief = ProjectBrief(
        title: '万界守夜人',
        genreId: '玄幻',
        templateId: 'genre:玄幻',
        premise: '灵气复苏的现代都市',
      );
      await repo.write(brief, expectedRevision: 0);

      // 模拟"重启"：重新实例化 repository
      final restoredRepo = ProjectBriefRepository(tempDir.path);
      final restored = await restoredRepo.read();

      expect(restored.title, '万界守夜人');
      expect(restored.genreId, '玄幻');
      expect(restored.templateId, 'genre:玄幻');
      expect(restored.premise, '灵气复苏的现代都市');
      expect(restored.revision, 1);
    });

    test('已采纳章节重启后文件存在且内容正确', () async {
      // 模拟候选 → 采纳
      final service = CandidateService(projectDir: tempDir.path);
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '第一章：守夜人的觉醒\n\n林渊站在楼顶，看着灵气如潮水般涌来。',
      );
      final chapterPath = '${tempDir.path}/chapters/chapter-1.md';
      service.adopt(entry.id, chapterPath);

      // 模拟"重启"：重新实例化 service，验证文件和候选状态
      final restoredService = CandidateService(projectDir: tempDir.path);

      // 章节文件存在
      final chapterFile = File(chapterPath);
      expect(chapterFile.existsSync(), isTrue);
      expect(
        chapterFile.readAsStringSync(),
        contains('林渊站在楼顶'),
      );

      // 候选状态仍为 adopted
      final restoredCandidate = restoredService.getCandidate(entry.id);
      expect(restoredCandidate?.status.name, 'adopted');
    });

    test('未采纳候选重启后仍可审阅', () async {
      final service = CandidateService(projectDir: tempDir.path);
      service.createCandidate(
        chapterId: 'chapter-1',
        content: '待审阅的候选正文',
      );

      // 模拟"重启"
      final restoredService = CandidateService(projectDir: tempDir.path);
      final pending = restoredService.listPendingAdoption();

      expect(pending.length, 1);
      expect(pending.first.content, '待审阅的候选正文');
      expect(pending.first.status.name, 'pending');
    });

    test('崩溃恢复：tmp 文件不干扰正常读取', () async {
      final service = CandidateService(projectDir: tempDir.path);
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '正常内容',
      );
      final chapterPath = '${tempDir.path}/chapters/chapter-1.md';
      service.adopt(entry.id, chapterPath);

      // 模拟崩溃残留：手动创建一个 .tmp 文件
      File('$chapterPath.tmp').writeAsStringSync('半截数据');

      // "重启"后正常读取不受影响
      final chapterFile = File(chapterPath);
      expect(chapterFile.readAsStringSync(), '正常内容');

      // 候选状态不受 tmp 影响
      final restoredService = CandidateService(projectDir: tempDir.path);
      expect(
        restoredService.getCandidate(entry.id)?.status.name,
        'adopted',
      );
    });

    test('ProjectBrief 不可丢弃：revision 递增保护', () async {
      final repo = ProjectBriefRepository(tempDir.path);
      const brief = ProjectBrief(
        title: '长夜',
        genreId: '悬疑',
        templateId: 'genre:悬疑',
      );
      final saved = await repo.write(brief, expectedRevision: 0);
      expect(saved.revision, 1);

      // 用旧 revision 覆盖会被拒绝
      expect(
        () => repo.write(brief, expectedRevision: 0),
        throwsA(isA<ProjectBriefConflict>()),
      );

      // 用正确 revision 可以修订
      final revised = await repo.write(
        brief.copyWith(title: '长夜（修订版）'),
        expectedRevision: 1,
      );
      expect(revised.revision, 2);
      expect(revised.title, '长夜（修订版）');
    });
  });

  group('端到端持久化链路', () {
    test('向导→项目→候选→采纳→重启→验证全部数据', () async {
      // 1. 模拟向导完成 → 写入 ProjectBrief
      final briefRepo = ProjectBriefRepository(tempDir.path);
      const brief = ProjectBrief(
        title: '端到端测试',
        genreId: '都市',
        templateId: 'genre:都市',
        premise: '测试前提',
      );
      await briefRepo.write(brief, expectedRevision: 0);

      // 2. 模拟候选生成 → 采纳
      final candidateService = CandidateService(projectDir: tempDir.path);
      final candidate = candidateService.createCandidate(
        chapterId: 'chapter-1',
        content: '端到端测试正文',
      );
      final chapterPath = '${tempDir.path}/chapters/chapter-1.md';
      candidateService.adopt(candidate.id, chapterPath);

      // 3. 模拟"重启"：全部重新实例化
      final restoredBriefRepo = ProjectBriefRepository(tempDir.path);
      final restoredCandidateService = CandidateService(
        projectDir: tempDir.path,
      );

      // 4. 验证全部数据
      final restoredBrief = await restoredBriefRepo.read();
      expect(restoredBrief.title, '端到端测试');
      expect(restoredBrief.genreId, '都市');

      final chapterFile = File(chapterPath);
      expect(chapterFile.existsSync(), isTrue);
      expect(chapterFile.readAsStringSync(), '端到端测试正文');

      final restoredCandidate = restoredCandidateService.getCandidate(
        candidate.id,
      );
      expect(restoredCandidate?.status.name, 'adopted');
    });
  });
}
