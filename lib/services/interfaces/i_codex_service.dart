import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/core/models/codex_entry.dart';

/// Codex 知识库服务接口
abstract class ICodexService {
  Future<CodexEntry> create(CodexEntry entry, {AIProvider? provider});
  Future<List<CodexEntry>> list(String projectId, CodexEntryType type);
  Future<CodexEntry?> get(String id, CodexEntryType type);
  Future<CodexEntry> update(CodexEntry entry, {AIProvider? provider});
  Future<void> delete(CodexEntry entry);
  Future<List<CodexEntry>> search(String projectId, String query);
  Future<List<CodexEntry>> semanticSearch(
    String projectId,
    String query, {
    required AIProvider provider,
    int limit = 10,
  });
  Future<Map<CodexEntryType, List<CodexEntry>>> getAllForProject(
      String projectId);
}
