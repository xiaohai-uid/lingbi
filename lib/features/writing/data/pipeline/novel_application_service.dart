/// 小说写作应用服务 — 统一编排入口
///
/// UI 不得直接编排 ContextAssembler、CandidateService、BookState、WriteLockService。
/// 所有写作流水线操作通过本服务完成。
library;

import 'dart:convert';
import 'dart:io';

import 'package:lingbi/shared/ai/ai_provider.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:lingbi/features/canon/data/canon_service.dart';
import 'package:lingbi/services/document_service.dart';
import 'package:lingbi/features/skill/data/market_intel_service.dart';

import 'book_state.dart';
import 'candidate_service.dart';
import 'context_assembler.dart';
import 'generation_context.dart';
import 'project_data_source.dart';
import 'write_lock_service.dart';
import 'writing_pipeline_state.dart';

/// 操作结果
class PipelineResult<T> {
  const PipelineResult.success(this.data) : error = null;
  const PipelineResult.failure(this.error) : data = null;

  final T? data;
  final PipelineError? error;
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// 流水线错误
class PipelineError {
  const PipelineError(this.code, this.message);

  final String code;
  final String message;

  /// 源版本冲突：候选生成后章节被人工编辑
  static const sourceVersionConflict = 'SOURCE_VERSION_CONFLICT';
  static const projectBusy = 'PROJECT_BUSY';
  static const settlementFailed = 'SETTLEMENT_FAILED';
  static const notSettled = 'NOT_SETTLED';
  static const aiError = 'AI_ERROR';
  static const writeError = 'WRITE_ERROR';
  static const invalidState = 'INVALID_STATE';

  @override
  String toString() => 'PipelineError($code): $message';
}

/// 章节写作准备结果
class ChapterWritePreparation {
  const ChapterWritePreparation({
    required this.context,
    required this.fragments,
    required this.sourceVersion,
    required this.bookState,
  });

  final GenerationContext context;
  final List<ContextFragment> fragments;
  final String sourceVersion;
  final BookState bookState;
}

/// 结算建议条目
class SettlementItem {
  const SettlementItem({
    required this.category,
    required this.description,
    this.entityId,
    this.entityName,
  });

  factory SettlementItem.fromJson(Map<String, dynamic> json) => SettlementItem(
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        entityId: json['entity_id'] as String?,
        entityName: json['entity_name'] as String?,
      );

  /// 类别: character_position, item_change, relationship_change,
  /// new_character, new_rule, new_foreshadowing, foreshadowing_resolved,
  /// plotline_change
  final String category;
  final String description;
  final String? entityId;
  final String? entityName;

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
        if (entityId != null) 'entity_id': entityId,
        if (entityName != null) 'entity_name': entityName,
      };
}

/// 结算建议
class SettlementProposal {
  SettlementProposal({
    required this.id,
    required this.chapterId,
    required this.candidateId,
    required this.items,
    this.status = 'pending',
    this.createdAt,
  });

