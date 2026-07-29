import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'theme/app_theme.dart';
import 'package:lingbi/features/onboarding/ui/onboarding_gate.dart';

class LingBiAppV3 extends StatefulWidget {

  const LingBiAppV3({super.key, required this.locator});
  final ServiceLocator locator;

  @override
  State<LingBiAppV3> createState() => _LingBiAppV3State();
}

class _LingBiAppV3State extends State<LingBiAppV3> {
  @override
  void initState() {
    super.initState();
    widget.locator.settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.locator.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  bool get _isDarkMode {
    final mode = widget.locator.settingsService.themeMode;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    // ThemeMode.system: use platform brightness
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  void _onToggleTheme(bool dark) {
    widget.locator.settingsService.setThemeMode(
      dark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    return MaterialApp(
      title: '灵笔 - AI 小说创作平台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: widget.locator.settingsService.themeMode,
      home: OnboardingGate(
        isDarkMode: isDark,
        onToggleTheme: _onToggleTheme,
      ),
    );
  }
}
