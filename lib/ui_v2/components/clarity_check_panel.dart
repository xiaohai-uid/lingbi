/// 清晰度检测面板 - 测试输入文本是否需要澄清
library;

import 'package:flutter/material.dart';
import 'package:lingbi/services/clarity_check_service.dart';

class ClarityCheckPanel extends StatefulWidget {
  const ClarityCheckPanel({super.key});

  @override
  State<ClarityCheckPanel> createState() => _ClarityCheckPanelState();
}

class _ClarityCheckPanelState extends State<ClarityCheckPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ClarityCheckService _service = ClarityCheckService();
  ClarityCheckResult? _result;

  static const _accentColor = Color(0xFF059669);

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _check() {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _result = _service.assess(input);
    });
  }

  void _applyOption(String option) {
    _inputController.text = option;
    _check();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PanelHeader(
          icon: Icons.check_circle_rounded,
          title: '清晰度检测',
          accentColor: _accentColor,
        ),
        const SizedBox(height: 6),
        Text(
          '测试输入文本是否需要进一步澄清',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        _PanelSection(
          title: '输入文本',
          icon: Icons.text_fields_rounded,
          accentColor: _accentColor,
          child: TextField(
            controller: _inputController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '输入待检测文本',
              hintText: '在此输入需要检测清晰度的文本...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('检测'),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _ResultCard(result: _result!, onOptionTap: _applyOption),
        ],
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.01,
          ),
        ),
      ],
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.only(left: 14, top: 12, bottom: 12, right: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentColor, width: 3),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onOptionTap});

  final ClarityCheckResult result;
  final ValueChanged<String> onOptionTap;

  @override
  Widget build(BuildContext context) {
    final isClear = !result.needsClarification;
    final statusColor =
        isClear ? const Color(0xFF059669) : const Color(0xFFD97706);
    final statusIcon =
        isClear ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
    final statusText = isClear ? '文本清晰' : '需进一步澄清';

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (result.question.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                '需要澄清的问题',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.02,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.question,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
            if (result.quickOptions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                '快捷选项',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.02,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: result.quickOptions
                    .map((option) => ActionChip(
                          label: Text(option),
                          onPressed: () => onOptionTap(option),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
