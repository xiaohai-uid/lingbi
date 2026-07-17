import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────
// Warm Glass 设计系统组件库
// 对应 Open Design css/style.css 的所有组件
// ─────────────────────────────────────────────────────

// ═══ 设计令牌 ═══
class WgTokens {
  WgTokens._();

  // 亮色
  static const bg = Color(0xFFFAF8F5);
  static const bgWarm = Color(0xFFF5F0E8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGlass = Color(0xBFFFFFFF); // 75%
  static const fg = Color(0xFF1A1612);
  static const fg2 = Color(0xFF6B635A);
  static const fg3 = Color(0xFF8A7B68);
  static const muted = Color(0xFFC8BFB0);
  static const accent = Color(0xFFE8A838);
  static const accentHover = Color(0xFFD49530);
  static const accentActive = Color(0xFFC0842A);
  static const accentSoft = Color(0x1AE8A838); // 10%
  static const accentGlow = Color(0x33E8A838); // 20%
  static const border = Color(0x1A3D3529);
  static const borderLight = Color(0xFFF0EAE0);
  static const surfaceHover = Color(0xE0FFFFFF);
  static const surfaceStrong = Color(0xF2FFFFFF);
  static const warn = Color(0xFFD4893A);
  static const warnSoft = Color(0x1AD4893A);
  static const success = Color(0xFF5B8C5A);
  static const successSoft = Color(0x1A5B8C5A);
  static const danger = Color(0xFFC45A5A);
  static const dangerSoft = Color(0x1AC45A5A);
  static const info = Color(0xFF5A8CA0);
  static const infoSoft = Color(0x1A5A8CA0);

  // 暗色
  static const darkBg = Color(0xFF1A1612);
  static const darkBgWarm = Color(0xFF231E18);
  static const darkSurface = Color(0xFF2C261E);
  static const darkFg = Color(0xFFE8DDD0);
  static const darkFg2 = Color(0xFFA89880);
  static const darkFg3 = Color(0xFF7A6C5C);
  static const darkBorder = Color(0xFF3D3529);
  static const darkBorderLight = Color(0xFF332C22);

  static const sidebarWidth = 240.0;
  static const topbarHeight = 56.0;
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space8 = 32.0;
  static const space10 = 40.0;
  static const space12 = 48.0;

  static Color bgFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : bg;
  static Color bgWarmFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBgWarm : bgWarm;
  static Color surfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : surface;
  static Color fgFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkFg : fg;
  static Color fg2For(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkFg2 : fg2;
  static Color fg3For(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkFg3 : fg3;
  static Color borderFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : border;
  static Color borderLightFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorderLight
          : borderLight;
}

// ═══ 毛玻璃面板 ═══
class WgGlassPanel extends StatelessWidget {
  const WgGlassPanel({
    super.key,
    required this.child,
    this.blur = 16,
    this.padding,
    this.borderRadius,
    this.color,
    this.borderColor,
  });
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(WgTokens.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ??
                (isDark
                    ? WgTokens.darkSurface.withValues(alpha: 0.85)
                    : WgTokens.surfaceGlass),
            borderRadius:
                borderRadius ?? BorderRadius.circular(WgTokens.radiusLg),
            border: Border.all(
                color: borderColor ??
                    (isDark ? WgTokens.darkBorderLight : WgTokens.borderLight)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══ 暖白卡片 ═══
class WgCard extends StatelessWidget {
  const WgCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.margin,
    this.width,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      width: width,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(WgTokens.space5),
      decoration: BoxDecoration(
        color: isDark ? WgTokens.darkSurface : WgTokens.surface,
        borderRadius: BorderRadius.circular(WgTokens.radiusLg),
        border: Border.all(
            color: borderColor ??
                (isDark ? WgTokens.darkBorderLight : WgTokens.borderLight)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WgTokens.radiusLg),
        child: card,
      );
    }
    return card;
  }
}

// ═══ 项目卡片 ═══
class WgProjectCard extends StatelessWidget {
  const WgProjectCard({
    super.key,
    required this.title,
    this.genre,
    this.status,
    this.chapters = 0,
    this.wordCount = 0,
    this.characters = 0,
    this.qualityScore,
    this.onTap,
    this.accentColor,
  });
  final String title;
  final String? genre;
  final String? status;
  final int chapters;
  final int wordCount;
  final int characters;
  final String? qualityScore;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusText = status == 'in_progress'
        ? '连载中'
        : status == 'completed'
            ? '已完结'
            : '草稿';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WgTokens.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: WgTokens.space4),
        padding: const EdgeInsets.all(WgTokens.space5),
        decoration: BoxDecoration(
          color: isDark ? WgTokens.darkSurface : WgTokens.surface,
          borderRadius: BorderRadius.circular(WgTokens.radiusLg),
          border: Border.all(
              color: isDark ? WgTokens.darkBorderLight : WgTokens.borderLight),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : WgTokens.fg.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部渐变分隔线
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [WgTokens.accent, Color(0xFFD49530)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: WgTokens.space3),
            // 标题
            Text(title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSerifSC',
                  color: isDark ? WgTokens.darkFg : WgTokens.fg,
                )),
            const SizedBox(height: WgTokens.space1),
            // 元信息
            Row(children: [
              if (genre != null) ...[
                Text(genre!,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? WgTokens.darkFg3 : WgTokens.fg3)),
                const SizedBox(width: 8),
                Text('·',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? WgTokens.darkFg3 : WgTokens.fg3)),
                const SizedBox(width: 8),
              ],
              WgBadge(
                statusText,
                type: status == 'completed'
                    ? WgBadgeType.success
                    : WgBadgeType.accent,
              ),
            ]),
            const SizedBox(height: WgTokens.space3),
            // 统计
            Row(children: [
              _stat('$chapters', '章', isDark),
              const SizedBox(width: WgTokens.space4),
              _stat(wordCount.toString(), '字', isDark),
              const SizedBox(width: WgTokens.space4),
              _stat('$characters', '人物', isDark),
              if (qualityScore != null) ...[
                const SizedBox(width: WgTokens.space4),
                _stat(qualityScore!, '质量分', isDark),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, bool isDark) {
    return Text.rich(TextSpan(
      children: [
        TextSpan(
            text: value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? WgTokens.darkFg : WgTokens.fg,
                fontSize: 12)),
        TextSpan(
            text: ' $label',
            style: TextStyle(
                color: isDark ? WgTokens.darkFg2 : WgTokens.fg2, fontSize: 12)),
      ],
    ));
  }
}

// ═══ Badge ═══
enum WgBadgeType { accent, success, info, danger, neutral }

class WgBadge extends StatelessWidget {
  const WgBadge(this.label,
      {super.key, this.type = WgBadgeType.accent, this.fontSize = 11});
  final String label;
  final WgBadgeType type;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    switch (type) {
      case WgBadgeType.accent:
        bg = WgTokens.accentSoft;
        text = WgTokens.accent;
      case WgBadgeType.success:
        bg = WgTokens.successSoft;
        text = WgTokens.success;
      case WgBadgeType.info:
        bg = WgTokens.infoSoft;
        text = WgTokens.info;
      case WgBadgeType.danger:
        bg = WgTokens.dangerSoft;
        text = WgTokens.danger;
      case WgBadgeType.neutral:
        bg = WgTokens.bgWarm;
        text = WgTokens.fg3;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.w500, color: text)),
    );
  }
}

