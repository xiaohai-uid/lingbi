/// 最小写作任务面板
///
/// 提供：AI 写作按钮、写作要求输入、流式进度、候选预览、
/// 原文/候选对比、拒绝、采纳、重新生成、错误重试。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingbi/modules/pipeline/novel_application_service.dart';
import 'package:lingbi/modules/pipeline/candidate_service.dart';

/// 写作面板状态
enum WritingPanelState {
  idle,
  preparing,
  generating,
  reviewing,
  adopting,
  settling,
  done,
  error,
}

/// 最小写作任务面板
class NovelWritingPanel extends StatefulWidget {
  const NovelWritingPanel({
    super.key,
    required this.service,
    required this.chapterId,
    required this.targetFilePath,
    this.previousChapterId,
    this.originalContent = '',
    this.onAdopted,
    this.isDirty = false,
    this.onSaveBeforeWrite,
  });

  final NovelApplicationService service;
  final String chapterId;
  final String targetFilePath;
  final String? previousChapterId;
  final String originalContent;
  final VoidCallback? onAdopted;

  /// 编辑器是否有未保存修改
  final bool isDirty;

  /// AI 写作前强制保存回调，返回 true 表示保存成功
  final Future<bool> Function()? onSaveBeforeWrite;

  @override
  State<NovelWritingPanel> createState() => _NovelWritingPanelState();
}

class _NovelWritingPanelState extends State<NovelWritingPanel> {
  final _instructionController = TextEditingController();
  final _scrollController = ScrollController();

  WritingPanelState _state = WritingPanelState.idle;
  String _streamBuffer = '';
  String _errorMessage = '';
  String? _candidateId;
  CandidateEntry? _candidate;
  ChapterWritePreparation? _preparation;
  bool _showDiff = false;
  StreamSubscription<PipelineResult<String>>? _streamSub;

