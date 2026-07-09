import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:lingbi_launcher/service_manager.dart';
import 'package:lingbi_launcher/docker_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'package:process_run/process_run.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LauncherApp());
}

class LauncherApp extends StatelessWidget {
  const LauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LauncherState(),
      child: MaterialApp(
        title: '灵笔启动器',
        home: const LauncherHome(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class LauncherState extends ChangeNotifier {
  // 启动模式: local, docker, hybrid
  String _mode = 'local';
  String get mode => _mode;

  // 服务状态: stopped, starting, running, error
  final Map<String, ServiceStatus> _services = {
    'API Gateway': ServiceStatus.stopped,
    'AI Provider': ServiceStatus.stopped,
    'Project': ServiceStatus.stopped,
    'Document': ServiceStatus.stopped,
    'Codex': ServiceStatus.stopped,
    'Export': ServiceStatus.stopped,
    'Version': ServiceStatus.stopped,
    'Settings': ServiceStatus.stopped,
    'Quota': ServiceStatus.stopped,
    'Storage': ServiceStatus.stopped,
    'Sync': ServiceStatus.stopped,
    'Canvas': ServiceStatus.stopped,
  };

  Map<String, ServiceStatus> get services => Map.unmodifiable(_services);

  // 服务进程映射
  final Map<String, Process> _processes = {};

  // 日志缓冲
  final Map<String, StringBuffer> _logs = {};

  bool get isRunning => _processes.isNotEmpty;

  Future<void> setMode(String mode) async {
    _mode = mode;
    notifyListeners();
  }

  Future<void> startAll() async {
    if (_mode == 'docker') {
      await DockerManager.startAll();
    } else {
      await ServiceManager.startAllLocal(_services, _processes, _logs);
    }
    notifyListeners();
  }

  Future<void> stopAll() async {
    if (_mode == 'docker') {
      await DockerManager.stopAll();
    } else {
      await ServiceManager.stopAllLocal(_processes);
    }
    notifyListeners();
  }

  Future<void> restartService(String name) async {
    await stopService(name);
    await startService(name);
  }

  Future<void> stopService(String name) async {
    final process = _processes[name];
    if (process != null) {
      await process.kill();
      _processes.remove(name);
    }
    _services[name] = ServiceStatus.stopped;
    notifyListeners();
  }

  Future<void> startService(String name) async {
    await ServiceManager.startService(name, _services, _processes, _logs);
    notifyListeners();
  }

  String getLog(String name) => _logs[name]?.toString() ?? '';

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}

enum ServiceStatus {
  stopped,
  starting,
  running,
  error,
  degraded,
}

class LauncherHome extends StatefulWidget {
  const LauncherHome({super.key});

  @override
  State<LauncherHome> createState() => _LauncherHomeState();
}

class _LauncherHomeState extends State<LauncherHome> {
  @override
  void initState() {
    super.initState();
    _initWindow();
  }

  Future<void> _initWindow() async {
    await windowManager.ensureInitialized();
    const windowSize = Size(800, 600);
    await windowManager.waitUntilReadyToShow();
    await windowManager.setSize(windowSize);
    await windowManager.setMinSize(const Size(600, 400));
    await windowManager.center();
    await windowManager.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('灵笔启动器'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (mode) {
              context.read<LauncherState>().setMode(mode);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'local', child: Text('本地模式')),
              PopupMenuItem(value: 'docker', child: Text('Docker 模式')),
              PopupMenuItem(value: 'hybrid', child: Text('混合模式')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 控制面板
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.read<LauncherState>().startAll(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('启动全部'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<LauncherState>().stopAll(),
                  icon: const Icon(Icons.stop),
                  label: const Text('停止全部'),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '模式: ${context.watch<LauncherState>().mode}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 服务列表
          Expanded(
            child: Consumer<LauncherState>(
              builder: (context, state, _) {
                return ListView.builder(
                  itemCount: state.services.length,
                  itemBuilder: (context, index) {
                    final name = state.services.keys.elementAt(index);
                    final status = state.services[name]!;
                    return _ServiceTile(
                      name: name,
                      status: status,
                      onRestart: () => state.restartService(name),
                      onLog: () => _showLogDialog(context, name, state.getLog(name)),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDialog(BuildContext context, String name, String log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name 日志'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: Text(log, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String name;
  final ServiceStatus status;
  final VoidCallback onRestart;
  final VoidCallback onLog;

  const _ServiceTile({
    required this.name,
    required this.status,
    required this.onRestart,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      ServiceStatus.running => Colors.green,
      ServiceStatus.starting => Colors.orange,
      ServiceStatus.error => Colors.red,
      ServiceStatus.degraded => Colors.deepOrange,
      _ => Colors.grey,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor,
        radius: 8,
      ),
      title: Text(name),
      subtitle: Text(status.name.toUpperCase()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重启',
            onPressed: onRestart,
          ),
          IconButton(
            icon: const Icon(Icons.article),
            tooltip: '日志',
            onPressed: onLog,
          ),
        ],
      ),
    );
  }
}