/// 真实项目数据源适配器
///
/// 将灵笔现有的 ProjectService/DocumentService/CanonService
/// 适配为 ContextAssembler 所需的 ContextDataSource 接口。
/// 每个上下文片段记录类型、来源、优先级。
library;

import 'package:lingbi/core/models/canon_entry.dart';
import 'package:lingbi/services/canon_service.dart';
import 'package:lingbi/services/document_service.dart';

import 'context_assembler.dart';
import 'generation_context.dart';

/// 上下文片段来源追踪
class ContextFragment {
  const ContextFragment({
    required this.type,
    required this.sourceId,
    required this.content,
    required this.priority,
    this.isProtected = false,
    this.charBudget = 0,
  });

  /// 片段类型（如 'canon_character', 'document_previous', 'compass'）
  final String type;

  /// 来源路径或来源 ID
  final String sourceId;

  /// 内容
  final String content;

  /// 优先级（1=最高，永不截断）
  final int priority;

  /// 是否受保护（不可被裁剪）
  final bool isProtected;

  /// 字符预算（0=无限制）
  final int charBudget;
}

/// 真实项目数据源
///
/// 从灵笔现有服务读取数据，组装为上下文片段。
/// 禁止把向量召回内容当作正典。
class ProjectDataSource implements ContextDataSource {
  ProjectDataSource({
    required DocumentService documentService,
    required CanonService canonService,
    required String projectId,
    this.currentDocumentId,
  })  : _documentService = documentService,
        _canonService = canonService,
        _projectId = projectId;

  final DocumentService _documentService;
  final CanonService _canonService;
  final String _projectId;
  final String? currentDocumentId;

  /// 市场情报上下文（由外部注入，如 MarketIntelService 生成的摘要）
  String marketContext = '';

  /// 收集到的来源追踪信息
  final List<ContextFragment> fragments = [];

  @override
  String getRecentText(String chapterId) {
    // 同步读取当前章节内容作为"上文"
    // 注意：这里使用同步方式，因为 ContextDataSource 接口是同步的
    // 实际数据在 assembleContext 前通过 prepare() 预加载
    return _recentTextCache;
  }

  String _recentTextCache = '';

  @override
  List<ChapterSummaryEntry> getChapterSummaries(String novelId) {
    return _chapterSummariesCache;
  }

  List<ChapterSummaryEntry> _chapterSummariesCache = [];

  @override
  List<String> getOutlineWindow(String chapterId) {
    return _outlineCache;
  }

  final List<String> _outlineCache = [];

  @override
  String getCurrentChapterSummary(String chapterId) {
    return _currentChapterSummaryCache;
  }

  final String _currentChapterSummaryCache = '';

  @override
  List<CharacterCard> getActiveCharacters(String chapterId) {
    return _charactersCache;
  }

  List<CharacterCard> _charactersCache = [];

  @override
  ForeshadowingState getForeshadowingState(String novelId) {
    // 本轮暂不实现伏笔追踪
    return const ForeshadowingState();
  }

  @override
  String getStyleProfile(String novelId) {
    return _styleCache;
  }

  final String _styleCache = '';

  @override
  WorldRules getWorldRules(String novelId) {
    return _worldRulesCache;
  }

  WorldRules _worldRulesCache = const WorldRules();

  @override
  String getCurrentState(String novelId) {
    return ''; // 本轮暂不实现运行态
  }

  @override
  String getLedger(String novelId) {
    return ''; // 本轮暂不实现资源账本
  }

  @override
  String getRelationships(String novelId) {
    return ''; // 本轮暂不实现关系账本
  }

