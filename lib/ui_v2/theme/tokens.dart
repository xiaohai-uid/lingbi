import 'package:flutter/material.dart';

class LingBiTokens {
  LingBiTokens._();

  // ─── Brand Colors ───────────────────────────────────────────────
  static const Color inkGold = Color(0xFFC9A96E); // 墨金 — 灵笔品牌色
  static const Color inkGoldHover = Color(0xFFB8944F);
  static const Color inkGoldLight = Color(0xFF9A7B3F); // 亮色背景用深金
  static const Color blue = Color(0xFF0075DE);
  static const Color blueHover = Color(0xFF005BAB);
  static const Color cinnabar = Color(0xFFC75B39);
  static const Color cinnabarSoft = Color(0xFFE8916A);

  // ─── Light Palette ──────────────────────────────────────────────
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F6F3);
  static const Color lightSurfaceContainer = Color(0xFFEFEDE8);
  static const Color lightFg = Color(0xFF1A1A18);
  static const Color lightFgSecondary = Color(0xFF5C5A54);
  static const Color lightMuted = Color(0xFF9C9890);
  static const Color lightBorder = Color(0x14FFFFFF);
  static const Color lightBorderOpaque = Color(0xFFE4E2DC);

  // ─── Dark Palette ───────────────────────────────────────────────
  static const Color darkBg = Color(0xFF1A1A18);
  static const Color darkSurface = Color(0xFF252523);
  static const Color darkSurfaceContainer = Color(0xFF2F2F2C);
  static const Color darkFg = Color(0xFFEAE8E3);
  static const Color darkFgSecondary = Color(0xFFA09C95);
  static const Color darkMuted = Color(0xFF6B6862);
  static const Color darkBorder = Color(0x14FFFFFF);
  static const Color darkBorderOpaque = Color(0xFF3A3A36);

  // ─── Semantic ───────────────────────────────────────────────────
  static const Color success = Color(0xFF1AAE39);
  static const Color warning = Color(0xFFDD5B00);
  static const Color error = Color(0xFFDC2626);

  // ─── Typography ─────────────────────────────────────────────────
  static const String fontDisplay = 'Noto Serif SC'; // 标题/品牌 — 衬线体
  static const String fontBody = 'Noto Sans SC';
  static const String fontMono = 'JetBrains Mono';

  // ─── Spacing ────────────────────────────────────────────────────
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ─── Radius ─────────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusPill = 9999;

  // ─── Elevation ──────────────────────────────────────────────────
  static List<BoxShadow> raisedShadow(Color shadowColor) => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.027),
          blurRadius: 7.85,
          offset: const Offset(0, 2.025),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.02),
          blurRadius: 2.93,
          offset: const Offset(0, 0.8),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.01),
          blurRadius: 1.04,
          offset: const Offset(0, 0.175),
        ),
      ];

  // ─── Layout ─────────────────────────────────────────────────────
  static const double sidebarWidth = 240;
  static const double topBarHeight = 52;
  static const double aiPanelWidth = 380;
  static const double containerMaxWidth = 1200;
}

class LingBiColors extends ThemeExtension<LingBiColors> {

  const LingBiColors({
    required this.bg,
    required this.surface,
    required this.surfaceContainer,
    required this.fg,
    required this.fgSecondary,
    required this.muted,
    required this.border,
    required this.borderOpaque,
    required this.accent,
    required this.accentHover,
    required this.cinnabar,
    required this.cinnabarSoft,
  });
  final Color bg;
  final Color surface;
  final Color surfaceContainer;
  final Color fg;
  final Color fgSecondary;
  final Color muted;
  final Color border;
  final Color borderOpaque;
  final Color accent;
  final Color accentHover;
  final Color cinnabar;
  final Color cinnabarSoft;

  static const LingBiColors light = LingBiColors(
    bg: LingBiTokens.lightBg,
    surface: LingBiTokens.lightSurface,
    surfaceContainer: LingBiTokens.lightSurfaceContainer,
    fg: LingBiTokens.lightFg,
    fgSecondary: LingBiTokens.lightFgSecondary,
    muted: LingBiTokens.lightMuted,
    border: LingBiTokens.lightBorder,
    borderOpaque: LingBiTokens.lightBorderOpaque,
    accent: LingBiTokens.inkGoldLight,
    accentHover: LingBiTokens.inkGold,
    cinnabar: LingBiTokens.cinnabar,
    cinnabarSoft: LingBiTokens.cinnabarSoft,
  );

  static const LingBiColors dark = LingBiColors(
    bg: LingBiTokens.darkBg,
    surface: LingBiTokens.darkSurface,
    surfaceContainer: LingBiTokens.darkSurfaceContainer,
    fg: LingBiTokens.darkFg,
    fgSecondary: LingBiTokens.darkFgSecondary,
    muted: LingBiTokens.darkMuted,
    border: LingBiTokens.darkBorder,
    borderOpaque: LingBiTokens.darkBorderOpaque,
    accent: LingBiTokens.inkGold,
    accentHover: LingBiTokens.inkGoldHover,
    cinnabar: LingBiTokens.cinnabarSoft,
    cinnabarSoft: LingBiTokens.cinnabar,
  );

  @override
  LingBiColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceContainer,
    Color? fg,
    Color? fgSecondary,
    Color? muted,
    Color? border,
    Color? borderOpaque,
    Color? accent,
    Color? accentHover,
    Color? cinnabar,
    Color? cinnabarSoft,
  }) {
    return LingBiColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      fg: fg ?? this.fg,
      fgSecondary: fgSecondary ?? this.fgSecondary,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      borderOpaque: borderOpaque ?? this.borderOpaque,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      cinnabar: cinnabar ?? this.cinnabar,
      cinnabarSoft: cinnabarSoft ?? this.cinnabarSoft,
    );
  }

  @override
  LingBiColors lerp(LingBiColors other, double t) {
    return LingBiColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fgSecondary: Color.lerp(fgSecondary, other.fgSecondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderOpaque: Color.lerp(borderOpaque, other.borderOpaque, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      cinnabar: Color.lerp(cinnabar, other.cinnabar, t)!,
      cinnabarSoft: Color.lerp(cinnabarSoft, other.cinnabarSoft, t)!,
    );
  }

  static LingBiColors of(BuildContext context) =>
      Theme.of(context).extension<LingBiColors>() ?? LingBiColors.light;
}
