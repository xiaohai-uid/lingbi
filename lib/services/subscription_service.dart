/// SubscriptionService — 订阅层管理 + 功能门禁
///
/// 管理灵笔的 Free/Pro 分层：
/// - Free 层：本地编辑 + 自带 API Key + 基础 Skill + 基础导出
/// - Pro 层：云同步 + 高级导出（Word/PDF 模板）+ 批量操作 + 官方模型套餐
///
/// 设计原则：
/// - 离线优先：许可证验证不依赖网络
/// - 优雅降级：Pro 过期后回退 Free，不阻断基础功能
/// - 门禁粒度：按功能枚举控制，UI 层通过 canAccess() 判断
library;

/// 订阅层级
enum SubscriptionTier { free, pro }

/// Pro 功能枚举 — 用于门禁检查
enum ProFeature {
  /// 本地编辑（Free 可用）
  localEditing,

  /// 基础 Skill（Free 可用）
  basicSkills,

  /// 基础导出 Markdown/TXT（Free 可用）
  basicExport,

  /// 自带 API Key（Free 可用）
  byoApiKey,

  /// 云同步（Pro）
  cloudSync,

  /// 高级导出 Word/PDF 模板（Pro）
  advancedExport,

  /// 批量操作（Pro）
  batchOperations,

  /// 官方模型套餐（Pro）
  officialModelPlan,
}

/// Free 层可用的功能集合
const _freeFeatures = {
  ProFeature.localEditing,
  ProFeature.basicSkills,
  ProFeature.basicExport,
  ProFeature.byoApiKey,
};

/// 订阅状态
class SubscriptionState {
  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.expiresAt,
    this.licenseKey = '',
  });

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    return SubscriptionState(
      tier: json['tier'] == 'pro' ? SubscriptionTier.pro : SubscriptionTier.free,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      licenseKey: json['licenseKey'] as String? ?? '',
    );
  }

  final SubscriptionTier tier;
  final DateTime? expiresAt;
  final String licenseKey;

  bool get isPro => tier == SubscriptionTier.pro;

  /// 订阅是否活跃（Free 永远活跃；Pro 需未过期）
  bool get isActive {
    if (!isPro) return true;
    if (expiresAt == null) return false;
    return expiresAt!.isAfter(DateTime.now());
  }

  /// 功能门禁检查
  bool canAccess(ProFeature feature) {
    if (_freeFeatures.contains(feature)) return true;
    return isPro && isActive;
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        'licenseKey': licenseKey,
      };
}

/// 订阅服务
///
/// 管理当前订阅状态，提供功能门禁查询。
/// 由 ServiceLocator 持有，UI 层通过 ServiceLocator.instance.subscriptionService 访问。
class SubscriptionService {
  SubscriptionService();

  /// Free 层每日 AI 调用限额
  static const int freeDailyLimit = 100;

  SubscriptionState _state = const SubscriptionState();

  /// 当前订阅状态
  SubscriptionState get state => _state;

  /// 是否为 Pro 用户（且活跃）
  bool get isPro => _state.isPro && _state.isActive;

  /// 每日限额（Pro 无限制返回 -1）
  int get dailyLimit => isPro ? -1 : freeDailyLimit;

  /// 功能门禁检查
  bool canAccess(ProFeature feature) => _state.canAccess(feature);

  /// 激活 Pro
  void activatePro({
    required String licenseKey,
    required DateTime expiresAt,
  }) {
    _state = SubscriptionState(
      tier: SubscriptionTier.pro,
      licenseKey: licenseKey,
      expiresAt: expiresAt,
    );
  }

  /// 从持久化状态恢复
  void restore(SubscriptionState state) {
    _state = state;
  }

  /// 降级回 Free（取消订阅/过期）
  void deactivate() {
    _state = const SubscriptionState();
  }
}

/// 模型套餐 — 灵笔代理的 AI 模型包
class ModelPlan {
  const ModelPlan({
    required this.id,
    required this.name,
    required this.provider,
    required this.pricePerMonth,
    required this.includedTokens,
    required this.models,
  });

  factory ModelPlan.fromJson(Map<String, dynamic> json) {
    return ModelPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      pricePerMonth: (json['pricePerMonth'] as num?)?.toDouble() ?? 0,
      includedTokens: json['includedTokens'] as int? ?? 0,
      models: (json['models'] as List?)?.cast<String>() ?? [],
    );
  }

  final String id;
  final String name;
  final String provider;
  final double pricePerMonth;
  final int includedTokens;
  final List<String> models;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
        'pricePerMonth': pricePerMonth,
        'includedTokens': includedTokens,
        'models': models,
      };
}

/// 用量记录 — 套餐周期内的 token 消耗
class UsageRecord {
  const UsageRecord({
    required this.planId,
    required this.usedTokens,
    required this.periodStart,
    required this.periodEnd,
  });

  final String planId;
  final int usedTokens;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// 计算剩余额度
  int remainingTokens(ModelPlan plan) {
    final remaining = plan.includedTokens - usedTokens;
    return remaining > 0 ? remaining : 0;
  }
}
