
import 'package:flutter/material.dart';
import 'package:lingbi/generated/l10n/app_localizations.dart';
import '../../core/di/service_locator.dart';
import '../../services/search_service.dart';

/// 联网搜索对话框
class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _loading = false;
  String? _error;
  String _summary = '';

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() { _loading = true; _error = null; _results = []; _summary = ''; });
    try {
      final resp = await ServiceLocator.instance.searchService.searchWeb(query: query);
      setState(() { _results = resp.results; _summary = resp.summary; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600, height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('联网搜索', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '输入搜索关键词...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
                  child: _loading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppLocalizations.of(context)!.s55),
                ),
              ],
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
            if (_summary.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('摘要: $_summary', style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context)!.s102))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final r = _results[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(r.snippet, maxLines: 3, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.open_in_new, size: 16),
                            onTap: () {},
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

