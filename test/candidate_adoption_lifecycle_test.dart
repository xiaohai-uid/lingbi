import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/writing/data/pipeline/candidate_service.dart';

/// #45 验证：候选采纳 → 原子写入
///
/// 验收条件：
/// 1. 采纳操作将候选正文原子写入正式章节文件，候选状态变为 adopted
/// 2. 拒绝操作将候选状态变为 rejected，文件保留可回看
/// 3. "需要修改"标记为 revisionNeeded
/// 4. 原子写入保证：写入中途失败不产生半截文件
void main() {
  late Directory tempDir;
  late CandidateService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_candidate_');
    service = CandidateService(projectDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('候选生命周期', () {
    test('adopt: 候选正文写入正式文件，状态变为 adopted', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '第一章正文内容',
        model: 'test-model',
      );
      expect(entry.status, CandidateStatus.pending);

      final targetPath = '${tempDir.path}/chapters/chapter-1.md';
      service.adopt(entry.id, targetPath);

      // 正式文件存在且内容正确
      final targetFile = File(targetPath);
      expect(targetFile.existsSync(), isTrue);
      expect(targetFile.readAsStringSync(), '第一章正文内容');

      // 候选状态变为 adopted
      final updated = service.getCandidate(entry.id);
      expect(updated?.status, CandidateStatus.adopted);
    });

    test('reject: 状态变为 rejected，候选文件保留', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '不满意的版本',
      );

      service.reject(entry.id, reason: '节奏太慢');

      final updated = service.getCandidate(entry.id);
      expect(updated?.status, CandidateStatus.rejected);
      expect(updated?.metadata['reject_reason'], '节奏太慢');
      // 候选文件仍然保留（可回看）
      expect(updated?.content, '不满意的版本');
    });

    test('revisionNeeded: 审稿未通过标记', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '需要修改的版本',
      );

      service.updateReview(entry.id, {'passed': false, 'issues': ['节奏']});

      final updated = service.getCandidate(entry.id);
      expect(updated?.status, CandidateStatus.revisionNeeded);
    });

    test('approved: 审稿通过标记', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '通过审稿的版本',
      );

      service.updateReview(entry.id, {'passed': true});

      final updated = service.getCandidate(entry.id);
      expect(updated?.status, CandidateStatus.approved);
    });

    test('已采纳的候选不能再次采纳', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '内容',
      );
      final targetPath = '${tempDir.path}/chapters/ch.md';
      service.adopt(entry.id, targetPath);

      expect(
        () => service.adopt(entry.id, targetPath),
        throwsStateError,
      );
    });

    test('已拒绝的候选不能采纳', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '内容',
      );
      service.reject(entry.id);

      expect(
        () => service.adopt(entry.id, '${tempDir.path}/ch.md'),
        throwsStateError,
      );
    });
  });

  group('原子写入保证', () {
    test('采纳后不存在残留临时文件', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '原子写入测试',
      );
      final targetPath = '${tempDir.path}/chapters/atomic.md';
      service.adopt(entry.id, targetPath);

      // 目标目录中不应有 .tmp 文件
      final chapterDir = Directory('${tempDir.path}/chapters');
      final tmpFiles = chapterDir
          .listSync()
          .where((f) => f.path.endsWith('.tmp'))
          .toList();
      expect(tmpFiles, isEmpty);
    });

    test('目标文件内容与候选完全一致（无截断）', () {
      // 使用较长内容验证完整性
      final longContent = '段落内容。' * 1000;
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: longContent,
      );
      final targetPath = '${tempDir.path}/chapters/long.md';
      service.adopt(entry.id, targetPath);

      final written = File(targetPath).readAsStringSync();
      expect(written.length, longContent.length);
      expect(written, longContent);
    });

    test('目标目录不存在时自动创建', () {
      final entry = service.createCandidate(
        chapterId: 'chapter-1',
        content: '深层目录',
      );
      final targetPath = '${tempDir.path}/deep/nested/dir/ch.md';
      service.adopt(entry.id, targetPath);

      expect(File(targetPath).existsSync(), isTrue);
      expect(File(targetPath).readAsStringSync(), '深层目录');
    });
  });
}
