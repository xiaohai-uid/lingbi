import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const c = LingBiColors.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: c.accent,
        primaryContainer: c.accent.withValues(alpha: 0.12),
        onPrimaryContainer: c.accent,
        secondary: c.cinnabar,
        onSecondary: Colors.white,
        secondaryContainer: c.cinnabar.withValues(alpha: 0.12),
        onSecondaryContainer: c.cinnabar,
        surface: c.bg,
        onSurface: c.fg,
        surfaceContainerHighest: c.surfaceContainer,
        onSurfaceVariant: c.fgSecondary,
        outline: c.borderOpaque,
        error: LingBiTokens.error,
      ),
      extensions: const [LingBiColors.light],
      scaffoldBackgroundColor: c.bg,
      fontFamily: LingBiTokens.fontDisplay,
      dividerColor: c.borderOpaque.withValues(alpha: 0.6),
      cardTheme: _cardTheme(c),
      appBarTheme: _appBarTheme(c),
      navigationBarTheme: _navBarTheme(c),
      inputDecorationTheme: _inputTheme(c),
      textTheme: _textTheme(c),
      dividerTheme: DividerThemeData(
        color: c.borderOpaque.withValues(alpha: 0.5),
        thickness: 1,
        space: 0,
      ),
    );
  }

  static ThemeData dark() {
    const c = LingBiColors.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: c.accent,
        onPrimary: LingBiTokens.darkBg,
        primaryContainer: c.accent.withValues(alpha: 0.18),
        onPrimaryContainer: c.accent,
        secondary: c.cinnabar,
        onSecondary: LingBiTokens.darkBg,
        secondaryContainer: c.cinnabar.withValues(alpha: 0.18),
        onSecondaryContainer: c.cinnabar,
        surface: c.bg,
        onSurface: c.fg,
        surfaceContainerHighest: c.surfaceContainer,
        onSurfaceVariant: c.fgSecondary,
        outline: c.borderOpaque,
        error: LingBiTokens.error,
        onError: Colors.white,
      ),
      extensions: const [LingBiColors.dark],
      scaffoldBackgroundColor: c.bg,
      fontFamily: LingBiTokens.fontDisplay,
      dividerColor: c.borderOpaque.withValues(alpha: 0.5),
      cardTheme: _cardTheme(c),
      appBarTheme: _appBarTheme(c),
      navigationBarTheme: _navBarTheme(c),
      inputDecorationTheme: _inputTheme(c),
      textTheme: _textTheme(c),
      dividerTheme: DividerThemeData(
        color: c.borderOpaque.withValues(alpha: 0.4),
        thickness: 1,
        space: 0,
      ),
    );
  }

  static CardThemeData _cardTheme(LingBiColors c) {
    return CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
        side: BorderSide(color: c.borderOpaque.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
    );
  }

  static AppBarTheme _appBarTheme(LingBiColors c) {
    return AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.fg,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: c.fg,
        fontFamily: LingBiTokens.fontDisplay,
      ),
    );
  }

  static NavigationBarThemeData _navBarTheme(LingBiColors c) {
    return NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.accent.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.accent,
            fontFamily: LingBiTokens.fontDisplay,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: c.fgSecondary,
          fontFamily: LingBiTokens.fontDisplay,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(size: 20, color: c.accent);
        }
        return IconThemeData(size: 20, color: c.fgSecondary);
      }),
    );
  }

  static InputDecorationTheme _inputTheme(LingBiColors c) {
    return InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LingBiTokens.space3,
        vertical: LingBiTokens.space2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        borderSide: BorderSide(color: c.borderOpaque),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        borderSide: BorderSide(color: c.borderOpaque),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c.muted,
        fontFamily: LingBiTokens.fontDisplay,
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c.fgSecondary,
        fontFamily: LingBiTokens.fontDisplay,
      ),
    );
  }

  static TextTheme _textTheme(LingBiColors c) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: c.fg,
        letterSpacing: -2.125 / 64 * 48,
        height: 1.04,
      ),
      displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: c.fg,
        letterSpacing: -1.5 / 48 * 40,
        height: 1,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: c.fg,
        letterSpacing: -1,
        height: 1.10,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: c.fg,
        letterSpacing: -0.625 / 26 * 26,
        height: 1.23,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: c.fg,
        letterSpacing: -0.25,
        height: 1.27,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: c.fg,
        letterSpacing: -0.125 / 20 * 20,
        height: 1.40,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.fg,
        letterSpacing: 0,
        height: 1.40,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: c.fg,
        letterSpacing: 0,
        height: 1.50,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: c.fg,
        letterSpacing: 0,
        height: 1.75,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: c.fgSecondary,
        letterSpacing: 0,
        height: 1.60,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: c.muted,
        letterSpacing: 0,
        height: 1.50,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.fg,
        letterSpacing: 0,
        height: 1.33,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: c.fgSecondary,
        letterSpacing: 0,
        height: 1.43,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: c.muted,
        letterSpacing: 0.125,
        height: 1.33,
      ),
    );
  }
}
