/// 小说写作循环 — 对标 OpenWrite 的对话式 Agent 写作范式。
///
/// 这是一个**确定性编排器**（复刻 novel-writer 的固定 Step 流程），
/// 不依赖免费 API 的 function-calling 能力，因此在任何模型上都稳定：
///
///   1. 读维护文档（人物库 / 世界观 / 章节摘要）+ 最近若干章；
///   2. 经 [ContextCompiler] 压缩为预算内上下文（mandatory 优先）；
///   3. 调用 [AIProvider.chat] 流式生成"最少 N 字"新章节；
///   4. 走 [AiResponseNormalizer] 产出**候选正文**（不直接落盘）；
///   5. 用户确认（或 autoApprove）后经 [AtomicFileStore] 原子写入
///      `章节内容/第X章.md`；
///   6. 生成/更新 `章节摘要.md`（供下一章上下文）。
library;

import 'dart:io';

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/ai/ai_response_normalizer.dart';
import 'package:lingbi/shared/ai/model_registry.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/features/writing/data/context/context_compiler.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/features/review/data/version_history_service.dart';

/// 一个候选章节（尚未落盘）。
class ChapterCandidate {
  const ChapterCandidate({
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.chineseCharCount,
    required this.manifest,
    this.warnings = const [],
  });

  final int chapterNumber;
  final String title;
  final String content;
  final int chineseCharCount;
  final ContextManifest manifest;
  final List<String> warnings;

  /// 候选是否达到最小字数要求（由循环填充 [warnings]）。
  bool get isEmpty => content.trim().isEmpty;
}

/// 章节落盘结果。
class ChapterCommitResult {
  const ChapterCommitResult({
    required this.candidate,
    required this.chapterPath,
    required this.summaryPath,
  });

  final ChapterCandidate candidate;
  final String chapterPath;
  final String summaryPath;
}

/// 确认回调：返回 true 表示采纳并落盘。
typedef ChapterConfirm = Future<bool> Function(ChapterCandidate candidate);

class NovelWritingLoop {
  NovelWritingLoop({
    required this.provider,
    required this.projectDir,
    ContextCompiler? compiler,
    AtomicFileStore? store,
    this.canonService,
    this.projectId,
    this.recentChapterCount = 5,
    this.minChineseChars = 2000,
    this.versionHistoryService,
  })  : compiler = compiler ?? ContextCompiler(config: _configFor(provider)),
        store = store ?? AtomicFileStore();

  /// 依据 Provider 当前模型的上下文窗口推导编译预算（p6 动态扩容）。
  ///
  /// 内置模型有完整元数据时按窗口放大预算；未知模型回退默认 8000。
  static CompilerConfig _configFor(AIProvider provider) {
    final info = ModelRegistry.instance.findModel(provider.currentModelId);
    return CompilerConfig.forModel(
      contextWindow: info?.contextWindow,
      maxOutputTokens: info?.maxOutputTokens,
    );
  }

  final AIProvider provider;
  final String projectDir;
  final ContextCompiler compiler;
  final AtomicFileStore store;

  /// 可选：从 Canon（人物/世界观）拉取设定，增强 mandatory 上下文。
  final CanonService? canonService;
  final String? projectId;

  final int recentChapterCount;
  final int minChineseChars;

  /// 版本快照服务：commitChapter 写入前自动保存旧版本，支持回滚。
  final VersionHistoryService? versionHistoryService;

  String get _settingsDir => '$projectDir/小说资料';
  String get _chaptersDir => '$projectDir/章节内容';
  String get _summaryPath => '$_settingsDir/章节摘要.md';

  /// 生成下一章候选正文（不落盘）。
  Future<ChapterCandidate> proposeNextChapter({String? guidance}) async {
    final nextNumber = await _nextChapterNumber();
    final entries = await _gatherContext(nextNumber);
    final compiled = compiler.compile(entries, currentChapter: nextNumber);

    final messages = _buildMessages(
      compiledContext: compiled.text,
      chapterNumber: nextNumber,
      guidance: guidance,
    );

    final normalizer = AiResponseNormalizer(treatAllAsCandidate: true);
    final buffer = StringBuffer();
    final warnings = <String>[];
    await for (final event in normalizer.normalize(
      provider.chat(messages: messages, temperature: 0.8, maxTokens: 4096),
    )) {
      switch (event) {
        case NormalizerChunk(:final block):
          if (block.type == NormalizedBlockType.candidate ||
              block.type == NormalizedBlockType.answer) {
            buffer.write(block.text);
          } else if (block.type == NormalizedBlockType.warning) {
            warnings.add(block.text);
          }
        case NormalizerError(:final message):
          warnings.add(message);
        case NormalizerDone():
          break;
      }
    }

    final raw = buffer.toString().trim();
    final title = _extractTitle(raw, nextNumber);
    final charCount = _chineseCharCount(raw);
    if (charCount < minChineseChars) {
      warnings.add('本章仅 $charCount 中文字，低于最小要求 $minChineseChars 字。');
    }

    return ChapterCandidate(
      chapterNumber: nextNumber,
      title: title,
      content: raw,
      chineseCharCount: charCount,
      manifest: compiled.manifest,
      warnings: warnings,
    );
  }

