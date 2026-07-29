import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/models/canon_entry.dart';

/// Canon 正典知识库服务接口
abstract class ICanonService {
  Future<CanonEntry> create(CanonEntry entry, {AIProvider? provider});
  Future<List<CanonEntry>> list(String projectId, CanonEntryType type);
  Future<CanonEntry?> get(String id, CanonEntryType type);
  Future<CanonEntry> update(CanonEntry entry, {AIProvider? provider});
  Future<void> delete(CanonEntry entry);
  Future<List<CanonEntry>> search(String projectId, String query);
  Future<List<CanonEntry>> semanticSearch(
    String projectId,
    String query, {
    required AIProvider provider,
    int limit = 10,
  });
  Future<Map<CanonEntryType, List<CanonEntry>>> getAllForProject(
      String projectId);
}
