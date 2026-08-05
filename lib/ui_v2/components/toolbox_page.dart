/// 工具箱页面 - 左侧工具列表 + 右侧内容区域
library;

import 'package:flutter/material.dart';

import 'package:lingbi/features/review/ui/anti_hallucination_panel.dart';
import 'package:lingbi/features/canon/ui/change_propagation_panel.dart';
import 'package:lingbi/features/canon/ui/character_relation_panel.dart';
import 'package:lingbi/features/review/ui/clarity_check_panel.dart';
import 'package:lingbi/features/review/ui/de_ai_flavor_panel.dart';
import 'package:lingbi/features/import_export/ui/drama_conversion_panel.dart';
import 'package:lingbi/features/writing/ui/foreshadowing_panel.dart';
import 'package:lingbi/features/skill/ui/market_panel.dart';
import 'package:lingbi/features/settings/ui/model_router_panel.dart';
import 'package:lingbi/features/parallel_world/ui/parallel_world_panel.dart';
import 'package:lingbi/features/knowledge/ui/reference_book_panel.dart';
import 'package:lingbi/features/writing/ui/short_story_panel.dart';
import 'package:lingbi/features/review/ui/six_dimension_review_panel.dart';
import 'package:lingbi/features/strand/ui/strand_weave_panel.dart';
import 'package:lingbi/features/style/ui/style_profile_panel.dart';
import 'package:lingbi/features/knowledge/ui/vector_knowledge_panel.dart';
import 'package:lingbi/features/knowledge/ui/web_search_panel.dart';
import 'package:lingbi/features/collaboration/ui/workflow_approval_panel.dart';
import 'package:lingbi/features/routing/ui/token_ledger_panel.dart';

class ToolboxPage extends StatefulWidget {
  const ToolboxPage({super.key, this.projectId});

  final String? projectId;

  @override
  State<ToolboxPage> createState() => _ToolboxPageState();
}

class _ToolboxPageState extends State<ToolboxPage> {
  int _selectedIndex = 0;

  static const List<_ToolItem> _tools = [
    _ToolItem('角色关系', Icons.hub_rounded),
    _ToolItem('一键成剧', Icons.theater_comedy_rounded, isExperimental: true),
    _ToolItem('平行世界', Icons.public_rounded, isExperimental: true),
    _ToolItem('流程审批', Icons.fact_check_rounded, isExperimental: true),
    _ToolItem('六维审稿', Icons.radar_rounded, isExperimental: true),
    _ToolItem('伏笔管理', Icons.anchor_rounded),
    _ToolItem('清晰度检测', Icons.lightbulb_rounded, isExperimental: true),
    _ToolItem('反幻觉监督', Icons.shield_rounded, isExperimental: true),
    _ToolItem('参考书', Icons.menu_book_rounded, isExperimental: true),
    _ToolItem('向量知识', Icons.storage_rounded, isExperimental: true),
    _ToolItem('网络搜索', Icons.travel_explore_rounded, isExperimental: true),
    _ToolItem('模型路由', Icons.account_tree_rounded),
    _ToolItem('风格蒸馏', Icons.format_paint_rounded, isExperimental: true),
    _ToolItem('短篇引擎', Icons.flash_on_rounded),
    _ToolItem('市场情报', Icons.insights_rounded, isExperimental: true),
    _ToolItem('变更传播', Icons.sync_alt_rounded),
    _ToolItem('去AI味', Icons.auto_fix_high_rounded, isExperimental: true),
    _ToolItem('叙事线编织', Icons.linear_scale_rounded, isExperimental: true),
    _ToolItem('Token 账本', Icons.data_usage_rounded, isExperimental: true),
  ];

  Widget _buildPanel() {
    final pid = widget.projectId ?? '';
    switch (_selectedIndex) {
      case 0:
        return CharacterRelationPanel(projectId: pid);
      case 1:
        return DramaConversionPanel(projectId: pid);
      case 2:
        return ParallelWorldPanel(projectId: pid);
      case 3:
        return WorkflowApprovalPanel(projectId: pid);
      case 4:
        return SixDimensionReviewPanel(projectId: pid);
      case 5:
        return ForeshadowingPanel(projectId: pid);
      case 6:
        return const ClarityCheckPanel();
      case 7:
        return AntiHallucinationPanel(projectId: pid);
      case 8:
        return ReferenceBookPanel(projectId: pid);
      case 9:
        return VectorKnowledgePanel(projectId: pid);
      case 10:
        return WebSearchPanel(projectId: pid);
      case 11:
        return ModelRouterPanel(projectId: pid);
      case 12:
        return StyleProfilePanel(projectId: pid);
      case 13:
        return ShortStoryPanel(projectId: pid);
      case 14:
        return const MarketPanel();
      case 15:
        return ChangePropagationPanel(projectId: pid);
      case 16:
        return DeAiFlavorPanel(projectId: pid);
      case 17:
        return StrandWeavePanel(projectId: pid);
      case 18:
        return const TokenLedgerPanel();
      default:
        return const Center(child: Text('选择工具'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  '工具箱',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _tools.length,
                  itemBuilder: (context, index) {
                    final tool = _tools[index];
                    final isSelected = index == _selectedIndex;
                    return Material(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                tool.icon,
                                size: 20,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tool.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (tool.isExperimental)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Experimental',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: theme.dividerColor,
        ),
        Expanded(
          child: _buildPanel(),
        ),
      ],
    );
  }
}

class _ToolItem {
  const _ToolItem(this.label, this.icon, {this.isExperimental = false});

  final String label;
  final IconData icon;
  final bool isExperimental;
}
