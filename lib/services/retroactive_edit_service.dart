/// RetroactiveEditService — 回溯编辑服务
///
/// 对编辑器选中文本执行 AI 改写/扩写/润色等操作，并管理版本快照。
library;

import 'dart:convert';
import '../services/interfaces/i_retroactive_edit_service.dart';
import '../services/interfaces/i_ai_service.dart';
import '../services/generation/text_refinement.dart';

/// 编辑历史条目
class _EditHistoryEntry {
  final String documentId;
  final String contentBefore;
  final String contentAfter;
  final DateTime timestamp;

  const _EditHistoryEntry({
    required this.documentId,
    required this.contentBefore,
    required this.contentAfter,
    required this.timestamp,
  });
}

class RetroactiveEditService implements IRetroactiveEditService {
  RetroactiveEditService({
    required IAIService aiService,
  }) : _aiService = aiService;

  final IAIService _aiService;
  final Map<String, List<_EditHistoryEntry>> _histories = {};

  @override
  Future<EditResult> edit({
    required String selectedText,
    required String fullContext,
    required EditMode mode,
    String? targetTone,
    int? startOffset,
    int? endOffset,
  }) async {
    final modeStr = TextRefinementService.modeFromEnum(mode);
    final prompt = TextRefinementService.buildPrompt(
      mode: modeStr,
      text: selectedText,
      targetTone: targetTone,
    );

    // 调用 AI
    final chunks = <String>[];
    await for (final chunk in _aiService.chat(
      message: prompt,
      systemPrompt: '你是一个专业小说编辑助手。直接输出结果，不要额外说明。',
    )) {
      chunks.add(chunk);
    }
    final newText = chunks.join('');

    return EditResult(
      newText: newText,
      mode: modeStr,
      hasSnapshot: false,
    );
  }

  @override
  Future<String?> undo(String documentId) async {
    final history = _histories[documentId];
    if (history == null || history.isEmpty) return null;

    final lastEntry = history.removeLast();
    return lastEntry.contentBefore;
  }

  @override
  List<String> getHistory(String documentId) {
    final history = _histories[documentId];
    if (history == null) return [];
    return history.map((e) => '[${e.timestamp}] ${e.documentId}').toList();
  }

  /// 保存编辑前快照
  void snapshotBefore(String documentId, String content) {
    _histories.putIfAbsent(documentId, () => []);
  }

  /// 保存编辑后快照（同时记录编辑对）
  void snapshotAfter(String documentId, String contentBefore, String contentAfter) {
    _histories.putIfAbsent(documentId, () => []);
    _histories[documentId]!.add(_EditHistoryEntry(
      documentId: documentId,
      contentBefore: contentBefore,
      contentAfter: contentAfter,
      timestamp: DateTime.now(),
    ));
  }
}
