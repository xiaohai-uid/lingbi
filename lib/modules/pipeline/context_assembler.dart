/// 上下文组装器 (Context Assembler)
///
/// 借鉴 OpenWrite ContextBuilder / canonical_packet 设计思想。
/// 负责在每次 AI 生成前，从各数据源收集信息，
/// 组装成完整的 GenerationContext，并执行 token 预算裁剪。
library;

import 'generation_context.dart';
import 'creative_compass.dart';

/// 上下文组装配置
class AssemblerConfig {
  const AssemblerConfig({
    this.tokenBudget = 8000,
    this.recentTextMaxChars = 3000,
    this.chapterSummaryMaxChars = 200,
    this.maxOutlineNodes = 5,
    this.maxCharacters = 8,
    this.maxForeshadowing = 10,
    this.styleProfileMaxChars = 500,
  });

  /// 总 token 预算
  final int tokenBudget;

  /// 上文最大字符数
  final int recentTextMaxChars;

  /// 每章摘要最大字符数
  final int chapterSummaryMaxChars;

  /// 大纲窗口最大节点数
  final int maxOutlineNodes;

  /// 最大出场角色数
  final int maxCharacters;

  /// 最大伏笔条目数
  final int maxForeshadowing;

  /// 风格档案最大字符数
  final int styleProfileMaxChars;
}

/// 数据源接口（由外部注入具体实现）
abstract class ContextDataSource {
  /// 获取最近章节文本
  String getRecentText(String chapterId);

  /// 获取章节摘要列表
  List<ChapterSummaryEntry> getChapterSummaries(String novelId);

  /// 获取大纲窗口
  List<String> getOutlineWindow(String chapterId);

  /// 获取当前章节大纲摘要
  String getCurrentChapterSummary(String chapterId);

  /// 获取出场角色
  List<CharacterCard> getActiveCharacters(String chapterId);

  /// 获取伏笔状态
  ForeshadowingState getForeshadowingState(String novelId);

  /// 获取风格档案
  String getStyleProfile(String novelId);

  /// 获取世界观规则
  WorldRules getWorldRules(String novelId);

  /// 获取世界当前状态
  String getCurrentState(String novelId);

  /// 获取资源账本
  String getLedger(String novelId);

  /// 获取角色关系
  String getRelationships(String novelId);
}

/// 章节摘要条目
class ChapterSummaryEntry {
  const ChapterSummaryEntry({
    required this.chapterId,
    required this.title,
    required this.summary,
  });

  final String chapterId;
  final String title;
  final String summary;
}

/// 上下文组装器
///
/// 使用方式：
/// ```dart
/// final assembler = ContextAssembler(
///   projectDir: '/path/to/project',
///   dataSource: MyDataSource(),
/// );
/// final context = assembler.assemble(
///   novelId: 'novel_001',
///   chapterId: 'ch_005',
///   userInstruction: '让主角在此章发现真相',
/// );
/// final prompt = context.toPromptContext();
/// ```
class ContextAssembler {
  ContextAssembler({
    required String projectDir,
    required ContextDataSource dataSource,
    AssemblerConfig config = const AssemblerConfig(),
  })  : _dataSource = dataSource,
        _config = config,
        _compassStore = CreativeCompassStore(projectDir: projectDir);

  final ContextDataSource _dataSource;
  final AssemblerConfig _config;
  final CreativeCompassStore _compassStore;

