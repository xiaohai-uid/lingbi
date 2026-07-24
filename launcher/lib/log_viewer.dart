import 'package:flutter/material.dart';

/// 日志查看器 — 实时显示微服务 stdout/stderr
class LogViewer extends StatefulWidget {
  final String serviceName;
  final StringBuffer logBuffer;
  final VoidCallback onClose;

  const LogViewer({
    super.key,
    required this.serviceName,
    required this.logBuffer,
    required this.onClose,
  });

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterController = TextEditingController();
  bool _autoScroll = true;
  String _filter = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_autoScroll) return;
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

  List<String> get _filteredLines {
    final allLines = widget.logBuffer.toString().split('\n');
    if (_filter.isEmpty) return allLines;
    final q = _filter.toLowerCase();
    return allLines.where((l) => l.toLowerCase().contains(q)).toList();
  }

  Color _lineColor(String line, ThemeData theme) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('exception')) {
      return Colors.red;
    }
    if (lower.contains('warn')) {
      return Colors.orange;
    }
    if (lower.contains('debug') || lower.contains('trace')) {
      return theme.disabledColor;
    }
    return theme.textTheme.bodySmall?.color ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _filteredLines;
    _scrollToBottom();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.description, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('${widget.serviceName} — 日志',
                    style: theme.textTheme.titleSmall),
                const Spacer(),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _filterController,
                    decoration: const InputDecoration(
                      hintText: '过滤...',
                      prefixIcon: Icon(Icons.filter_list, size: 16),
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _autoScroll
                        ? Icons.vertical_align_bottom
                        : Icons.pause_circle_outline,
                    size: 18,
                  ),
                  tooltip: _autoScroll ? '自动滚动: 开' : '自动滚动: 关',
                  onPressed: () =>
                      setState(() => _autoScroll = !_autoScroll),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: '关闭',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          // Log content
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Text('暂无日志', style: theme.textTheme.bodyMedium))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: lines.length,
                    itemBuilder: (ctx, i) {
                      final line = lines[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: _lineColor(line, theme),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
