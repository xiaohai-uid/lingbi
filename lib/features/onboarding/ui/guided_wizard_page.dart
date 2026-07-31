/// 引导型向导（v1.2.1 两屏重做）
///
/// 第一屏（QuickPickScreen）：题材 + 字数目标 + 发布平台（全必选）
/// 第二屏（DeepFillScreen）：书名 + 主角 + 世界观 + 创意方向 + 第一章目标
///
/// 完成后创建项目 + chapter-1.md → 导航到编辑器流式展示第一章。
/// spec: docs/adr/0002-wizard-two-screen-interaction.md
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lingbi/features/onboarding/data/guided_wizard_state_machine.dart';
import 'package:lingbi/features/onboarding/ui/wizard_card_selector.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/shared/models/project.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_event.dart';
import 'package:lingbi/workflows/first_chapter/first_chapter_state_store.dart';

// ─── 预设选项数据 ───────────────────────────────────────────

const _genreOptions = [
  CardOption(id: '玄幻', label: '玄幻', emoji: '🔥', description: '东方玄幻·异世大陆'),
  CardOption(id: '都市', label: '都市', emoji: '🏙️', description: '都市生活·职场'),
  CardOption(id: '仙侠', label: '仙侠', emoji: '⚔️', description: '修真·仙侠奇缘'),
  CardOption(id: '悬疑灵异', label: '悬疑灵异', emoji: '🔍', description: '悬疑·灵异·推理'),
  CardOption(id: '科幻', label: '科幻', emoji: '🚀', description: '星际·未来·赛博'),
  CardOption(id: '奇幻', label: '奇幻', emoji: '🐉', description: '剑与魔法·异世界'),
  CardOption(id: '武侠', label: '武侠', emoji: '🗡️', description: '传统武侠·江湖'),
  CardOption(id: '现实', label: '现实', emoji: '📖', description: '现实主义·乡土'),
  CardOption(id: '军事', label: '军事', emoji: '🎖️', description: '军旅·战争'),
  CardOption(id: '历史', label: '历史', emoji: '🏯', description: '历史·架空'),
  CardOption(id: '游戏', label: '游戏', emoji: '🎮', description: '网游·电竞'),
  CardOption(id: '体育', label: '体育', emoji: '⚽', description: '竞技·运动'),
  CardOption(id: '诸天无限', label: '诸天无限', emoji: '🌌', description: '无限流·诸天'),
  CardOption(id: '轻小说', label: '轻小说', emoji: '🌸', description: '日系·二次元'),
];

const _wordCountOptions = [
  CardOption(id: '短篇(3-5万)', label: '短篇', emoji: '📄', description: '3-5万字'),
  CardOption(id: '中篇(10-20万)', label: '中篇', emoji: '📑', description: '10-20万字'),
  CardOption(id: '长篇(50万+)', label: '长篇', emoji: '📚', description: '50万字以上'),
  CardOption(id: '连载(100万+)', label: '连载', emoji: '♾️', description: '100万字以上'),
];

const _platformOptions = [
  CardOption(id: '起点', label: '起点', emoji: '📕', description: '起点中文网'),
  CardOption(id: '番茄', label: '番茄', emoji: '🍅', description: '番茄小说'),
  CardOption(id: '晋江', label: '晋江', emoji: '💜', description: '晋江文学城'),
  CardOption(id: '七猫', label: '七猫', emoji: '🐱', description: '七猫小说'),
  CardOption(id: '自由发布', label: '自由发布', emoji: '✍️', description: '不绑定平台'),
];

const _creativeDirectionOptions = [
  CardOption(id: '爽文升级', label: '爽文升级', emoji: '⚡', description: '打脸·升级·碾压'),
  CardOption(id: '悬疑反转', label: '悬疑反转', emoji: '🔄', description: '烧脑·反转·伏笔'),
  CardOption(id: '虐恋情深', label: '虐恋情深', emoji: '💔', description: '虐心·深情·纠葛'),
  CardOption(id: '日常温馨', label: '日常温馨', emoji: '☀️', description: '治愈·日常·轻松'),
  CardOption(id: '热血争霸', label: '热血争霸', emoji: '🏆', description: '争霸·热血·兄弟'),
];

// ─── 向导页面 ───────────────────────────────────────────

/// 引导型向导页面（两屏结构）
class GuidedWizardPage extends StatefulWidget {
  const GuidedWizardPage({super.key, required this.onComplete});

