import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/codex_service.dart';
import 'package:flutter/material.dart';
import '../../core/models/codex_entry.dart';

class CodexPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const CodexPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<CodexPage> createState() => _CodexPageState();
}

class _CodexPageState extends State<CodexPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CodexService _codexService = ServiceLocator.instance.codexService;
  Map<CodexEntryType, List<CodexEntry>> _entries = {};
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const _tabLabels = {
    CodexEntryType.character: '角色',
    CodexEntryType.location: '地点',
    CodexEntryType.lore: '传说',
    CodexEntryType.plotNode: '情节',
  };

  static const _tabIcons = {
    CodexEntryType.character: Icons.person,
    CodexEntryType.location: Icons.place,
    CodexEntryType.lore: Icons.auto_stories,
    CodexEntryType.plotNode: Icons.account_tree,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _codexService.getAllForProject(widget.projectId);
    if (mounted) setState(() { _entries = data; _loading = false; });
  }

  List<CodexEntry> _filtered(CodexEntryType type) {
    final list = _entries[type] ?? [];
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((e) =>
        e.name.toLowerCase().contains(q) ||
        e.description.toLowerCase().contains(q)).toList();
  }

  void _showEntryForm(CodexEntryType type, [CodexEntry? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final attrCtrl = TextEditingController(
      text: existing != null && existing.attributes.isNotEmpty
          ? existing.attributes.entries.map((e) => '${e.key}: ${e.value}').join('\n')
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? '编辑$_tabLabels[type]' : '新建$_tabLabels[type]'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '名称', hintText: '输入名称...'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: '描述', hintText: '输入描述...'),
                  maxLines: 4,
                ),
                if (type == CodexEntryType.character) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: attrCtrl,
                    decoration: const InputDecoration(
                      labelText: '属性（每行一个 key: value）',
                      hintText: '性格: 勇敢\n年龄: 25\n职业: 骑士',
                    ),
                    maxLines: 4,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final attrs = <String, dynamic>{};
              for (final line in attrCtrl.text.split('\n')) {
                final parts = line.split(':');
                if (parts.length >= 2) {
                  attrs[parts[0].trim()] = parts.sublist(1).join(':').trim();
                }
              }
              final entry = (existing ?? CodexEntry(
                projectId: widget.projectId,
                type: type,
                name: nameCtrl.text.trim(),
              )).copyWith(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                attributes: attrs,
              );
              if (existing != null) {
                await _codexService.update(entry);
              } else {
                await _codexService.create(entry);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: Text(existing != null ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(CodexEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${entry.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _codexService.delete(entry);
      _loadData();
    }
  }

  Widget _buildEntryList(CodexEntryType type) {
    final items = _filtered(type);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_tabIcons[type], size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text('暂无$_tabLabels[type]', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add, size: 18),
              label: Text('添加$_tabLabels[type]'),
              onPressed: () => _showEntryForm(type),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add, size: 18),
              label: Text('添加$_tabLabels[type]'),
              onPressed: () => _showEntryForm(type),
            ),
          );
        }
        final entry = items[i - 1];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(_tabIcons[type], size: 20),
            ),
            title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: entry.description.isNotEmpty
                ? Text(entry.description, maxLines: 2, overflow: TextOverflow.ellipsis)
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showEntryForm(type, entry);
                if (v == 'delete') _deleteEntry(entry);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: ListTile(
                  leading: Icon(Icons.edit, size: 18), title: Text('编辑'),
                )),
                const PopupMenuItem(value: 'delete', child: ListTile(
                  leading: Icon(Icons.delete, size: 18, color: Colors.red),
                  title: Text('删除', style: TextStyle(color: Colors.red)),
                )),
              ],
            ),
            onTap: () => _showEntryForm(type, entry),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} - 知识库'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索角色、地点、传说...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  for (final type in CodexEntryType.values)
                    Tab(
                      icon: Icon(_tabIcons[type], size: 18),
                      text: '$_tabLabels[type] (${(_entries[type] ?? []).length})',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                for (final type in CodexEntryType.values)
                  _buildEntryList(type),
              ],
            ),
    );
  }
}
