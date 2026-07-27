import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';
import '../models/project_template.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onCreateProject,
    required this.onOpenProject,
    required this.onOpenSkillMarket,
  });
  final ValueChanged<ProjectTemplate> onCreateProject;
  final VoidCallback onOpenProject;
  final VoidCallback onOpenSkillMarket;

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space6,
          vertical: LingBiTokens.space16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(c),
              const SizedBox(height: LingBiTokens.space6),
              Text(
                '欢迎来到灵笔',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: c.fg,
                  letterSpacing: -1.5 / 48 * 40,
                ),
              ),
              const SizedBox(height: LingBiTokens.space3),
              Text(
                'AI 驱动的小说创作平台\n让灵感流淌，让故事成真',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: c.fgSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: LingBiTokens.space10),
              _buildPrimaryButton(c),
              const SizedBox(height: LingBiTokens.space12),
              _buildSectionLabel('从模板开始', c),
              const SizedBox(height: LingBiTokens.space4),
              _buildTemplateGrid(c),
              const SizedBox(height: LingBiTokens.space12),
              _buildQuickActions(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(LingBiColors c) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '灵',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(LingBiColors c) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => onCreateProject(ProjectTemplate.freeform),
        icon: const Icon(LingBiIcons.add, size: 20),
        label: const Text('新建项目'),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: LingBiTokens.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, LingBiColors c) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTemplateGrid(LingBiColors c) {
    return Wrap(
      spacing: LingBiTokens.space3,
      runSpacing: LingBiTokens.space3,
      children:
          ProjectTemplate.values.map((t) => _buildTemplateCard(t, c)).toList(),
    );
  }

  Widget _buildTemplateCard(ProjectTemplate t, LingBiColors c) {
    return InkWell(
      onTap: () => onCreateProject(t),
      borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(LingBiTokens.space4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
          border: Border.all(
            color: c.borderOpaque.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(t.icon, size: 24, color: c.accent),
            const SizedBox(height: LingBiTokens.space3),
            Text(
              t.genreLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.fg,
              ),
            ),
            const SizedBox(height: LingBiTokens.space1),
            Text(
              t.description,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: c.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(LingBiColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionChip(c, LingBiIcons.upload, '导入已有作品', onTap: onOpenProject),
        const SizedBox(width: LingBiTokens.space3),
        _buildActionChip(c, LingBiIcons.skillMarket, '浏览技能市场',
            onTap: onOpenSkillMarket),
      ],
    );
  }

  Widget _buildActionChip(LingBiColors c, IconData icon, String label,
      {VoidCallback? onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.fgSecondary,
        side: BorderSide(color: c.borderOpaque),
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space4,
          vertical: LingBiTokens.space2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
        ),
      ),
    );
  }
}
