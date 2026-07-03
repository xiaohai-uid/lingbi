import 'package:lingbi/core/models/codex_entry.dart';
import 'package:lingbi/services/codex_service.dart';

class CodexLinkingService {
  final CodexService _codex;

  CodexLinkingService({required CodexService codexService})
      : _codex = codexService;

  /// 从文档内容中检测提到的角色/地点名称
  Future<List<CodexEntry>> findMentions(String projectId, String documentContent) async {
    final allEntries = await _codex.getAllForProject(projectId);
    final mentions = <CodexEntry>{};

    for (final type in allEntries.keys) {
      for (final entry in allEntries[type] ?? []) {
        // 检查角色名或地点名是否在文档中出现
        if (documentContent.contains(entry.name) && entry.name.length > 1) {
          mentions.add(entry);
        }
      }
    }

    return mentions.toList();
  }

  /// 生成文档的 Codex 摘要
  Future<String> generateCodexSummary(String projectId, String documentContent) async {
    final mentions = await findMentions(projectId, documentContent);
    if (mentions.isEmpty) return '暂无关联的知识库条目';

    final buffer = StringBuffer();
    buffer.write('📚 关联知识库条目：\n\n');
    for (final entry in mentions) {
      final icon = {
        CodexEntryType.character: '👤',
        CodexEntryType.location: '📍',
        CodexEntryType.lore: '📖',
        CodexEntryType.plotNode: '🎬',
      }[entry.type] ?? '📌';
      buffer.write('$icon ${entry.name}\n');
      if (entry.description.isNotEmpty) {
        buffer.write('   ${entry.description}\n');
      }
    }
    return buffer.toString();
  }
}
