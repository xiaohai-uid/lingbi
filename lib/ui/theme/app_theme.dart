import 'package:flutter/material.dart';

/// 灵笔主题系统 — Warm Glass 暖色调玻璃拟态
/// 参考 Open Design 设计系统：暖白底色 + 琥珀金强调 + Noto 字体
class AppTheme {
  AppTheme._();

  // ─── 品牌色系（Open Design Warm Glass） ───
  static const _warmBg = Color(0xFFFAF8F5); // 暖白底色
  static const _surface = Color(0xFFFFFFFF); // 表面白
  static const _surfaceGlass = Color(0xCCFFFFFF); // 毛玻璃白 (80%)
  static const _fg = Color(0xFF3D3529); // 主文字暖棕
  static const _fg2 = Color(0xFF8B7D6B); // 次要文字
  static const _fg3 = Color(0xFF8A7B68); // 辅助文字
  static const _gold = Color(0xFFE8A838); // 琥珀金强调
  static const _border = Color(0xFFE8E0D6); // 边框
  static const _borderLight = Color(0xFFF0EAE0); // 浅边框

  // ─── 暗色模式 ───
  static const _darkBg = Color(0xFF1A1612);
  static const _darkSurface = Color(0xFF2C261E);
  static const _darkFg = Color(0xFFE8DDD0);
  static const _darkFg2 = Color(0xFFA89880);
  static const _darkFg3 = Color(0xFF7A6C5C);
  static const _darkBorderLight = Color(0xFF332C22);

  // ─── 字体 ───
  static const String _bodyFont = 'NotoSansSC';
  static const String _titleFont = 'NotoSerifSC';

  // ─── 亮色 / 暗色 ───
  static ThemeData get light => _buildLightTheme();
  static ThemeData get dark => _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: _gold,
      fontFamily: _bodyFont,
    );
    return base.copyWith(
      scaffoldBackgroundColor: _warmBg,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: _surfaceGlass,
        foregroundColor: _fg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _fg,
          fontFamily: _titleFont,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderLight),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(
        color: _borderLight,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(color: _fg2, size: 20),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: _titleFont,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _fg,
            letterSpacing: -0.5),
        displayMedium: TextStyle(
            fontFamily: _titleFont,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _fg,
            letterSpacing: -0.3),
        titleLarge: TextStyle(
            fontFamily: _titleFont,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _fg),
        titleMedium: TextStyle(
            fontFamily: _titleFont,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _fg),
        titleSmall: TextStyle(
            fontFamily: _titleFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _fg),
        bodyLarge: TextStyle(fontSize: 16, color: _fg2, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: _fg2, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, color: _fg3, height: 1.4),
        labelLarge:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _fg),
        labelSmall: TextStyle(fontSize: 12, color: _fg3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _gold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: const TabBarTheme(
        indicatorColor: _gold,
        labelColor: _gold,
        unselectedLabelColor: _fg3,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: _gold,
      fontFamily: _bodyFont,
    );

    return base.copyWith(
      scaffoldBackgroundColor: _darkBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: _darkSurface.withValues(alpha: 0.85),
        foregroundColor: _darkFg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _darkFg,
          fontFamily: _titleFont,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkSurface.withValues(alpha: 0.6),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorderLight),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(
        color: _darkBorderLight,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(color: _darkFg2, size: 20),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: _titleFont,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _darkFg,
            letterSpacing: -0.5),
        displayMedium: TextStyle(
            fontFamily: _titleFont,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _darkFg,
            letterSpacing: -0.3),
        titleLarge: TextStyle(
            fontFamily: _titleFont,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _darkFg),
        titleMedium: TextStyle(
            fontFamily: _titleFont,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _darkFg),
        titleSmall: TextStyle(
            fontFamily: _titleFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _darkFg2),
        bodyLarge: TextStyle(fontSize: 16, color: _darkFg2, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: _darkFg2, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, color: _darkFg3, height: 1.4),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: _darkFg2),
        labelSmall: TextStyle(fontSize: 12, color: _darkFg3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _gold,
          foregroundColor: _darkBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _darkBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: const TabBarTheme(
        indicatorColor: _gold,
        labelColor: _gold,
        unselectedLabelColor: _darkFg3,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13),
      ),
    );
  }
}
