import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WebSearchWidget extends StatefulWidget {
  const WebSearchWidget({super.key});

  @override
  State<WebSearchWidget> createState() => _WebSearchWidgetState();
}

class _WebSearchWidgetState extends State<WebSearchWidget> {
  final TextEditingController _queryCtrl = TextEditingController();
  List<SearchResult> _results = [];
  bool _loading = false;
  bool _showResults = false;

  Future<void> _search() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _loading = true; _showResults = true; });

    try {
      // 使用 DuckDuckGo 的免费搜索 API
      final response = await http.get(
        Uri.parse('https://api.duckduckgo.com/?q=$query&format=json'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = <SearchResult>[];
        final abstractText = json['AbstractText'] as String?;
        final abstractUrl = json['AbstractURL'] as String?;
        if (abstractText != null && abstractText.isNotEmpty) {
          results.add(SearchResult(
            title: json['Heading'] as String? ?? '摘要',
            snippet: abstractText,
            url: abstractUrl ?? '',
          ));
        }
        final related = json['RelatedTopics'] as List? ?? [];
        for (final topic in related.take(5)) {
          if (topic is Map) {
            results.add(SearchResult(
              title: topic['Text']?.toString().split(' - ').first ?? '',
              snippet: topic['Text']?.toString() ?? '',
              url: topic['FirstURL']?.toString() ?? '',
            ));
          }
        }
        setState(() { _results = results; _loading = false; });
      } else {
        setState(() { _loading = false; });
      }
    } catch (e) {
      setState(() { _loading = false; _results = [
        SearchResult(title: '搜索失败', snippet: '无法连接到搜索引擎: $e', url: ''),
      ]; });
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  decoration: const InputDecoration(
                    hintText: '联网搜索...',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              IconButton(
                icon: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 20),
                onPressed: _loading ? null : _search,
              ),
            ],
          ),
        ),
        if (_showResults)
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Text('无搜索结果', style: theme.textTheme.bodyMedium),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _results.length,
                    itemBuilder: (ctx, i) {
                      final r = _results[i];
                      return Card(
                        child: ListTile(
                          title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(r.snippet, maxLines: 3, overflow: TextOverflow.ellipsis),
                          onTap: r.url.isNotEmpty ? () {
                            // Copy URL to clipboard or open
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('链接: ${r.url}')),
                            );
                          } : null,
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}

class SearchResult {
  final String title;
  final String snippet;
  final String url;
  SearchResult({required this.title, required this.snippet, required this.url});
}
