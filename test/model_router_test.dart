/// 多模型路由 — 单元测试
///
/// 覆盖：路由/降级/切换
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/model_router_service.dart';

void main() {
  group('ModelRouteConfig', () {
    test('fromJson / toJson 往返', () {
      const config = ModelRouteConfig(
        planningEndpointId: 'deepseek',
        writingEndpointId: 'openai',
        reviewEndpointId: 'claude',
      );

      final json = config.toJson();
      final restored = ModelRouteConfig.fromJson(json);

      expect(restored.planningEndpointId, 'deepseek');
      expect(restored.writingEndpointId, 'openai');
      expect(restored.reviewEndpointId, 'claude');
      expect(restored.hasCustomRoutes, isTrue);
    });

    test('getEndpointId 按槽位获取', () {
      const config = ModelRouteConfig(
        planningEndpointId: 'a',
        writingEndpointId: 'b',
        reviewEndpointId: 'c',
      );

      expect(config.getEndpointId(RouteSlot.planning), 'a');
      expect(config.getEndpointId(RouteSlot.writing), 'b');
      expect(config.getEndpointId(RouteSlot.review), 'c');
    });

    test('空配置 hasCustomRoutes 为 false', () {
      const config = ModelRouteConfig();
      expect(config.hasCustomRoutes, isFalse);
    });
  });

  group('RouteSlot', () {
    test('label 中文标签', () {
      expect(RouteSlot.planning.label, '规划');
      expect(RouteSlot.writing.label, '正文');
      expect(RouteSlot.review.label, '审阅');
    });
  });

  group('ModelRouterService 路由', () {
    late ModelRouterService service;

    setUp(() {
      service = ModelRouterService(
        defaultEndpointId: 'free',
      );
    });

    test('未配置时降级为默认', () {
      final resolution = service.resolve(RouteSlot.writing);
      expect(resolution.endpointId, 'free');
      expect(resolution.isFallback, isTrue);
    });

    test('配置后路由到指定 endpoint', () {
      service.setRoute(RouteSlot.writing, 'openai');

      final resolution = service.resolve(RouteSlot.writing);
      expect(resolution.endpointId, 'openai');
      expect(resolution.isFallback, isFalse);
    });

    test('各槽位独立配置', () {
      service.setRoute(RouteSlot.planning, 'deepseek');
      service.setRoute(RouteSlot.writing, 'openai');
      service.setRoute(RouteSlot.review, 'claude');

      expect(service.getProviderForTask(RouteSlot.planning), 'deepseek');
      expect(service.getProviderForTask(RouteSlot.writing), 'openai');
      expect(service.getProviderForTask(RouteSlot.review), 'claude');
    });

    test('clearRoute 恢复默认', () {
      service.setRoute(RouteSlot.planning, 'deepseek');
      service.clearRoute(RouteSlot.planning);

      final resolution = service.resolve(RouteSlot.planning);
      expect(resolution.isFallback, isTrue);
      expect(resolution.endpointId, 'free');
    });

    test('配置的 endpoint 不在可用列表中时降级', () {
      service.availableEndpoints = ['openai', 'claude'];
      service.setRoute(RouteSlot.writing, 'nonexist');

      final resolution = service.resolve(RouteSlot.writing);
      expect(resolution.isFallback, isTrue);
      expect(resolution.endpointId, 'free');
    });

    test('resolveAll 返回全部槽位', () {
      service.setRoute(RouteSlot.planning, 'deepseek');

      final all = service.resolveAll();
      expect(all.length, 3);
      expect(all[RouteSlot.planning]!.endpointId, 'deepseek');
      expect(all[RouteSlot.writing]!.isFallback, isTrue);
    });
  });

  group('配置持久化', () {
    test('loadConfig / exportConfig 往返', () {
      final service = ModelRouterService();
      service.loadConfig(const ModelRouteConfig(
        planningEndpointId: 'a',
        writingEndpointId: 'b',
      ));

      final exported = service.exportConfig();
      expect(exported.planningEndpointId, 'a');
      expect(exported.writingEndpointId, 'b');
      expect(exported.reviewEndpointId, '');
    });

    test('onConfigChanged 回调触发', () {
      final service = ModelRouterService();
      var called = false;
      service.onConfigChanged = () => called = true;

      service.setRoute(RouteSlot.review, 'claude');
      expect(called, isTrue);
    });
  });

  group('成本优化', () {
    test('相同模型时给出建议', () {
      final service = ModelRouterService(defaultEndpointId: 'openai');
      // 规划和正文都降级到同一个默认
      final hint = service.getCostOptimizationHint();
      expect(hint, contains('建议'));
    });

    test('不同模型时无建议', () {
      final service = ModelRouterService();
      service.setRoute(RouteSlot.planning, 'deepseek');
      service.setRoute(RouteSlot.writing, 'openai');

      final hint = service.getCostOptimizationHint();
      expect(hint, isEmpty);
    });

    test('路由状态摘要', () {
      final service = ModelRouterService(defaultEndpointId: 'free');
      service.setRoute(RouteSlot.writing, 'openai');

      final summary = service.getRouteSummary();
      expect(summary, contains('规划: 默认'));
      expect(summary, contains('正文: openai'));
      expect(summary, contains('审阅: 默认'));
    });
  });
}
