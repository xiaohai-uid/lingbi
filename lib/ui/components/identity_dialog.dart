import 'package:flutter/material.dart';

import 'package:lingbi/services/identity/identity_detector.dart';
import 'package:lingbi/services/identity/identity_rules.dart';

/// 身份识别确认对话框
///
/// 将 [DetectionResult] 中的候选身份逐条展示，
/// 用户可逐条「确认」或「忽略」。
///
/// [onConfirm] 在用户点击某条「确认」时回调，参数为被确认的候选；
/// [onIgnoreAll] 在用户点击「全部忽略」时回调。
class IdentityConfirmDialog extends StatefulWidget {
  const IdentityConfirmDialog({
    super.key,
    required this.result,
    required this.characterNameOf,
    required this.onConfirm,
    required this.onIgnoreAll,
  });
  final DetectionResult result;
  final String Function(String characterId) characterNameOf;
  final void Function(IdentityCandidate) onConfirm;
  final VoidCallback onIgnoreAll;

  @override
  State<IdentityConfirmDialog> createState() => _IdentityConfirmDialogState();
}

class _IdentityConfirmDialogState extends State<IdentityConfirmDialog> {
  late final Set<String> _confirmed;
  late final Set<String> _ignored;

  @override
  void initState() {
    super.initState();
    _confirmed = {};
    _ignored = {};
  }

  bool get _allResolved =>
      _confirmed.length + _ignored.length >= widget.result.candidates.length;

  void _resolve(IdentityCandidate c, bool confirm) {
    setState(() {
      if (confirm) {
        _ignored.remove(c.characterId);
        _confirmed.add(c.characterId);
        widget.onConfirm(c);
      } else {
        _confirmed.remove(c.characterId);
        _ignored.add(c.characterId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = widget.result.candidates;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20),
          const SizedBox(width: 8),
          Text('确认身份识别（${candidates.length}）'),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: candidates.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = candidates[i];
            final resolved = _confirmed.contains(c.characterId) ||
                _ignored.contains(c.characterId);
            final isConfirmed = _confirmed.contains(c.characterId);
            final charName = widget.characterNameOf(c.characterId);
            return ListTile(
              leading: Icon(
                isConfirmed ? Icons.check_circle : Icons.person_outline,
                color: isConfirmed ? Colors.green : null,
              ),
              title: Text('$charName → ${c.identityName}'),
              subtitle: Text(
                '置信度 ${(c.confidence * 100).round()}% · 来源 ${c.source}',
                style: theme.textTheme.labelSmall,
              ),
              trailing: resolved
                  ? Text(isConfirmed ? '已确认' : '已忽略')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _resolve(c, true),
                          child: const Text('确认'),
                        ),
                        TextButton(
                          onPressed: () => _resolve(c, false),
                          child: const Text('忽略'),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onIgnoreAll();
            Navigator.of(context).pop();
          },
          child: const Text('全部忽略'),
        ),
        FilledButton(
          onPressed: _allResolved ? () => Navigator.of(context).pop() : null,
          child: const Text('完成'),
        ),
      ],
    );
  }
}