// ═══ 统计卡片 ═══
class WgStatCard extends StatelessWidget {
  const WgStatCard(
      {super.key,
      required this.icon,
      required this.value,
      required this.label});
  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(WgTokens.space4),
      decoration: BoxDecoration(
        color: isDark ? WgTokens.darkSurface : WgTokens.surface,
        borderRadius: BorderRadius.circular(WgTokens.radiusMd),
        border: Border.all(
            color: isDark ? WgTokens.darkBorderLight : WgTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: WgTokens.accentSoft,
              borderRadius: BorderRadius.circular(WgTokens.radiusSm),
            ),
            child:
                Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(height: WgTokens.space3),
          Text(value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSerifSC',
                color: isDark ? WgTokens.darkFg : WgTokens.fg,
                height: 1.2,
              )),
          const SizedBox(height: WgTokens.space1),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? WgTokens.darkFg3 : WgTokens.fg3)),
        ],
      ),
    );
  }
}

// ═══ 质量进度条 ═══
enum WgQualityLevel { high, med, low }

class WgQualityBar extends StatelessWidget {
  const WgQualityBar({
    super.key,
    required this.percent,
    required this.label,
    required this.score,
    this.level = WgQualityLevel.med,
  });
  final double percent; // 0-100
  final String label;
  final String score;
  final WgQualityLevel level;

