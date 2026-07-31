/// 多候选生成服务 — 复刻 OpenWrite 的"抽卡模式"。
///
/// 并发调用 AI 生成 N 个版本，用户从中选最佳。
library;

import 'package:lingbi/shared/ai/ai_provider.dart';

class GachaCandidate {
  const GachaCandidate({
    required this.index,
    required this.content,
    required this.charCount,
  });

  final int index;
  final String content;
  final int charCount;
}

class MultiCandidateService {
  /// 并发生成 [count] 个候选版本。
  ///
  /// [provider] AI 提供者
  /// [systemPrompt] 系统提示
  /// [userPrompt] 用户指令
  /// [count] 并发数（默认 3）
  static Future<List<GachaCandidate>> generate({
    required AIProvider provider,
    required String systemPrompt,
    required String userPrompt,
    int count = 3,
    double temperature = 0.9,
    int maxTokens = 4096,
  }) async {
    final futures = List.generate(count, (i) async {
      try {
        final text = await provider.chatSync(
          messages: [
            ChatMessage(role: 'system', content: systemPrompt),
            ChatMessage(role: 'user', content: userPrompt),
          ],
          temperature: temperature + (i * 0.1), // 每个候选温度微增，增加多样性
          maxTokens: maxTokens,
        );
        return GachaCandidate(
          index: i + 1,
          content: text,
          charCount: text.length,
        );
      } catch (_) {
        return GachaCandidate(index: i + 1, content: '生成失败', charCount: 0);
      }
    });
    return Future.wait(futures);
  }
}
