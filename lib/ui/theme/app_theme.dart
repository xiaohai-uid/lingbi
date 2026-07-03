import 'package:flutter/material.dart';

/// 灵笔毛玻璃主题系统
class AppTheme {
  AppTheme._();

  // ─── 品牌色系 ───
  static const _primary = Color(0xFF7C5CFC); // 柔和紫
  static const _primaryLight = Color(0xFFA78BFA);
  static const _primaryDark = Color(0xFF6D4FE8);

  // ─── 亮色毛玻璃 ───
  static ThemeData get light => _buildLightTheme();
  static ThemeData get dark => _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: _primary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF2F0F7),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        foregroundColor: const Color(0xFF1C1B1F),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C1B1F),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.6),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1, space: 0,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF6B7280), size: 20),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: Color(0xFF1C1B1F), letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F), letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1C1B1F)),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1C1B1F)),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF2D2D2D), height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4B4B4B), height: 1.5),
        bodySmall: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D)),
        labelSmall: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary.withValues(alpha: 0.6), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: _primary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.7),
        foregroundColor: const Color(0xFFE8E8E8),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE8E8E8),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1, space: 0,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF9CA3AF), size: 20),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFF0F0F0), letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFF0F0F0), letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE8E8E8)),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE8E8E8)),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD0D0D0)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFD0D0D0), height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0B0B0), height: 1.5),
        bodySmall: TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFD0D0D0)),
        labelSmall: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F1F1F).withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryLight.withValues(alpha: 0.6), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}