  @override
  Widget build(BuildContext context) {
    final color = level == WgQualityLevel.high
        ? WgTokens.success
        : level == WgQualityLevel.med
            ? WgTokens.accent
            : WgTokens.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: WgTokens.fg2)),
          Text(score,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrainsMono',
                  color: color)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 4,
            color: WgTokens.bgWarm,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent / 100,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══ 按钮 ═══
class WgButton extends StatelessWidget {
  const WgButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.primary = true,
    this.small = false,
    this.fullWidth = false,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool primary;
  final bool small;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final hPad = small ? 12.0 : 20.0;
    final vPad = small ? 4.0 : 8.0;
    final fontSize = small ? 12.0 : 14.0;
    final radius = small ? WgTokens.radiusSm : WgTokens.radiusMd;

    if (primary) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [WgTokens.accent, WgTokens.accentHover]),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                  color: WgTokens.accentGlow,
                  blurRadius: 8,
                  offset: Offset(0, 2))
            ],
          ),
          child: _content(fontSize, WgTokens.surface),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: WgTokens.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: WgTokens.border),
        ),
        child: _content(fontSize, WgTokens.fg),
      ),
    );
  }

  Widget _content(double fontSize, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: fontSize + 2, color: textColor),
          const SizedBox(width: 6),
        ],
        Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: textColor)),
      ],
    );
  }
}

// ═══ 幽灵按钮 ═══
class WgGhostButton extends StatelessWidget {
  const WgGhostButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.small = false,
    this.color,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool small;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final hPad = small ? 12.0 : 20.0;
    final vPad = small ? 4.0 : 8.0;
    final fontSize = small ? 12.0 : 14.0;
    final btnColor = color ?? WgTokens.fg2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WgTokens.radiusSm),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2, color: btnColor),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: btnColor)),
          ],
        ),
      ),
    );
  }
}

// ═══ 输入框 ═══
class WgInput extends StatelessWidget {
  const WgInput(
      {super.key,
      this.hintText,
      this.controller,
      this.onChanged,
      this.maxLines = 1});
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WgTokens.darkSurface : WgTokens.surface,
        borderRadius: BorderRadius.circular(WgTokens.radiusMd),
        border:
            Border.all(color: isDark ? WgTokens.darkBorder : WgTokens.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        style: TextStyle(
            fontSize: 14, color: isDark ? WgTokens.darkFg : WgTokens.fg),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
              color: isDark ? WgTokens.darkFg3 : WgTokens.fg3, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }
}

// ═══ 顶栏 ═══
class WgTopbar extends StatelessWidget {
  const WgTopbar(
      {super.key, required this.title, this.breadcrumb, this.actions});
  final String title;
  final String? breadcrumb;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: WgTokens.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: WgTokens.space6),
      decoration: BoxDecoration(
        color: isDark
            ? WgTokens.darkSurface.withValues(alpha: 0.85)
            : WgTokens.surfaceGlass,
        border: Border(
            bottom: BorderSide(
                color:
                    isDark ? WgTokens.darkBorderLight : WgTokens.borderLight)),
      ),
      child: Row(
        children: [
          if (breadcrumb != null) ...[
            Text(breadcrumb!,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? WgTokens.darkFg3 : WgTokens.fg3)),
            const SizedBox(width: WgTokens.space2),
            Text('/',
                style:
                    TextStyle(color: isDark ? WgTokens.darkFg2 : WgTokens.fg2)),
            const SizedBox(width: WgTokens.space2),
          ],
          Text(title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSerifSC',
                color: isDark ? WgTokens.darkFg : WgTokens.fg,
              )),
          const Spacer(),
          if (actions != null) ...actions!,
          // 用户头像
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: WgTokens.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
                child: Text('吾',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: WgTokens.accent))),
          ),
        ],
      ),
    );
  }
}