  /// 组装完整的生成上下文
  ///
  /// 组装顺序（优先级从高到低）：
  /// 1. 作者意图 + 当前焦点（永不截断）
  /// 2. 用户临时指令（永不截断）
  /// 3. 上文（连贯性）
  /// 4. 章节摘要（记忆）
  /// 5. 大纲窗口
  /// 6. 角色卡片
  /// 7. 伏笔
  /// 8. 风格
  /// 9. 世界观
  /// 10. 运行态（状态/账本/关系）
  GenerationContext assemble({
    required String novelId,
    required String chapterId,
    String userInstruction = '',
    List<String> chapterGoals = const [],
    int targetWords = 6000,
    String emotionArc = '',
    List<String> spoilerBlacklist = const [],
    String marketContext = '',
  }) {
    // 1. 创作罗盘（永不截断）
    final compass = _compassStore.loadOrCreate();

    // 2. 收集各数据源
    final recentText = _truncate(
      _dataSource.getRecentText(chapterId),
      _config.recentTextMaxChars,
    );

    final summaries = _dataSource.getChapterSummaries(novelId);
    final chapterSummariesText = _formatSummaries(summaries);

    final outlineWindow = _dataSource
        .getOutlineWindow(chapterId)
        .take(_config.maxOutlineNodes)
        .toList();

    final currentChapterSummary =
        _dataSource.getCurrentChapterSummary(chapterId);

    final characters = _dataSource
        .getActiveCharacters(chapterId)
        .take(_config.maxCharacters)
        .toList();

    final foreshadowing = _dataSource.getForeshadowingState(novelId);

    final styleProfile = _truncate(
      _dataSource.getStyleProfile(novelId),
      _config.styleProfileMaxChars,
    );

    final worldRules = _dataSource.getWorldRules(novelId);
    final currentState = _dataSource.getCurrentState(novelId);
    final ledger = _dataSource.getLedger(novelId);
    final relationships = _dataSource.getRelationships(novelId);

    // 3. 组装
    var context = GenerationContext(
      novelId: novelId,
      chapterId: chapterId,
      authorIntent: compass.authorIntent.toPromptText(),
      creativeFocus: compass.currentFocus.toPromptText(),
      chapterGoals: chapterGoals,
      targetWords: targetWords,
      emotionArc: emotionArc,
      outlineWindow: outlineWindow,
      currentChapterSummary: currentChapterSummary,
      activeCharacters: characters,
      foreshadowing: foreshadowing,
      styleProfile: styleProfile,
      worldRules: worldRules,
      recentText: recentText,
      currentState: currentState,
      ledger: ledger,
      relationships: relationships,
      chapterSummaries: chapterSummariesText,
      userInstruction: userInstruction,
      spoilerBlacklist: spoilerBlacklist,
      tokenBudget: _config.tokenBudget,
      marketContext: marketContext,
    );

    // 4. Token 预算裁剪
    context = _applyTokenBudget(context);

    return context;
  }

  /// 格式化章节摘要
  String _formatSummaries(List<ChapterSummaryEntry> summaries) {
    if (summaries.isEmpty) return '';
    final parts = <String>[];
    for (final s in summaries) {
      final summary = s.summary.length > _config.chapterSummaryMaxChars
          ? '${s.summary.substring(0, _config.chapterSummaryMaxChars)}…'
          : s.summary;
      parts.add('${s.title}: $summary');
    }
    return parts.join('\n');
  }

