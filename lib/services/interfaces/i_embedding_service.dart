/// Embedding 服务接口
library;

abstract class IEmbeddingService {
  /// 生成文本向量
  Future<List<double>> embed(String text);

  /// 批量生成向量
  Future<List<List<double>>> embedBatch(List<String> texts);
}