// ═══ 空状态 ═══
class WgEmptyState extends StatelessWidget {
  const WgEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.description,
      this.action});
  final String icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WgTokens.space12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: 40,
                    color: isDark ? WgTokens.darkFg3 : WgTokens.fg3)),
            const SizedBox(height: WgTokens.space4),
            Text(title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSerifSC',
                  color: isDark ? WgTokens.darkFg : WgTokens.fg,
                )),
            if (description != null) ...[
              const SizedBox(height: WgTokens.space2),
              Text(description!,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? WgTokens.darkFg3 : WgTokens.fg3)),
            ],
            if (action != null) ...[
              const SizedBox(height: WgTokens.space5),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══ 章节树项目 ═══
class WgTreeItem extends StatelessWidget {
  const WgTreeItem({
    super.key,
    required this.label,
    this.chapterNum,
    required this.status,
    this.active = false,
    this.onTap,
  });
  final String label;
  final String? chapterNum;
  final String status; // 'done', 'draft', 'pending'
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = status == 'done'
        ? WgTokens.success
        : status == 'draft'
            ? WgTokens.accent
            : WgTokens.fg3;
    final dotText = status == 'done'
        ? '✓'
        : status == 'draft'
            ? '●'
            : '○';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WgTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? WgTokens.accentSoft : null,
          borderRadius: BorderRadius.circular(WgTokens.radiusSm),
        ),
        child: Row(
          children: [
            Text('📄',
                style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? WgTokens.darkFg3 : WgTokens.fg3)
                        .withValues(alpha: 0.5))),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                chapterNum != null ? '第$chapterNum章 · $label' : label,
                style: TextStyle(
                  fontSize: 13,
                  color: active
                      ? WgTokens.accent
                      : (isDark ? WgTokens.darkFg2 : WgTokens.fg2),
                  fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                  child: Text(dotText,
                      style: TextStyle(fontSize: 10, color: dotColor))),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ 角色卡片 ═══
class WgCharacterCard extends StatelessWidget {
  const WgCharacterCard({
    super.key,
    required this.avatarText,
    required this.name,
    required this.role,
    required this.tags,
    required this.arc,
    this.onTap,
  });
  final String avatarText;
  final String name;
  final String role;
  final List<String> tags;
  final String arc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WgTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(WgTokens.space5),
        decoration: BoxDecoration(
          color: isDark ? WgTokens.darkSurface : WgTokens.surface,
          borderRadius: BorderRadius.circular(WgTokens.radiusMd),
          border: Border.all(
              color: isDark ? WgTokens.darkBorderLight : WgTokens.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [WgTokens.accentSoft, WgTokens.bgWarm]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                  child: Text(avatarText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NotoSerifSC',
                        color: WgTokens.accent,
                      ))),
            ),
            const SizedBox(width: WgTokens.space4),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? WgTokens.darkFg : WgTokens.fg)),
                  const SizedBox(height: 2),
                  Text(role,
                      style:
                          const TextStyle(fontSize: 12, color: WgTokens.fg3)),
                  const SizedBox(height: WgTokens.space2),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tags.map((t) => WgBadge(t)).toList(),
                  ),
                  const SizedBox(height: WgTokens.space3),
                  Container(
                    padding: const EdgeInsets.only(top: WgTokens.space3),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: isDark
                                  ? WgTokens.darkBorderLight
                                  : WgTokens.borderLight)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('成长弧',
                            style:
                                TextStyle(fontSize: 11, color: WgTokens.fg3)),
                        const SizedBox(height: 2),
                        Text(arc,
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark ? WgTokens.darkFg : WgTokens.fg,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ 时间线项目 ═══
class WgTimelineItem extends StatelessWidget {
  const WgTimelineItem({
    super.key,
    required this.time,
    required this.title,
    required this.description,
    this.badges = const [],
    this.isLast = false,
  });
  final String time;
  final String title;
  final String description;
  final List<String> badges;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: WgTokens.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WgTokens.accent, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 2,
                        color: isDark ? WgTokens.darkBorder : WgTokens.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: WgTokens.space3),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : WgTokens.space5),
              padding: const EdgeInsets.all(WgTokens.space3),
              decoration: BoxDecoration(
                color: isDark ? WgTokens.darkSurface : WgTokens.surface,
                borderRadius: BorderRadius.circular(WgTokens.radiusMd),
                border: Border.all(
                    color: isDark
                        ? WgTokens.darkBorderLight
                        : WgTokens.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time,
                      style:
                          const TextStyle(fontSize: 11, color: WgTokens.fg3)),
                  const SizedBox(height: 2),
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? WgTokens.darkFg : WgTokens.fg)),
                  const SizedBox(height: 4),
                  Text(description,
                      style:
                          const TextStyle(fontSize: 12, color: WgTokens.fg2)),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: WgTokens.space2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          badges.map((b) => WgBadge(b, fontSize: 10)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══ 场景卡片 ═══
class WgSceneCard extends StatelessWidget {
  const WgSceneCard({
    super.key,
    required this.title,
    required this.meta,
    required this.preview,
    required this.badge,
    this.badgeType = WgBadgeType.success,
    this.qualityIndicators = const [],
  });
  final String title;
  final String meta;
  final String preview;
  final String badge;
  final WgBadgeType badgeType;
  final List<Map<String, dynamic>> qualityIndicators;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: WgTokens.space3),
      padding: const EdgeInsets.all(WgTokens.space4),
      decoration: BoxDecoration(
        color: isDark ? WgTokens.darkSurface : WgTokens.surface,
        borderRadius: BorderRadius.circular(WgTokens.radiusMd),
        border: Border.all(
            color: isDark ? WgTokens.darkBorderLight : WgTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? WgTokens.darkFg : WgTokens.fg)),
            WgBadge(badge, type: badgeType),
          ]),
          const SizedBox(height: 4),
          Text(meta, style: const TextStyle(fontSize: 11, color: WgTokens.fg3)),
          const SizedBox(height: WgTokens.space2),
          Text(preview,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? WgTokens.darkFg2 : WgTokens.fg2,
                  height: 1.5)),
          if (qualityIndicators.isNotEmpty) ...[
            const SizedBox(height: WgTokens.space2),
            Row(
                children: qualityIndicators.map((q) {
              final level = q['level'] as String;
              final color = level == 'high'
                  ? WgTokens.success
                  : level == 'med'
                      ? WgTokens.accent
                      : WgTokens.danger;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 4),
                    Text(q['label'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? WgTokens.darkFg3 : WgTokens.fg3)),
                  ],
                ),
              );
            }).toList()),
          ],
        ],
      ),
    );
  }
}

