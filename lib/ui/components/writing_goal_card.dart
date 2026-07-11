/// WritingGoalCard — 今日写作目标卡片
///
/// 显示目标字数、已写字数、进度条、连续天数。
library;

import 'package:flutter/material.dart';
import '../../services/writing_goal_service.dart';

class WritingGoalCard extends StatelessWidget {
  const WritingGoalCard({
    super.key,
    this.progress,
    this.todayStats,
    this.onSetGoal,
    this.onRefresh,
  });

  final GoalProgress? progress;
  final DailyWritingStat? todayStats;
  final VoidCallback? onSetGoal;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF2D2D5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 标题栏 ──
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('今日写作目标',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )),
              const Spacer(),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                  onPressed: onRefresh,
                ),
              if (onSetGoal != null)
                TextButton.icon(
                  icon: const Icon(Icons.settings, size: 14, color: Colors.white70),
                  label: const Text('设置目标',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                  onPressed: onSetGoal,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 进度条 ──
          if (progress != null) ...[
            Row(
              children: [
                Text(
                  '${progress!.currentWordCount} / ${progress!.targetWordCount} 字',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress!.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _progressColor(progress!.percentage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress!.percentage / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progressColor(progress!.percentage),
                ),
                minHeight: 8,
              ),
            ),
          ] else ...[
            const Text('未设置今日目标',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),

          // ── 统计数据行 ──
          Row(
            children: [
              _buildStatItem(
                icon: Icons.local_fire_department,
                label: '连续 ${progress?.streak ?? 0} 天',
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.edit_note,
                label: '今日 ${todayStats?.wordCount ?? 0} 字',
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.timer_outlined,
                label: '${todayStats?.minutesSpent ?? 0} 分钟',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Color _progressColor(double percentage) {
    if (percentage >= 100) return Colors.greenAccent;
    if (percentage >= 50) return Colors.orangeAccent;
    return Colors.blueAccent;
  }
}
