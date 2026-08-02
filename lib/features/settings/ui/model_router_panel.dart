/// 多模型路由面板
///
/// 为规划/正文/审阅三个槽位分别指定模型端点。
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/model_router_service.dart';

class ModelRouterPanel extends StatefulWidget {
  const ModelRouterPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<ModelRouterPanel> createState() => _ModelRouterPanelState();
}

class _ModelRouterPanelState extends State<ModelRouterPanel> {
  late ModelRouterService _service;
  final Map<RouteSlot, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _service = ServiceLocator.instance.modelRouterService;
    for (final slot in RouteSlot.values) {
      _controllers[slot] = TextEditingController(
        text: _service.config.getEndpointId(slot),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyRoute(RouteSlot slot) {
    final endpoint = _controllers[slot]!.text.trim();
    setState(() {
      if (endpoint.isEmpty) {
        _service.clearRoute(slot);
      } else {
        _service.setRoute(slot, endpoint);
      }
    });
  }

  Color _slotColor(RouteSlot slot) {
    return switch (slot) {
      RouteSlot.planning => Colors.blue,
      RouteSlot.writing => Colors.purple,
      RouteSlot.review => Colors.teal,
    };
  }

  IconData _slotIcon(RouteSlot slot) {
    return switch (slot) {
      RouteSlot.planning => Icons.map_outlined,
      RouteSlot.writing => Icons.edit_note,
      RouteSlot.review => Icons.rate_review_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolutions = _service.resolveAll();
    final hint = _service.getCostOptimizationHint();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('多模型路由', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '为不同任务类型指定模型端点，未配置时降级为默认模型。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...RouteSlot.values.map((slot) {
          final resolution = resolutions[slot]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _slotColor(slot).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_slotIcon(slot),
                            size: 20, color: _slotColor(slot)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slot.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text(slot.description,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (resolution.isFallback)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('默认',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                _slotColor(slot).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(resolution.endpointId,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _slotColor(slot))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[slot],
                          decoration: InputDecoration(
                            labelText: 'Endpoint ID',
                            hintText: '如: deepseek / openai / free',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: _controllers[slot]!.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _controllers[slot]!.clear();
                                      _applyRoute(slot);
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _applyRoute(slot),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () => _applyRoute(slot),
                        child: const Text('应用'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(hint)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('路由摘要',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(_service.getRouteSummary(),
                    style: Theme.of(context).textTheme.bodyMedium),
                if (_service.availableEndpoints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '可用端点: ${_service.availableEndpoints.join(", ")}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
