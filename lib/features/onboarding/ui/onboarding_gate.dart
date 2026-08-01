/// 引导门禁组件
///
/// 职责：
/// - 首次启动时自动标记引导完成（旧向导已移除，由 AppScaffold 内 WelcomePage 接管新手引导）
/// - 已完成引导后显示 AppScaffold
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/interfaces/i_settings_service.dart';
import 'package:lingbi/ui_v2/components/app_scaffold.dart';

/// 引导门禁 — 自动完成引导并进入主界面
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.settingsService,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final ISettingsService settingsService;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  @override
  void initState() {
    super.initState();
    // 旧版引导向导已移除，首次启动时自动标记引导完成。
    widget.settingsService.markOnboardingComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
    );
  }
}
