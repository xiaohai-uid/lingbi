/// 斜杠命令菜单
///
/// 在编辑器中输入 "/" 触发，显示可用技能列表。
/// 选择技能后由 SkillActionService 执行。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

/// 斜杠命令菜单组件
class SlashCommandMenu extends StatefulWidget {
  const SlashCommandMenu({
    super.key,
    required this.skills,
    required this.onSelected,
    required this.onDismiss,
    this.position = Offset.zero,
  });

  /// 可用技能列表
  final List<SkillAction> skills;

  /// 选择技能回调
  final ValueChanged<SkillAction> onSelected;

  /// 关闭菜单回调
  final VoidCallback onDismiss;

  /// 菜单显示位置
  final Offset position;

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu> {
  final _searchController = TextEditingController();
  late List<SkillAction> _filteredSkills;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredSkills = widget.skills;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSkills = query.isEmpty
          ? widget.skills
          : widget.skills
              .where((s) =>
                  s.name.toLowerCase().contains(query) ||
                  s.description.toLowerCase().contains(query))
              .toList();
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索技能...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onSubmitted: (_) => _selectCurrent(),
              ),
            ),
            const Divider(height: 1),
            // 技能列表
            Flexible(
              child: _filteredSkills.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '无匹配技能',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredSkills.length,
                      itemBuilder: (context, index) {
                        final skill = _filteredSkills[index];
                        final isSelected = index == _selectedIndex;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          leading: Icon(
                            _iconFor(skill.icon),
                            size: 20,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          title: Text(
                            skill.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            skill.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => widget.onSelected(skill),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCurrent() {
    if (_filteredSkills.isNotEmpty &&
        _selectedIndex < _filteredSkills.length) {
      widget.onSelected(_filteredSkills[_selectedIndex]);
    }
  }

  IconData _iconFor(String iconName) {
    return switch (iconName) {
      'edit_note' => Icons.edit_note,
      'auto_fix_high' => Icons.auto_fix_high,
      'auto_fix_normal' => Icons.auto_fix_normal,
      'auto_awesome' => Icons.auto_awesome,
      'auto_stories' => Icons.auto_stories,
      'chat' => Icons.chat,
      _ => Icons.bolt,
    };
  }
}

/// 显示斜杠命令菜单的辅助方法
void showSlashCommandMenu({
  required BuildContext context,
  required List<SkillAction> skills,
  required ValueChanged<SkillAction> onSelected,
  Offset position = Offset.zero,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (ctx) => Stack(
      children: [
        // 点击外部关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(color: Colors.transparent),
          ),
        ),
        // 菜单
        Positioned(
          left: position.dx,
          top: position.dy,
          child: SlashCommandMenu(
            skills: skills,
            onSelected: (skill) {
              Navigator.of(ctx).pop();
              onSelected(skill);
            },
            onDismiss: () => Navigator.of(ctx).pop(),
            position: position,
          ),
        ),
      ],
    ),
  );
}
