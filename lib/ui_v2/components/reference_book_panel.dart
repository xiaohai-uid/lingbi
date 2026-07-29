/// 参考书面板 - 管理项目参考书目与内容爬取
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/reference_book_service.dart';

class ReferenceBookPanel extends StatefulWidget {
  const ReferenceBookPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<ReferenceBookPanel> createState() => _ReferenceBookPanelState();
}

class _ReferenceBookPanelState extends State<ReferenceBookPanel> {
  bool _loading = true;
  List<ReferenceBook> _books = [];
  final Set<String> _crawlingIds = {};

  static const _accentColor = Color(0xFF0891B2);

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    try {
      final books = await ServiceLocator.instance.referenceBookService
          .listBooks(widget.projectId);
      if (mounted) setState(() => _books = books);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addBook() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddBookDialog(accentColor: _accentColor),
    );
    if (result == null || !mounted) return;
    try {
      await ServiceLocator.instance.referenceBookService.addBook(
        widget.projectId,
        title: result['title']!,
        sourceType: result['sourceType'] == 'url'
            ? ReferenceSourceType.url
            : result['sourceType'] == 'file'
                ? ReferenceSourceType.file
                : ReferenceSourceType.manual,
        sourceUrl: result['sourceUrl'] ?? '',
        author: result['author'] ?? '',
      );
      await _loadBooks();
    } catch (_) {}
  }

  Future<void> _removeBook(String bookId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除参考书'),
        content: const Text('确定要删除此参考书吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _accentColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ServiceLocator.instance.referenceBookService
        .removeBook(widget.projectId, bookId);
    await _loadBooks();
  }

  Future<void> _crawlBook(String bookId) async {
    setState(() => _crawlingIds.add(bookId));
    try {
      await ServiceLocator.instance.referenceBookService
          .crawl(projectId: widget.projectId, bookId: bookId);
      await _loadBooks();
    } finally {
      if (mounted) setState(() => _crawlingIds.remove(bookId));
    }
  }

  String _crawlStatusLabel(CrawlStatus s) {
    switch (s) {
      case CrawlStatus.idle:
        return '待爬取';
      case CrawlStatus.crawling:
        return '爬取中';
      case CrawlStatus.paused:
        return '已暂停';
      case CrawlStatus.completed:
        return '已完成';
      case CrawlStatus.failed:
        return '失败';
    }
  }

  Color _crawlStatusColor(CrawlStatus s) {
    switch (s) {
      case CrawlStatus.idle:
        return const Color(0xFF6B7280);
      case CrawlStatus.crawling:
        return const Color(0xFF2563EB);
      case CrawlStatus.paused:
        return const Color(0xFFD97706);
      case CrawlStatus.completed:
        return const Color(0xFF059669);
      case CrawlStatus.failed:
        return const Color(0xFFDC2626);
    }
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [
          const Expanded(
              child: _PanelHeader(
                  icon: Icons.book_rounded,
                  title: '参考书管理',
                  accentColor: _accentColor)),
          IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              color: _accentColor,
              tooltip: '添加参考书',
              onPressed: _addBook),
        ]),
        const SizedBox(height: 6),
        Text('共 ${_books.length} 本参考书',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 14),
        if (_books.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text('暂无参考书，点击右上角 + 添加',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
          )
        else
          ..._books.map((book) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(color: _accentColor, width: 3)),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(book.title,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                    if (book.author.isNotEmpty)
                                      Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(book.author,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant))),
                                  ])),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'crawl') _crawlBook(book.id);
                                  if (v == 'delete') _removeBook(book.id);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'crawl', child: Text('爬取')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('删除')),
                                ],
                              ),
                            ]),
                        const SizedBox(height: 10),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          _chip(
                              book.sourceType == ReferenceSourceType.url
                                  ? '网址'
                                  : book.sourceType == ReferenceSourceType.file
                                      ? '文件'
                                      : '手动',
                              _accentColor),
                          _chip(_crawlStatusLabel(book.crawlStatus),
                              _crawlStatusColor(book.crawlStatus)),
                        ]),
                        if (book.crawlProgress > 0 &&
                            book.crawlStatus == CrawlStatus.crawling) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                              value: book.crawlProgress,
                              color: const Color(0xFF2563EB),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest),
                        ],
                        if (book.totalChapters > 0)
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  '${book.crawledChapters}/${book.totalChapters} 章节',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant))),
                      ],
                    ),
                  ),
                  if (book.analysis.isComplete)
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.3)))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.analytics_rounded,
                                  size: 16, color: _accentColor),
                              const SizedBox(width: 6),
                              Text('分析结果',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                            ]),
                            const SizedBox(height: 8),
                            _AnalysisRow(
                                label: '风格', value: book.analysis.style),
                            _AnalysisRow(
                                label: '角色', value: book.analysis.characters),
                            _AnalysisRow(
                                label: '情节', value: book.analysis.plot),
                            _AnalysisRow(
                                label: '氛围',
                                value: book.analysis.atmosphere),
                          ]),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  const _AnalysisRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 48,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface))),
        ]));
  }
}

class _AddBookDialog extends StatefulWidget {
  const _AddBookDialog({required this.accentColor});

  final Color accentColor;

  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  String _sourceType = 'url';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    Navigator.pop(context, {
      'title': _titleCtrl.text.trim(),
      'sourceType': _sourceType,
      'sourceUrl': _urlCtrl.text.trim(),
      'author': _authorCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加参考书'),
      content:
          SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
                labelText: '书名', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _sourceType,
          decoration: const InputDecoration(
              labelText: '来源类型', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'url', child: Text('网址')),
            DropdownMenuItem(value: 'file', child: Text('文件')),
            DropdownMenuItem(value: 'manual', child: Text('手动')),
          ],
          onChanged: (v) => setState(() => _sourceType = v!),
        ),
        const SizedBox(height: 12),
        TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
                labelText: _sourceType == 'url' ? '网址' : '来源路径',
                hintText: _sourceType == 'url' ? 'https://...' : null,
                border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
            controller: _authorCtrl,
            decoration: const InputDecoration(
                labelText: '作者', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        FilledButton(
            onPressed: _submit,
            style:
                FilledButton.styleFrom(backgroundColor: widget.accentColor),
            child: const Text('添加')),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader(
      {required this.icon, required this.title, required this.accentColor});

  final IconData icon;
  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 22, color: accentColor),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.01)),
    ]);
  }
}
