/// 引导门禁组件
///
/// 职责：
/// - 未完成引导时显示两屏引导向导
/// - 已完成引导后显示 AppScaffold
/// - resetOnboarding() 后重新显示向导
library;

import 'package:flutter/material.dart';
import 'package:lingbi/features/settings/data/settings_service.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/ui_v2/components/app_scaffold.dart';
import 'guided_wizard_page.dart';

/// 引导门禁 — 根据 OnboardingState 决定显示向导或主界面
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.settingsService,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final SettingsService settingsService;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _needsOnboarding = true;
  Project? _initialProject;
  String? _initialDocumentId;

  @override
  void initState() {
    super.initState();
    _needsOnboarding = widget.settingsService.onboardingState.needsOnboarding;
    widget.settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final needs = widget.settingsService.onboardingState.needsOnboarding;
    if (needs != _needsOnboarding && mounted) {
      setState(() => _needsOnboarding = needs);
    }
  }

  void _onOnboardingComplete(Project project, String documentId) {
    setState(() {
      _initialProject = project;
      _initialDocumentId = documentId;
      _needsOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsOnboarding) {
      return GuidedWizardPage(onComplete: _onOnboardingComplete);
    }
    return AppScaffold(
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      initialProject: _initialProject,
      initialDocumentId: _initialDocumentId,
    );
  }
}
