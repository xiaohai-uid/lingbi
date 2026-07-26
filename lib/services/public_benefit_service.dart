/// 套餐/公益模型服务
///
/// 提供免费公益模型供新用户体验（能力偏低但零门槛）：
/// - 公益模型作为预置 EndpointConfig（protocol: openai, 指向公益端点）
/// - 新用户 Onboarding 时默认提供公益模型选项（无需 API Key）
/// - 配额限制：每日/每月调用次数上限，超限提示
/// - 性能提示：明确标注公益模型能力有限
/// - 用户配置自己的 API Key 后自动切换为默认
library;

// ─── 数据模型 ───

/// 公益模型配额
class BenefitQuota {
  const BenefitQuota({
    this.dailyLimit = 30,
    this.monthlyLimit = 500,
    this.dailyUsed = 0,
    this.monthlyUsed = 0,
    this.lastResetDay = '',
    this.lastResetMonth = '',
  });

  factory BenefitQuota.fromJson(Map<String, dynamic> json) {
    return BenefitQuota(
      dailyLimit: json['daily_limit'] as int? ?? 30,
      monthlyLimit: json['monthly_limit'] as int? ?? 500,
      dailyUsed: json['daily_used'] as int? ?? 0,
      monthlyUsed: json['monthly_used'] as int? ?? 0,
      lastResetDay: json['last_reset_day'] as String? ?? '',
      lastResetMonth: json['last_reset_month'] as String? ?? '',
    );
  }

  final int dailyLimit;
  final int monthlyLimit;
  final int dailyUsed;
  final int monthlyUsed;
  final String lastResetDay;
  final String lastResetMonth;

  int get dailyRemaining =>
      (dailyLimit - dailyUsed) > 0 ? (dailyLimit - dailyUsed) : 0;
  int get monthlyRemaining =>
      (monthlyLimit - monthlyUsed) > 0 ? (monthlyLimit - monthlyUsed) : 0;
  bool get isDailyExhausted => dailyUsed >= dailyLimit;
  bool get isMonthlyExhausted => monthlyUsed >= monthlyLimit;
  bool get isExhausted => isDailyExhausted || isMonthlyExhausted;

  BenefitQuota copyWith({
    int? dailyUsed,
    int? monthlyUsed,
    String? lastResetDay,
    String? lastResetMonth,
  }) {
    return BenefitQuota(
      dailyLimit: dailyLimit,
      monthlyLimit: monthlyLimit,
      dailyUsed: dailyUsed ?? this.dailyUsed,
      monthlyUsed: monthlyUsed ?? this.monthlyUsed,
      lastResetDay: lastResetDay ?? this.lastResetDay,
      lastResetMonth: lastResetMonth ?? this.lastResetMonth,
    );
  }

  Map<String, dynamic> toJson() => {
        'daily_limit': dailyLimit,
        'monthly_limit': monthlyLimit,
        'daily_used': dailyUsed,
        'monthly_used': monthlyUsed,
        'last_reset_day': lastResetDay,
        'last_reset_month': lastResetMonth,
      };
}

/// 公益模型信息
class BenefitModelInfo {
  const BenefitModelInfo({
    required this.id,
    required this.displayName,
    required this.endpoint,
    this.modelId = '',
    this.contextWindow = 4096,
    this.capabilityNote = '',
  });

  final String id;
  final String displayName;
  final String endpoint;
  final String modelId;
  final int contextWindow;

  /// 能力说明（UI 展示）
  final String capabilityNote;
}

// ─── 服务 ───

/// 公益模型服务
class PublicBenefitService {
  PublicBenefitService({
    List<BenefitModelInfo>? models,
  }) : _models = models ?? _defaultModels;

  final List<BenefitModelInfo> _models;
  BenefitQuota _quota = const BenefitQuota();

  /// 当前是否使用公益模型
  bool isUsingBenefitModel = true;

  /// 用户是否已配置自己的 API Key
  bool hasOwnApiKey = false;

  // ─── 1. 模型列表 ───

  /// 获取可用公益模型
  List<BenefitModelInfo> get availableModels => _models;

