import 'package:flutter/material.dart';

import 'package:lingbi/features/onboarding/data/project_onboarding_workflow.dart';
import 'package:lingbi/ui_v2/components/model_selector.dart';
import 'package:lingbi/features/onboarding/ui/onboarding_question_card.dart';
import 'package:lingbi/ui_v2/theme/tokens.dart';

class ProjectOnboardingPage extends StatefulWidget {
  const ProjectOnboardingPage({
    super.key,
    required this.projectId,
    required this.workflow,
    required this.onCompleted,
    required this.onManualWriting,
    this.modelSelector,
    this.genreId,
    this.modelReady,
    this.onConfigureModel,
  });

  final String projectId;
  final ProjectOnboardingWorkflow workflow;
  final VoidCallback onCompleted;
  final VoidCallback onManualWriting;
  final Widget? modelSelector;
  final String? genreId;
  final bool? modelReady;
  final VoidCallback? onConfigureModel;

  @override
  State<ProjectOnboardingPage> createState() => _ProjectOnboardingPageState();
}

class _ProjectOnboardingPageState extends State<ProjectOnboardingPage> {
  final _controller = TextEditingController();
  ProjectOnboardingState? _state;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state = await widget.workflow.resume(widget.projectId);
      if (!mounted) return;
      setState(() => _state = state);
      if (state.isCompleted) widget.onCompleted();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    await _advance(() => widget.workflow.answer(
          widget.projectId,
          _controller.text,
        ));
  }

  Future<void> _skip() async {
    await _advance(() => widget.workflow.skip(widget.projectId));
  }

  Future<void> _advance(
    Future<ProjectOnboardingState> Function() operation,
  ) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final state = await operation();
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _state = state;
        _saving = false;
      });
      if (state.isCompleted) widget.onCompleted();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  String _answerTitle(OnboardingQuestion question) => switch (question) {
        OnboardingQuestion.protagonistGoal => '主角目标',
        OnboardingQuestion.coreObstacle => '核心阻碍',
        OnboardingQuestion.openingEvent => '开场事件',
      };

  Widget _buildModelControl() {
    if (widget.modelReady != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.modelReady! ? '模型已配置' : '模型未配置'),
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onConfigureModel,
            child: Text(widget.modelReady! ? '更换模型' : '配置模型'),
          ),
        ],
      );
    }
    return widget.modelSelector ?? const ModelSelector();
  }

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    final state = _state;
    if (state == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : TextButton(onPressed: _load, child: const Text('重试')),
      );
    }
    if (state.isCompleted) return const SizedBox.shrink();

    return Material(
      color: colors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LingBiTokens.space8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '用三个问题开始创作',
                            style: TextStyle(
                              color: colors.fg,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: LingBiTokens.space1),
                          Text(
                            '第 ${state.currentIndex + 1} / 3 题 · 每一题都会立即保存',
                            style: TextStyle(color: colors.fgSecondary),
                          ),
                        ],
                      ),
                    ),
                    _buildModelControl(),
                  ],
                ),
                const SizedBox(height: LingBiTokens.space6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: OnboardingQuestionCard(
                        question: state.currentQuestion!,
                        controller: _controller,
                        isSaving: _saving,
                        onSubmit: _submit,
                        onSkip: _skip,
                        genreLabel: widget.genreId == null
                            ? null
                            : _genreLabel(widget.genreId!),
                      ),
                    ),
                    const SizedBox(width: LingBiTokens.space5),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(LingBiTokens.space5),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius:
                              BorderRadius.circular(LingBiTokens.radiusLg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '已形成的资产',
                              style: TextStyle(
                                color: colors.fg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: LingBiTokens.space3),
                            if (state.answers.isEmpty)
                              Text('你的回答会在这里实时沉淀。',
                                  style: TextStyle(color: colors.muted))
                            else
                              ...state.answers.entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: LingBiTokens.space3),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_answerTitle(entry.key),
                                          style: TextStyle(
                                              color: colors.muted,
                                              fontSize: 11)),
                                      const SizedBox(
                                          height: LingBiTokens.space1),
                                      Text(entry.value,
                                          style: TextStyle(color: colors.fg)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: LingBiTokens.space3),
                  Text(_error!,
                      style: const TextStyle(color: LingBiTokens.error)),
                ],
                const SizedBox(height: LingBiTokens.space4),
                TextButton.icon(
                  onPressed: widget.onManualWriting,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('直接写作'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _genreLabel(String genreId) {
    const labels = {
      'xuanhuan': '玄幻',
      'urban': '都市',
      'suspense': '悬疑',
      'romance': '言情',
      'scifi': '科幻',
      'history': '历史',
    };
    return labels[genreId] ?? genreId;
  }
}
