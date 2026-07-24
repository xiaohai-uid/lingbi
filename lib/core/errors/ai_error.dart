import 'app_error.dart';

/// AI 服务细化错误层次
///
/// 每种错误类型对应用户可理解的提示信息和恢复建议。
sealed class AIServiceError extends AppError {
  AIServiceError(
    super.message, {
    super.code,
    super.cause,
    required this.userHint,
    required this.recoveryAction,
  });

  /// 面向用户的可理解提示
  final String userHint;

  /// 建议的恢复操作
  final RecoveryAction recoveryAction;
}

/// 恢复操作类型
enum RecoveryAction {
  /// 检查并重新输入 API Key
  checkApiKey,

  /// 等待一段时间后重试
  retryLater,

  /// 检查网络连接后重试
  checkNetwork,

  /// 重试当前请求
  retry,

  /// 切换模型或供应商
  switchProvider,

  /// 检查磁盘空间或权限
  checkStorage,

  /// 无法自动恢复，需用户介入
  manualIntervention,
}

/// API Key 无效或认证失败 (HTTP 401/403)
class AIAuthError extends AIServiceError {
  AIAuthError({
    String message = 'API Key 无效或已过期',
    super.cause,
    String provider = '',
  })  : _provider = provider,
        super(
          message,
          code: 'AI_AUTH',
          userHint: provider.isEmpty
              ? 'API Key 无效，请检查是否复制完整，或重新生成密钥。'
              : '$provider 的 API Key 无效，请在设置中检查该密钥是否完整有效。',
          recoveryAction: RecoveryAction.checkApiKey,
        );

  final String _provider;
  String get provider => _provider;
}

/// 请求限流 (HTTP 429)
class AIRateLimitError extends AIServiceError {
  AIRateLimitError({
    String message = '请求过于频繁',
    super.cause,
    this.retryAfterSeconds,
  }) : super(
          message,
          code: 'AI_RATE_LIMIT',
          userHint: retryAfterSeconds != null
              ? '请求过于频繁，请等待 $retryAfterSeconds 秒后重试。已生成的内容已保留。'
              : '请求过于频繁，请稍后重试。已生成的内容已保留。',
          recoveryAction: RecoveryAction.retryLater,
        );

  /// 服务端建议的等待秒数（可能为 null）
  final int? retryAfterSeconds;
}

/// 网络连接错误（DNS 失败、超时、连接拒绝等）
class AINetworkError extends AIServiceError {
  AINetworkError({
    String message = '网络连接失败',
    super.cause,
  }) : super(
          message,
          code: 'AI_NETWORK',
          userHint: '网络连接中断，请检查网络后重试。已生成的内容已保留。',
          recoveryAction: RecoveryAction.checkNetwork,
        );
}

/// 模型返回错误（空内容、非法 JSON、服务端 500 等）
class AIModelError extends AIServiceError {
  AIModelError({
    String message = '模型返回异常',
    super.cause,
    this.httpStatus,
  }) : super(
          message,
          code: 'AI_MODEL',
          userHint: httpStatus != null && httpStatus >= 500
              ? 'AI 服务暂时不可用（服务器错误），请稍后重试。'
              : '模型返回了无法处理的内容，请重试或切换模型。',
          recoveryAction: httpStatus != null && httpStatus >= 500
              ? RecoveryAction.retryLater
              : RecoveryAction.switchProvider,
        );

  /// HTTP 状态码（如果有）
  final int? httpStatus;
}

/// 本地存储错误（磁盘只读、空间不足、文件损坏）
class AIStorageError extends AIServiceError {
  AIStorageError({
    String message = '本地存储异常',
    super.cause,
    this.isDiskFull = false,
    this.isReadOnly = false,
  }) : super(
          message,
          code: 'AI_STORAGE',
          userHint: isDiskFull
              ? '磁盘空间不足，无法保存生成结果。请清理磁盘后重试。'
              : isReadOnly
                  ? '磁盘为只读状态，无法保存数据。请检查文件权限。'
                  : '本地数据文件异常，请尝试重启应用。',
          recoveryAction: RecoveryAction.checkStorage,
        );

  final bool isDiskFull;
  final bool isReadOnly;
}

/// 用户主动取消生成
class AICancelledError extends AIServiceError {
  AICancelledError({
    String message = '生成已取消',
  }) : super(
          message,
          code: 'AI_CANCELLED',
          userHint: '已停止生成，之前输出的内容已保留。',
          recoveryAction: RecoveryAction.retry,
        );
}

