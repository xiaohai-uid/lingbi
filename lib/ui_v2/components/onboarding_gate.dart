/// 引导门禁组件
///
/// 职责：
/// - 等待 SettingsService 初始化（显示启动加载状态）
/// - 未完成引导时显示 OnboardingWizard
/// - 已完成引导后显示 AppScaffold
/// - resetOnboarding() 后立即重新显示向导
/// - 禁止主界面启动闪烁
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'onboarding_wizard.dart';
import 'app_scaffold.dart';

/// 引导门禁 — 根据 OnboardingState 决定显示向导或主界面
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _needsOnboarding = true;

  @override
  void initState() {
    super.initState();
    final settings = ServiceLocator.instance.settingsService;
    _needsOnboarding = settings.onboardingState.needsOnboarding;
    settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    ServiceLocator.instance.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final settings = ServiceLocator.instance.settingsService;
    final needs = settings.onboardingState.needsOnboarding;
    if (needs != _needsOnboarding && mounted) {
      setState(() => _needsOnboarding = needs);
    }
  }

  void _onOnboardingComplete() {
    setState(() => _needsOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_needsOnboarding) {
      return OnboardingWizard(onComplete: _onOnboardingComplete);
    }
    return AppScaffold(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
    );
  }
}