  @override
  void dispose() {
    _instructionController.dispose();
    _scrollController.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  // ─── 操作 ──────────────────────────────────────────────────────

  Future<void> _startGeneration() async {
    // 未保存检查：编辑器存在未保存修改时，先强制保存
    if (widget.isDirty && widget.onSaveBeforeWrite != null) {
      final saved = await widget.onSaveBeforeWrite!();
      if (!saved) return;
    }

    setState(() {
      _state = WritingPanelState.preparing;
      _streamBuffer = '';
      _errorMessage = '';
      _candidateId = null;
      _candidate = null;
    });

    // 1. 准备上下文
    final prepResult = await widget.service.prepareChapterWrite(
      chapterId: widget.chapterId,
      previousChapterId: widget.previousChapterId,
      userInstruction: _instructionController.text.trim(),
    );

    if (prepResult.isFailure) {
      setState(() {
        _state = WritingPanelState.error;
        _errorMessage = prepResult.error!.message;
      });
      return;
    }

    _preparation = prepResult.data;

    // 2. 流式生成
    setState(() => _state = WritingPanelState.generating);

    _streamSub = widget.service
        .generateCandidate(
      chapterId: widget.chapterId,
      context: _preparation!.context,
      sourceVersion: _preparation!.sourceVersion,
    )
        .listen(
      (result) {
        if (result.isSuccess) {
          setState(() => _streamBuffer += result.data!);
          _scrollToBottom();
        } else {
          setState(() {
            _state = WritingPanelState.error;
            _errorMessage = result.error!.message;
          });
        }
      },
      onDone: () {
        // 生成完成，获取候选
        final candidates =
            widget.service.listCandidates(widget.chapterId);
        if (candidates.isNotEmpty) {
          setState(() {
            _candidate = candidates.first;
            _candidateId = candidates.first.id;
            _state = WritingPanelState.reviewing;
          });
        }
      },
      onError: (e) {
        setState(() {
          _state = WritingPanelState.error;
          _errorMessage = e.toString();
        });
      },
    );
  }

  void _reject() {
    if (_candidateId == null) return;
    widget.service.rejectCandidate(_candidateId!);
    setState(() {
      _state = WritingPanelState.idle;
      _streamBuffer = '';
      _candidate = null;
      _candidateId = null;
    });
  }

  Future<void> _adopt() async {
    if (_candidateId == null) return;
    setState(() => _state = WritingPanelState.adopting);

    final result = await widget.service.adoptCandidate(
      candidateId: _candidateId!,
      chapterId: widget.chapterId,
      targetFilePath: widget.targetFilePath,
    );

    if (result.isSuccess) {
      // 采纳成功，尝试结算
      setState(() => _state = WritingPanelState.settling);
      final settleResult = await widget.service.proposeSettlement(
        chapterId: widget.chapterId,
        candidateId: _candidateId!,
        adoptedContent: _candidate?.content ?? _streamBuffer,
      );

      setState(() {
        _state = WritingPanelState.done;
        if (settleResult.isFailure) {
          _errorMessage = '正文已采纳，但结算失败: ${settleResult.error!.message}';
        }
      });
      widget.onAdopted?.call();
    } else {
      setState(() {
        _state = WritingPanelState.error;
        _errorMessage = result.error!.message;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
        const Divider(height: 1),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, size: 18),
          const SizedBox(width: 8),
          const Text('AI 写作', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildStateChip(),
        ],
      ),
    );
  }

  Widget _buildStateChip() {
    final (label, color) = switch (_state) {
      WritingPanelState.idle => ('就绪', Colors.grey),
      WritingPanelState.preparing => ('准备中…', Colors.blue),
      WritingPanelState.generating => ('生成中…', Colors.orange),
      WritingPanelState.reviewing => ('待审核', Colors.purple),
      WritingPanelState.adopting => ('采纳中…', Colors.blue),
      WritingPanelState.settling => ('结算中…', Colors.teal),
      WritingPanelState.done => ('完成', Colors.green),
      WritingPanelState.error => ('错误', Colors.red),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      WritingPanelState.idle => _buildIdleView(),
      WritingPanelState.preparing => _buildLoadingView('正在组装上下文…'),
      WritingPanelState.generating => _buildGeneratingView(),
      WritingPanelState.reviewing => _buildReviewView(),
      WritingPanelState.adopting => _buildLoadingView('正在安全写入…'),
      WritingPanelState.settling => _buildLoadingView('正在生成结算建议…'),
      WritingPanelState.done => _buildDoneView(),
      WritingPanelState.error => _buildErrorView(),
    };
  }

  Widget _buildIdleView() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _instructionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '输入写作要求（可选）\n例如：让主角在此章发现真相，气氛紧张…',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 12),
          if (!widget.service.canStartWriting())
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '⚠ 上一章尚未完成结算，请先处理结算',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          FilledButton.icon(
            onPressed: widget.service.canStartWriting()
                ? _startGeneration
                : null,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 写作'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildGeneratingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text('生成中… ${_streamBuffer.length} 字',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              _streamBuffer.isEmpty ? '等待 AI 输出…' : _streamBuffer,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewView() {
    final candidateContent = _candidate?.content ?? _streamBuffer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text('候选预览 (${candidateContent.length} 字)',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showDiff = !_showDiff),
                child: Text(_showDiff ? '隐藏对比' : '原文对比'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _showDiff ? _buildDiffView(candidateContent) : _buildCandidatePreview(candidateContent),
        ),
      ],
    );
  }

  Widget _buildCandidatePreview(String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        content,
        style: const TextStyle(fontSize: 14, height: 1.6),
      ),
    );
  }

  Widget _buildDiffView(String candidateContent) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(6),
                child: Text('原文',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(
                    widget.originalContent.isEmpty
                        ? '（空章节）'
                        : widget.originalContent,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(6),
                child: Text('候选',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple)),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(
                    candidateContent,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text('已采纳并写入章节',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_errorMessage,
                  style: const TextStyle(color: Colors.orange, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() {
                _state = WritingPanelState.idle;
                _streamBuffer = '';
                _errorMessage = '';
                _candidate = null;
                _candidateId = null;
              }),
              child: const Text('继续写作'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: _startGeneration,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _state = WritingPanelState.idle;
                    _errorMessage = '';
                  }),
                  child: const Text('返回'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_state != WritingPanelState.reviewing) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _reject,
              icon: const Icon(Icons.close),
              label: const Text('拒绝'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: _adopt,
              icon: const Icon(Icons.check),
              label: const Text('采纳'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _startGeneration,
            icon: const Icon(Icons.refresh),
            tooltip: '重新生成',
          ),
        ],
      ),
    );
  }
}
