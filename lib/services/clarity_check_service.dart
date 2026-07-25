/// AI 请求清晰度检查结果
class ClarityCheckResult {
  const ClarityCheckResult({
    this.needsClarification = false,
    this.question = '',
    this.quickOptions = const [],
  });

  /// 是否需要追问
  final bool needsClarification;

  /// 追问问题
  final String question;

  /// 快速选项（可选）
  final List<String> quickOptions;

  /// 无需追问，直接通过
  static const pass = ClarityCheckResult();
}

/// 模糊请求规则引擎 — 客户端关键词匹配
///
/// 设计原则：宁可漏判（pass 给 AI）也不过度拦截。
/// - 输入长度 > 50 字符视为足够具体，直接 pass
/// - 仅匹配高频模糊模式，不做语义分析
class ClarityCheckService {
  /// 预编译规则列表（static final，避免每次重新编译）
  static final List<_ClarityRule> _rules = [
    _ClarityRule(
      pattern: RegExp(r'(帮我写|写一段|帮我创作)'),
      question: '想写什么内容？可以告诉我主题、大致长度和风格偏好。',
      options: const ['短篇片段', '完整章节', '对话场景', '直接生成'],
    ),
    _ClarityRule(
      pattern: RegExp(r'(续写|继续写|接着写)'),
      question: '续写方向和长度？',
      options: const ['顺着当前情节', '引入转折', '500字左右', '直接生成'],
    ),
    _ClarityRule(
      pattern: RegExp(r'(改一下|修改|润色|优化)'),
      question: '想怎么改？',
      options: const ['更文学', '更口语', '更紧凑', '直接生成'],
    ),
    _ClarityRule(
      pattern: RegExp(r'(扩写|展开|详细写)'),
      question: '展开哪个方面？目标长度？',
      options: const ['角色心理', '环境描写', '对话细节', '直接生成'],
    ),
  ];

  /// 评估用户输入是否足够清晰
  ///
  /// 返回 [ClarityCheckResult]，如果 `needsClarification` 为 true，
  /// 则应向用户展示追问卡片。
  ClarityCheckResult assess(String userInput) {
    final trimmed = userInput.trim();
    // 如果输入已经足够具体（超过一定长度），跳过检查
    if (trimmed.length > 50) return ClarityCheckResult.pass;

    for (final rule in _rules) {
      if (rule.pattern.hasMatch(trimmed)) {
        return ClarityCheckResult(
          needsClarification: true,
          question: rule.question,
          quickOptions: rule.options,
        );
      }
    }
    return ClarityCheckResult.pass;
  }
}

/// 内部规则定义
class _ClarityRule {
  const _ClarityRule({
    required this.pattern,
    required this.question,
    this.options = const [],
  });

  /// 匹配模式（正则表达式）
  final RegExp pattern;

  /// 追问问题
  final String question;

  /// 快速选项
  final List<String> options;
}
