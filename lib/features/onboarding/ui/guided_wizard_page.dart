/// 引导型向导（v1.2 重做）
///
/// 3-5 步卡片式向导：书名 → 题材 → 主角 → 世界观 → 第一章目标
/// 由 GuidedWizardStateMachine 驱动，每步可跳过（填充默认值）。
/// 完成后标记 OnboardingState.completed = true。
///
/// 替换旧 onboarding_wizard.dart（ADR-0001）。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_state_store.dart';

/// 引导型向导页面
class GuidedWizardPage extends StatefulWidget {
  const GuidedWizardPage({super.key, required this.onComplete});

  /// 向导完成回调：传递已创建的项目和第一章文档 ID
  final void Function(Project project, String documentId) onComplete;

  @override
  State<GuidedWizardPage> createState() => _GuidedWizardPageState();
}

class _GuidedWizardPageState extends State<GuidedWizardPage> {
  late GuidedWizardStateMachine _machine;
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _machine = GuidedWizardStateMachine();
    _restoreState();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 从 SettingsService 恢复中断状态
  void _restoreState() {
    final settings = ServiceLocator.instance.settingsService;
    final savedJson = settings.onboardingState.wizardStateJson;
    if (savedJson != null) {
      _machine = GuidedWizardStateMachine.fromState(
        GuidedWizardState.fromJson(savedJson),
      );
    }
  }

  /// 持久化当前步骤（中断恢复）
  void _persistState() {
    final settings = ServiceLocator.instance.settingsService;
    settings.updateOnboardingState(
      settings.onboardingState.copyWith(
        lastStep: _machine.state.lastStep,
        wizardStateJson: _machine.state.toJson(),
      ),
    );
  }

  void _advance() {
    final input = _inputController.text.trim();
    _machine.advance(input.isEmpty ? _defaultHint() : input);
    _inputController.clear();
    _afterStepChange();
  }

  void _skip() {
    _machine.skip();
    _inputController.clear();
    _afterStepChange();
  }

  void _afterStepChange() {
    _persistState();
    if (_machine.state.isCompleted) {
      _completeOnboarding();
    } else {
      setState(() {});
      _focusNode.requestFocus();
    }
  }

  void _completeOnboarding() {
    if (_isCompleting) return;
    _isCompleting = true;

    final locator = ServiceLocator.instance;
    final settings = locator.settingsService;

    // 1. 创建项目 + 写入正典
    locator.wizardCompletionWorkflow.execute(_machine).then((result) async {
      // 2. 创建 chapter-1.md 文档
      final doc = await locator.documentService.createDocument(
        projectId: result.project.id,
        title: 'chapter-1',
        directoryPath: result.project.directoryPath,
        content: '',
      );

      // 3. 写入初始第一章工作流状态（idle），由编辑器启动生成
      const chapterId = 'chapter-1';
      final targetFilePath =
          '${result.project.directoryPath}${Platform.pathSeparator}$chapterId.md';
      final stateStore = FileFirstChapterStateStore(
        projectDirectory: result.project.directoryPath,
      );
      await stateStore.write(FirstChapterState(
        projectId: result.project.id,
        chapterId: chapterId,
        targetFilePath: targetFilePath,
        stage: FirstChapterStage.idle,
        updatedAt: DateTime.now().toUtc(),
      ));

      // 4. 标记 onboarding 完成
      settings.updateOnboardingState(
        settings.onboardingState.copyWith(
          completed: true,
          completedAt: DateTime.now(),
          lastStep: _machine.state.lastStep,
        ),
      );

      // 5. 导航到编辑器并打开 chapter-1.md
      widget.onComplete(result.project, doc.id);
    }).catchError((Object error) {
      // 降级：编排失败仍标记完成，用户可手动创建项目
      debugPrint('Wizard completion error: $error');
      settings.updateOnboardingState(
        settings.onboardingState.copyWith(
          completed: true,
          completedAt: DateTime.now(),
          lastStep: _machine.state.lastStep,
        ),
      );
      // 降级时无法传递项目信息，使用空回调
      // OnboardingGate 会显示欢迎页
    });
  }

  String _defaultHint() {
    return switch (_machine.state.currentStep) {
      GuidedWizardStep.title => '未命名作品',
      GuidedWizardStep.genre => '通用',
      GuidedWizardStep.protagonist => '主角',
      GuidedWizardStep.worldview => '',
      GuidedWizardStep.firstChapterGoal => '开篇引入，建立世界观和主角',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _machine.state.currentStep;
    final config = _stepConfig(step);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 进度指示
                _buildProgress(theme),
                const SizedBox(height: 40),
                // 步骤标题
                Text(
                  config.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // 步骤描述
                Text(
                  config.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // 输入框
                TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: config.hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onSubmitted: (_) => _advance(),
                ),
                const SizedBox(height: 24),
                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: const Text('跳过'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _advance,
                      child: Text(
                        step == GuidedWizardStep.firstChapterGoal
                            ? '完成'
                            : '下一步',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ThemeData theme) {
    final total = GuidedWizardStep.values.length;
    final current = _machine.state.lastStep;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < current;
        final isCurrent = i == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone || isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  _StepConfig _stepConfig(GuidedWizardStep step) {
    return switch (step) {
      GuidedWizardStep.title => const _StepConfig(
          title: '给你的作品起个名字',
          description: '一个好标题是成功的一半。稍后也可以修改。',
          hint: '例如：万界守夜人',
        ),
      GuidedWizardStep.genre => const _StepConfig(
          title: '选择题材',
          description: 'AI 会根据题材调整生成风格和用词。',
          hint: '例如：玄幻、都市、悬疑、言情',
        ),
      GuidedWizardStep.protagonist => const _StepConfig(
          title: '描述你的主角',
          description: '名字、身份、性格……简单几个词就行。',
          hint: '例如：守夜人林渊，沉默寡言的都市猎人',
        ),
      GuidedWizardStep.worldview => const _StepConfig(
          title: '世界观关键词',
          description: '故事发生在什么样的世界？可跳过。',
          hint: '例如：灵气复苏的现代都市',
        ),
      GuidedWizardStep.firstChapterGoal => const _StepConfig(
          title: '第一章想写什么？',
          description: '告诉 AI 你的开篇目标，完成后立即生成候选正文。',
          hint: '例如：主角首次觉醒，遭遇诡异事件',
        ),
    };
  }
}

class _StepConfig {
  const _StepConfig({
    required this.title,
    required this.description,
    required this.hint,
  });

  final String title;
  final String description;
  final String hint;
}
