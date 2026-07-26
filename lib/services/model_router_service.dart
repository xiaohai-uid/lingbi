/// 多模型路由服务
///
/// 为规划/正文/审阅分别指定不同模型：
/// - 每个路由槽位可选任何已配置的 EndpointConfig
/// - 实现用便宜模型规划、贵模型写正文的成本优化策略
/// - 未配置时降级为当前默认模型
library;

import 'package:lingbi/core/ai/ai_provider.dart';

// ─── 数据模型 ───

/// 路由槽位类型
enum RouteSlot {
  planning,
  writing,
  review;

  String get label => switch (this) {
        RouteSlot.planning => '规划',
        RouteSlot.writing => '正文',
        RouteSlot.review => '审阅',
      };

  String get description => switch (this) {
        RouteSlot.planning => '大纲/情节规划/结构设计（推荐低成本模型）',
        RouteSlot.writing => '正文生成/章节写作（推荐高质量模型）',
        RouteSlot.review => '审稿/校对/一致性检查（推荐推理模型）',
      };

  static RouteSlot fromString(String s) {
    return RouteSlot.values.firstWhere(
      (e) => e.name == s,
      orElse: () => RouteSlot.writing,
    );
  }
}

/// 路由配置
class ModelRouteConfig {
  const ModelRouteConfig({
    this.planningEndpointId = '',
    this.writingEndpointId = '',
    this.reviewEndpointId = '',
  });

  factory ModelRouteConfig.fromJson(Map<String, dynamic> json) {
    return ModelRouteConfig(
      planningEndpointId:
          json['planning_endpoint_id'] as String? ?? '',
      writingEndpointId:
          json['writing_endpoint_id'] as String? ?? '',
      reviewEndpointId: json['review_endpoint_id'] as String? ?? '',
    );
  }

  final String planningEndpointId;
  final String writingEndpointId;
  final String reviewEndpointId;

  /// 获取指定槽位的 endpoint ID
  String getEndpointId(RouteSlot slot) {
    return switch (slot) {
      RouteSlot.planning => planningEndpointId,
      RouteSlot.writing => writingEndpointId,
      RouteSlot.review => reviewEndpointId,
    };
  }

  /// 是否有任何自定义路由
  bool get hasCustomRoutes =>
      planningEndpointId.isNotEmpty ||
      writingEndpointId.isNotEmpty ||
      reviewEndpointId.isNotEmpty;

  ModelRouteConfig copyWith({
    String? planningEndpointId,
    String? writingEndpointId,
    String? reviewEndpointId,
  }) {
    return ModelRouteConfig(
      planningEndpointId:
          planningEndpointId ?? this.planningEndpointId,
      writingEndpointId:
          writingEndpointId ?? this.writingEndpointId,
      reviewEndpointId:
          reviewEndpointId ?? this.reviewEndpointId,
    );
  }

  Map<String, dynamic> toJson() => {
        'planning_endpoint_id': planningEndpointId,
        'writing_endpoint_id': writingEndpointId,
        'review_endpoint_id': reviewEndpointId,
      };
}

/// 路由解析结果
class RouteResolution {
  const RouteResolution({
    required this.slot,
    required this.endpointId,
    required this.isFallback,
  });

  final RouteSlot slot;
  final String endpointId;

  /// 是否为降级（使用默认模型）
  final bool isFallback;
}

// ─── 服务 ───

/// 多模型路由服务
class ModelRouterService {
  ModelRouterService({
    ModelRouteConfig? config,
    this.defaultEndpointId = 'free',
  }) : _config = config ?? const ModelRouteConfig();

  ModelRouteConfig _config;

  /// 默认 endpoint（未配置槽位时使用）
  final String defaultEndpointId;

  /// 可用 endpoint 列表（由外部注入）
  List<String> availableEndpoints = [];

  /// 路由变更回调
  void Function()? onConfigChanged;

  // ─── 1. 配置管理 ───

  /// 获取当前路由配置
  ModelRouteConfig get config => _config;

  /// 设置指定槽位的路由
  void setRoute(RouteSlot slot, String endpointId) {
    _config = switch (slot) {
      RouteSlot.planning =>
        _config.copyWith(planningEndpointId: endpointId),
      RouteSlot.writing =>
        _config.copyWith(writingEndpointId: endpointId),
      RouteSlot.review =>
        _config.copyWith(reviewEndpointId: endpointId),
    };
    onConfigChanged?.call();
  }

  /// 清除指定槽位（恢复默认）
  void clearRoute(RouteSlot slot) {
    setRoute(slot, '');
  }

  /// 加载配置
  void loadConfig(ModelRouteConfig config) {
    _config = config;
  }

  /// 导出配置（持久化）
  ModelRouteConfig exportConfig() => _config;

  // ─── 2. 路由解析 ───

  /// 解析指定槽位应使用的 endpoint
  ///
  /// 如果槽位未配置或配置的 endpoint 不可用，降级为默认。
  RouteResolution resolve(RouteSlot slot) {
    final configured = _config.getEndpointId(slot);

    if (configured.isNotEmpty) {
      // 检查是否在可用列表中（如果列表非空）
      if (availableEndpoints.isEmpty ||
          availableEndpoints.contains(configured)) {
        return RouteResolution(
          slot: slot,
          endpointId: configured,
          isFallback: false,
        );
      }
    }

    // 降级为默认
    return RouteResolution(
      slot: slot,
      endpointId: defaultEndpointId,
      isFallback: true,
    );
  }

  /// 解析所有槽位
  Map<RouteSlot, RouteResolution> resolveAll() {
    return {
      for (final slot in RouteSlot.values) slot: resolve(slot),
    };
  }

  /// 获取指定任务类型应使用的 provider ID
  String getProviderForTask(RouteSlot slot) {
    return resolve(slot).endpointId;
  }

  // ─── 3. 成本优化建议 ───

  /// 获取成本优化建议
  String getCostOptimizationHint() {
    final planning = resolve(RouteSlot.planning);
    final writing = resolve(RouteSlot.writing);

    if (planning.endpointId == writing.endpointId) {
      return '提示：规划和正文使用相同模型。'
          '建议规划用低成本模型（如 DeepSeek），正文用高质量模型以优化成本。';
    }
    return '';
  }

  /// 获取路由状态摘要（UI 展示）
  String getRouteSummary() {
    final parts = <String>[];
    for (final slot in RouteSlot.values) {
      final resolution = resolve(slot);
      final label = resolution.isFallback
          ? '${slot.label}: 默认'
          : '${slot.label}: ${resolution.endpointId}';
      parts.add(label);
    }
    return parts.join(' | ');
  }
}
