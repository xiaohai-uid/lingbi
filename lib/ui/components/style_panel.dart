/// StylePanel — 文风检测展示面板
library;

import 'package:flutter/material.dart';
import '../../data/database/world_database.dart';

/// 文风展示面板
class StylePanel extends StatelessWidget {
  const StylePanel({
    super.key,
    this.currentProfile,
    this.previousProfile,
    this.driftScore,
    this.onAnalyze,
  });

  /// 当前风格画像
  final StyleProfile? currentProfile;

  /// 前一章的风格画像（用于漂移对比）
  final StyleProfile? previousProfile;

  /// 漂移分数 (0.0=一致, 1.0=完全不同)
  final double? driftScore;

  /// 分析触发回调
  final VoidCallback? onAnalyze;

  Color _driftColor(double score) {
    if (score < 0.3) return Colors.green;
    if (score < 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 标题 ──
        Row(
          children: [
            const Text('🎨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('文风分析',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (onAnalyze != null)
              TextButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('分析风格', style: TextStyle(fontSize: 12)),
                onPressed: onAnalyze,
              ),
          ],
        ),

        if (currentProfile == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('尚未分析风格，点击"分析风格"开始',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else ...[
          const SizedBox(height: 8),

          // ── 风格卡片 ──
          _buildProfileCard(currentProfile!),

          // ── 漂移检测 ──
          if (driftScore != null) ...[
            const SizedBox(height: 12),
            _buildDriftCard(driftScore!),
          ],
        ],
      ],
    );
  }

  Widget _buildProfileCard(StyleProfile profile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.summary,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTag('语调', profile.tone),
              _buildTag('词汇', profile.vocabularyLevel),
              _buildTag('节奏', profile.pacing),
              _buildTag('对话',
                  '${(profile.dialogueRatio * 100).toStringAsFixed(0)}%'),
              _buildTag('句式复杂度',
                  profile.sentenceComplexity.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: const TextStyle(fontSize: 11, color: Color(0xFF3D3529))),
    );
  }

  Widget _buildDriftCard(double score) {
    final color = _driftColor(score);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(score < 0.3 ? Icons.check_circle : Icons.warning,
              color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              score < 0.3
                  ? '风格一致性好（漂移率 ${(score * 100).toStringAsFixed(0)}%）'
                  : '风格漂移风险（漂移率 ${(score * 100).toStringAsFixed(0)}%）',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
