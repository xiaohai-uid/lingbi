import 'dart:io';

import 'package:system_tray/system_tray.dart';

/// System Tray Manager — 系统托盘管理
class TrayManager {
  static final SystemTray _tray = SystemTray();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await _tray.initSystemTray(
      title: '灵笔',
      toolTip: '灵笔一键启动器',
    );

    await _tray.setImage('assets/icon.ico');

    await _tray.setContextMenu(
      Menu(items: [
        MenuItem(label: '显示', onClick: (_) => _showWindow()),
        MenuItem(label: '启动全部', onClick: (_) => _startAll()),
        MenuItem(label: '停止全部', onClick: (_) => _stopAll()),
        MenuItem(label: '退出', onClick: (_) => _quit()),
      ]),
    );

    await _tray.registerCallback((event) async {
      if (event == kTrayEventClick) {
        _showWindow();
      }
    });

    _initialized = true;
  }

  static void _showWindow() {
    // 显示窗口逻辑（通过 window_manager）
  }

  static void _startAll() {
    // 启动所有服务
  }

  static void _stopAll() {
    // 停止所有服务
  }

  static void _quit() {
    _tray.destroy();
    exit(0);
  }

  static void updateStatus(ServiceStatus status) {
    final tooltip = switch (status) {
      ServiceStatus.running => '灵笔 - 运行中',
      ServiceStatus.starting => '灵笔 - 启动中...',
      ServiceStatus.error => '灵笔 - 错误',
      _ => '灵笔',
    };
    _tray.setToolTip(tooltip);
  }
}
