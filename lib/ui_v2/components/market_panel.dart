/// MarketPanel — 市场情报面板
///
/// 展示平台热门趋势数据，支持：
/// - 平台/题材选择
/// - 热门作品榜单
/// - 平均章长统计
/// - 热门标签
/// - 注入 AI 上下文开关
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/market_intel_service.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

/// 市场情报面板 — 嵌入写作页右侧或 AI 面板 Tab
class MarketPanel extends StatefulWidget {
  const MarketPanel({super.key, this.onContextGenerated, this.projectGenre, this.projectPlatform});

  /// 市场上下文生成回调（供外部注入 AI pipeline）
  final void Function(String marketContext)? onContextGenerated;

  /// 当前项目已选题材（自动预选，无需用户重复选择）
  final String? projectGenre;

  /// 当前项目目标平台
  final String? projectPlatform;

  @override
  State<MarketPanel> createState() => _MarketPanelState();
}

class _MarketPanelState extends State<MarketPanel> {
  static const _platforms = ['起点', '番茄', '七猫'];
  static const _genres = ['玄幻', '都市', '悬疑', '言情', '科幻', '历史'];

  late String _selectedPlatform;
  late String _selectedGenre;
  bool _loading = false;
  bool _injectToContext = false;
  MarketIntelSnapshot? _snapshot;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // 优先使用项目已选的平台/题材，避免用户重复选择
    _selectedPlatform = (widget.projectPlatform != null &&
            _platforms.contains(widget.projectPlatform))
        ? widget.projectPlatform!
        : '起点';
    _selectedGenre = (widget.projectGenre != null &&
            _genres.contains(widget.projectGenre))
        ? widget.projectGenre!
        : '玄幻';
    _fetchTrends();
  }

  Future<void> _fetchTrends() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final service = ServiceLocator.instance.marketIntelService;
      final snapshot = await service.fetchTrends(
        platform: _selectedPlatform,
        genre: _selectedGenre,
      );
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _loading = false;
        });
        if (_injectToContext && snapshot != null) {
          widget.onContextGenerated?.call(
            MarketIntelService.buildContextSummary(snapshot),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '获取市场数据失败';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(
          left: BorderSide(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(c),
          _buildFilters(c),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? _buildError(c)
                    : _snapshot == null
                        ? _buildEmpty(c)
                        : _buildContent(c),
          ),
          _buildFooter(c),
        ],
      ),
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space4, LingBiTokens.space4,
        LingBiTokens.space4, LingBiTokens.space2,
      ),
      child: Row(
        children: [
          Icon(LingBiIcons.market, size: 18, color: c.accent),
          const SizedBox(width: LingBiTokens.space2),
          Text(
            '市场情报',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.fg,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(LingBiIcons.refresh, size: 18, color: c.fgSecondary),
            onPressed: _loading ? null : _fetchTrends,
            tooltip: '刷新',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LingBiTokens.space4,
        vertical: LingBiTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 平台选择
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _platforms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final p = _platforms[i];
                final active = p == _selectedPlatform;
                return ChoiceChip(
                  label: Text(p, style: TextStyle(fontSize: 12, color: active ? c.bg : c.fgSecondary)),
                  selected: active,
                  selectedColor: c.accent,
                  backgroundColor: c.surfaceContainer,
                  onSelected: (_) {
                    setState(() => _selectedPlatform = p);
                    _fetchTrends();
                  },
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          const SizedBox(height: LingBiTokens.space2),
          // 题材标签
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _genres.map((g) {
              final active = g == _selectedGenre;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedGenre = g);
                  _fetchTrends();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingBiTokens.space2,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: active ? c.accent.withValues(alpha: 0.12) : c.surface,
                    borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
                    border: Border.all(
                      color: active ? c.accent : c.borderOpaque,
                    ),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? c.accent : c.fgSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LingBiColors c) {
    final snapshot = _snapshot!;
    return ListView(
      padding: const EdgeInsets.all(LingBiTokens.space4),
      children: [
        // 统计卡片
        if (snapshot.avgChapterWords > 0)
          Container(
            padding: const EdgeInsets.all(LingBiTokens.space3),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(LingBiIcons.chapter, size: 16, color: c.accent),
                const SizedBox(width: LingBiTokens.space2),
                Text(
                  '同类型平均章长: ${snapshot.avgChapterWords} 字',
                  style: TextStyle(fontSize: 13, color: c.fg),
                ),
              ],
            ),
          ),
        const SizedBox(height: LingBiTokens.space3),
        // 热门标签
        if (snapshot.hotTags.isNotEmpty) ...[
          Text(
            '热门标签',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.fgSecondary),
          ),
          const SizedBox(height: LingBiTokens.space1),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: snapshot.hotTags.take(8).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.surfaceContainer,
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
                ),
                child: Text(tag, style: TextStyle(fontSize: 11, color: c.fgSecondary)),
              );
            }).toList(),
          ),
          const SizedBox(height: LingBiTokens.space3),
        ],
        // 热门作品列表
        Text(
          '热门作品 TOP${snapshot.trends.length}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.fgSecondary),
        ),
        const SizedBox(height: LingBiTokens.space2),
        ...snapshot.trends.take(10).map((t) => _buildTrendItem(t, c)),
      ],
    );
  }

  Widget _buildTrendItem(MarketTrendEntry entry, LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LingBiTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 排名
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: entry.rank <= 3
                  ? LingBiTokens.cinnabar.withValues(alpha: 0.1)
                  : c.surfaceContainer,
              borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
            ),
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: entry.rank <= 3 ? LingBiTokens.cinnabar : c.muted,
              ),
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(fontSize: 13, color: c.fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.tags.isNotEmpty)
                  Text(
                    entry.tags.take(3).join(' / '),
                    style: TextStyle(fontSize: 11, color: c.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // 热度条
          Container(
            width: 40,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: c.surfaceContainer,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (entry.heatScore / 100).clamp(0.1, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.all(LingBiTokens.space4),
      child: Row(
        children: [
          SizedBox(
            width: 16, height: 16,
            child: Checkbox(
              value: _injectToContext,
              onChanged: (v) {
                setState(() => _injectToContext = v ?? false);
                if (_injectToContext && _snapshot != null) {
                  widget.onContextGenerated?.call(
                    MarketIntelService.buildContextSummary(_snapshot),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: LingBiTokens.space2),
          Text(
            '注入 AI 写作上下文',
            style: TextStyle(fontSize: 12, color: c.fgSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(LingBiColors c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LingBiIcons.close, color: c.muted, size: 32),
          const SizedBox(height: LingBiTokens.space2),
          Text(_error, style: TextStyle(fontSize: 13, color: c.muted)),
          const SizedBox(height: LingBiTokens.space3),
          FilledButton.tonal(onPressed: _fetchTrends, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmpty(LingBiColors c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LingBiIcons.market, color: c.muted, size: 32),
          const SizedBox(height: LingBiTokens.space2),
          Text(
            '暂无市场数据\n配置爬虫 API 后自动获取',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.muted),
          ),
        ],
      ),
    );
  }
}
