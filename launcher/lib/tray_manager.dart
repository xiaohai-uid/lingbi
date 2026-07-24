import 'dart:async';

import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';

/// 系统托盘管理器 — 最小化到托盘、右键菜单、异常提示
///
/// 基于 `tray_manager` 包（已声明于 pubspec.yaml）实现真实的 Windows 托盘集成。
/// tray_manager 在 Windows 上已注册原生支持（见 windows/flutter/generated_plugins.cmake）。
class TrayManager with tray.TrayListener {
  bool _initialized = false;
  bool _visible = true;
  Timer? _flashTimer;
  String _baseTooltip = '灵笔启动器';

  // 右键菜单项 key
  static const _kShow = 'show_window';
  static const _kHide = 'hide_to_tray';
  static const _kStartAll = 'start_all_services';
  static const _kStopAll = 'stop_all_services';
  static const _kQuit = 'quit_app';

  late void Function() _onShow;
  late void Function() _onHide;
  late void Function() _onQuit;
  late Future<void> Function() _onStartAll;
  late Future<void> Function() _onStopAll;

  /// 初始化系统托盘图标与右键菜单。
  ///
  /// [onShow] 显示窗口回调；[onHide] 隐藏到托盘回调；
  /// [onQuit] 退出应用回调；[onStartAll]/[onStopAll] 启停全部服务回调。
  Future<void> initialize({
    required void Function() onShow,
    required void Function() onHide,
    required void Function() onQuit,
    required Future<void> Function() onStartAll,
    required Future<void> Function() onStopAll,
  }) async {
    _onShow = onShow;
    _onHide = onHide;
    _onQuit = onQuit;
    _onStartAll = onStartAll;
    _onStopAll = onStopAll;

    tray.trayManager.addListener(this);

    // 设置托盘图标。Windows 使用 .ico，复用 windows/runner 生成的应用图标。
    // 注意：tray_manager 在 Windows 上将路径解析为
    // {exe 目录}/data/flutter_assets/{iconPath}，因此图标需作为 Flutter asset 打包。
    await tray.trayManager.setIcon('assets/icons/app_icon.ico');
    await tray.trayManager.setToolTip(_baseTooltip);

    final menu = tray.Menu(items: [
      tray.MenuItem(key: _kShow, label: '显示窗口'),
      tray.MenuItem(key: _kHide, label: '隐藏到托盘'),
      tray.MenuItem.separator(),
      tray.MenuItem(key: _kStartAll, label: '启动全部服务'),
      tray.MenuItem(key: _kStopAll, label: '停止全部服务'),
      tray.MenuItem.separator(),
      tray.MenuItem(key: _kQuit, label: '退出'),
    ]);
    await tray.trayManager.setContextMenu(menu);

    _initialized = true;
  }

  /// 最小化到系统托盘（隐藏主窗口）。
  Future<void> minimizeToTray() async {
    if (!_initialized) return;
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
    _visible = false;
    await tray.trayManager.setToolTip('$_baseTooltip — 运行于托盘');
  }

  /// 从托盘恢复窗口。
  Future<void> restoreFromTray() async {
    if (!_initialized) return;
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.focus();
    _visible = true;
    await tray.trayManager.setToolTip(_baseTooltip);
  }

  /// 托盘提示闪烁（表示异常）。
  ///
  /// tray_manager 包在 Windows 上未提供原生图标闪烁 API，
  /// 此处通过交替切换 tooltip 文本模拟告警提示。
  Future<void> flashIcon({int count = 5}) async {
    if (!_initialized) return;
    _flashTimer?.cancel();
    var toggled = 0;
    var on = false;
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (toggled >= count) {
        t.cancel();
        tray.trayManager.setToolTip(_baseTooltip);
        return;
      }
      on = !on;
      tray.trayManager.setToolTip(on ? '⚠ $_baseTooltip — 服务异常' : _baseTooltip);
      toggled++;
    });
  }

  /// 更新托盘提示文本。
  Future<void> updateTooltip(String tooltip) async {
    if (!_initialized) return;
    _baseTooltip = tooltip;
    await tray.trayManager.setToolTip(tooltip);
  }

  /// 销毁托盘图标并释放监听。
  Future<void> destroy() async {
    _flashTimer?.cancel();
    if (!_initialized) return;
    tray.trayManager.removeListener(this);
    await tray.trayManager.destroy();
    _initialized = false;
  }

  @override
  void onTrayIconMouseDown() {
    // 左键单击托盘图标：恢复显示窗口
    restoreFromTray();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键菜单由包自动弹出，无需手动处理
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    switch (menuItem.key) {
      case _kShow:
        _onShow();
        break;
      case _kHide:
        _onHide();
        break;
      case _kStartAll:
        _onStartAll();
        break;
      case _kStopAll:
        _onStopAll();
        break;
      case _kQuit:
        _onQuit();
        break;
    }
  }

  bool get isVisible => _visible;
  bool get isInitialized => _initialized;
}
