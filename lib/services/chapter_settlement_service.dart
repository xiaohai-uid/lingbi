import 'dart:convert';

import 'package:lingbi/modules/pipeline/novel_application_service.dart';
import 'package:lingbi/services/atomic_file_store.dart';

class ChapterSettlementApplyResult {
  const ChapterSettlementApplyResult({
    required this.summaryPath,
    required this.appliedCount,
  });

  final String summaryPath;
  final int appliedCount;
}

/// Applies an author-approved settlement to the portable project files.
///
/// Extraction remains owned by [NovelApplicationService]. This boundary only
/// persists the author's decision and exposes accepted facts to later context
/// compilation through `章节摘要.md`.
class ChapterSettlementService {
  ChapterSettlementService({
    required this.projectDir,
    AtomicFileStore? store,
  }) : _store = store ?? AtomicFileStore();

  final String projectDir;
  final AtomicFileStore _store;

  String get _summaryPath => '$projectDir/小说资料/章节摘要.md';
  String _proposalPath(String id) => '$projectDir/.lingbi/settlements/$id.json';

  Future<ChapterSettlementApplyResult> applyApprovedFacts(
    SettlementProposal proposal, {
    required Set<int> selectedIndexes,
  }) async {
    final selected = selectedIndexes
        .where((index) => index >= 0 && index < proposal.items.length)
        .toList()
      ..sort();
    final marker = '<!-- lingbi-settlement:${proposal.id} -->';
    final existing = await _store.readString(_summaryPath) ?? '# 章节摘要\n';

    if (!existing.contains(marker)) {
      final section = StringBuffer()
        ..writeln()
        ..writeln(marker)
        ..writeln('### ${proposal.chapterId} 状态结算');
      for (final index in selected) {
        final item = proposal.items[index];
        final entity = item.entityName?.trim();
        section.writeln(
          '- [${_categoryLabel(item.category)}] '
          '${entity == null || entity.isEmpty ? '' : '$entity：'}'
          '${item.description}',
        );
      }
      await _store.writeString(_summaryPath, '$existing${section.toString()}');
    }

    proposal.status = 'confirmed';
    await _persistSettlementDecision(proposal);
    return ChapterSettlementApplyResult(
      summaryPath: _summaryPath,
      appliedCount: selected.length,
    );
  }

  Future<void> recordDeferredDecision(SettlementProposal proposal) async {
    proposal.status = 'rejected';
    await _persistSettlementDecision(proposal);
  }

  Future<void> _persistSettlementDecision(SettlementProposal proposal) {
    return _store.writeString(
      _proposalPath(proposal.id),
      const JsonEncoder.withIndent('  ').convert(proposal.toJson()),
    );
  }

  String _categoryLabel(String category) => switch (category) {
        'character_position' => '人物位置',
        'item_change' => '物品变化',
        'relationship_change' => '关系变化',
        'new_character' => '新人物',
        'new_rule' => '新设定',
        'new_foreshadowing' => '新伏笔',
        'foreshadowing_resolved' => '伏笔回收',
        'plotline_change' => '剧情推进',
        _ => '状态变化',
      };
}
