/// 身份规则库 — 称呼→身份 映射规则
library identity_rules;

/// 一条身份识别规则
class IdentityRule {
  const IdentityRule({
    required this.pattern,
    required this.identityName,
    this.weight = 50,
    this.organizationId,
    this.isRegex = false,
  });

  /// 匹配模式（正则或关键词）
  final String pattern;

  /// 匹配到的身份名称
  final String identityName;

  /// 该身份默认权重
  final int weight;

  /// 所属组织（可选）
  final String? organizationId;

  /// 是否为正则表达式
  final bool isRegex;
}

/// 身份候选（匹配结果）
class IdentityCandidate {
  const IdentityCandidate({
    required this.characterId,
    required this.identityName,
    required this.confidence,
    required this.source,
    this.suggestedWeight = 50,
  });
  final String characterId;
  final String identityName;
  final double confidence; // 0.0 - 1.0
  final String source; // "rule:称呼" / "rule:组织" / "llm"
  final int suggestedWeight;
}

/// 规则集 — 管理默认规则 + 用户自定义规则
class IdentityRuleSet {
  IdentityRuleSet() {
    _rules.addAll(defaultRules);
  }
  final List<IdentityRule> _rules = [];

  /// 添加用户自定义规则
  void addRule(IdentityRule rule) {
    // 避免重复
    _rules.removeWhere((r) =>
        r.pattern == rule.pattern && r.identityName == rule.identityName);
    _rules.add(rule);
  }

  /// 获取所有规则
  List<IdentityRule> get rules => List.unmodifiable(_rules);

  /// 默认规则库 — 常见网文/剧本称呼
  static const List<IdentityRule> defaultRules = [
    // 宗门/门派身份
    IdentityRule(
        pattern: '掌门',
        identityName: '掌门/宗主',
        weight: 85,
        organizationId: 'sect'),
    IdentityRule(
        pattern: '长老', identityName: '长老', weight: 75, organizationId: 'sect'),
    IdentityRule(
        pattern: '师尊',
        identityName: '师父/师尊',
        weight: 80,
        organizationId: 'sect'),
    IdentityRule(
        pattern: '师父', identityName: '师父', weight: 75, organizationId: 'sect'),
    IdentityRule(pattern: '徒儿', identityName: '弟子', organizationId: 'sect'),
    IdentityRule(
        pattern: '弟子', identityName: '弟子', weight: 40, organizationId: 'sect'),
    IdentityRule(
        pattern: '大师兄',
        identityName: '大师兄',
        weight: 60,
        organizationId: 'sect'),
    IdentityRule(
        pattern: '大师姐',
        identityName: '大师姐',
        weight: 60,
        organizationId: 'sect'),
    IdentityRule(
        pattern: '师兄', identityName: '师兄', weight: 40, organizationId: 'sect'),
    IdentityRule(
        pattern: '师姐', identityName: '师姐', weight: 40, organizationId: 'sect'),
    IdentityRule(
        pattern: '师弟', identityName: '师弟', weight: 30, organizationId: 'sect'),
    IdentityRule(
        pattern: '师妹', identityName: '师妹', weight: 30, organizationId: 'sect'),

    // 家族身份
    IdentityRule(
        pattern: '家主',
        identityName: '家主/族长',
        weight: 80,
        organizationId: 'clan'),
    IdentityRule(
        pattern: '族长', identityName: '族长', weight: 80, organizationId: 'clan'),
    IdentityRule(
        pattern: '少主', identityName: '少主', weight: 70, organizationId: 'clan'),
    IdentityRule(pattern: '少爷', identityName: '少爷', organizationId: 'clan'),
    IdentityRule(pattern: '小姐', identityName: '小姐', organizationId: 'clan'),
    IdentityRule(pattern: '公子', identityName: '公子', organizationId: 'clan'),

    // 修仙/玄幻身份
    IdentityRule(pattern: '道友', identityName: '道友/同修', weight: 30),
    IdentityRule(pattern: '前辈', identityName: '前辈', weight: 60),
    IdentityRule(pattern: '老祖', identityName: '老祖', weight: 90),
    IdentityRule(pattern: '大能', identityName: '大能/强者', weight: 85),
    IdentityRule(pattern: '散修', identityName: '散修', weight: 40),

    // 官场/朝廷身份
    IdentityRule(
        pattern: '陛下',
        identityName: '皇帝/君王',
        weight: 95,
        organizationId: 'court'),
    IdentityRule(
        pattern: '皇上', identityName: '皇帝', weight: 95, organizationId: 'court'),
    IdentityRule(
        pattern: '王爷', identityName: '王爷', weight: 80, organizationId: 'court'),
    IdentityRule(
        pattern: '丞相', identityName: '丞相', weight: 85, organizationId: 'court'),
    IdentityRule(
        pattern: '将军',
        identityName: '将军',
        weight: 75,
        organizationId: 'military'),

    // 关系身份
    IdentityRule(pattern: '道侣', identityName: '道侣/伴侣', weight: 85),
    IdentityRule(pattern: '夫君', identityName: '夫君/丈夫', weight: 80),
    IdentityRule(pattern: '娘子', identityName: '娘子/妻子', weight: 80),
    IdentityRule(
        pattern: '爱妃',
        identityName: '爱妃/妃子',
        weight: 70,
        organizationId: 'court'),
  ];
}
