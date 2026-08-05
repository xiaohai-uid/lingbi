import 'package:flutter/material.dart';

import '../../../shared/di/service_locator.dart';
import '../../../ui_v2/theme/tokens.dart';
import '../ledger/token_ledger.dart';

/// Read-only run/node token usage panel.
class TokenLedgerPanel extends StatefulWidget {
  const TokenLedgerPanel({super.key, this.ledger});

  final TokenLedger? ledger;

  @override
  State<TokenLedgerPanel> createState() => _TokenLedgerPanelState();
}

class _TokenLedgerPanelState extends State<TokenLedgerPanel> {
  late final TokenLedger _ledger;
  Map<String, TokenUsage> _byNode = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ledger = widget.ledger ?? ServiceLocator.instance.tokenLedger;
    _load();
  }

  Future<void> _load() async {
    final runIds = await _ledger.listRunIds();
    if (runIds.isNotEmpty) {
      _byNode = await _ledger.summarizeByNode(runIds.first);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_byNode.isEmpty) {
      return Center(
        child: Text(
          '暂无 Token 账本',
          style: TextStyle(color: c.muted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(LingBiTokens.space4),
      children: [
        for (final entry in _byNode.entries)
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
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.totalTokens} tokens · ${entry.value.attempts} 次尝试',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
