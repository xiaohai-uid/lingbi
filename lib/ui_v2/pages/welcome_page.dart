import 'package:flutter/material.dart';

import '../../shared/models/project.dart';
import '../models/project_template.dart';
import '../theme/lingbi_icons.dart';
import '../theme/tokens.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    required this.onCreateProject,
    required this.onOpenProject,
    required this.onOpenSkillMarket,
    this.recentProjects = const [],
    this.onResumeProject,
  });

  final ValueChanged<ProjectTemplate> onCreateProject;
  final VoidCallback onOpenProject;
  final VoidCallback onOpenSkillMarket;
  final List<Project> recentProjects;
  final ValueChanged<Project>? onResumeProject;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  ProjectTemplate? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return ColoredBox(
      color: c.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space6,
          vertical: LingBiTokens.space12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, c),
                if (widget.recentProjects.isNotEmpty) ...[
                  const SizedBox(height: LingBiTokens.space10),
                  _buildSectionTitle(context, '最近项目'),
                  const SizedBox(height: LingBiTokens.space3),
                  _buildRecentProjects(c),
                ],
                const SizedBox(height: LingBiTokens.space10),
                _buildSectionTitle(context, '选择题材'),
                const SizedBox(height: LingBiTokens.space3),
                _buildTemplateGrid(c),
                if (_selectedTemplate != null) ...[
                  const SizedBox(height: LingBiTokens.space5),
                  _buildSelectedAction(c),
                ],
                const SizedBox(height: LingBiTokens.space8),
                _buildQuickActions(c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, LingBiColors c) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 260),
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '灵笔',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: c.accent,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: LingBiTokens.space5),
            Text(
              '把灵感写成长篇故事',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: c.fg,
                    fontFamily: LingBiTokens.fontDisplay,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: LingBiTokens.space4),
            Text(
              '从题材和三条关键设定开始，资产、章节与候选稿都保存在本地。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: c.fgSecondary,
                    fontFamily: LingBiTokens.fontBody,
                  ),
            ),
            const SizedBox(height: LingBiTokens.space6),
            FilledButton.icon(
              onPressed: () => setState(
                () => _selectedTemplate = ProjectTemplate.freeform,
              ),
              icon: const Icon(LingBiIcons.add, size: 18),
              label: const Text('新建自由项目'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String label) => Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: LingBiTokens.fontDisplay,
              fontWeight: FontWeight.w700,
            ),
      );

  Widget _buildRecentProjects(LingBiColors c) {
    return Wrap(
      spacing: LingBiTokens.space3,
      runSpacing: LingBiTokens.space3,
      children: widget.recentProjects
          .map(
            (project) => SizedBox(
              width: 300,
              child: OutlinedButton(
                onPressed: widget.onResumeProject == null
                    ? null
                    : () => widget.onResumeProject!(project),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.fg,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(LingBiTokens.space4),
                  side: BorderSide(color: c.borderOpaque),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: LingBiTokens.space1),
                    Text(
                      project.directoryPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTemplateGrid(LingBiColors c) => Wrap(
        spacing: LingBiTokens.space3,
        runSpacing: LingBiTokens.space3,
        children: ProjectTemplate.values
            .map(
              (template) => _buildTemplateCard(
                template,
                c,
                selected: _selectedTemplate?.templateId == template.templateId,
              ),
            )
            .toList(),
      );

  Widget _buildTemplateCard(
    ProjectTemplate template,
    LingBiColors c, {
    required bool selected,
  }) {
    return SizedBox(
      width: 300,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
          side: BorderSide(
            color: selected ? c.accent : c.borderOpaque,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _selectedTemplate = template),
          borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(LingBiTokens.space5),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_outline : template.icon,
                  size: 22,
                  color: selected ? c.accent : c.fgSecondary,
                ),
                const SizedBox(width: LingBiTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.genreLabel,
                        style: TextStyle(
                          color: c.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: LingBiTokens.space1),
                      Text(
                        template.description,
                        style: TextStyle(
                          color: c.fgSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAction(LingBiColors c) {
    final selected = _selectedTemplate!;
    return Container(
      padding: const EdgeInsets.all(LingBiTokens.space4),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.07),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '已选择${selected.genreLabel}',
              style: TextStyle(color: c.fg, fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            key: const ValueKey('continue-with-template'),
            onPressed: () => widget.onCreateProject(selected),
            child: const Text('填写项目简报'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(LingBiColors c) => Row(
        children: [
          OutlinedButton.icon(
            onPressed: widget.onOpenProject,
            icon: const Icon(LingBiIcons.upload, size: 18),
            label: const Text('打开本地项目'),
          ),
          const SizedBox(width: LingBiTokens.space3),
          TextButton.icon(
            onPressed: widget.onOpenSkillMarket,
            icon: const Icon(LingBiIcons.skillMarket, size: 18),
            label: const Text('浏览技能市场'),
            style: TextButton.styleFrom(foregroundColor: c.fgSecondary),
          ),
        ],
      );
}