  /// 截断文本
  String _truncate(String text, int maxChars) {
    if (maxChars <= 0 || text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }

  /// 应用 token 预算裁剪
  ///
  /// 裁剪优先级（从低到高，先裁低优先级）：
  /// 1. 资源账本
  /// 2. 角色关系
  /// 3. 世界当前状态
  /// 4. 章节摘要
  /// 5. 伏笔
  /// 6. 角色卡片
  /// 7. 大纲窗口
  /// 8. 上文
  /// 永不截断：作者意图、当前焦点、用户指令
  GenerationContext _applyTokenBudget(GenerationContext context) {
    if (context.estimateTokens() <= context.tokenBudget) {
      return context;
    }

    // 逐步裁剪低优先级内容
    var result = context;

    // 裁剪账本
    if (result.estimateTokens() > result.tokenBudget &&
        result.ledger.isNotEmpty) {
      result = GenerationContext(
        novelId: result.novelId,
        chapterId: result.chapterId,
        authorIntent: result.authorIntent,
        creativeFocus: result.creativeFocus,
        chapterGoals: result.chapterGoals,
        targetWords: result.targetWords,
        emotionArc: result.emotionArc,
        outlineWindow: result.outlineWindow,
        currentChapterSummary: result.currentChapterSummary,
        activeCharacters: result.activeCharacters,
        foreshadowing: result.foreshadowing,
        styleProfile: result.styleProfile,
        worldRules: result.worldRules,
        recentText: result.recentText,
        currentState: result.currentState,
        ledger: '',
        relationships: result.relationships,
        chapterSummaries: result.chapterSummaries,
        userInstruction: result.userInstruction,
        spoilerBlacklist: result.spoilerBlacklist,
        tokenBudget: result.tokenBudget,
      );
    }

    // 裁剪角色关系
    if (result.estimateTokens() > result.tokenBudget &&
        result.relationships.isNotEmpty) {
      result = GenerationContext(
        novelId: result.novelId,
        chapterId: result.chapterId,
        authorIntent: result.authorIntent,
        creativeFocus: result.creativeFocus,
        chapterGoals: result.chapterGoals,
        targetWords: result.targetWords,
        emotionArc: result.emotionArc,
        outlineWindow: result.outlineWindow,
        currentChapterSummary: result.currentChapterSummary,
        activeCharacters: result.activeCharacters,
        foreshadowing: result.foreshadowing,
        styleProfile: result.styleProfile,
        worldRules: result.worldRules,
        recentText: result.recentText,
        currentState: result.currentState,
        ledger: result.ledger,
        relationships: '',
        chapterSummaries: result.chapterSummaries,
        userInstruction: result.userInstruction,
        spoilerBlacklist: result.spoilerBlacklist,
        tokenBudget: result.tokenBudget,
      );
    }

    // 裁剪章节摘要（保留最近 3 章）
    if (result.estimateTokens() > result.tokenBudget &&
        result.chapterSummaries.isNotEmpty) {
      final lines = result.chapterSummaries.split('\n');
      final trimmed = lines.length > 3
          ? lines.sublist(lines.length - 3).join('\n')
          : result.chapterSummaries;
      result = GenerationContext(
        novelId: result.novelId,
        chapterId: result.chapterId,
        authorIntent: result.authorIntent,
        creativeFocus: result.creativeFocus,
        chapterGoals: result.chapterGoals,
        targetWords: result.targetWords,
        emotionArc: result.emotionArc,
        outlineWindow: result.outlineWindow,
        currentChapterSummary: result.currentChapterSummary,
        activeCharacters: result.activeCharacters,
        foreshadowing: result.foreshadowing,
        styleProfile: result.styleProfile,
        worldRules: result.worldRules,
        recentText: result.recentText,
        currentState: result.currentState,
        ledger: result.ledger,
        relationships: result.relationships,
        chapterSummaries: trimmed,
        userInstruction: result.userInstruction,
        spoilerBlacklist: result.spoilerBlacklist,
        tokenBudget: result.tokenBudget,
      );
    }

    // 裁剪上文（保留最后 1500 字符）
    if (result.estimateTokens() > result.tokenBudget &&
        result.recentText.length > 1500) {
      result = GenerationContext(
        novelId: result.novelId,
        chapterId: result.chapterId,
        authorIntent: result.authorIntent,
        creativeFocus: result.creativeFocus,
        chapterGoals: result.chapterGoals,
        targetWords: result.targetWords,
        emotionArc: result.emotionArc,
        outlineWindow: result.outlineWindow,
        currentChapterSummary: result.currentChapterSummary,
        activeCharacters: result.activeCharacters,
        foreshadowing: result.foreshadowing,
        styleProfile: result.styleProfile,
        worldRules: result.worldRules,
        recentText:
            '…${result.recentText.substring(result.recentText.length - 1500)}',
        currentState: result.currentState,
        ledger: result.ledger,
        relationships: result.relationships,
        chapterSummaries: result.chapterSummaries,
        userInstruction: result.userInstruction,
        spoilerBlacklist: result.spoilerBlacklist,
        tokenBudget: result.tokenBudget,
      );
    }

    return result;
  }
}

/// 空数据源（用于测试或降级模式）
class EmptyDataSource implements ContextDataSource {
  const EmptyDataSource();

  @override
  String getRecentText(String chapterId) => '';

  @override
  List<ChapterSummaryEntry> getChapterSummaries(String novelId) => [];

  @override
  List<String> getOutlineWindow(String chapterId) => [];

  @override
  String getCurrentChapterSummary(String chapterId) => '';

  @override
  List<CharacterCard> getActiveCharacters(String chapterId) => [];

  @override
  ForeshadowingState getForeshadowingState(String novelId) =>
      const ForeshadowingState();

  @override
  String getStyleProfile(String novelId) => '';

  @override
  WorldRules getWorldRules(String novelId) => const WorldRules();

  @override
  String getCurrentState(String novelId) => '';

  @override
  String getLedger(String novelId) => '';

  @override
  String getRelationships(String novelId) => '';
}
