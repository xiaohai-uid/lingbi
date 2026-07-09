/// LLM 请求/响应数据模型
library llm_models;

/// LLM 请求参数
class LLMRequest {
  const LLMRequest({
    required this.messages,
    this.systemPrompt,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.presencePenalty,
    this.frequencyPenalty,
    this.stop,
    this.responseSchema,
  });

  /// 消息列表
  final List<LLMMessage> messages;

  /// 系统提示（可选，与 messages 中 system 角色不冲突）
  final String? systemPrompt;

  /// 生成温度 (0.0 - 2.0)
  final double? temperature;

  /// 最大输出 token 数
  final int? maxTokens;

  /// Top-P 采样
  final double? topP;

  /// 存在惩罚 (-2.0 - 2.0)
  final double? presencePenalty;

  /// 频率惩罚 (-2.0 - 2.0)
  final double? frequencyPenalty;

  /// 停止序列
  final List<String>? stop;

  /// 期望的响应 JSON Schema（结构化输出）
  final Map<String, dynamic>? responseSchema;

  /// 转换为 JSON map（用于 API 调用）
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (temperature != null) map['temperature'] = temperature;
    if (maxTokens != null) map['max_tokens'] = maxTokens;
    if (topP != null) map['top_p'] = topP;
    if (presencePenalty != null) map['presence_penalty'] = presencePenalty;
    if (frequencyPenalty != null) map['frequency_penalty'] = frequencyPenalty;
    if (stop != null) map['stop'] = stop;
    return map;
  }
}

/// LLM 响应
class LLMResponse {
  const LLMResponse({
    required this.content,
    this.usage,
    this.finishReason,
  });

  /// 生成的文本内容
  final String content;

  /// Token 使用统计
  final TokenUsage? usage;

  /// 结束原因（'stop', 'length', 'error' 等）
  final String? finishReason;
}

/// Token 使用统计
class TokenUsage {
  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    int? totalTokens,
  }) : totalTokens = totalTokens ?? (promptTokens + completionTokens);
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
}

/// 聊天消息
class LLMMessage {
  const LLMMessage({required this.role, required this.content});

  factory LLMMessage.fromJson(Map<String, dynamic> json) {
    return LLMMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }
  final String role; // 'user', 'assistant', 'system'
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