  /// 预加载所有数据（异步，在 assemble 前调用）
  Future<void> prepare({
    String? currentDocId,
    String? previousDocId,
  }) async {
    fragments.clear();

    // 1. 读取当前章节内容
    if (currentDocId != null) {
      final doc = await _documentService.getDocument(currentDocId);
      if (doc != null) {
        final content = await _documentService.readContent(doc.filePath);
        _recentTextCache = content;
        fragments.add(ContextFragment(
          type: 'document_current',
          sourceId: doc.filePath,
          content: content,
          priority: 3,
          charBudget: 3000,
        ));
      }
    }

    // 2. 读取上一章节内容（用于连贯性）
    if (previousDocId != null) {
      final prevDoc = await _documentService.getDocument(previousDocId);
      if (prevDoc != null) {
        final prevContent =
            await _documentService.readContent(prevDoc.filePath);
        // 取最后 2000 字符作为上文
        final truncated = prevContent.length > 2000
            ? '…${prevContent.substring(prevContent.length - 2000)}'
            : prevContent;
        _recentTextCache = truncated;
        fragments.add(ContextFragment(
          type: 'document_previous',
          sourceId: prevDoc.filePath,
          content: truncated,
          priority: 3,
          charBudget: 2000,
        ));
      }
    }

    // 3. 读取 Canon 角色
    try {
      final characters =
          await _canonService.list(_projectId, CanonEntryType.character);
      _charactersCache = characters.map((entry) {
        return CharacterCard(
          name: entry.name,
          role: entry.attributes['role'] as String? ?? '',
          currentState: entry.attributes['status'] as String? ?? '',
          personality: entry.attributes['personality'] as String? ?? '',
          relationships: _extractRelationships(entry),
        );
      }).toList();

      for (final entry in characters) {
        fragments.add(ContextFragment(
          type: 'canon_character',
          sourceId: entry.id,
          content: '${entry.name}: ${entry.description}',
          priority: 6,
          charBudget: 200,
        ));
      }
    } catch (_) {
      _charactersCache = [];
    }

    // 4. 读取 Canon 世界规则（lore）
    try {
      final loreEntries =
          await _canonService.list(_projectId, CanonEntryType.lore);
      final constraints = loreEntries.map((e) => e.description).toList();
      final entities = <WorldEntity>[];

      // 读取地点
      final locations =
          await _canonService.list(_projectId, CanonEntryType.location);
      for (final loc in locations) {
        entities.add(WorldEntity(name: loc.name, description: loc.description));
        fragments.add(ContextFragment(
          type: 'canon_location',
          sourceId: loc.id,
          content: '${loc.name}: ${loc.description}',
          priority: 7,
          charBudget: 150,
        ));
      }

      _worldRulesCache = WorldRules(
        constraints: constraints,
        entities: entities,
      );

      for (final entry in loreEntries) {
        fragments.add(ContextFragment(
          type: 'canon_lore',
          sourceId: entry.id,
          content: entry.description,
          priority: 7,
          charBudget: 200,
        ));
      }
    } catch (_) {
      _worldRulesCache = const WorldRules();
    }

    // 5. 读取所有文档列表（用于章节摘要）
    try {
      final docs = await _documentService.getDocuments(_projectId);
      _chapterSummariesCache = docs
          .where((d) => d.id != currentDocId)
          .take(10)
          .map((d) => ChapterSummaryEntry(
                chapterId: d.id,
                title: d.title,
                summary: '${d.title} (${d.wordCount}字)',
              ))
          .toList();
    } catch (_) {
      _chapterSummariesCache = [];
    }

    // 6. 市场情报片段（低优先级，可被裁剪）
    if (marketContext.isNotEmpty) {
      fragments.add(ContextFragment(
        type: 'market_intel',
        sourceId: 'market_intel_service',
        content: marketContext,
        priority: 9,
        charBudget: 500,
      ));
    }
  }

  List<String> _extractRelationships(CanonEntry entry) {
    final rels = <String>[];
    final attrs = entry.attributes;
    if (attrs.containsKey('relationships')) {
      final r = attrs['relationships'];
      if (r is List) {
        rels.addAll(r.cast<String>());
      } else if (r is String && r.isNotEmpty) {
        rels.add(r);
      }
    }
    return rels;
  }
}
