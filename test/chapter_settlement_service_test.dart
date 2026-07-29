import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/modules/pipeline/novel_application_service.dart';
import 'package:lingbi/services/chapter_settlement_service.dart';

void main() {
  late Directory tempDir;
  late ChapterSettlementService service;

  SettlementProposal proposal() => SettlementProposal(
        id: 'stl-chapter-2',
        chapterId: '第2章',
        candidateId: 'candidate-2',
        items: const [
          SettlementItem(
            category: 'character_position',
            entityName: '沈砚',
            description: '沈砚抵达临安。',
          ),
          SettlementItem(
            category: 'new_foreshadowing',
            description: '铜牌背面的刻痕指向旧案。',
          ),
        ],
        createdAt: DateTime.utc(2026, 7, 29),
      );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_settlement_');
    Directory('${tempDir.path}/小说资料').createSync(recursive: true);
    File('${tempDir.path}/小说资料/章节摘要.md').writeAsStringSync('# 章节摘要\n');
    service = ChapterSettlementService(projectDir: tempDir.path);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('confirm atomically appends only selected facts and persists status',
      () async {
    final draft = proposal();

    final result =
        await service.applyApprovedFacts(draft, selectedIndexes: {1});

    final summary = File(result.summaryPath).readAsStringSync();
    expect(summary, contains('铜牌背面的刻痕指向旧案'));
    expect(summary, isNot(contains('沈砚抵达临安')));
    expect(result.appliedCount, 1);
    expect(draft.status, 'confirmed');

    final persisted = jsonDecode(
      File('${tempDir.path}/.lingbi/settlements/${draft.id}.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(persisted['status'], 'confirmed');
  });

  test('confirm is idempotent for the same settlement proposal', () async {
    final draft = proposal();

    await service.applyApprovedFacts(draft, selectedIndexes: {0, 1});
    await service.applyApprovedFacts(draft, selectedIndexes: {0, 1});

    final summary = File('${tempDir.path}/小说资料/章节摘要.md').readAsStringSync();
    expect(
        RegExp('lingbi-settlement:${draft.id}').allMatches(summary).length, 1);
  });

  test('skip persists a rejected status without changing chapter summary',
      () async {
    final draft = proposal();

    await service.recordDeferredDecision(draft);

    expect(draft.status, 'rejected');
    expect(
      File('${tempDir.path}/小说资料/章节摘要.md').readAsStringSync(),
      '# 章节摘要\n',
    );
  });
}