  /// 向导完成回调：传递已创建的项目和第一章文档 ID
  final void Function(Project project, String documentId) onComplete;

  @override
  State<GuidedWizardPage> createState() => _GuidedWizardPageState();
}

class _GuidedWizardPageState extends State<GuidedWizardPage> {
  late GuidedWizardStateMachine _machine;
  bool _isOnScreenOne = true;
  bool _isCompleting = false;

  // 第二屏文本控制器
  final _titleCtrl = TextEditingController();
  final _protagonistCtrl = TextEditingController();
  final _worldviewCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _machine = GuidedWizardStateMachine();
    _restoreState();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _protagonistCtrl.dispose();
    _worldviewCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _restoreState() {
    final settings = ServiceLocator.instance.settingsService;
    final savedJson = settings.onboardingState.wizardStateJson;
    if (savedJson != null) {
      _machine = GuidedWizardStateMachine.fromState(
        GuidedWizardState.fromJson(savedJson),
      );
      // 如果第一屏已完成，恢复到第二屏
      if (_machine.isScreenOneComplete()) {
        _isOnScreenOne = false;
      }
    }
  }

  void _persistState() {
    final settings = ServiceLocator.instance.settingsService;
    settings.updateOnboardingState(
      settings.onboardingState.copyWith(
        lastStep: _isOnScreenOne ? 0 : 1,
        wizardStateJson: _machine.state.toJson(),
      ),
    );
  }

  // ─── 第一屏操作 ───────────────────────────────────────────

