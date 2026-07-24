import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'service_manager.dart';
import 'log_viewer.dart';
import 'env_detector.dart';
import 'settings_panel.dart';
import 'tray_manager.dart';
import 'auto_updater.dart';

/// 启动器主页面 — 显示所有微服务状态 + 操作按钮
class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key});

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage> with WindowListener {
  final Map<String, ServiceStatus> _statusMap = {};
  final Map<String, Process> _processes = {};
  final Map<String, StringBuffer> _logs = {};
  bool _busy = false;
  String? _selectedService;
  final TrayManager _tray = TrayManager();

  static const List<String> _serviceOrder = [
    'API Gateway',
    'AI Provider',
    'Project',
    'Document',
    'Canon',
    'Export',
    'Version',
    'Settings',
    'Quota',
    'Storage',
    'Sync',
    'Canvas',
  ];

  @override
  void initState() {
    super.initState();
    for (final name in _serviceOrder) {
      _statusMap[name] = ServiceStatus.stopped;
      _logs[name] = StringBuffer();
    }
    windowManager.addListener(this);
    _initTray();
  }

  Future<void> _initTray() async {
    try {
      await _tray.initialize(
        onShow: _tray.restoreFromTray,
        onHide: _tray.minimizeToTray,
        onQuit: _quit,
        onStartAll: _startAll,
        onStopAll: _stopAll,
      );
    } catch (e) {
      // 托盘初始化失败不应阻塞主界面运行
      debugPrint('托盘初始化失败: $e');
    }
  }

  /// 窗口关闭按钮拦截：转为最小化到托盘而非退出
  @override
  void onWindowClose() async {
    await _tray.minimizeToTray();
  }

  /// 真正退出：停止服务 → 销毁托盘 → 关闭窗口 → 退出进程
  Future<void> _quit() async {
    await _stopAll();
    await _tray.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
    exit(0);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _tray.destroy();
    _stopAll();
    super.dispose();
  }

  int get _runningCount =>
      _statusMap.values.where((s) => s == ServiceStatus.running).length;

  int get _totalCount => _serviceOrder.length;

  bool get _allRunning => _runningCount == _totalCount;

  Future<void> _startAll() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ServiceManager.startAllLocal(_statusMap, _processes, _logs);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _stopAll() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ServiceManager.stopAllLocal(_processes);
    for (final name in _serviceOrder) {
      _statusMap[name] = ServiceStatus.stopped;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _restartService(String name) async {
    if (_busy) return;
    setState(() => _busy = true);
    final proc = _processes[name];
    if (proc != null) {
      try {
        proc.kill();
        await proc.exitCode;
      } catch (_) {}
      _processes.remove(name);
    }
    _statusMap[name] = ServiceStatus.stopped;
    await ServiceManager.startService(name, _statusMap, _processes, _logs);
    if (mounted) setState(() => _busy = false);
  }

  void _showEnvCheck() async {
    final results = await EnvDetector.detectAll();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('环境检测'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in results)
                ListTile(
                  leading: Icon(
                    r.available ? Icons.check_circle : Icons.error,
                    color: r.available ? Colors.green : Colors.red,
                  ),
                  title: Text(r.name),
                  subtitle: Text(r.version ?? '未安装'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Future<void> _checkUpdate() async {
    final result = await AutoUpdater.checkForUpdate();
    if (!mounted) return;
    if (result.hasUpdate && result.version != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('发现新版本'),
          content: Text(
            '最新版本：${result.version}\n\n${result.releaseNotes ?? '（无发布说明）'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已是最新版本')),
      );
    }
  }

  Color _statusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.running:
        return Colors.green;
      case ServiceStatus.starting:
        return Colors.orange;
      case ServiceStatus.error:
        return Colors.red;
      case ServiceStatus.degraded:
        return Colors.amber;
      case ServiceStatus.stopped:
        return Colors.grey;
    }
  }

  IconData _statusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.running:
        return Icons.circle;
      case ServiceStatus.starting:
        return Icons.pending;
      case ServiceStatus.error:
        return Icons.error;
      case ServiceStatus.degraded:
        return Icons.warning;
      case ServiceStatus.stopped:
        return Icons.radio_button_unchecked;
    }
  }

  String _statusLabel(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.running:
        return '运行中';
      case ServiceStatus.starting:
        return '启动中';
      case ServiceStatus.error:
        return '错误';
      case ServiceStatus.degraded:
        return '降级';
      case ServiceStatus.stopped:
        return '已停止';
    }
  }

  int _portFor(String name) {
    return ServiceManager.getConfig(name)?.port ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.rocket_launch, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('灵笔启动器'),
            const SizedBox(width: 16),
            Chip(
              avatar: Icon(
                _allRunning ? Icons.check_circle : Icons.pending,
                size: 16,
                color: _allRunning ? Colors.green : Colors.orange,
              ),
              label: Text('$_runningCount / $_totalCount'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: '环境检测',
            onPressed: _showEnvCheck,
          ),
          IconButton(
            icon: const Icon(Icons.system_update),
            tooltip: '检查更新',
            onPressed: _checkUpdate,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const SettingsPanel(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作按钮栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _busy || _allRunning ? null : _startAll,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('一键启动全部'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _busy || _runningCount == 0 ? null : _stopAll,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('停止全部'),
                ),
                const Spacer(),
                if (_busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          // 服务列表
          Expanded(
            child: Row(
              children: [
                // 左侧服务列表
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _serviceOrder.length,
                    itemBuilder: (ctx, i) {
                      final name = _serviceOrder[i];
                      final status = _statusMap[name] ?? ServiceStatus.stopped;
                      final selected = _selectedService == name;
                      return Card(
                        color: selected
                            ? theme.colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: Icon(
                            _statusIcon(status),
                            color: _statusColor(status),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            '端口: ${_portFor(name)} · ${_statusLabel(status)}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'restart') _restartService(name);
                              if (v == 'logs') {
                                setState(() => _selectedService = name);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'restart',
                                child: ListTile(
                                  leading: Icon(Icons.refresh, size: 18),
                                  title: Text('重启'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'logs',
                                child: ListTile(
                                  leading: Icon(Icons.description, size: 18),
                                  title: Text('查看日志'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() => _selectedService = name);
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 右侧日志面板
                if (_selectedService != null)
                  Expanded(
                    flex: 3,
                    child: LogViewer(
                      serviceName: _selectedService!,
                      logBuffer: _logs[_selectedService!] ?? StringBuffer(),
                      onClose: () =>
                          setState(() => _selectedService = null),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
