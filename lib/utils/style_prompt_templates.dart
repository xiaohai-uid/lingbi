/// 文风检测 — LLM Prompt 模板
library;

/// 风格分析 Prompt — 分析文本生成结构化 StyleProfile
String styleAnalysisPrompt(String text) {
  return '''
你是一个专业的文学风格分析专家。
分析以下文本的写作风格，输出 JSON 格式的结构化分析结果。

输出格式：
{
  "summary": "一句话风格概述（如：古典仙侠风格，文笔细腻）",
  "tone": "严肃/轻松/幽默/沉重/悬疑/温馨/悲壮",
  "vocabularyLevel": "通俗/文学/古风/口语/诗化",
  "dialogueRatio": 0.0-1.0之间的数字（对话字数/总字数估算），
  "sentenceComplexity": 0.0-1.0之间的数字（0=简单短句，1=复杂长句），
  "pacing": "紧凑/舒缓/张弛有度/急促",
  "rhetoricalDevices": ["常用的修辞手法，如比喻、排比、对仗、夸张等"],
  "paragraphLength": 0.0-1.0之间的数字（0=段落很短，1=段落很长），
  "keywords": ["风格关键词，如：细腻、豪放、冷峻、华丽等"]
}

注意：
1. 所有数值字段必须精确，基于文本实际统计
2. dialogueRatio 根据对话文本占比估算
3. 只输出 JSON，不要包含其他内容

文本：
$text
''';
}

/// 风格漂移检测 Prompt
String styleDriftPrompt(String textA, String textB) {
  return '''
你是一个专业的文学风格一致性检测专家。
比较以下两段文本的风格差异，输出 JSON 格式的分析结果。

输出格式：
{
  "driftScore": 0.0-1.0之间的数字（0=风格完全一致，1=风格完全不同），
  "driftedDimensions": ["发生漂移的维度，如 tone、vocabularyLevel、dialogueRatio 等"],
  "details": "具体描述风格差异在哪里",
  "suggestions": "如何修正风格漂移的建议"
}

注意：
1. driftScore 基于实际风格差异计算
2. driftedDimensions 列出具体发生变化的方面
3. 只输出 JSON，不要包含其他内容

文本A：
$textA

文本B：
$textB
''';
}
