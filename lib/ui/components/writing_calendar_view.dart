/// WritingCalendarView — 写作日历月视图
///
/// 显示某月的每日写作统计，类似 GitHub contributions 热力图风格。
library;

import 'package:flutter/material.dart';
import '../../data/database/world_database.dart';

class WritingCalendarView extends StatelessWidget {
  const WritingCalendarView({
    super.key,
    this.stats = const [],
    this.year,
    this.month,
    this.onDayTap,
  });

  final List<DailyWritingStat> stats;
  final int? year;
  final int? month;
  final void Function(String date)? onDayTap;

  int get _year => year ?? DateTime.now().year;
  int get _month => month ?? DateTime.now().month;

  Map<String, int> get _statsMap {
    final map = <String, int>{};
    for (final s in stats) {
      map[s.date] = s.wordCount;
    }
    return map;
  }

  Color _dayColor(int wordCount) {
    if (wordCount == 0) return const Color(0xFF2D2D2D);
    if (wordCount < 500) return const Color(0xFF1B5E20).withValues(alpha: 0.4);
    if (wordCount < 1500) return const Color(0xFF1B5E20).withValues(alpha: 0.6);
    if (wordCount < 3000) return const Color(0xFF1B5E20).withValues(alpha: 0.8);
    return const Color(0xFF00E676);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_year, _month);
    final lastDay = DateTime(_year, _month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // Sunday = 0
    final daysInMonth = lastDay.day;
    final statsMap = _statsMap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份标题
        Text(
          '$_year年$_month月',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '总写作: ${stats.fold(0, (sum, s) => sum + s.wordCount)} 字 | '
          '活跃天数: ${stats.length} 天',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),

        // 星期表头
        Row(
          children: ['日', '一', '二', '三', '四', '五', '六']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500])),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),

        // 日期网格
        ...List.generate(
          ((firstWeekday + daysInMonth) / 7).ceil(),
          (weekIdx) => Row(
            children: List.generate(7, (dayIdx) {
              final dayNum = weekIdx * 7 + dayIdx - firstWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 32));
              }

              final dateStr = '$_year-${_month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
              final wordCount = statsMap[dateStr] ?? 0;

              return Expanded(
                child: InkWell(
                  onTap: wordCount > 0 ? () => onDayTap?.call(dateStr) : null,
                  child: Container(
                    height: 32,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: _dayColor(wordCount),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 10,
                          color: wordCount > 0 ? Colors.white : Colors.grey[600],
                          fontWeight: wordCount > 0 ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),
        // 图例
        Row(
          children: [
            _buildLegendItem(const Color(0xFF2D2D2D), '无'),
            _buildLegendItem(const Color(0xFF1B5E20).withValues(alpha: 0.4), '<500'),
            _buildLegendItem(const Color(0xFF1B5E20).withValues(alpha: 0.6), '<1500'),
            _buildLegendItem(const Color(0xFF1B5E20).withValues(alpha: 0.8), '<3000'),
            _buildLegendItem(const Color(0xFF00E676), '3000+'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
