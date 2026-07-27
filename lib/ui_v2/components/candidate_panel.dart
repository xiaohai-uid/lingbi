/// 候选面板 — NovelApplicationService 的 UI 层
///
/// 本组件仅作为现有服务的 UI，不重新实现候选存储、采纳、锁、快照和状态机。
/// 所有操作通过 NovelApplicationService 完成。
///
/// 候选完成后支持：
/// - 插入光标处
/// - 替换选区
/// - 追加到末尾
/// - 复制
/// - 丢弃
/// - 重新生成
/// - 撤销
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingbi/core/ai/ai_response_normalizer.dart';
import 'package:lingbi/modules/pipeline/candidate_service.dart';
import 'model_status_bar.dart';

/// 候选采纳模式
enum AdoptMode {
  /// 插入光标处
  insertAtCursor,

  /// 替换选区
  replaceSelection,

  /// 追加到末尾
  appendToEnd,
}

/// 候选面板组件
class CandidatePanel extends StatefulWidget {
  const CandidatePanel({
    super.key,
    required this.candidate,
    required this.processBlocks,
    this.isStreaming = false,
    this.safeReplaceOnly = false,
    this.onAdopt,
    this.onDiscard,
    this.onRegenerate,
    this.onCopy,
  });

  /// 候选条目（来自 CandidateService）
  final CandidateEntry candidate;

  /// 过程信息块（用于折叠显示）
  final List<NormalizedBlock> processBlocks;

  /// 是否正在流式生成
  final bool isStreaming;

  /// When true, adoption is routed through the transactional workflow and
  /// replaces the chapter only after lock, source-version and snapshot checks.
  final bool safeReplaceOnly;

  /// 采纳回调（返回采纳模式）
  final ValueChanged<AdoptMode>? onAdopt;

  /// 丢弃回调
  final VoidCallback? onDiscard;

  /// 重新生成回调
  final VoidCallback? onRegenerate;

  /// 复制回调
  final VoidCallback? onCopy;

  @override
  State<CandidatePanel> createState() => _CandidatePanelState();
}

class _CandidatePanelState extends State<CandidatePanel> {
  bool _showProcess = false;
  bool _processAutoCollapsed = false;

  @override
  void didUpdateWidget(CandidatePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 最终结果开始后自动折叠过程区
    if (oldWidget.isStreaming &&
        !widget.isStreaming &&
        !_processAutoCollapsed) {
      _showProcess = false;
      _processAutoCollapsed = true;
    }
    // 流式生成时过程区展开
    if (widget.isStreaming && !_processAutoCollapsed) {
      _showProcess = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          _buildHeader(theme),
          // 过程区（可折叠）
          if (widget.processBlocks.isNotEmpty) _buildProcessSection(theme),
          // 候选正文
          _buildCandidateContent(theme),
          // 操作栏
          if (!widget.isStreaming) _buildActionBar(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(
            widget.isStreaming ? Icons.hourglass_top : Icons.auto_stories,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isStreaming ? '生成中...' : 'AI 候选',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          const ModelStatusBar(compact: true),
          const SizedBox(width: 8),
          if (widget.isStreaming)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProcessSection(ThemeData theme) {
    final processText = widget.processBlocks.map((b) => b.text).join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _showProcess = !_showProcess),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  _showProcess
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '过程信息',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '不可信标记',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showProcess)
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              child: Text(
                processText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCandidateContent(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          widget.candidate.content,
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (widget.safeReplaceOnly)
            FilledButton.icon(
              onPressed: widget.onAdopt == null
                  ? null
                  : () => widget.onAdopt!(AdoptMode.replaceSelection),
              icon: const Icon(Icons.verified_user_outlined, size: 16),
              label: const Text('安全采纳到正文'),
            )
          else
            // Legacy cursor modes are only safe for non-persistent previews.
            PopupMenuButton<AdoptMode>(
              tooltip: '采纳到编辑器',
              offset: const Offset(0, -100),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: AdoptMode.insertAtCursor,
                  child: Text('插入光标处'),
                ),
                const PopupMenuItem(
                  value: AdoptMode.replaceSelection,
                  child: Text('替换选区'),
                ),
                const PopupMenuItem(
                  value: AdoptMode.appendToEnd,
                  child: Text('追加到末尾'),
                ),
              ],
              onSelected: (mode) => widget.onAdopt?.call(mode),
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('采纳'),
              ),
            ),
          // 复制
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.candidate.content));
              widget.onCopy?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('复制'),
          ),
          // 重新生成
          OutlinedButton.icon(
            onPressed: widget.onRegenerate,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重新生成'),
          ),
          // 丢弃
          TextButton.icon(
            onPressed: widget.onDiscard,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('丢弃'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