  /// 采纳候选并原子落盘 `章节内容/第X章.md`，同时更新章节摘要。
  Future<ChapterCommitResult> commitChapter(ChapterCandidate candidate) async {
    final chapterPath = '$_chaptersDir/第${candidate.chapterNumber}章.md';
    final body = candidate.content.startsWith('#')
        ? candidate.content
        : '# 第${candidate.chapterNumber}章 ${candidate.title}\n\n${candidate.content}';
    // 写前版本快照：保存旧章节内容以支持回滚。
    await _saveSnapshot(chapterPath);
    await store.writeString(chapterPath, body);
    await _updateSummary(candidate);
    return ChapterCommitResult(
      candidate: candidate,
      chapterPath: chapterPath,
      summaryPath: _summaryPath,
    );
  }

  /// 端到端写一章：生成候选 → 确认 → 落盘。
  ///
  /// [autoApprove] 为 true 时无人值守直接落盘（供自动化测试连续生成）；
  /// 否则调用 [confirm]；两者都未通过则**不落盘**，返回 null。
  Future<ChapterCommitResult?> writeNextChapter({
    String? guidance,
    bool autoApprove = false,
    ChapterConfirm? confirm,
  }) async {
    final candidate = await proposeNextChapter(guidance: guidance);
    final approved = autoApprove || (confirm != null && await confirm(candidate));
    if (!approved) return null;
    return commitChapter(candidate);
  }

  // ─── 内部 ────────────────────────────────────────────────────

  Future<List<ContextEntry>> _gatherContext(int nextNumber) async {
    final entries = <ContextEntry>[];

    // 维护文档：人物库 / 世界观（mandatory，绝不被预算挤掉）。
    final characters = await store.readString('$_settingsDir/人物库.md');
    if (characters != null && characters.trim().isNotEmpty) {
      entries.add(ContextEntry(
        id: 'canon-characters',
        source: '人物库.md',
        reason: '主角与配角设定，保证跨章人物一致',
        timePoint: null,
        priority: ContextPriority.mandatory,
        content: characters,
      ));
    }
    final worldview = await store.readString('$_settingsDir/世界观.md');
    if (worldview != null && worldview.trim().isNotEmpty) {
      entries.add(ContextEntry(
        id: 'canon-worldview',
        source: '世界观.md',
        reason: '修炼体系/宗门/地理设定，保证术语一致',
        timePoint: null,
        priority: ContextPriority.mandatory,
        content: worldview,
      ));
    }

    // 可选：CanonService 中的人物/世界设定条目。
    if (canonService != null && projectId != null) {
      final canonText = await _canonAsText(projectId!);
      if (canonText.isNotEmpty) {
        entries.add(ContextEntry(
          id: 'canon-service',
          source: 'Canon 设定库',
          reason: '结构化人物/地点/世界设定',
          timePoint: null,
          priority: ContextPriority.mandatory,
          content: canonText,
        ));
      }
    }

    // 章节摘要（high）。
    final summary = await store.readString(_summaryPath);
    if (summary != null && summary.trim().isNotEmpty) {
      entries.add(ContextEntry(
        id: 'chapter-summaries',
        source: '章节摘要.md',
        reason: '前情提要，衔接剧情',
        timePoint: nextNumber - 1,
        priority: ContextPriority.high,
        content: summary,
      ));
    }

    // 最近若干章正文（recency 加分）。
    final recent = await _recentChapters(nextNumber);
    for (final chapter in recent) {
      entries.add(ContextEntry(
        id: 'chapter-${chapter.number}',
        source: '第${chapter.number}章.md',
        reason: '最近章节原文，保持文风与细节连贯',
        timePoint: chapter.number,
        priority: ContextPriority.high,
        content: chapter.content,
      ));
    }

    return entries;
  }

  Future<String> _canonAsText(String projectId) async {
    try {
      final all = await canonService!.getAllForProject(projectId);
      final parts = <String>[];
      all.forEach((type, list) {
        if (list.isEmpty) return;
        parts.add('## ${_canonTypeLabel(type)}');
        for (final e in list) {
          parts.add('- ${e.name}：${e.description}');
        }
      });
      return parts.join('\n');
    } catch (_) {
      return '';
    }
  }

