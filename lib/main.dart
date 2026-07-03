import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';

import 'ui/theme/app_theme.dart';
import 'ui/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ServiceLocator
  await ServiceLocator.init();

  runApp(const LingBiApp());
}

class LingBiApp extends StatefulWidget {
  const LingBiApp({super.key});

  @override
  State<LingBiApp> createState() => _LingBiAppState();
}

class _LingBiAppState extends State<LingBiApp> {
  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ServiceLocator.instance.settingsService;
    return MaterialApp(
      title: '灵笔',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      home: const HomePage(),
    );
  }
}
