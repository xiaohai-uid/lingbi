/// 向量知识库服务 (RAG)
///
/// 提供项目内所有设定/章节/参考书的自动向量化与语义检索：
/// - 增量索引：内容变更时触发
/// - 语义检索：生成前根据当前章节内容召回 top-K 相关段落
/// - 全量重建：用户手动触发
/// - ContextAssembler 集成：按相关性排序注入
/// - 嵌入模型可配置（用户 API 的 /v1/embeddings 或本地模型）
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

// ─── 数据模型 ───

/// 向量条目类型
enum VectorEntryType {
  canon,
  chapter,
  reference,
  foreshadowing,
  outline,
  custom;

  static VectorEntryType fromString(String s) {
    return VectorEntryType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => VectorEntryType.custom,
    );
  }
}

/// 单条向量索引条目
class VectorEntry {
  const VectorEntry({
    required this.id,
    required this.type,
    required this.content,
    required this.embedding,
    this.metadata = const {},
    this.indexedAt = '',
  });

  factory VectorEntry.fromJson(Map<String, dynamic> json) {
    return VectorEntry(
      id: json['id'] as String? ?? '',
      type: VectorEntryType.fromString(json['type'] as String? ?? 'custom'),
      content: json['content'] as String? ?? '',
      embedding: (json['embedding'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      indexedAt: json['indexed_at'] as String? ?? '',
    );
  }

  final String id;
  final VectorEntryType type;
  final String content;
  final List<double> embedding;
  final Map<String, dynamic> metadata;
  final String indexedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'embedding': embedding,
        'metadata': metadata,
        'indexed_at': indexedAt,
      };
}

/// 向量索引 — 项目级
class VectorIndex {
  VectorIndex({
    required this.projectId,
    this.entries = const [],
    DateTime? lastRebuiltAt,
  }) : lastRebuiltAt = lastRebuiltAt ?? DateTime.now();

  factory VectorIndex.fromJson(Map<String, dynamic> json) {
    return VectorIndex(
      projectId: json['project_id'] as String? ?? '',
      entries: (json['entries'] as List?)
              ?.map((e) => VectorEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastRebuiltAt:
          DateTime.tryParse(json['last_rebuilt_at'] as String? ?? ''),
    );
  }

  final String projectId;
  final List<VectorEntry> entries;
  final DateTime lastRebuiltAt;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'entries': entries.map((e) => e.toJson()).toList(),
        'last_rebuilt_at': lastRebuiltAt.toIso8601String(),
      };
}

/// 语义检索结果
class RetrievalResult {
  const RetrievalResult({
    required this.entry,
    required this.score,
  });

  final VectorEntry entry;

  /// 余弦相似度 [0, 1]
  final double score;
}

// ─── 服务 ───

/// 向量知识库服务
///
/// 使用 AIProvider.embed() 生成嵌入向量，
/// 通过 IProjectMetaRepository 持久化索引（JSON 文件），
/// 纯 Dart 余弦相似度检索（无需原生向量数据库）。
class VectorKnowledgeService {
  VectorKnowledgeService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
    this.topK = 5,
    this.similarityThreshold = 0.3,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  AIProvider _aiProvider;

  set aiProvider(AIProvider provider) => _aiProvider = provider;

  /// 默认检索返回条数
  final int topK;

  /// 相似度阈值（低于此值不返回）
  final double similarityThreshold;

  static const _indexFileName = 'vector_index.json';

  /// 内存缓存（避免频繁磁盘 IO）
  final Map<String, VectorIndex> _cache = {};

  // ─── 1. 索引管理 ───

  /// 加载项目向量索引
  Future<VectorIndex> loadIndex(String projectId) async {
    if (_cache.containsKey(projectId)) {
      return _cache[projectId]!;
    }
    final data = await _metaRepository.read(projectId, _indexFileName);
    final index = data != null
        ? VectorIndex.fromJson(data)
        : VectorIndex(projectId: projectId);
    _cache[projectId] = index;
    return index;
  }

  /// 保存索引到磁盘
  Future<void> _saveIndex(String projectId, VectorIndex index) async {
    _cache[projectId] = index;
    await _metaRepository.write(projectId, _indexFileName, index.toJson());
  }

