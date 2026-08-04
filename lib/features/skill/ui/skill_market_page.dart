import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingbi/features/routing/default_rules.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/skill/data/skill/distillation_service.dart';
import 'package:lingbi/features/skill/data/skill_marketplace.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';
import 'package:lingbi/ui_v2/theme/lingbi_icons.dart';

class SkillMarketPage extends StatefulWidget {
  const SkillMarketPage({super.key, required this.onBack, this.projectId});

  final VoidCallback onBack;
  final String? projectId;

  @override
  State<SkillMarketPage> createState() => _SkillMarketPageState();
}

class _SkillMarketPageState extends State<SkillMarketPage> {
  String _selectedCategory = '全部';
  String _searchQuery = '';
  Timer? _debounce;
  bool _loading = true;
  String? _error;

  /// 使用 ServiceLocator 中的共享实例（而非自实例化）
  late final SkillMarketplace _skillMarketplace;
  List<SkillEntry> _allSkills = [];
  List<SkillEntry> _displayedSkills = [];
  final _installingIds = <String>{};
  bool _distilling = false;

  static const _categoryDisplayNames = <String, String>{
    '\u5168\u90e8': '\u5168\u90e8',
    '\u5199\u4f5c\u8f85\u52a9': '\u5199\u4f5c\u8f85\u52a9',
    '\u4e16\u754c\u6784\u5efa': '\u4e16\u754c\u6784\u5efa',
    '\u7814\u7a76\u8f85\u52a9': '\u7814\u7a76\u8f85\u52a9',
    '\u7ed3\u6784\u5206\u6790': '\u7ed3\u6784\u5206\u6790',
    '\u521b\u610f\u8f85\u52a9': '\u521b\u610f\u8f85\u52a9',
    '\u51fa\u7248\u5de5\u5177': '\u51fa\u7248\u5de5\u5177',
    '\u8d28\u91cf\u68c0\u67e5': '\u8d28\u91cf\u68c0\u67e5',
    'analysis': '\u7ed3\u6784\u5206\u6790',
    'writing': '\u5199\u4f5c\u8f85\u52a9',
    'translation': '\u51fa\u7248\u5de5\u5177',
    'formatting': '\u5199\u4f5c\u8f85\u52a9',
  };

  final _categories = [
    '\u5168\u90e8',
    '\u5df2\u5b89\u88c5',
    '\u5199\u4f5c\u8f85\u52a9',
    '\u4e16\u754c\u6784\u5efa',
    '\u7814\u7a76\u8f85\u52a9',
    '\u7ed3\u6784\u5206\u6790',
    '\u521b\u610f\u8f85\u52a9',
    '\u51fa\u7248\u5de5\u5177',
  ];

  @override
  void initState() {
    super.initState();
    // 从 ServiceLocator 获取共享实例（降级模式时回退为本地实例）
    _skillMarketplace = ServiceLocator.instance.initSucceeded
        ? ServiceLocator.instance.skillMarketplace
        : SkillMarketplace();
    _init();
  }