  String _canonTypeLabel(CanonEntryType type) => switch (type) {
        CanonEntryType.character => '人物',
        CanonEntryType.location => '地点',
        CanonEntryType.lore => '设定',
        CanonEntryType.plotNode => '情节',
      };

  List<ChatMessage> _buildMessages({
    required String compiledContext,
    required int chapterNumber,
    String? guidance,
  }) {
    final system = StringBuffer()
      ..writeln('你是一位专业的中文网络小说连载作家，正在续写一部长篇小说。')
      ..writeln('请严格遵守以下要求：')
      ..writeln('1. 只输出【第$chapterNumber章】的正文，不要解释、不要大纲、不要总结。')
      ..writeln('2. 第一行用「# 第$chapterNumber章 标题」给出本章标题。')
      ..writeln('3. 正文不少于 $minChineseChars 个中文字，情节完整、有推进。')
      ..writeln('4. 严格沿用下方设定中的主角姓名、修炼体系与专有名词，保持前后一致。')
      ..writeln('5. 与最近章节自然衔接，不要重复已发生的情节。');
    if (compiledContext.trim().isNotEmpty) {
      system
        ..writeln()
        ..writeln('———— 已有设定与前情（务必遵循）————')
        ..writeln(compiledContext);
    }

    final user = StringBuffer()
      ..write('请续写第 $chapterNumber 章。');
    if (guidance != null && guidance.trim().isNotEmpty) {
      user.write('本章写作要求：${guidance.trim()}');
    }

    return [
      ChatMessage(role: 'system', content: system.toString()),
      ChatMessage(role: 'user', content: user.toString()),
    ];
  }

  Future<void> _updateSummary(ChapterCandidate candidate) async {
    final existing = await store.readString(_summaryPath) ?? '# 章节摘要\n';
    final excerpt = _excerpt(candidate.content);
    final line = '\n## 第${candidate.chapterNumber}章 ${candidate.title}\n'
        '（约${candidate.chineseCharCount}字）$excerpt\n';
    await store.writeString(_summaryPath, '$existing$line');
  }

  String _excerpt(String content) {
    final plain = content
        .replaceAll(RegExp(r'^#.*$', multiLine: true), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    if (plain.length <= 140) return plain;
    return '${plain.substring(0, 140)}…';
  }

  Future<int> _nextChapterNumber() async {
    final dir = Directory(_chaptersDir);
    if (!await dir.exists()) return 1;
    var maxNumber = 0;
    final pattern = RegExp(r'第(\d+)章\.md$');
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final match = pattern.firstMatch(entity.path.replaceAll(r'\', '/'));
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNumber) maxNumber = n;
      }
    }
    return maxNumber + 1;
  }

  Future<List<_Chapter>> _recentChapters(int nextNumber) async {
    final chapters = <_Chapter>[];
    final start = (nextNumber - recentChapterCount).clamp(1, nextNumber);
    for (var n = start; n < nextNumber; n++) {
      final content = await store.readString('$_chaptersDir/第$n章.md');
      if (content != null && content.trim().isNotEmpty) {
        chapters.add(_Chapter(number: n, content: content));
      }
    }
    return chapters;
  }

  String _extractTitle(String content, int number) {
    final firstLine = content.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    final match = RegExp(r'^#+\s*第\d+章\s*(.*)$').firstMatch(firstLine.trim());
    if (match != null && match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    return '第$number章';
  }

  /// 统计中文字数（CJK 统一表意文字）。
  static int _chineseCharCount(String text) {
    var count = 0;
    for (final code in text.runes) {
      if (code >= 0x4E00 && code <= 0x9FFF ||
          code >= 0x3400 && code <= 0x4DBF ||
          code >= 0xF900 && code <= 0xFAFF) {
        count++;
      }
    }
    return count;
  }

  /// 写前快照：若目标文件已存在且 versionHistoryService 可用，保存旧版本。
  Future<void> _saveSnapshot(String relativePath) async {
    final svc = versionHistoryService;
    if (svc == null) return;
    try {
      final oldContent = await store.readString(relativePath);
      if (oldContent == null || oldContent.trim().isEmpty) return;
      await svc.saveVersion(
        projectDir: projectDir,
        docId: relativePath,
        content: oldContent,
        summary: 'commitChapter 写前快照',
      );
    } catch (_) {
      // 快照失败不阻塞写入（非关键路径）。
    }
  }
}

class _Chapter {
  const _Chapter({required this.number, required this.content});
  final int number;
  final String content;
}
