import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'launcher_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化窗口管理器并拦截关闭，使关闭按钮转为最小化到托盘
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  runApp(const LauncherApp());
}

class LauncherApp extends StatelessWidget {
  const LauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '灵笔启动器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LauncherPage(),
    );
  }
}
