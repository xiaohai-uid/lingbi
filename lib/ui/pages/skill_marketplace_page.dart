import 'package:flutter/material.dart';
import 'package:lingbi/features/skill/data/skill_marketplace.dart';

/// Skill 市场页面 — 浏览、搜索、安装/卸载 Skill
class SkillMarketplacePage extends StatefulWidget {
  const SkillMarketplacePage({super.key});

  @override
  State<SkillMarketplacePage> createState() => _SkillMarketplacePageState();
}

class _SkillMarketplacePageState extends State<SkillMarketplacePage> {
  final SkillMarketplace _marketplace = SkillMarketplace();
  final TextEditingController _searchController = TextEditingController();
  List<SkillEntry> _skills = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  static const _categories = {
    'all': '全部',
    'writing': '写作辅助',
    'analysis': '分析',
    'translation': '翻译',
    'formatting': '格式化',
    'general': '通用',
  };

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _marketplace.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() => _loading = true);
    final skills = await _marketplace.fetchSkills();
    if (mounted) setState(() { _skills = skills; _loading = false; });
  }

  List<SkillEntry> get _filteredSkills {
    var result = _skills;
    if (_selectedCategory != 'all') {
      result = result.where((s) => s.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) =>
        s.name.toLowerCase().contains(q) ||
        s.description.toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill 市场'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索 Skill...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final entry in _categories.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _selectedCategory == entry.key,
                          onSelected: (v) => setState(() => _selectedCategory = v ? entry.key : 'all'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSkills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text('暂无匹配的 Skill', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredSkills.length,
                  itemBuilder: (ctx, i) {
                    final skill = _filteredSkills[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_iconForCategory(skill.category)),
                        ),
                        title: Text(skill.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${skill.author} · v${skill.version}\n${skill.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => _installSkill(skill),
                          child: const Text('安装'),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'writing': return Icons.edit_note;
      case 'analysis': return Icons.analytics;
      case 'translation': return Icons.translate;
      case 'formatting': return Icons.format_paint;
      default: return Icons.extension;
    }
  }

  void _installSkill(SkillEntry skill) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在安装 ${skill.name}...')),
    );
    _marketplace.install(skill).then((ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '${skill.name} 安装成功' : '安装失败')),
      );
    });
  }
}