  factory SettlementProposal.fromJson(Map<String, dynamic> json) =>
      SettlementProposal(
        id: json['id'] as String? ?? '',
        chapterId: json['chapter_id'] as String? ?? '',
        candidateId: json['candidate_id'] as String? ?? '',
        items: (json['items'] as List? ?? [])
            .map((i) => SettlementItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String chapterId;
  final String candidateId;
  final List<SettlementItem> items;
  String status; // pending, confirmed, rejected, failed
  DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter_id': chapterId,
        'candidate_id': candidateId,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

/// 小说写作应用服务
///
/// 统一编排：上下文组装 → AI 生成 → 候选管理 → 安全采纳 → 结算建议
class NovelApplicationService {
  NovelApplicationService({
    required String projectDir,
    required String projectId,
    required DocumentService documentService,
    required CanonService canonService,
    required AIService aiService,
    MutationProtocol? mutationProtocol,
  })  : _mutationProtocol = mutationProtocol,
        _projectDir = projectDir,
        _projectId = projectId,
        _documentService = documentService,
        _canonService = canonService,
        _aiService = aiService,
        _candidateService = CandidateService(
          projectDir: projectDir,
          mutationProtocol: mutationProtocol,
          projectId: projectId,
        ),
        _writeLock = WriteLockService(projectDir: projectDir),
        _bookStateStore = BookStateStore(projectDir: projectDir),
        _stateMachine = WritingPipelineStateMachine(projectDir: projectDir),
        _settlementDir = Directory('$projectDir/.lingbi/settlements'),
        _snapshotDir = Directory('$projectDir/.lingbi/snapshots');

  final String _projectDir;
  final String _projectId;
  final MutationProtocol? _mutationProtocol;
  final DocumentService _documentService;
  final CanonService _canonService;
  final AIService _aiService;
  final CandidateService _candidateService;
  final WriteLockService _writeLock;
  final BookStateStore _bookStateStore;
  final WritingPipelineStateMachine _stateMachine;
  final Directory _settlementDir;
  final Directory _snapshotDir;

  /// 当前流水线阶段
  PipelineStage get currentStage =>
      _stateMachine.activeWorkflow?.currentStage ?? PipelineStage.idle;

  /// 是否空闲
  bool get isIdle => _stateMachine.isIdle;

  /// 是否忙碌
  bool get isBusy => _stateMachine.isBusy;

  /// Cancel the provider request used by a recoverable workflow.
  Future<void> cancelGeneration() async {
    _aiService.currentProvider.cancel();
  }

  // ─── 1. 准备章节写作 ───────────────────────────────────────────

  /// 准备章节写作：组装上下文，记录源版本
  ///
  /// 返回上下文包 + 来源追踪 + 源文件版本（用于后续冲突检测）
  Future<PipelineResult<ChapterWritePreparation>> prepareChapterWrite({
    required String chapterId,
    String? previousChapterId,
    String userInstruction = '',
  }) async {
    try {
      // 检查是否有未结算的章节阻止写作
      final bookState = _bookStateStore.loadOrCreate();
      if (bookState.blockingReason.isNotEmpty &&
          bookState.stage == BookStage.settling) {
        return const PipelineResult.failure(PipelineError(
          PipelineError.notSettled,
          '上一章尚未完成结算，请先处理结算或重试结算',
        ));
      }

      // 启动状态机
      _stateMachine.startWorkflow(chapterId);

      // 创建真实数据源并预加载
      final dataSource = ProjectDataSource(
        documentService: _documentService,
        canonService: _canonService,
        projectId: _projectId,
        currentDocumentId: chapterId,
      );
      await dataSource.prepare(
        currentDocId: chapterId,
        previousDocId: previousChapterId,
      );

      // 组装上下文
      final assembler = ContextAssembler(
        projectDir: _projectDir,
        dataSource: dataSource,
      );

      // 加载市场情报上下文（P1.7：自动注入 marketContext）
      final marketContext = await _loadMarketContext();

      final context = assembler.assemble(
        novelId: _projectId,
        chapterId: chapterId,
        userInstruction: userInstruction,
        marketContext: marketContext,
      );

      // 记录源版本（文件修改时间 + 大小作为版本标识）
      final sourceVersion = await _getSourceVersion(chapterId);

      // 更新 BookState
      _bookStateStore.updateProgress(
        chapterId: chapterId,
        stage: BookStage.chapterPreflight,
        action: 'prepare_chapter_write',
      );

      // 推进状态机
      _stateMachine.advance(PipelineStage.writing,
          message: 'context assembled');

      return PipelineResult.success(ChapterWritePreparation(
        context: context,
        fragments: dataSource.fragments,
        sourceVersion: sourceVersion,
        bookState: bookState,
      ));
    } catch (e) {
      _stateMachine.failAndRollback(e.toString());
      return PipelineResult.failure(PipelineError(
        PipelineError.invalidState,
        '准备失败: $e',
      ));
    }
  }

  /// 加载市场情报上下文（从本地缓存）
  ///
  /// 尝试读取项目的 targetPlatform/genre 对应的市场快照，
  /// 生成摘要文本注入 AI prompt。失败时静默返回空字符串。
  Future<String> _loadMarketContext() async {
    try {
      final marketService = ServiceLocator.instance.marketIntelService;
      // 从项目配置读取平台和题材（存储在项目目录 .lingbi/project.json）
      final projectFile = File('$_projectDir/.lingbi/project.json');
      String platform = '';
      String genre = '';
      if (await projectFile.exists()) {
        final data = jsonDecode(await projectFile.readAsString())
            as Map<String, dynamic>;
        platform = data['targetPlatform'] as String? ?? '';
        genre = data['genre'] as String? ?? '';
      }
      if (platform.isEmpty && genre.isEmpty) return '';
      final snapshot = await marketService.loadCache(
        platform.isEmpty ? '起点' : platform,
        genre.isEmpty ? '玄幻' : genre,
      );
      return MarketIntelService.buildContextSummary(snapshot);
    } catch (_) {
      return '';
    }
  }

  // ─── 2. 生成候选 ───────────────────────────────────────────────

  /// 生成候选正文（流式）
  ///
  /// AI 输出只写入候选区，不修改正式章节/Canon/BookState。
  /// 返回候选 ID 和流式内容。
  Stream<PipelineResult<String>> generateCandidate({
    required String chapterId,
    required GenerationContext context,
    required String sourceVersion,
    double temperature = 0.8,
    int maxTokens = 4096,
  }) async* {
    try {
      // 构建 prompt
      final promptSections = context.toPromptSections();
      final systemPrompt = promptSections.values.join('\n\n');
      final userPrompt = context.userInstruction.isNotEmpty
          ? context.userInstruction
          : '请根据以上上下文续写本章内容，约${context.targetWords}字。';

      // 创建空候选（流式填充）
      final candidate = _candidateService.createCandidate(
        chapterId: chapterId,
        content: '',
        model: _aiService.currentProviderName,
        metadata: {'source_version': sourceVersion},
      );

      final buffer = StringBuffer();

      // 调用 AIService 流式生成
      final messages = [
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(role: 'user', content: userPrompt),
      ];

      await for (final chunk in _aiService.currentProvider.chat(
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      )) {
        buffer.write(chunk);
        yield PipelineResult.success(chunk);
      }

      // 保存完整候选内容
      candidate.content = buffer.toString();
      candidate.status = CandidateStatus.pending;
      _saveCandidate(candidate);

      // 推进状态机到 awaitingAdoption（跳过 reviewing，本轮无审稿 Agent）
      _stateMachine.advance(PipelineStage.reviewing,
          message: 'generation done');
      _stateMachine.advance(PipelineStage.awaitingAdoption,
          message: 'candidate ready');

      // 更新 BookState
      _bookStateStore.updateProgress(
        chapterId: chapterId,
        stage: BookStage.reviewAndRevise,
        action: 'candidate_generated',
      );
    } catch (e) {
      _stateMachine.failAndRollback(e.toString());
      yield PipelineResult.failure(PipelineError(
        PipelineError.aiError,
        'AI 生成失败: $e',
      ));
    }
  }

  /// 生成候选正文（非流式，一次性返回）
  Future<PipelineResult<CandidateEntry>> generateCandidateSync({
    required String chapterId,
    required GenerationContext context,
    required String sourceVersion,
    double temperature = 0.8,
    int maxTokens = 4096,
  }) async {
    try {
      final promptSections = context.toPromptSections();
      final systemPrompt = promptSections.values.join('\n\n');
      final userPrompt = context.userInstruction.isNotEmpty
          ? context.userInstruction
          : '请根据以上上下文续写本章内容，约${context.targetWords}字。';

      final messages = [
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(role: 'user', content: userPrompt),
      ];

      final result = await _aiService.currentProvider.chatSync(
        messages: messages,
        maxTokens: maxTokens,
      );

      final candidate = _candidateService.createCandidate(
        chapterId: chapterId,
        content: result,
        model: _aiService.currentProviderName,
        metadata: {'source_version': sourceVersion},
      );

      // 推进状态机
      if (_stateMachine.activeWorkflow?.currentStage == PipelineStage.writing) {
        _stateMachine.advance(PipelineStage.reviewing,
            message: 'generation done');
        _stateMachine.advance(PipelineStage.awaitingAdoption,
            message: 'candidate ready');
      }

      _bookStateStore.updateProgress(
        chapterId: chapterId,
        stage: BookStage.reviewAndRevise,
        action: 'candidate_generated',
      );

      return PipelineResult.success(candidate);
    } catch (e) {
      _stateMachine.failAndRollback(e.toString());
      return PipelineResult.failure(PipelineError(
        PipelineError.aiError,
        'AI 生成失败: $e',
      ));
    }
  }

  // ─── 3. 获取候选 ───────────────────────────────────────────────

  /// 获取候选详情
  CandidateEntry? getCandidate(String candidateId) {
    return _candidateService.getCandidate(candidateId);
  }

  /// 列出章节候选
  List<CandidateEntry> listCandidates(String chapterId) {
    return _candidateService.listCandidates(chapterId);
  }

  // ─── 4. 拒绝候选 ───────────────────────────────────────────────

  /// 拒绝候选（不修改正文）
  PipelineResult<void> rejectCandidate(String candidateId, {String? reason}) {
    try {
      _candidateService.reject(candidateId, reason: reason);

      // 推进状态机
      if (_stateMachine.activeWorkflow != null &&
          _stateMachine.canTransition(
              _stateMachine.activeWorkflow!.currentStage,
              PipelineStage.rejected)) {
        _stateMachine.advance(PipelineStage.rejected, message: 'user rejected');
        _stateMachine.advance(PipelineStage.idle, message: 'reset');
      }

      return const PipelineResult.success(null);
    } catch (e) {
      return PipelineResult.failure(PipelineError(
        PipelineError.invalidState,
        '拒绝失败: $e',
      ));
    }
  }

  // ─── 5. 安全采纳 ───────────────────────────────────────────────

  /// 安全采纳候选
  ///
  /// 步骤：获取写锁 → 校验源版本 → 创建快照 → 写临时文件 → 原子替换
  ///       → 更新候选状态 → 更新 BookState → 释放写锁
  Future<PipelineResult<String>> adoptCandidate({
    required String candidateId,
    required String chapterId,
    required String targetFilePath,
  }) async {
    try {
      // 1. 获取写锁
      if (!_writeLock.acquire('adopt_candidate:$candidateId')) {
        return const PipelineResult.failure(PipelineError(
          PipelineError.projectBusy,
          '项目正忙，无法采纳',
        ));
      }

      try {
        // 2. 校验源版本
        final candidate = _candidateService.getCandidate(candidateId);
        if (candidate == null) {
          return PipelineResult.failure(PipelineError(
            PipelineError.invalidState,
            '候选不存在: $candidateId',
          ));
        }

        final savedVersion =
            candidate.metadata['source_version'] as String? ?? '';
        final currentVersion = await _getSourceVersion(chapterId);
        if (savedVersion.isNotEmpty &&
            currentVersion.isNotEmpty &&
            savedVersion != currentVersion) {
          return const PipelineResult.failure(PipelineError(
            PipelineError.sourceVersionConflict,
            '源章节在候选生成后被修改，不能覆盖人工编辑',
          ));
        }

        // 3. 创建快照
        await _createSnapshot(targetFilePath, chapterId);

        // 4-5. 经 MutationProtocol 写入正式正文（userUi 隐式批准，ADR-010）。
        final protocol = _mutationProtocol;
        if (protocol == null) {
          return const PipelineResult.failure(PipelineError(
            PipelineError.writeError,
            '采纳失败: MutationProtocol 未注入（fail-closed）',
          ));
        }
        final edit = await protocol.applyUserEdit(ChangeRequest(
          projectId: _projectId,
          origin: ChangeOrigin.userUi,
          action: ChangeAction.replaceText,
          target: ChangeTarget(
            projectRelativePath: _relativePath(targetFilePath),
            kind: 'chapter',
          ),
          baseRevision: 0,
          payload: candidate.content,
        ));
        if (edit.errorOrNull() != null) {
          return PipelineResult.failure(PipelineError(
            PipelineError.writeError,
            '采纳失败: ${edit.errorOrNull()}',
          ));
        }

        // 6. 更新候选状态
        candidate.status = CandidateStatus.adopted;
        candidate.updatedAt = DateTime.now();
        _saveCandidate(candidate);

        // 7. 更新 BookState
        _bookStateStore.updateProgress(
          chapterId: chapterId,
          stage: BookStage.settling,
          action: 'candidate_adopted',
        );

        // 8. 推进状态机
        if (_stateMachine.activeWorkflow != null) {
          final stage = _stateMachine.activeWorkflow!.currentStage;
          if (_stateMachine.canTransition(stage, PipelineStage.adopted)) {
            _stateMachine.advance(PipelineStage.adopted, message: 'adopted');
          }
        }

        return PipelineResult.success(targetFilePath);
      } finally {
        // 释放写锁
        _writeLock.release();
      }
    } catch (e) {
      _writeLock.release();
      return PipelineResult.failure(PipelineError(
        PipelineError.writeError,
        '采纳失败: $e',
      ));
    }
  }

  String _relativePath(String targetFilePath) {
    // 前缀比较对斜杠与大小写不敏感（Windows 反斜杠 vs 正斜杠、盘符大小写），
    // 避免匹配失败时把绝对路径当作项目相对路径交给协议（PATH_ESCAPE）。
    final projectDir = _projectDir.replaceAll(r'\', '/').toLowerCase();
    final target = targetFilePath.replaceAll(r'\', '/').toLowerCase();
    if (target.startsWith(projectDir)) {
      var relative = target.substring(projectDir.length);
      while (relative.startsWith('/')) {
        relative = relative.substring(1);
      }
      return relative;
    }
    return target;
  }

  // ─── 6. 状态结算建议 ───────────────────────────────────────────

  /// 生成结算建议
  ///
  /// 只提取客观事实变化，不直接写入正式运行态。
  /// 结算失败时保留已采纳正文，标记 SETTLEMENT_FAILED。
  Future<PipelineResult<SettlementProposal>> proposeSettlement({
    required String chapterId,
    required String candidateId,
    required String adoptedContent,
  }) async {
    try {
      // 使用 AI 提取事实变化
      final prompt = '''分析以下章节正文，提取客观事实变化。只输出 JSON 数组，每项包含:
- category: 类别(character_position/item_change/relationship_change/new_character/new_rule/new_foreshadowing/foreshadowing_resolved/plotline_change)
- description: 变化描述
- entity_name: 相关实体名（可选）

正文：
$adoptedContent''';

      final messages = [
        const ChatMessage(
          role: 'system',
          content: '你是一个小说状态结算助手。只提取客观事实变化，不做主观评价。输出纯 JSON 数组。',
        ),
        ChatMessage(role: 'user', content: prompt),
      ];

      String aiResult;
      try {
        aiResult = await _aiService.currentProvider.chatSync(
          messages: messages,
        );
      } catch (e) {
        // AI 调用失败 → 结算失败
        _bookStateStore.updateProgress(
          chapterId: chapterId,
          stage: BookStage.settling,
          action: 'settlement_failed',
          blockingReason: 'SETTLEMENT_FAILED: $e',
        );
        return PipelineResult.failure(PipelineError(
          PipelineError.settlementFailed,
          '结算 AI 调用失败: $e',
        ));
      }

      // 解析 AI 输出
      final items = _parseSettlementItems(aiResult);

      final proposal = SettlementProposal(
        id: 'stl_${chapterId}_${DateTime.now().millisecondsSinceEpoch}',
        chapterId: chapterId,
        candidateId: candidateId,
        items: items,
        createdAt: DateTime.now(),
      );

      // 持久化结算建议
      _saveSettlement(proposal);

      // 推进状态机
      if (_stateMachine.activeWorkflow != null) {
        final stage = _stateMachine.activeWorkflow!.currentStage;
        if (_stateMachine.canTransition(stage, PipelineStage.settling)) {
          _stateMachine.advance(PipelineStage.settling,
              message: 'settlement proposed');
        }
        if (_stateMachine.canTransition(
            _stateMachine.activeWorkflow!.currentStage,
            PipelineStage.settled)) {
          _stateMachine.advance(PipelineStage.settled,
              message: 'settlement done');
          _stateMachine.advance(PipelineStage.idle, message: 'complete');
        }
      }

      // 更新 BookState
      _bookStateStore.updateProgress(
        chapterId: chapterId,
        stage: BookStage.chapterPreflight,
        action: 'settlement_proposed',
        blockingReason: '',
      );

      return PipelineResult.success(proposal);
    } catch (e) {
      // 结算失败：保留已采纳正文，标记失败
      _bookStateStore.updateProgress(
        chapterId: chapterId,
        stage: BookStage.settling,
        action: 'settlement_failed',
        blockingReason: 'SETTLEMENT_FAILED: $e',
      );
      _stateMachine.failAndRollback(e.toString());
      return PipelineResult.failure(PipelineError(
        PipelineError.settlementFailed,
        '结算失败: $e',
      ));
    }
  }

  /// 重试结算
  Future<PipelineResult<SettlementProposal>> retrySettlement({
    required String chapterId,
    required String candidateId,
  }) async {
    final candidate = _candidateService.getCandidate(candidateId);
    if (candidate == null) {
      return PipelineResult.failure(PipelineError(
        PipelineError.invalidState,
        '候选不存在: $candidateId',
      ));
    }
    // 清除阻塞
    _bookStateStore.updateProgress(
      chapterId: chapterId,
      stage: BookStage.settling,
      action: 'retry_settlement',
      blockingReason: '',
    );
    return proposeSettlement(
      chapterId: chapterId,
      candidateId: candidateId,
      adoptedContent: candidate.content,
    );
  }

  /// 获取结算建议
  SettlementProposal? getSettlement(String chapterId) {
    if (!_settlementDir.existsSync()) return null;
    for (final file in _settlementDir.listSync()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final json =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          if (json['chapter_id'] == chapterId) {
            return SettlementProposal.fromJson(json);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// 检查章节是否可以开始写作（未结算阻止）
  bool canStartWriting() {
    final bookState = _bookStateStore.loadOrCreate();
    if (bookState.blockingReason.contains('SETTLEMENT_FAILED')) {
      return false;
    }
    return isIdle;
  }

  // ─── 内部方法 ──────────────────────────────────────────────────

  /// 获取源文件版本标识（修改时间+大小）
  Future<String> _getSourceVersion(String chapterId) async {
    try {
      final doc = await _documentService.getDocument(chapterId);
      if (doc == null) return '';
      final file = File(doc.filePath);
      if (!file.existsSync()) return '';
      final stat = file.statSync();
      return '${stat.modified.millisecondsSinceEpoch}_${stat.size}';
    } catch (_) {
      return '';
    }
  }

  /// 创建快照
  Future<void> _createSnapshot(String filePath, String chapterId) async {
    final sourceFile = File(filePath);
    if (!sourceFile.existsSync()) return;

    if (!_snapshotDir.existsSync()) {
      _snapshotDir.createSync(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final snapshotPath = '${_snapshotDir.path}/${chapterId}_$timestamp.md';
    sourceFile.copySync(snapshotPath);
  }

  /// 保存候选（内部使用）
  void _saveCandidate(CandidateEntry entry) {
    _candidateService.ensureDir();
    final metaFile = File('$_projectDir/.lingbi/candidates/${entry.id}.json');
    metaFile.writeAsStringSync(jsonEncode(entry.toJson()));
    final contentFile = File('$_projectDir/.lingbi/candidates/${entry.id}.md');
    contentFile.writeAsStringSync(entry.content);
  }

  /// 保存结算建议
  void _saveSettlement(SettlementProposal proposal) {
    if (!_settlementDir.existsSync()) {
      _settlementDir.createSync(recursive: true);
    }
    final file = File('${_settlementDir.path}/${proposal.id}.json');
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(proposal.toJson()),
    );
  }

  /// 解析 AI 输出的结算条目
  List<SettlementItem> _parseSettlementItems(String aiOutput) {
    try {
      // 尝试提取 JSON 数组
      final jsonStr = _extractJsonArray(aiOutput);
      if (jsonStr == null) return [];
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return SettlementItem(
          category: map['category'] as String? ?? 'plotline_change',
          description: map['description'] as String? ?? '',
          entityName: map['entity_name'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// 从 AI 输出中提取 JSON 数组
  String? _extractJsonArray(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }
}
