import 'package:lingbi/core/models/codex_entry.dart';

/// Codex 知识库服务接口
@Deprecated(
    'Use ICanonService instead. Codex interface is replaced by Canon in v4.0')
abstract class ICodexService {
  Future<CodexEntry> create(CodexEntry entry, {String? providerName});
  Future<List<CodexEntry>> list(String projectId, CodexEntryType type);
  Future<CodexEntry?> get(String id, CodexEntryType type);
  Future<CodexEntry> update(CodexEntry entry, {String? providerName});
  Future<void> delete(CodexEntry entry);
  Future<List<CodexEntry>> search(String projectId, String query);
  Future<List<CodexEntry>> semanticSearch(
    String projectId,
    String query, {
    required String providerName,
    int limit = 10,
  });
  Future<Map<CodexEntryType, List<CodexEntry>>> getAllForProject(
      String projectId);
}
