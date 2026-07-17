import 'package:flutter/material.dart';

import 'package:lingbi/ui/theme/wg_components.dart';

class WgNavItem {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const WgNavItem({required this.icon, required this.label, this.active = false, this.onTap});
}

/// 统一的灵笔侧边栏：品牌 logo + 导航项 + 底部用户区。
/// 用于仪表盘 / 知识库 / 故事画布 / 设置 等导航页，消除重复代码。
class WgSidebar extends StatelessWidget {
  final List<WgNavItem> items;
  final String brandName;
  final String userName;
  final String userRole;
  const WgSidebar({
    super.key,
    this.items = const [],
    this.brandName = 'Lingbi',
    this.userName = '吾名',
    this.userRole = '创作者',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WgTokens.bgFor(context).withValues(alpha: 0.95), WgTokens.bgFor(context).withValues(alpha: 0.85)],
          ),
          border: Border(right: BorderSide(color: WgTokens.borderFor(context))),
        ),
        child: Column(children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            child: Row(children: [
              _brandLogo(),
              const SizedBox(width: 10),
              Text(brandName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.01)),
            ]),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [for (final it in items) _navTile(it)]),
            ),
          const Spacer(),
          _userFooter(context),
        ]),
      ),
    );
  }

  Widget _brandLogo() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [WgTokens.accent, WgTokens.warn]),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: WgTokens.accent.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Center(child: Text('灵', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
      );

  Widget _navTile(WgNavItem it) => InkWell(
        onTap: it.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: it.active ? WgTokens.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(it.icon, size: 18, color: it.active ? WgTokens.accent : WgTokens.fg2),
            const SizedBox(width: 12),
            Text(it.label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: it.active ? FontWeight.w600 : FontWeight.w400,
                    color: it.active ? WgTokens.accent : WgTokens.fg2)),
          ]),
        ),
      );

  Widget _userFooter(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: WgTokens.borderFor(context)))),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [WgTokens.accent, WgTokens.warn]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(userName.isNotEmpty ? userName[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(userRole, style: const TextStyle(fontSize: 11, color: WgTokens.fg2, letterSpacing: 0.02)),
          ]),
        ]),
      );
}