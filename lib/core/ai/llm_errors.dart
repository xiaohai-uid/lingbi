/// LLM 异常层次定义
///
/// 所有与 LLM 相关的异常继承自 [LLMException] sealed class，
/// 通过模式匹配 (switch + when) 进行精细化错误处理。
library llm_errors;

/// LLM 异常基类 — sealed 确保穷尽匹配
sealed class LLMException implements Exception {
  const LLMException({required this.message, required this.provider});
  final String message;
  final String provider;

  @override
  String toString() => '[$provider] $message';
}

/// 认证失败（API Key 无效/过期）
class LLMAuthException extends LLMException {
  const LLMAuthException({required super.message, required super.provider});
}

/// 速率限制（请求过频繁）
class LLMRateLimitException extends LLMException {
  const LLMRateLimitException({
    required super.message,
    required super.provider,
    this.retryAfterSeconds,
  });
  final int? retryAfterSeconds;
}

/// 请求超时
class LLMTimeoutException extends LLMException {
  const LLMTimeoutException({
    required super.message,
    required super.provider,
    this.timeoutSeconds,
  });
  final int? timeoutSeconds;
}

/// 响应错误（非预期的状态码或格式）
class LLMResponseException extends LLMException {
  const LLMResponseException({
    required super.message,
    required super.provider,
    this.statusCode,
  });
  final int? statusCode;
}

/// 配置错误（缺少 API Key 等）
class LLMConfigurationException extends LLMException {
  const LLMConfigurationException({
    required super.message,
    required super.provider,
    this.missingField,
  });
  final String? missingField;
}
