import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';

class CanonLinkingService {

  CanonLinkingService({required CanonService canonService})
      : _canon = canonService;
  final CanonService _canon;

  /// 从文档内容中检测提到的角色/地点名称
  Future<List<CanonEntry>> findMentions(String projectId, String documentContent) async {
    final allEntries = await _canon.getAllForProject(projectId);
    final mentions = <CanonEntry>{};

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

  /// 生成文档的 Canon 摘要
  Future<String> generateCanonSummary(String projectId, String documentContent) async {
    final mentions = await findMentions(projectId, documentContent);
    if (mentions.isEmpty) return '暂无关联的正典条目';

    final buffer = StringBuffer();
    buffer.write('📚 关联正典条目：\n\n');
    for (final entry in mentions) {
      final icon = {
        CanonEntryType.character: '👤',
        CanonEntryType.location: '📍',
        CanonEntryType.lore: '📖',
        CanonEntryType.plotNode: '🎬',
      }[entry.type] ?? '📌';
      buffer.write('$icon ${entry.name}\n');
      if (entry.description.isNotEmpty) {
        buffer.write('   ${entry.description}\n');
      }
    }
    return buffer.toString();
  }
}
