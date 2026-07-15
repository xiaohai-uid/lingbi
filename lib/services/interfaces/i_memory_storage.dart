/// 向量存储服务接口
library;

/// 搜索结果条目
class StorageSearchResult {

  const StorageSearchResult({
    required this.id,
    required this.score,
    required this.payload,
  });
  final String id;
  final double score;
  final Map<String, dynamic> payload;
}

abstract class IMemoryStorage {
  /// 存储向量 + payload
  Future<void> upsertVector({
    required String id,
    required List<double> vector,
    required Map<String, dynamic> payload,
    String collection = 'memory_summaries',
  });

  /// 语义搜索
  Future<List<StorageSearchResult>> searchVectors({
    required List<double> vector,
    int limit = 10,
    String collection = 'memory_summaries',
  });

  /// 删除向量
  Future<void> deleteVector(String id, {String collection = 'memory_summaries'});
}