/// 配额用尽
class AIQuotaError extends AIServiceError {
  AIQuotaError({
    String message = '免费额度已用完',
    super.cause,
    required int dailyLimit,
  }) : super(
          message,
          code: 'AI_QUOTA',
          userHint:
              '今日免费额度已用完（$dailyLimit 次/天）。请配置自己的 API Key 或明天再试。',
          recoveryAction: RecoveryAction.checkApiKey,
        );
}

/// AiErrorMapper — 将任意异常映射为用户可理解的错误信息
///
/// 所有错误必须：
/// - 使用用户可理解的中文
/// - 说明已生成内容是否保留
/// - 提供可执行的下一步
/// - 在允许时提供重试
class AiErrorMapper {
  const AiErrorMapper._();

  /// 将任意异常转换为对应的 AIServiceError
  static AIServiceError map(Object error, {String provider = ''}) {
    if (error is AIServiceError) return error;

    final msg = error.toString().toLowerCase();

    // HTTP 状态码检测
    if (msg.contains('401') || msg.contains('403') || msg.contains('unauthorized') || msg.contains('invalid api key')) {
      return AIAuthError(provider: provider, cause: error);
    }
    if (msg.contains('429') || msg.contains('rate limit') || msg.contains('too many requests')) {
      final match = RegExp(r'retry.?after[:\s]*(\d+)').firstMatch(msg);
      final seconds = match != null ? int.tryParse(match.group(1) ?? '') : null;
      return AIRateLimitError(retryAfterSeconds: seconds, cause: error);
    }
    if (msg.contains('500') || msg.contains('502') || msg.contains('503') || msg.contains('internal server error')) {
      return AIModelError(httpStatus: 500, cause: error);
    }

    // 网络错误检测
    if (msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('dns') ||
        msg.contains('handshake')) {
      return AINetworkError(cause: error);
    }

    // 存储错误检测
    if (msg.contains('no space') || msg.contains('disk full') || msg.contains('enospc')) {
      return AIStorageError(isDiskFull: true, cause: error);
    }
    if (msg.contains('read-only') || msg.contains('readonly') || msg.contains('eperm') || msg.contains('access denied')) {
      return AIStorageError(isReadOnly: true, cause: error);
    }

    // 默认归为模型错误
    return AIModelError(message: '未知错误: $error', cause: error);
  }

  /// 构建用户可见的错误消息（含数据保留说明和下一步）
  static UserFacingError toUserFacing(AIServiceError error) {
    return UserFacingError(
      title: _titleFor(error),
      message: error.userHint,
      dataRetained: _dataRetainedFor(error),
      nextStep: _nextStepFor(error),
      canRetry: error.recoveryAction == RecoveryAction.retry ||
          error.recoveryAction == RecoveryAction.retryLater ||
          error.recoveryAction == RecoveryAction.checkNetwork,
      recoveryAction: error.recoveryAction,
    );
  }

  static String _titleFor(AIServiceError error) {
    return switch (error) {
      AIAuthError() => 'API Key 无效',
      AIRateLimitError() => '请求过于频繁',
      AINetworkError() => '网络连接中断',
      AIModelError() => 'AI 服务异常',
      AIStorageError() => '本地存储异常',
      AICancelledError() => '生成已停止',
      AIQuotaError() => '免费额度已用完',
    };
  }

  static bool _dataRetainedFor(AIServiceError error) {
    // 除存储错误外，已生成的内容均保留
    return error is! AIStorageError;
  }

  static String _nextStepFor(AIServiceError error) {
    return switch (error.recoveryAction) {
      RecoveryAction.checkApiKey => '请前往设置页检查 API Key 是否正确',
      RecoveryAction.retryLater => '请稍后重试',
      RecoveryAction.checkNetwork => '请检查网络连接后重试',
      RecoveryAction.retry => '点击重试按钮重新生成',
      RecoveryAction.switchProvider => '请尝试切换其他模型或供应商',
      RecoveryAction.checkStorage => '请检查磁盘空间和文件权限',
      RecoveryAction.manualIntervention => '请重启应用，若问题持续请反馈',
    };
  }
}

/// 用户可见的错误信息结构
class UserFacingError {
  const UserFacingError({
    required this.title,
    required this.message,
    required this.dataRetained,
    required this.nextStep,
    required this.canRetry,
    required this.recoveryAction,
  });

  /// 错误标题
  final String title;

  /// 详细说明
  final String message;

  /// 已生成内容是否保留
  final bool dataRetained;

  /// 建议的下一步
  final String nextStep;

  /// 是否可重试
  final bool canRetry;

  /// 恢复操作类型
  final RecoveryAction recoveryAction;

  /// 数据保留说明文本
  String get dataRetentionNote =>
      dataRetained ? '已生成的内容已保留，不会丢失。' : '部分数据可能未保存。';
}
