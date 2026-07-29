import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

class CanonPage extends StatefulWidget {

  const CanonPage({super.key, this.projectId});
  final String? projectId;

  @override
  State<CanonPage> createState() => _CanonPageState();
}

class _CanonPageState extends State<CanonPage> {
  String _selectedCategory = '全部';
  final _categories = ['全部', '角色', '地点', '传说', '情节节点'];
  List<CanonEntry> _allEntries = [];
  List<CanonEntry> _filteredEntries = [];
  bool _loading = false;
  String _searchQuery = '';
  Timer? _debounce;

  static const _categoryToType = <String, CanonEntryType>{
    '角色': CanonEntryType.character,
    '地点': CanonEntryType.location,
    '传说': CanonEntryType.lore,
    '情节节点': CanonEntryType.plotNode,
  };

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) _loadData();
  }

  @override
  void didUpdateWidget(covariant CanonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectId != oldWidget.projectId && widget.projectId != null) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final pid = widget.projectId;
    if (pid == null) return;
    setState(() => _loading = true);
    try {
      final allMap =
          await ServiceLocator.instance.canonService.getAllForProject(pid);
      final all = allMap.values.expand((e) => e).toList();
      if (mounted) {
        setState(() {
          _allEntries = all;
          _applyFilters();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    var result = _allEntries;
    if (_selectedCategory != '全部') {
      final type = _categoryToType[_selectedCategory];
      if (type != null) {
        result = result.where((e) => e.type == type).toList();
      }
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList();
    }
    _filteredEntries = result;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
          _applyFilters();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Column(
      children: [
        _buildHeader(c),
        _buildSearchAndFilter(c),
        Expanded(child: _buildContent(c)),
      ],
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        LingBiTokens.space5,
        LingBiTokens.space6,
        LingBiTokens.space3,
      ),
      child: Row(
        children: [
          Text(
            '正典 / 世界构建',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.fg,
              letterSpacing: -0.625 / 26 * 26,
            ),
          ),
          const Spacer(),
          _buildAddButton(c),
        ],
      ),
    );
  }

  Widget _buildAddButton(LingBiColors c) {
    return ElevatedButton.icon(
      onPressed: () => _showCreateDialog(c),
      icon: const Icon(LingBiIcons.add, size: 16),
      label: const Text('新建条目'),
      style: ElevatedButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space4,
          vertical: LingBiTokens.space2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: '搜索正典内容…',
              prefixIcon: Icon(LingBiIcons.search, size: 18),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: LingBiTokens.space3),
          Wrap(
            spacing: LingBiTokens.space2,
            runSpacing: LingBiTokens.space2,
            children: _categories.map((cat) {
              final isActive = cat == _selectedCategory;
              return InkWell(
                onTap: () => setState(() {
                  _selectedCategory = cat;
                  _applyFilters();
                }),
                borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingBiTokens.space3,
                    vertical: LingBiTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? c.accent.withValues(alpha: 0.1) : c.surface,
                    borderRadius:
                        BorderRadius.circular(LingBiTokens.radiusPill),
                    border: Border.all(
                      color: isActive
                          ? c.accent.withValues(alpha: 0.3)
                          : c.borderOpaque.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? c.accent : c.fgSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(CanonEntryType type) {
    switch (type) {
      case CanonEntryType.character:
        return LingBiIcons.character;
      case CanonEntryType.location:
        return LingBiIcons.location;
      case CanonEntryType.lore:
        return LingBiIcons.book;
      case CanonEntryType.plotNode:
        return LingBiIcons.timeline;
    }
  }

  Color _colorForType(CanonEntryType type, LingBiColors c) {
    switch (type) {
      case CanonEntryType.character:
        return c.cinnabar;
      case CanonEntryType.location:
        return c.accent;
      case CanonEntryType.lore:
        return LingBiTokens.warning;
      case CanonEntryType.plotNode:
        return LingBiTokens.success;
    }
  }

  String _typeName(CanonEntryType type) {
    switch (type) {
      case CanonEntryType.character:
        return '角色';
      case CanonEntryType.location:
        return '地点';
      case CanonEntryType.lore:
        return '传说';
      case CanonEntryType.plotNode:
        return '情节节点';
    }
  }

  Widget _buildContent(LingBiColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredEntries.isEmpty) {
      return Center(
        child: Text(
          _allEntries.isEmpty ? '暂无条目，点击"新建条目"开始' : '无匹配结果',
          style: TextStyle(fontSize: 14, color: c.muted),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: LingBiTokens.space4,
        mainAxisSpacing: LingBiTokens.space4,
        childAspectRatio: 1.3,
      ),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) =>
          _buildCanonCard(_filteredEntries[index], c),
    );
  }

  Widget _buildCanonCard(CanonEntry entry, LingBiColors c) {
    final icon = _iconForType(entry.type);
    final color = _colorForType(entry.type, c);
    final typeName = _typeName(entry.type);

    return Container(
      padding: const EdgeInsets.all(LingBiTokens.space4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
        border: Border.all(
          color: c.borderOpaque.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: LingBiTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    Row(
                      children: [
                        _buildBadge(c, typeName, color),
                        const SizedBox(width: LingBiTokens.space1),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LingBiTokens.space3),
          Text(
            entry.description,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: c.fgSecondary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(LingBiColors c, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showCreateDialog(LingBiColors c) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    CanonEntryType selectedType = CanonEntryType.character;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新建条目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：陈曦',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CanonEntryType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: '类型'),
                items: const [
                  DropdownMenuItem(
                    value: CanonEntryType.character,
                    child: Text('角色'),
                  ),
                  DropdownMenuItem(
                    value: CanonEntryType.location,
                    child: Text('地点'),
                  ),
                  DropdownMenuItem(
                    value: CanonEntryType.lore,
                    child: Text('传说'),
                  ),
                  DropdownMenuItem(
                    value: CanonEntryType.plotNode,
                    child: Text('情节节点'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedType = v);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final pid = widget.projectId;
                if (pid == null) return;
                final entry = CanonEntry(
                  projectId: pid,
                  type: selectedType,
                  name: name,
                  description: descCtrl.text.trim(),
                );
                try {
                  await ServiceLocator.instance.canonService.create(entry);
                  if (mounted) await _loadData();
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}
