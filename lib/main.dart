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
    final locator = ServiceLocator.instance;
    if (locator.initSucceeded) {
      locator.settingsService.addListener(_onSettingsChanged);
    }
  }

  @override
  void dispose() {
    final locator = ServiceLocator.instance;
    if (locator.initSucceeded) {
      locator.settingsService.removeListener(_onSettingsChanged);
    }
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locator = ServiceLocator.instance;
    return MaterialApp(
      title: '灵笔',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: locator.initSucceeded ? locator.settingsService.themeMode : ThemeMode.light,
      home: locator.initSucceeded
          ? const HomePage()
          : _DegradedHome(initError: locator.initError),
    );
  }
}

/// 降级模式首页 — 当 ServiceLocator 初始化失败时显示基本的本地写作入口
class _DegradedHome extends StatelessWidget {
  final String? initError;
  const _DegradedHome({this.initError});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('灵笔 — 本地模式')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                '部分服务初始化失败，已进入本地模式',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (initError != null) ...[
                const SizedBox(height: 8),
                Text(
                  initError!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
