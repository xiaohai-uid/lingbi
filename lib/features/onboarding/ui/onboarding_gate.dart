/// 引导门禁组件
///
/// 职责：
/// - 等待 SettingsService 初始化（显示启动加载状态）
/// - 首次启动时自动标记引导完成（旧向导已移除，由 AppScaffold 内 WelcomePage 接管新手引导）
/// - 已完成引导后显示 AppScaffold
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/features/settings/data/settings_service.dart';
import 'package:lingbi/ui_v2/components/app_scaffold.dart';

/// 引导门禁 — 根据 OnboardingState 决定是否需要自动完成引导
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
  Project? _initialProject;
  String? _initialDocumentId;

  @override
  void initState() {
    super.initState();
    _autoCompleteOnboardingIfNeeded();
  }

  /// 旧版引导向导已移除，首次启动时自动标记引导完成。
  /// 新手引导由 AppScaffold 内的 WelcomePage 接管。
  void _autoCompleteOnboardingIfNeeded() {
    final settings = ServiceLocator.instance.settingsService;
    if (settings.onboardingState.needsOnboarding) {
      settings.updateOnboardingState(
        settings.onboardingState.copyWith(
          completed: true,
          schemaVersion: currentOnboardingSchemaVersion,
          completedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      initialProject: _initialProject,
      initialDocumentId: _initialDocumentId,
    );
  }
}