  Future<void> _init() async {
    await _skillMarketplace.initialize();
    _loadSkills();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // 只有自实例化时才 dispose（ServiceLocator 实例由其自身管理）
    if (!ServiceLocator.instance.initSucceeded) {
      _skillMarketplace.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _allSkills = await _skillMarketplace.loadLocalRegistry();
      if (_allSkills.isEmpty) {
        _allSkills = await _skillMarketplace.fetchSkills();
      }
      if (_allSkills.isEmpty) {
        setState(() {
          _error =
              '\u65e0\u6cd5\u52a0\u8f7d\u6280\u80fd\u5217\u8868\uff0c\u8bf7\u68c0\u67e5\u7f51\u7edc\u8fde\u63a5';
          _loading = false;
        });
        return;
      }
      _applyFilters();
    } catch (e) {
      setState(() => _error = '\u52a0\u8f7d\u5931\u8d25: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    var result = List<SkillEntry>.from(_allSkills);

    if (_selectedCategory == '\u5df2\u5b89\u88c5') {
      result =
          result.where((s) => _skillMarketplace.isInstalled(s.id)).toList();
    } else if (_selectedCategory != '\u5168\u90e8') {
      result = result.where((s) {
        final displayCat = _categoryDisplayNames[s.category] ?? s.category;
        return displayCat == _selectedCategory ||
            s.category == _selectedCategory;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q) ||
            s.tags.any((t) => t.toLowerCase().contains(q)) ||
            s.author.toLowerCase().contains(q);
      }).toList();
    }

    setState(() => _displayedSkills = result);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
      _applyFilters();
    });
  }

  void _selectCategory(String cat) {
    setState(() => _selectedCategory = cat);
    _applyFilters();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _installSkill(SkillEntry skill) async {
    setState(() => _installingIds.add(skill.id));
    final ok = await _skillMarketplace.install(skill);
    if (!mounted) return;
    setState(() => _installingIds.remove(skill.id));
    if (ok) {
      _showSnack(
          '${skill.name} \u5b89\u88c5\u6210\u529f\uff01\u53ef\u5728\u300c\u5df2\u5b89\u88c5\u300d\u4e2d\u67e5\u770b\u4f7f\u7528\u6307\u5357');
      _applyFilters();
    } else {
      _showSnack(
          '${skill.name} \u5b89\u88c5\u5931\u8d25\uff0c\u8bf7\u68c0\u67e5\u7f51\u7edc');
    }
  }

  Future<void> _uninstallSkill(SkillEntry skill) async {
    final ok = await _skillMarketplace.uninstall(skill.id);
    if (!mounted) return;
    if (ok) {
      _showSnack('${skill.name} \u5df2\u5378\u8f7d');
      _applyFilters();
    }
  }

  Future<void> _showSkillDetail(SkillEntry skill) async {
    final content = await _skillMarketplace.readSkillContent(skill.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _SkillDetailDialog(
        skill: skill,
        content: content,
        isInstalled: _skillMarketplace.isInstalled(skill.id),
        onInstall: () {
          Navigator.of(ctx).pop();
          _installSkill(skill);
        },
        onUninstall: () {
          Navigator.of(ctx).pop();
          _uninstallSkill(skill);
        },
      ),
    );
  }

  // ==================== 蒸馏功能 ====================

  Widget _buildDistillButton(LingBiColors c) {
    return InkWell(
      onTap: _distilling ? null : _showDistillDialog,
      borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space1,
        ),
        decoration: BoxDecoration(
          color: _distilling ? c.muted : c.accent,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_distilling)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              _distilling ? '蒸馏中...' : '从我的作品蒸馏',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistillDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('从我的作品蒸馏 Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '蒸馏将从你的正典（Canon）和写作风格中自动生成一个专属 Skill。',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Skill 名称（可选）',
                hintText: '默认使用项目名+风格',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startDistillation(nameCtrl.text.trim());
            },
            child: const Text('开始蒸馏'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDistillation(String customName) async {
    if (!ServiceLocator.instance.initSucceeded) {
      _showSnack('降级模式下无法使用蒸馏功能');
      return;
    }
    setState(() => _distilling = true);
    try {
      final distillation = ServiceLocator.instance.distillationService;
      final result = await distillation.distill(DistillationConfig(
        projectId: widget.projectId!,
        projectName: customName.isNotEmpty ? customName : '我的',
        skillName: customName,
      ));
      if (!mounted) return;
      setState(() => _distilling = false);
      if (result.success) {
        _showSnack('蒸馏成功！「${result.skillName}」已添加到技能列表');
        _applyFilters();
      } else {
        _showSnack(result.error ?? '蒸馏失败');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _distilling = false);
      _showSnack('蒸馏失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Column(
      children: [
        _buildHeader(c),
        _buildSearchBar(c),
        _buildCategoryFilter(c),
        Expanded(child: _buildContent(c)),
      ],
    );
  }

  Widget _buildContent(LingBiColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LingBiIcons.download, size: 40, color: c.muted),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: c.fgSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadSkills,
              child: const Text('\u91cd\u8bd5'),
            ),
          ],
        ),
      );
    }
    if (_displayedSkills.isEmpty) {
      return Center(
        child: Text(
          _selectedCategory == '\u5df2\u5b89\u88c5'
              ? '\u8fd8\u6ca1\u6709\u5b89\u88c5\u4efb\u4f55\u6280\u80fd'
              : '\u6ca1\u6709\u627e\u5230\u5339\u914d\u7684\u6280\u80fd',
          style: TextStyle(color: c.muted, fontSize: 14),
        ),
      );
    }
    return _buildSkillGrid(c);
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
          InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(LingBiTokens.space1),
              child: Icon(
                LingBiIcons.chevronLeft,
                size: 20,
                color: c.fgSecondary,
              ),
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          Text(
            '\u6280\u80fd\u5e02\u573a',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.fg,
              letterSpacing: -0.625 / 26 * 26,
            ),
          ),
          const Spacer(),
          // 蒸馏入口：从我的作品生成 Skill
          if (widget.projectId != null) _buildDistillButton(c),
          const SizedBox(width: LingBiTokens.space3),
          Text(
            '已安装 ${_countInstalled()} 个',
            style: TextStyle(fontSize: 13, color: c.muted),
          ),
        ],
      ),
    );
  }

  int _countInstalled() {
    return _allSkills.where((s) => _skillMarketplace.isInstalled(s.id)).length;
  }

  Widget _buildSearchBar(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LingBiTokens.space6),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
          hintText: '\u641c\u7d22\u6280\u80fd\u2026',
          prefixIcon: Icon(LingBiIcons.search, size: 18),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        LingBiTokens.space3,
        LingBiTokens.space6,
        LingBiTokens.space4,
      ),
      child: SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isActive = cat == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: LingBiTokens.space2),
              child: InkWell(
                onTap: () => _selectCategory(cat),
                borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingBiTokens.space4,
                    vertical: LingBiTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive ? c.accent.withValues(alpha: 0.1) : c.surface,
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
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? c.accent : c.fgSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkillGrid(LingBiColors c) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        0,
        LingBiTokens.space6,
        LingBiTokens.space6,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: LingBiTokens.space4,
        mainAxisSpacing: LingBiTokens.space4,
        childAspectRatio: 1.1,
      ),
      itemCount: _displayedSkills.length,
      itemBuilder: (context, index) =>
          _buildSkillCard(_displayedSkills[index], c),
    );
  }

  Widget _buildSkillCard(SkillEntry skill, LingBiColors c) {
    final displayCategory =
        _categoryDisplayNames[skill.category] ?? skill.category;
    final route = defaultRouteRuleFor(skill.id);
    final rating = (4.0 + (skill.downloadCount % 10) / 10.0).toStringAsFixed(1);
    final installed = _skillMarketplace.isInstalled(skill.id);
    final installing = _installingIds.contains(skill.id);

    return InkWell(
      onTap: () => _showSkillDetail(skill),
      borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(LingBiTokens.space4),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
          border: Border.all(
            color: installed
                ? Colors.green.withValues(alpha: 0.4)
                : c.borderOpaque.withValues(alpha: 0.4),
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
                _buildBadge(c, displayCategory),
                if (installed) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(LingBiTokens.radiusPill),
                    ),
                    child: const Text(
                      '\u5df2\u5b89\u88c5',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.star, size: 12, color: LingBiTokens.warning),
                const SizedBox(width: 2),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.fgSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LingBiTokens.space3),
            Text(
              skill.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.fg,
              ),
            ),
            const SizedBox(height: LingBiTokens.space1),
            Expanded(
              child: Text(
                skill.description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: c.fgSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (route != null) ...[
              const SizedBox(height: LingBiTokens.space1),
              Text(
                '自动路由：${route.entry.displayName} · 阈值 ${route.minScore.toStringAsFixed(1)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: c.accent,
                ),
              ),
            ],
            const SizedBox(height: LingBiTokens.space3),
            Row(
              children: [
                Icon(LingBiIcons.download, size: 12, color: c.muted),
                const SizedBox(width: LingBiTokens.space1),
                Text(
                  _formatCount(skill.downloadCount),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: c.muted,
                  ),
                ),
                const Spacer(),
                if (installing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (installed)
                  _buildActionButton(c, '\u67e5\u770b\u6307\u5357',
                      () => _showSkillDetail(skill))
                else
                  _buildActionButton(
                      c, '\u5b89\u88c5', () => _installSkill(skill)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(LingBiColors c, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: c.accent,
        ),
      ),
    );
  }

  Widget _buildActionButton(LingBiColors c, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space3,
          vertical: LingBiTokens.space1,
        ),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}\u4e07';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