  /// 增量索引单条内容
  ///
  /// 如果同 id 已存在则更新，否则追加。
  Future<void> indexContent(
    String projectId, {
    required String id,
    required VectorEntryType type,
    required String content,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (content.trim().isEmpty) return;

    final embedding = await _aiProvider.embed(content);
    if (embedding.isEmpty) return;

    final index = await loadIndex(projectId);
    final entry = VectorEntry(
      id: id,
      type: type,
      content: content,
      embedding: embedding,
      metadata: metadata,
      indexedAt: DateTime.now().toIso8601String(),
    );

    // 替换或追加
    final updatedEntries = index.entries.where((e) => e.id != id).toList()
      ..add(entry);

    final updatedIndex = VectorIndex(
      projectId: projectId,
      entries: updatedEntries,
      lastRebuiltAt: index.lastRebuiltAt,
    );
    await _saveIndex(projectId, updatedIndex);
  }

  /// 批量索引（用于全量重建）
  Future<void> indexBatch(
    String projectId,
    List<({String id, VectorEntryType type, String content})> items,
  ) async {
    final entries = <VectorEntry>[];
    for (final item in items) {
      if (item.content.trim().isEmpty) continue;
      final embedding = await _aiProvider.embed(item.content);
      if (embedding.isEmpty) continue;
      entries.add(VectorEntry(
        id: item.id,
        type: item.type,
        content: item.content,
        embedding: embedding,
        indexedAt: DateTime.now().toIso8601String(),
      ));
    }

    final index = VectorIndex(
      projectId: projectId,
      entries: entries,
      lastRebuiltAt: DateTime.now(),
    );
    await _saveIndex(projectId, index);
  }

  /// 删除指定条目
  Future<void> removeEntry(String projectId, String id) async {
    final index = await loadIndex(projectId);
    final updatedEntries = index.entries.where((e) => e.id != id).toList();
    final updatedIndex = VectorIndex(
      projectId: projectId,
      entries: updatedEntries,
      lastRebuiltAt: index.lastRebuiltAt,
    );
    await _saveIndex(projectId, updatedIndex);
  }

  /// 全量重建索引
  ///
  /// 从 project_meta 中读取所有设定文件，重新生成嵌入。
  Future<VectorIndex> rebuildIndex(String projectId) async {
    final files = await _metaRepository.list(projectId);
    final items = <({String id, VectorEntryType type, String content})>[];

    for (final file in files) {
      // 跳过索引文件自身
      if (file == _indexFileName) continue;

      final data = await _metaRepository.read(projectId, file);
      if (data == null) continue;

      final type = _inferType(file);
      final content = _extractContent(data);
      if (content.isNotEmpty) {
        items.add((id: 'meta_$file', type: type, content: content));
      }
    }

    await indexBatch(projectId, items);
    return loadIndex(projectId);
  }

  // ─── 2. 语义检索 ───

  /// 语义检索：根据查询文本召回 top-K 相关条目
  Future<List<RetrievalResult>> search(
    String projectId,
    String query, {
    int? k,
    double? threshold,
    VectorEntryType? typeFilter,
  }) async {
    final effectiveK = k ?? topK;
    final effectiveThreshold = threshold ?? similarityThreshold;

    final queryEmbedding = await _aiProvider.embed(query);
    if (queryEmbedding.isEmpty) return [];

    final index = await loadIndex(projectId);

    var candidates = index.entries;
    if (typeFilter != null) {
      candidates = candidates.where((e) => e.type == typeFilter).toList();
    }

    final results = <RetrievalResult>[];
    for (final entry in candidates) {
      if (entry.embedding.isEmpty) continue;
      final score = cosineSimilarity(queryEmbedding, entry.embedding);
      if (score >= effectiveThreshold) {
        results.add(RetrievalResult(entry: entry, score: score));
      }
    }

    // 按相似度降序
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(effectiveK).toList();
  }

  // ─── 3. ContextAssembler 集成 ───

  /// 构建 RAG 上下文文本（供 ContextAssembler 注入）
  ///
  /// 根据当前章节内容语义召回相关设定/伏笔/参考段落。
  Future<String> buildRagContext(
    String projectId,
    String chapterContent, {
    int? k,
  }) async {
    if (chapterContent.trim().isEmpty) return '';

    final results = await search(projectId, chapterContent, k: k);
    if (results.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('【知识库语义召回（RAG）】');
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      final typeLabel = _typeLabel(r.entry.type);
      final percent = (r.score * 100).round();
      buffer.writeln('$typeLabel (相关度$percent%):');
      // 截断过长内容
      final content = r.entry.content.length > 500
          ? '${r.entry.content.substring(0, 500)}…'
          : r.entry.content;
      buffer.writeln(content);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  // ─── 4. 统计 ───

  /// 获取索引统计信息
  Future<Map<String, int>> getStats(String projectId) async {
    final index = await loadIndex(projectId);
    final stats = <String, int>{'total': index.entries.length};
    for (final type in VectorEntryType.values) {
      stats[type.name] = index.entries.where((e) => e.type == type).length;
    }
    return stats;
  }

  // ─── 辅助方法 ───

  /// 余弦相似度计算
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;

    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = math.sqrt(normA) * math.sqrt(normB);
    if (denominator == 0) return 0;
    return dotProduct / denominator;
  }

  /// 根据文件名推断条目类型
  VectorEntryType _inferType(String fileName) {
    if (fileName.contains('character') || fileName.contains('canon')) {
      return VectorEntryType.canon;
    }
    if (fileName.contains('chapter') || fileName.contains('content')) {
      return VectorEntryType.chapter;
    }
    if (fileName.contains('reference') || fileName.contains('ref_book')) {
      return VectorEntryType.reference;
    }
    if (fileName.contains('foreshadow')) {
      return VectorEntryType.foreshadowing;
    }
    if (fileName.contains('outline')) {
      return VectorEntryType.outline;
    }
    return VectorEntryType.custom;
  }

  /// 从 JSON 数据中提取可索引文本
  String _extractContent(Map<String, dynamic> data) {
    // 尝试常见字段
    if (data.containsKey('content')) {
      return data['content'] as String? ?? '';
    }
    if (data.containsKey('description')) {
      return data['description'] as String? ?? '';
    }
    if (data.containsKey('summary')) {
      return data['summary'] as String? ?? '';
    }
    // 列表型数据（如角色列表）
    if (data.containsKey('entries')) {
      final entries = data['entries'] as List?;
      if (entries != null) {
        return entries
            .map((e) =>
                e is Map ? (e['name'] ?? e['title'] ?? '').toString() : '')
            .where((s) => s.isNotEmpty)
            .join('\n');
      }
    }
    // 回退：序列化整个 JSON（截断）
    final raw = jsonEncode(data);
    return raw.length > 2000 ? raw.substring(0, 2000) : raw;
  }

  /// 类型标签（中文）
  String _typeLabel(VectorEntryType type) {
    return switch (type) {
      VectorEntryType.canon => '设定',
      VectorEntryType.chapter => '章节',
      VectorEntryType.reference => '参考',
      VectorEntryType.foreshadowing => '伏笔',
      VectorEntryType.outline => '大纲',
      VectorEntryType.custom => '知识',
    };
  }
}
