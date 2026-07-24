/// 书籍状态追踪
///
/// 借鉴 OpenWrite BookState + BookStage 设计思想。
/// 追踪整本书的写作进度和当前阶段。
library;

import 'dart:convert';
import 'dart:io';

/// 书籍阶段
enum BookStage {
  /// 初始规划
  planning,

  /// 章节预检（准备写下一章）
  chapterPreflight,

  /// 写作中
  writing,

  /// 审稿与修订
  reviewAndRevise,

  /// 结算中
  settling,

  /// 已完成
  completed,
}

/// 书籍状态
class BookState {
  BookState({
    this.novelId = '',
    this.title = '',
    this.currentChapter = '',
    this.currentArc = 'arc_001',
    this.stage = BookStage.planning,
    this.blockingReason = '',
    this.lastAgentAction = '',
    this.totalChapters = 0,
    this.totalWords = 0,
    this.lastUpdated,
  });

  String novelId;
  String title;
  String currentChapter;
  String currentArc;
  BookStage stage;
  String blockingReason;
  String lastAgentAction;
  int totalChapters;
  int totalWords;
  DateTime? lastUpdated;

  Map<String, dynamic> toJson() => {
        'novel_id': novelId,
        'title': title,
        'current_chapter': currentChapter,
        'current_arc': currentArc,
        'stage': stage.name,
        'blocking_reason': blockingReason,
        'last_agent_action': lastAgentAction,
        'total_chapters': totalChapters,
        'total_words': totalWords,
        if (lastUpdated != null)
          'last_updated': lastUpdated!.toIso8601String(),
      };

  factory BookState.fromJson(Map<String, dynamic> json) => BookState(
        novelId: json['novel_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        currentChapter: json['current_chapter'] as String? ?? '',
        currentArc: json['current_arc'] as String? ?? 'arc_001',
        stage: BookStage.values.firstWhere(
          (s) => s.name == json['stage'],
          orElse: () => BookStage.planning,
        ),
        blockingReason: json['blocking_reason'] as String? ?? '',
        lastAgentAction: json['last_agent_action'] as String? ?? '',
        totalChapters: json['total_chapters'] as int? ?? 0,
        totalWords: json['total_words'] as int? ?? 0,
        lastUpdated: json['last_updated'] != null
            ? DateTime.parse(json['last_updated'] as String)
            : null,
      );
}

/// 书籍状态存储服务
///
/// 持久化到 {projectDir}/.lingbi/runtime/book_state.json
class BookStateStore {
  BookStateStore({required String projectDir})
      : _stateFile =
            File('$projectDir/.lingbi/runtime/book_state.json');

  final File _stateFile;

  /// 加载或创建书籍状态
  BookState loadOrCreate({String novelId = '', String title = ''}) {
    if (_stateFile.existsSync()) {
      try {
        final json = jsonDecode(_stateFile.readAsStringSync())
            as Map<String, dynamic>;
        return BookState.fromJson(json);
      } catch (_) {
        // 文件损坏，创建新的
      }
    }
    return BookState(novelId: novelId, title: title);
  }

  /// 保存书籍状态
  void save(BookState state) {
    state.lastUpdated = DateTime.now();
    _stateFile.parent.createSync(recursive: true);
    _stateFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(state.toJson()),
    );
  }

  /// 更新当前章节和阶段
  void updateProgress({
    required String chapterId,
    BookStage? stage,
    String? action,
    String? blockingReason,
  }) {
    final state = loadOrCreate();
    state.currentChapter = chapterId;
    if (stage != null) state.stage = stage;
    if (action != null) state.lastAgentAction = action;
    if (blockingReason != null) state.blockingReason = blockingReason;
    save(state);
  }

  /// 标记审稿通过，准备写下一章
  void markReviewPassed(String chapterId) {
    updateProgress(
      chapterId: chapterId,
      stage: BookStage.chapterPreflight,
      action: 'review_passed',
      blockingReason: '',
    );
  }

  /// 标记审稿未通过，需要修订
  void markReviewFailed(String chapterId, String reason) {
    updateProgress(
      chapterId: chapterId,
      stage: BookStage.reviewAndRevise,
      action: 'review_failed',
      blockingReason: reason,
    );
  }
}
