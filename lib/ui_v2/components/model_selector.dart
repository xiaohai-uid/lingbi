/// 模型选择器 — 点击切换模型
///
/// 显示当前模型 ID + 上下文窗口标签，点击弹出按供应商分组的模型列表。
/// 替换静态 ModelStatusBar，提供 OpenWrite 式的即时模型切换体验。
library;

import 'package:flutter/material.dart';

import 'package:lingbi/shared/ai/model_registry.dart';
import 'package:lingbi/shared/di/service_locator.dart';

import '../theme/tokens.dart';

/// 可交互模型选择器
class ModelSelector extends StatefulWidget {
  const ModelSelector({super.key, this.compact = false});

  final bool compact;

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  late final VoidCallback _settingsListener;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _settingsListener = () {
      if (mounted) setState(() {});
    };
    ServiceLocator.instance.settingsService.addListener(_settingsListener);
  }

  @override
  void dispose() {
    ServiceLocator.instance.settingsService.removeListener(_settingsListener);
    super.dispose();
  }

  String get _currentProvider =>
      ServiceLocator.instance.settingsService.selectedProvider;

  String get _currentModelId {
    final settings = ServiceLocator.instance.settingsService;
    final id = settings.getSelectedModelId(_currentProvider);
    if (id.isNotEmpty) return id;
    return ServiceLocator.instance.aiService.currentModelId;
  }

  String _modelLabel(ModelInfo model) {
    final ctx = model.contextWindow;
    if (ctx == null || ctx <= 0) return model.id;
    if (ctx >= 1000) {
      return '${model.id} ${(ctx / 1000).toStringAsFixed(0)}K';
    }
    return '${model.id} $ctx';
  }

  Future<void> _showModelMenu() async {
    final aiService = ServiceLocator.instance.aiService;
    final providers = aiService.availableProviders;

    if (providers.isEmpty) return;

    final items = <PopupMenuEntry<String>>[];

    for (var i = 0; i < providers.length; i++) {
      final provider = providers[i];
      final pid = provider.name;
      final models = ModelRegistry.instance.getModelsForProvider(pid);
      final isCurrentProvider = pid == _currentProvider;

      if (i > 0) items.add(const PopupMenuDivider(height: 1));

      // 供应商分组标题
      items.add(
        PopupMenuItem<String>(
          enabled: false,
          height: 32,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 6,
                color: isCurrentProvider
                    ? LingBiColors.of(context).accent
                    : LingBiColors.of(context).muted,
              ),
              const SizedBox(width: 8),
              Text(
                provider.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LingBiColors.of(context).fgSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );

      // 模型列表
      for (final model in models) {
        final isSelected = model.id == _currentModelId && isCurrentProvider;
        items.add(
          PopupMenuItem<String>(
            value: '$pid:${model.id}',
            height: 36,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: isSelected
                      ? LingBiColors.of(context).accent
                      : LingBiColors.of(context).muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _modelLabel(model),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? LingBiColors.of(context).fg
                          : LingBiColors.of(context).fgSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSpace = screenHeight - offset.dy - renderBox.size.height;
    final maxHeight = bottomSpace - 16;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height + 4,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height + 4,
      ),
      items: items,
      constraints: BoxConstraints(
        maxHeight: maxHeight.clamp(200.0, 480.0),
        minWidth: 220,
        maxWidth: 340,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    if (result == null || !mounted) return;

    final parts = result.split(':');
    if (parts.length < 2) return;
    final providerId = parts[0];
    final modelId = parts.sublist(1).join(':');

    setState(() => _isSwitching = true);
    final selection = await ServiceLocator.instance.runtimeModelSelection
        .select(providerId, modelId);
    if (!mounted) return;
    setState(() => _isSwitching = false);
    if (!selection.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selection.message)),
      );
    }
  }

  String _currentLabel() {
    final modelId = _currentModelId;
    if (modelId.isEmpty) return _currentProvider;

    final models =
        ModelRegistry.instance.getModelsForProvider(_currentProvider);
    for (final m in models) {
      if (m.id == modelId) return _modelLabel(m);
    }
    return modelId;
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);

    return InkWell(
      onTap: _isSwitching ? null : _showModelMenu,
      borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
      child: Container(
        height: widget.compact ? 28 : 32,
        padding: const EdgeInsets.symmetric(
          horizontal: LingBiTokens.space2,
        ),
        decoration: BoxDecoration(
          color: c.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
          border: Border.all(color: c.borderOpaque.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSwitching)
              SizedBox.square(
                dimension: widget.compact ? 14 : 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: c.accent,
                ),
              )
            else
              Icon(
                Icons.smart_toy_outlined,
                size: widget.compact ? 14 : 16,
                color: c.accent,
              ),
            const SizedBox(width: LingBiTokens.space1),
            Flexible(
              child: Text(
                _currentLabel(),
                style: TextStyle(
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: c.fg,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: widget.compact ? 14 : 16,
              color: c.muted,
            ),
          ],
        ),
      ),
    );
  }
}
