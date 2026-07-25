/// AI 参数校验工具
///
/// 发送前自动校验温度和最大 Token 参数合法性，越界即时提示。
/// 发送前自动清理异常字符，防止特殊字符导致请求被拒。
class AiParamValidator {
  /// 温度范围
  static const double minTemperature = 0.0;
  static const double maxTemperature = 2.0;

  /// 最大 Token 范围
  static const int minMaxTokens = 1;
  static const int maxMaxTokens = 128000;

  /// 校验温度参数
  static String? validateTemperature(double temperature) {
    if (temperature < minTemperature || temperature > maxTemperature) {
      return '温度值必须在 $minTemperature ~ $maxTemperature 之间';
    }
    return null;
  }

  /// 校验最大 Token 参数
  static String? validateMaxTokens(int maxTokens) {
    if (maxTokens < minMaxTokens) {
      return '最大 Token 数不能少于 $minMaxTokens';
    }
    if (maxTokens > maxMaxTokens) {
      return '最大 Token 数不能超过 $maxMaxTokens';
    }
    return null;
  }

  /// 清理异常字符（控制字符）
  ///
  /// 保留 \n, \r, \t, 去除其他控制字符。
  static String sanitizeText(String text) {
    return text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }
}
