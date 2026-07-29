/// 短篇写作面板
///
/// 引导流程（情绪设计→反转构思→精修出稿）+ 拆文分析 + 扫榜趋势。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/features/writing/data/short_story_service.dart';

class ShortStoryPanel extends StatefulWidget {
  const ShortStoryPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<ShortStoryPanel> createState() => _ShortStoryPanelState();
}

class _ShortStoryPanelState extends State<ShortStoryPanel> {
  bool _loading = true;
  ShortStoryFlowState _flowState = const ShortStoryFlowState();
  final TextEditingController _storyIdeaController = TextEditingController();
  final TextEditingController _reversalController = TextEditingController();
  final TextEditingController _draftController = TextEditingController();
  final TextEditingController _analyzeController = TextEditingController();
  bool _suggesting = false;
  bool _saving = false;
  ShortStoryAnalysis? _analysis;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _storyIdeaController.dispose();
    _reversalController.dispose();
    _draftController.dispose();
    _analyzeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state = await ServiceLocator.instance.shortStoryService
          .loadFlowState(widget.projectId);
      if (mounted) {
        setState(() {
          _flowState = state;
          _reversalController.text = state.reversalIdea;
          _draftController.text = state.draft;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _suggestCurve() async {
    if (_storyIdeaController.text.trim().isEmpty) return;
    setState(() => _suggesting = true);
    try {
      final curve = await ServiceLocator.instance.shortStoryService
          .suggestEmotionCurve(storyIdea: _storyIdeaController.text.trim());
      if (mounted && curve.isNotEmpty) {
        final updated = _flowState.copyWith(emotionCurve: curve);
        setState(() => _flowState = updated);
        await ServiceLocator.instance.shortStoryService
            .saveFlowState(widget.projectId, updated);
      }
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  Future<void> _completeEmotion() async {
    setState(() => _saving = true);
    try {
      final updated = await ServiceLocator.instance.shortStoryService
          .completeEmotionDesign(
              widget.projectId, _flowState.emotionCurve);
      if (mounted) setState(() => _flowState = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completeReversal() async {
    if (_reversalController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = await ServiceLocator.instance.shortStoryService
          .completeReversalDesign(
              widget.projectId, _reversalController.text.trim());
      if (mounted) setState(() => _flowState = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completePolish() async {
    if (_draftController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = await ServiceLocator.instance.shortStoryService
          .completePolish(widget.projectId, _draftController.text.trim());
      if (mounted) setState(() => _flowState = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _analyzeText() async {
    if (_analyzeController.text.trim().isEmpty) return;
    setState(() => _analyzing = true);
    try {
      final result = await ServiceLocator.instance.shortStoryService
          .analyzeShortStory(_analyzeController.text.trim());
      if (mounted) setState(() => _analysis = result);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('短篇写作', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (_flowState.isComplete)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('短篇引导流程已完成！')),
                ],
              ),
            ),
          )
        else
          Stepper(
            currentStep: _flowState.currentStep.index,
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: [
              Step(
                title: const Text('情绪设计'),
                isActive: _flowState.currentStep.index >= 0,
                state: _flowState.currentStep.index > 0
                    ? StepState.complete
                    : StepState.editing,
                content: _buildEmotionStep(),
              ),
              Step(
                title: const Text('反转构思'),
                isActive: _flowState.currentStep.index >= 1,
                state: _flowState.currentStep.index > 1
                    ? StepState.complete
                    : StepState.editing,
                content: _buildReversalStep(),
              ),
              Step(
                title: const Text('精修出稿'),
                isActive: _flowState.currentStep.index >= 2,
                state: StepState.editing,
                content: _buildPolishStep(),
              ),
            ],
          ),
        const Divider(height: 32),
        Text('拆文分析', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _analyzeController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '粘贴短篇文本',
            hintText: '输入需要拆解分析的短篇作品...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _analyzing ? null : _analyzeText,
          icon: _analyzing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_analyzing ? '分析中...' : '拆文分析'),
        ),
        if (_analysis != null) ...[
          const SizedBox(height: 12),
          if (!_analysis!.isSuccess)
            Text(_analysis!.error,
                style: TextStyle(color: Theme.of(context).colorScheme.error))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _analysisRow('故事核', _analysis!.storyCore),
                    _analysisRow('结构', _analysis!.structure),
                    _analysisRow('反转设计', _analysis!.reversalDesign),
                    if (_analysis!.resonancePoints.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('共鸣点',
                          style: Theme.of(context).textTheme.labelMedium),
                      ..._analysis!.resonancePoints.map(
                          (p) => Text('• $p',
                              style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _analysisRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmotionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _storyIdeaController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '故事创意',
            hintText: '输入故事核心创意，AI 将生成情绪曲线建议...',
            border: OutlineInputBorder(),
            isDense: true,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _suggesting ? null : _suggestCurve,
          icon: _suggesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lightbulb_outline, size: 18),
          label: Text(_suggesting ? '生成中...' : 'AI 建议曲线'),
        ),
        const SizedBox(height: 12),
        if (_flowState.emotionCurve.isNotEmpty) ...[
          ..._flowState.emotionCurve.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${p.intensity}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text('${p.position} · ${p.emotion}'),
                  subtitle: p.description.isNotEmpty
                      ? Text(p.description, maxLines: 1)
                      : null,
                ),
              )),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _completeEmotion,
            child: const Text('完成情绪设计'),
          ),
        ],
      ],
    );
  }

  Widget _buildReversalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _reversalController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '反转构思',
            hintText: '铺垫→误导→揭示→回味...',
            border: OutlineInputBorder(),
            isDense: true,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : _completeReversal,
          child: const Text('完成反转构思'),
        ),
      ],
    );
  }

  Widget _buildPolishStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _draftController,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: '精修终稿',
            hintText: '节奏调整/金句打磨/结尾升华...',
            border: OutlineInputBorder(),
            isDense: true,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : _completePolish,
          child: const Text('完成出稿'),
        ),
      ],
    );
  }
}
