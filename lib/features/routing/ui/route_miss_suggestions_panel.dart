import 'package:flutter/material.dart';

import '../../../shared/di/service_locator.dart';
import '../../../ui_v2/theme/tokens.dart';

/// Read-only panel showing repeated route-miss skill suggestions.
class RouteMissSuggestionsPanel extends StatelessWidget {
  const RouteMissSuggestionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    final suggestions = ServiceLocator.instance.skillActionService.suggestions;
    if (suggestions.isEmpty) {
      return Center(
        child: Text(
          '暂无新技能建议',
          style: TextStyle(color: c.muted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(LingBiTokens.space4),
      children: [
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: LingBiTokens.space3),
            child: Container(
              padding: const EdgeInsets.all(LingBiTokens.space3),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(LingBiTokens.radiusMd),
                border: Border.all(
                  color: c.borderOpaque.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.suggestedSkillId,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: c.fg,
                          ),
                        ),
                        Text(
                          '${suggestion.scene} · ${suggestion.count} 次 miss',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome, size: 18, color: Colors.amber),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
