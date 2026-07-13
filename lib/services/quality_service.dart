/// 质量审查服务(本地启发式,无需 LLM / 后端)
///
/// 从章节正文计算四个维度评分(0-10):情节密度 / 人物深度 / 节奏控制 / 钩子密度。
/// 纯本地、确定性、无网络依赖,与项目本地优先架构一致。
library quality_service;

import 'dart:math';

import 'package:lingbi/core/models/quality_report.dart';

class QualityService {
  const QualityService();

  /// 分析正文质量。
  /// [characterNames] 可选,传入已知角色名可提升「人物深度」准确度。
  QualityReport analyze(String text, {List<String> characterNames = const []}) {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const QualityReport(dimensions: [
        QualityDimension(label: '情节密度', score: 0),
        QualityDimension(label: '人物深度', score: 0),
        QualityDimension(label: '节奏控制', score: 0),
        QualityDimension(label: '钩子密度', score: 0),
      ]);
    }

    final charCount = clean.length;
    final sentences = _splitSentences(clean);
    final sentenceCount = sentences.length;
    final dialogueChars = _countDialogueChars(clean);
    final dialogueRatio = dialogueChars / charCount;

    // 钩子密度:悬念类关键词每千字频次
    final hookHits = _countHooks(clean);
    final hooksPer1k = hookHits / charCount * 1000;
    final hookScore = _clamp01to10(hooksPer1k / 6);

    // 人物深度:对话占比 + 已知角色提及多样度
    final dialogueScore = _clamp01to10(dialogueRatio / 0.4);
    double varietyScore = 0;
    if (characterNames.isNotEmpty) {
      final mentioned = characterNames
          .where((n) => n.isNotEmpty && clean.contains(n))
          .length;
      varietyScore = _clamp01to10(mentioned / characterNames.length / 0.6);
    }
    final depthScore = characterNames.isEmpty
        ? dialogueScore
        : dialogueScore * 0.5 + varietyScore * 0.5;

    // 情节密度:每千字句数(事件密度)
    final sentencesPer1k = sentenceCount / charCount * 1000;
    final plotScore = _clamp01to10(sentencesPer1k / 25);

    // 节奏控制:句长变异系数
    final pacingScore = _pacingScore(sentences.map((s) => s.length).toList());

    final dimensions = [
      QualityDimension(label: '情节密度', score: plotScore),
      QualityDimension(label: '人物深度', score: depthScore),
      QualityDimension(label: '节奏控制', score: pacingScore),
      QualityDimension(label: '钩子密度', score: hookScore),
    ];
    return QualityReport(dimensions: dimensions, suggestions: _suggest(dimensions));
  }

  List<String> _splitSentences(String text) => text
      .split(RegExp(r'[\n。！？!?…]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  int _countDialogueChars(String text) {
    var total = 0;
    for (final m in RegExp(r'「[^」]*」|“[^”]*”|『[^』]*』')
        .allMatches(text)) {
      total += m.group(0)!.length - 2;
    }
    return total < 0 ? 0 : total;
  }

  int _countHooks(String text) {
    final pattern = RegExp(
      '悬念|转折|危机|秘密|反转|伏笔|谜|背叛|死亡|觉醒|陷阱|意外|真相|阴谋|突变|惊变|逆袭|重逢|诀别',
    );
    return pattern.allMatches(text).length;
  }

  double _pacingScore(List<int> lengths) {
    if (lengths.isEmpty) return 0;
    final mean = lengths.reduce((a, b) => a + b) / lengths.length;
    if (mean == 0) return 0;
    final variance = lengths
            .map((l) => (l - mean) * (l - mean))
            .reduce((a, b) => a + b) /
        lengths.length;
    final std = variance <= 0 ? 0.0 : sqrt(variance);
    // 变异系数,理想区间约 0.4-0.8,峰值 0.6
    final ratio = std / mean;
    return _clamp01to10(1 - (ratio - 0.6).abs() / 0.6);
  }

  double _clamp01to10(double x) => x.clamp(0, 1) * 10;

  List<String> _suggest(List<QualityDimension> dims) {
    final out = <String>[];
    for (final d in dims) {
      if (d.score >= 5) continue;
      switch (d.label) {
        case '情节密度':
          out.add('💡 增加情节推进,减少静态描写');
        case '人物深度':
          out.add('✍ 增加对话与角色互动,丰富人物刻画');
        case '节奏控制':
          out.add('📊 调整段落长短,改善叙事节奏');
        case '钩子密度':
          out.add('🪝 增加悬念钩子(转折/危机/秘密)提升吸引力');
      }
    }
    return out;
  }
}