  void _onScreenOneNext() {
    if (!_machine.isScreenOneComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一个题材'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    _persistState();
    setState(() => _isOnScreenOne = false);
  }

  // ─── 第二屏操作 ───────────────────────────────────────────

  void _onBackToScreenOne() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确定要返回吗？'),
        content: const Text('当前填写内容将清空'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定返回'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        // 清空全部数据
        _machine = GuidedWizardStateMachine();
        _titleCtrl.clear();
        _protagonistCtrl.clear();
        _worldviewCtrl.clear();
        _goalCtrl.clear();
        _persistState();
        setState(() => _isOnScreenOne = true);
      }
    });
  }

  void _onScreenTwoComplete() {
    // 收集第二屏文本输入
    final title = _titleCtrl.text.trim();
    final protagonist = _protagonistCtrl.text.trim();
    final worldview = _worldviewCtrl.text.trim();
    final goal = _goalCtrl.text.trim();

    // 设置文本维度
    if (title.isNotEmpty) {
      _machine.setDimension(
          WizardDimension.title, WizardStepValue(selected: [title]));
    }
    if (protagonist.isNotEmpty) {
      _machine.setDimension(
          WizardDimension.protagonist, WizardStepValue(selected: [protagonist]));
    }
    if (worldview.isNotEmpty) {
      _machine.setDimension(
          WizardDimension.worldview, WizardStepValue(selected: [worldview]));
    }
    if (goal.isNotEmpty) {
      _machine.setDimension(
          WizardDimension.firstChapterGoal,
          WizardStepValue(selected: [goal]));
    }

    // 校验第二屏
    if (!_machine.isScreenTwoComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写主角描述和第一章目标'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 标记完成
    _machine.markCompleted();
    _persistState();
    _completeOnboarding();
  }

  // ─── 完成编排 ───────────────────────────────────────────

  void _completeOnboarding() {
    if (_isCompleting) return;
    _isCompleting = true;

    final locator = ServiceLocator.instance;
    final settings = locator.settingsService;

    locator.wizardCompletionWorkflow.execute(_machine).then((result) async {
      final doc = await locator.documentService.createDocument(
        projectId: result.project.id,
        title: 'chapter-1',
        directoryPath: result.project.directoryPath,
      );

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

      settings.updateOnboardingState(
        settings.onboardingState.copyWith(
          completed: true,
          completedAt: DateTime.now(),
          lastStep: 1,
        ),
      );

      widget.onComplete(result.project, doc.id);
    }).catchError((Object error) {
      debugPrint('Wizard completion error: $error');
      settings.updateOnboardingState(
        settings.onboardingState.copyWith(
          completed: true,
          completedAt: DateTime.now(),
          lastStep: 1,
        ),
      );
    });
  }

  // ─── UI 构建 ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _isOnScreenOne ? _buildScreenOne() : _buildScreenTwo(),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenOne() {
    final c = LingBiColors.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 进度指示（2 屏）
          _buildScreenIndicator(c, 0),
          const SizedBox(height: 32),
          Text('快速选择', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('10 秒完成作品骨架',
              style: TextStyle(color: c.muted)),
          const SizedBox(height: 32),
          // 题材
          _buildSectionTitle(c, '题材', '选择 1-3 个你感兴趣的题材'),
          const SizedBox(height: 12),
          WizardCardSelector(
            options: _genreOptions,
            multiSelect: true,
            maxSelections: 3,
            hotCount: 6,
            initialSelected:
                _machine.state.dimensionData[WizardDimension.genre]?.selected ??
                    [],
            onChanged: (selected, custom) => _machine.setDimension(
              WizardDimension.genre,
              WizardStepValue(selected: selected, customText: custom),
            ),
          ),
          const SizedBox(height: 28),
          // 字数目标
          _buildSectionTitle(c, '字数目标', '你计划写多长？'),
          const SizedBox(height: 12),
          WizardCardSelector(
            options: _wordCountOptions,
            multiSelect: false,
            initialSelected: _machine
                    .state.dimensionData[WizardDimension.wordCount]?.selected ??
                [],
            onChanged: (selected, custom) => _machine.setDimension(
              WizardDimension.wordCount,
              WizardStepValue(selected: selected, customText: custom),
            ),
          ),
          const SizedBox(height: 28),
          // 发布平台
          _buildSectionTitle(c, '发布平台', '主要发布在哪个平台？'),
          const SizedBox(height: 12),
          WizardCardSelector(
            options: _platformOptions,
            multiSelect: false,
            initialSelected:
                _machine.state.dimensionData[WizardDimension.platform]
                        ?.selected ??
                    [],
            onChanged: (selected, custom) => _machine.setDimension(
              WizardDimension.platform,
              WizardStepValue(selected: selected, customText: custom),
            ),
          ),
          const SizedBox(height: 40),
          // 下一步按钮
          Center(
            child: FilledButton(
              onPressed: _onScreenOneNext,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text('下一步'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTwo() {
    final c = LingBiColors.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScreenIndicator(c, 1),
          const SizedBox(height: 32),
          Text('深度填写', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('让 AI 更懂你的故事', style: TextStyle(color: c.muted)),
          const SizedBox(height: 32),
          // 书名（可跳过）
          _buildSectionTitle(c, '书名', '可跳过，默认"未命名作品"'),
          const SizedBox(height: 8),
          _buildTextField(_titleCtrl, '例如：万界守夜人'),
          const SizedBox(height: 24),
          // 主角描述（必填）
          _buildSectionTitle(c, '主角描述 *', '名字、身份、性格……简单几个词就行'),
          const SizedBox(height: 8),
          _buildTextField(_protagonistCtrl, '例如：守夜人林渊，沉默寡言的都市猎人'),
          const SizedBox(height: 24),
          // 世界观（可跳过）
          _buildSectionTitle(c, '世界观', '可跳过。故事发生在什么样的世界？'),
          const SizedBox(height: 8),
          _buildTextField(_worldviewCtrl, '例如：灵气复苏的现代都市'),
          const SizedBox(height: 24),
          // 创意方向（B 型，可跳过）
          _buildSectionTitle(c, '创意方向', '可跳过，最多选 3 个'),
          const SizedBox(height: 12),
          WizardCardSelector(
            options: _creativeDirectionOptions,
            multiSelect: true,
            maxSelections: 3,
            initialSelected: _machine.state
                    .dimensionData[WizardDimension.creativeDirection]
                    ?.selected ??
                [],
            onChanged: (selected, custom) => _machine.setDimension(
              WizardDimension.creativeDirection,
              WizardStepValue(selected: selected, customText: custom),
            ),
          ),
          const SizedBox(height: 24),
          // 第一章目标（必填）
          _buildSectionTitle(c, '第一章目标 *', '告诉 AI 你的开篇目标'),
          const SizedBox(height: 8),
          _buildTextField(_goalCtrl, '例如：主角首次觉醒，遭遇诡异事件'),
          const SizedBox(height: 40),
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _onBackToScreenOne,
                child: const Text('返回上一屏'),
              ),
              const SizedBox(width: 24),
              FilledButton(
                onPressed: _onScreenTwoComplete,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text('完成'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 通用组件 ───────────────────────────────────────────

  Widget _buildScreenIndicator(LingBiColors c, int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final isActive = i == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? c.accent : c.borderOpaque,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(LingBiColors c, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: c.fg)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: c.muted)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        ),
        filled: true,
      ),
    );
  }
}