/// \u6280\u80fd\u8be6\u60c5\u5bf9\u8bdd\u6846 \u2014 \u663e\u793a SKILL.md \u5185\u5bb9\uff08\u4f7f\u7528\u6b65\u9aa4\u6307\u5357\uff09
class _SkillDetailDialog extends StatelessWidget {
  const _SkillDetailDialog({
    required this.skill,
    required this.content,
    required this.isInstalled,
    required this.onInstall,
    required this.onUninstall,
  });

  final SkillEntry skill;
  final String? content;
  final bool isInstalled;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(LingBiTokens.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: c.fg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${skill.author} \u00b7 v${skill.version} \u00b7 ${_formatCount(skill.downloadCount)} \u6b21\u5b89\u88c5',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: content != null
                  ? SingleChildScrollView(
                      child: _renderMarkdown(content!, c),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isInstalled
                                ? '\u8bfb\u53d6\u6280\u80fd\u5185\u5bb9\u5931\u8d25'
                                : '\u5b89\u88c5\u540e\u53ef\u67e5\u770b\u5b8c\u6574\u4f7f\u7528\u6307\u5357',
                            style: TextStyle(color: c.fgSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            skill.description,
                            style: TextStyle(color: c.muted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isInstalled) ...[
                  OutlinedButton(
                    onPressed: onUninstall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('\u5378\u8f7d'),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton(
                  onPressed: isInstalled
                      ? () => Navigator.of(context).pop()
                      : onInstall,
                  child: Text(isInstalled
                      ? '\u5173\u95ed'
                      : '\u5b89\u88c5\u6b64\u6280\u80fd'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderMarkdown(String md, LingBiColors c) {
    final lines = md.split('\n');
    final widgets = <Widget>[];
    var inCodeBlock = false;
    final codeBuffer = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('```')) {
        if (inCodeBlock) {
          widgets.add(_buildCodeBlock(codeBuffer.toString(), c));
          codeBuffer.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
        continue;
      }
      if (inCodeBlock) {
        codeBuffer.writeln(line);
        continue;
      }
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.substring(2),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: c.fg),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line.substring(3),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.fg),
          ),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(4),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: c.fg),
          ),
        ));
      } else if (line.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.accent, width: 3)),
          ),
          child: Text(
            line.substring(2),
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: c.fgSecondary,
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\u2022  ', style: TextStyle(color: c.accent, fontSize: 13)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: TextStyle(
                      fontSize: 13, color: c.fgSecondary, height: 1.5),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('|')) {
        widgets.add(Text(
          line,
          style: TextStyle(
              fontSize: 12, fontFamily: 'monospace', color: c.fgSecondary),
        ));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Text(
          line,
          style: TextStyle(fontSize: 13, color: c.fgSecondary, height: 1.6),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildCodeBlock(String code, LingBiColors c) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        border: Border.all(color: c.borderOpaque.withValues(alpha: 0.3)),
      ),
      child: SelectableText(
        code.trimRight(),
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: c.fg,
          height: 1.5,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}\u4e07';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
