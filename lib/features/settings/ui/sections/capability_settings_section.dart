import 'package:flutter/material.dart';

import '../../../routing/tool_bootstrap.dart';
import '../../../../ui_v2/theme/tokens.dart';
import 'settings_section_scaffold.dart';

class CapabilitySettingsSection extends StatefulWidget {
  const CapabilitySettingsSection({super.key});

  @override
  State<CapabilitySettingsSection> createState() =>
      _CapabilitySettingsSectionState();
}

class _CapabilitySettingsSectionState extends State<CapabilitySettingsSection> {
  final ToolBootstrap _bootstrap = ToolBootstrap();
  Map<ToolKind, ToolStatus>? _statuses;

  static const _requirements = [
    ToolRequirement(kind: ToolKind.git, label: 'git'),
    ToolRequirement(kind: ToolKind.python, label: 'python'),
    ToolRequirement(kind: ToolKind.crawl4ai, label: 'Crawl4AI'),
    ToolRequirement(kind: ToolKind.llmGateway, label: 'LLM 网关'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final statuses = await _bootstrap.checkAll(_requirements);
    if (mounted) setState(() => _statuses = statuses);
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final statuses = _statuses;
    return SettingsSectionScaffold(
      c: c,
      items: [
        for (final requirement in _requirements)
          SettingsSectionItem(
            icon: Icons.build_outlined,
            title: requirement.label,
            subtitle: statuses?[requirement.kind]?.detail ?? '检测中...',
            trailing: statuses == null
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LingBiTokens.space2,
                      vertical: LingBiTokens.space1,
                    ),
                    decoration: BoxDecoration(
                      color: statuses[requirement.kind]!.available
                          ? LingBiTokens.success.withValues(alpha: 0.1)
                          : LingBiTokens.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        LingBiTokens.radiusPill,
                      ),
                    ),
                    child: Text(
                      statuses[requirement.kind]!.available ? '可用' : '缺失',
                      style: TextStyle(
                        fontSize: 12,
                        color: statuses[requirement.kind]!.available
                            ? LingBiTokens.success
                            : LingBiTokens.warning,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
