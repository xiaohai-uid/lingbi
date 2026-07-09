import 'dart:convert';

/// JSON Schema 处理器
///
/// 从 LLM 响应文本中提取 JSON 块（支持 ```json 代码块），
/// 并解析为目标类型。
class SchemaProcessor {
  /// 从文本中提取第一个 JSON 代码块
  ///
  /// 支持格式：
  /// - ```json {...} ```
  /// - ``` {...} ```
  /// - 纯 JSON 文本 {...}
  Map<String, dynamic>? extractJsonBlock(String text) {
    // 尝试匹配 ```json 或 ``` 代码块
    final codeBlockRE = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final codeMatch = codeBlockRE.firstMatch(text);
    if (codeMatch != null) {
      try {
        return jsonDecode(codeMatch.group(1)!.trim()) as Map<String, dynamic>;
      } catch (_) {}
    }

    // 尝试解析纯 JSON（无代码块包裹）
    try {
      final firstBrace = text.indexOf('{');
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace > firstBrace) {
        return jsonDecode(text.substring(firstBrace, lastBrace + 1))
            as Map<String, dynamic>;
      }
    } catch (_) {}

    return null;
  }

  /// 从文本中提取并解析结构化数据
  ///
  /// [fromJson] 将 JSON Map 转换为目标类型 [T]。
  /// 如果无法提取 JSON 则返回 null。
  T? extractStructured<T>(
    String text,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final json = extractJsonBlock(text);
    if (json == null) return null;
    try {
      return fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 提取文本中所有 JSON 代码块
  List<Map<String, dynamic>> extractAllJsonBlocks(String text) {
    final results = <Map<String, dynamic>>[];
    final codeBlockRE = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    for (final match in codeBlockRE.allMatches(text)) {
      try {
        final json = jsonDecode(match.group(1)!.trim()) as Map<String, dynamic>;
        results.add(json);
      } catch (_) {}
    }
    return results;
  }
}