  /// 获取推荐公益模型（第一个）
  BenefitModelInfo? get recommendedModel =>
      _models.isNotEmpty ? _models.first : null;

  // ─── 2. 配额管理 ───

  /// 获取当前配额状态
  BenefitQuota get quota => _quota;

  /// 尝试消费一次配额
  ///
  /// 返回 null 表示成功，否则返回超限提示文本。
  String? tryConsume() {
    _checkReset();
    if (_quota.isDailyExhausted) {
      return '今日公益模型额度已用完（${_quota.dailyLimit}次/天）。'
          '建议配置自己的 API Key 获得无限制体验。';
    }
    if (_quota.isMonthlyExhausted) {
      return '本月公益模型额度已用完（${_quota.monthlyLimit}次/月）。'
          '建议配置自己的 API Key 获得无限制体验。';
    }
    _quota = _quota.copyWith(
      dailyUsed: _quota.dailyUsed + 1,
      monthlyUsed: _quota.monthlyUsed + 1,
    );
    return null;
  }

  /// 获取配额提示（UI 展示）
  String get quotaHint {
    if (_quota.isExhausted) {
      return '额度已用完，请配置 API Key';
    }
    if (_quota.dailyRemaining <= 5) {
      return '今日剩余 ${_quota.dailyRemaining} 次';
    }
    return '今日 ${_quota.dailyUsed}/${_quota.dailyLimit}';
  }

  /// 获取能力提示（UI 展示）
  String get capabilityHint {
    return '公益模型能力有限（上下文${_models.isNotEmpty ? _models.first.contextWindow ~/ 1024 : 4}K），'
        '建议配置自己的 API Key 获得最佳体验。';
  }

  // ─── 3. 自动切换 ───

  /// 通知用户已配置 API Key
  ///
  /// 返回是否应自动切换离开公益模型。
  bool notifyOwnApiKeyConfigured(String providerId) {
    hasOwnApiKey = true;
    if (isUsingBenefitModel) {
      isUsingBenefitModel = false;
      return true; // 建议切换
    }
    return false;
  }

  /// 切回公益模型（用户主动选择）
  void switchToBenefitModel() {
    isUsingBenefitModel = true;
  }

  /// 获取切换建议文本
  String get switchSuggestion {
    if (isUsingBenefitModel && hasOwnApiKey) {
      return '检测到您已配置 API Key，建议切换到自有模型获得更好体验。';
    }
    return '';
  }

  // ─── 4. 序列化 ───

  /// 加载配额状态
  void loadQuota(BenefitQuota quota) {
    _quota = quota;
    _checkReset();
  }

  /// 导出配额状态（持久化）
  BenefitQuota exportQuota() => _quota;

  // ─── 辅助 ───

  void _checkReset() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final thisMonth = '${now.year}-${now.month}';

    var needsUpdate = false;
    var dailyUsed = _quota.dailyUsed;
    var monthlyUsed = _quota.monthlyUsed;

    if (_quota.lastResetDay != today) {
      dailyUsed = 0;
      needsUpdate = true;
    }
    if (_quota.lastResetMonth != thisMonth) {
      monthlyUsed = 0;
      needsUpdate = true;
    }

    if (needsUpdate) {
      _quota = _quota.copyWith(
        dailyUsed: dailyUsed,
        monthlyUsed: monthlyUsed,
        lastResetDay: today,
        lastResetMonth: thisMonth,
      );
    }
  }

  /// 默认公益模型列表
  static const _defaultModels = [
    BenefitModelInfo(
      id: 'benefit_deepseek',
      displayName: '公益 DeepSeek (免费)',
      endpoint: 'https://benefit.lingbi.app/v1',
      modelId: 'deepseek-chat',
      capabilityNote: '基础对话能力，适合体验。长文生成质量有限。',
    ),
    BenefitModelInfo(
      id: 'benefit_qwen',
      displayName: '公益 Qwen (免费)',
      endpoint: 'https://benefit.lingbi.app/v1',
      modelId: 'qwen-turbo',
      capabilityNote: '轻量快速，适合短文本。复杂情节理解力有限。',
    ),
  ];
}