// ═══ 建议卡片 ═══
class WgSuggestionCard extends StatelessWidget {
  const WgSuggestionCard({
    super.key,
    required this.title,
    required this.description,
    this.type = WgBadgeType.accent,
  });
  final String title;
  final String description;
  final WgBadgeType type;

  @override
  Widget build(BuildContext context) {
    Color bg, border;
    switch (type) {
      case WgBadgeType.accent:
        bg = WgTokens.accentSoft;
        border = const Color(0x26E8A838);
      case WgBadgeType.info:
        bg = WgTokens.infoSoft;
        border = const Color(0x1F5A8CA0);
      case WgBadgeType.neutral:
        bg = WgTokens.bgWarm;
        border = WgTokens.borderLight;
      default:
        bg = WgTokens.accentSoft;
        border = const Color(0x26E8A838);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: WgTokens.space2),
      padding: const EdgeInsets.all(WgTokens.space3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(WgTokens.radiusMd),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WgTokens.fg)),
          const SizedBox(height: 2),
          Text(description,
              style: const TextStyle(
                  fontSize: 11, color: WgTokens.fg2, height: 1.5)),
        ],
      ),
    );
  }
}

// ═══ 侧边栏布局 ═══


// ═══ 上下文面板（右栏用） ═══
class WgContextSection extends StatelessWidget {
  const WgContextSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: WgTokens.space3),
          child: Text(title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: WgTokens.fg3,
              )),
        ),
        child,
      ],
    );
  }
}
