import 'package:flutter/material.dart';
import 'package:lingbi/core/models/canon_entry.dart';
import 'package:lingbi/services/web_search_service.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

typedef WebContextSearch = Future<List<SearchResult>> Function(String query);
typedef CanonContextSearch = Future<List<CanonEntry>> Function(String query);

enum _ContextSource { web, canon }

class AiContextBrowser extends StatefulWidget {
  const AiContextBrowser({
    super.key,
    required this.searchWeb,
    required this.searchCanon,
    required this.onInsertContext,
  });

  final WebContextSearch searchWeb;
  final CanonContextSearch searchCanon;
  final ValueChanged<String> onInsertContext;

  @override
  State<AiContextBrowser> createState() => _AiContextBrowserState();
}

class _AiContextBrowserState extends State<AiContextBrowser> {
  final TextEditingController _queryController = TextEditingController();
  _ContextSource _source = _ContextSource.web;
  List<SearchResult> _webResults = const [];
  List<CanonEntry> _canonResults = const [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      if (_source == _ContextSource.web) {
        final results = await widget.searchWeb(query);
        if (mounted) setState(() => _webResults = results);
      } else {
        final results = await widget.searchCanon(query);
        if (mounted) setState(() => _canonResults = results);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeSource(Set<_ContextSource> selection) {
    if (selection.isEmpty) return;
    setState(() {
      _source = selection.first;
      _error = null;
      _hasSearched = false;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_ContextSource>(
                segments: const [
                  ButtonSegment(
                    value: _ContextSource.web,
                    icon: Icon(Icons.language, size: 16),
                    label: Text('联网'),
                  ),
                  ButtonSegment(
                    value: _ContextSource.canon,
                    icon: Icon(Icons.auto_stories_outlined, size: 16),
                    label: Text('正典'),
                  ),
                ],
                selected: {_source},
                onSelectionChanged: _changeSource,
                showSelectedIcon: false,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('ai-context-query'),
                      controller: _queryController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _source == _ContextSource.web
                            ? '搜索创作资料'
                            : '搜索人物、地点与设定',
                        prefixIcon: const Icon(Icons.search, size: 18),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: '搜索',
                    child: IconButton.filled(
                      key: const ValueKey('ai-context-search'),
                      onPressed: _isLoading ? null : _search,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.borderOpaque),
        Expanded(child: _buildResults(colors)),
      ],
    );
  }

  Widget _buildResults(LingBiColors colors) {
    if (_error != null) {
      return _StatusView(
        icon: Icons.cloud_off_outlined,
        title: '暂时无法搜索',
        detail: _error!,
      );
    }
    if (!_hasSearched) {
      return _StatusView(
        icon: _source == _ContextSource.web
            ? Icons.travel_explore_outlined
            : Icons.menu_book_outlined,
        title: _source == _ContextSource.web ? '查找可追溯资料' : '调用项目正典',
        detail: _source == _ContextSource.web
            ? '搜索结果会保留标题、摘要与来源地址。'
            : '将人物、地点、世界观和剧情节点加入本轮对话。',
      );
    }

    final itemCount = _source == _ContextSource.web
        ? _webResults.length
        : _canonResults.length;
    if (!_isLoading && itemCount == 0) {
      return const _StatusView(
        icon: Icons.search_off,
        title: '没有找到结果',
        detail: '换一个更具体的关键词再试。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: itemCount,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 12,
        endIndent: 12,
        color: colors.borderOpaque.withValues(alpha: 0.6),
      ),
      itemBuilder: (context, index) => _source == _ContextSource.web
          ? _buildWebResult(colors, _webResults[index], index)
          : _buildCanonResult(colors, _canonResults[index], index),
    );
  }

  Widget _buildWebResult(
    LingBiColors colors,
    SearchResult result,
    int index,
  ) {
    return _ContextResultTile(
      title: result.title,
      detail: result.snippet,
      meta: result.source.isNotEmpty ? result.source : result.url,
      colors: colors,
      insertKey: ValueKey('insert-web-context-$index'),
      onInsert: () => widget.onInsertContext(
        '【联网资料】\n${result.toContextText()}',
      ),
    );
  }

  Widget _buildCanonResult(
    LingBiColors colors,
    CanonEntry entry,
    int index,
  ) {
    return _ContextResultTile(
      title: entry.name,
      detail: entry.description,
      meta: _canonTypeLabel(entry.type),
      colors: colors,
      insertKey: ValueKey('insert-canon-context-$index'),
      onInsert: () => widget.onInsertContext(
        '【项目正典 · ${_canonTypeLabel(entry.type)}】\n'
        '${entry.name}\n${entry.description}',
      ),
    );
  }

  String _canonTypeLabel(CanonEntryType type) => switch (type) {
        CanonEntryType.character => '角色',
        CanonEntryType.location => '地点',
        CanonEntryType.lore => '世界观',
        CanonEntryType.plotNode => '剧情节点',
      };
}

class _ContextResultTile extends StatelessWidget {
  const _ContextResultTile({
    required this.title,
    required this.detail,
    required this.meta,
    required this.colors,
    required this.insertKey,
    required this.onInsert,
  });

  final String title;
  final String detail;
  final String meta;
  final LingBiColors colors;
  final Key insertKey;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.fgSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Tooltip(
            message: '加入对话上下文',
            child: IconButton(
              key: insertKey,
              onPressed: onInsert,
              icon: const Icon(Icons.add_circle_outline, size: 19),
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: colors.muted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.fgSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
