/// 记忆系统 — LLM 摘要 Prompt 模板
///
/// 用于生成场景级、章级、卷级结构化摘要的 prompt 模板。
library;

/// 场景摘要 Prompt — 分析场景正文，输出结构化 JSON
String sceneSummaryPrompt(String sceneText) {
  return '''
你是一个专业的小说分析和摘要助手。
分析以下场景正文，输出 JSON 格式的结构化摘要。

输出格式：
{
  "summary": "200-500字场景摘要，涵盖核心事件、人物互动和情节推进",
  "keywords": ["关键词1", "关键词2"],
  "characters": ["角色ID1", "角色ID2"],
  "location": "场景地点",
  "mood": "平静/紧张/悲伤/欢快/悬疑/温馨",
  "inStoryDay": "第X天 或 季节描述",
  "causeEvent": "触发本场景的前置事件简述",
  "effectEvent": "本场景引发的后续可能事件",
  "characterEmotions": {
    "角色名": "情感状态（如：愤怒、悲伤、欣喜、焦虑等）"
  },
  "conflictType": "人物/社会/内心/自然/无",
  "suspenseTags": ["悬念标签"],
  "keyDialogues": [
    {"speaker": "角色名", "line": "关键对话原文"}
  ],
  "signatureMoments": ["名场面描述"],
  "foreshadowingIds": []
}

注意：
1. summary 必须涵盖核心情节推进，不能仅描述氛围
2. 情感分析基于角色行为和对白推断
3. 关键对话选取对剧情有推动作用的对话
4. 名场面指画面感强、情感冲击大的场景
5. 只输出 JSON，不要包含其他内容

场景正文：
$sceneText
''';
}

/// 章节摘要 Prompt — 聚合场景摘要生成章级摘要
String chapterSummaryPrompt(String chapterTitle, String sceneSummariesJson) {
  return '''
你是一个专业的小说章节摘要助手。
基于以下本章所有场景的结构化摘要，生成章级结构化摘要。

输出格式：
{
  "summary": "500-1000字章摘要，涵盖本章整体情节推进",
  "hook": "章末钩子描述",
  "majorEvents": ["关键事件1", "关键事件2"],
  "characterArcs": {
    "角色名": "本章弧光变化"
  },
  "conflictResolution": "冲突解决情况",
  "emotionalClimax": "本章情感高潮点",
  "unansweredQuestions": ["未解答的悬念"]
}

注意：
1. 整合所有场景的事件，形成连贯的章节叙事
2. hook 指本章结尾留下的悬念/期待
3. 角色弧光描述角色在本章中的变化
4. 只输出 JSON，不要包含其他内容

章节标题：$chapterTitle

场景摘要列表：
$sceneSummariesJson
''';
}

/// 卷摘要 Prompt — 聚合章摘要生成卷级摘要
String volumeSummaryPrompt(String volumeTitle, String chapterSummariesJson) {
  return '''
你是一个专业的小说卷摘要助手。
基于以下本卷所有章节的结构化摘要，生成卷级结构化摘要。

输出格式：
{
  "summary": "1000-2000字卷摘要，涵盖本卷整体故事弧",
  "mainCharacters": {
    "角色名": "角色状态"
  },
  "storyArc": "本卷故事弧描述",
  "majorPlotPoints": ["重大情节转折1", "重大情节转折2"],
  "unresolvedThreads": ["未解决线索"]
}

注意：
1. 整合所有章节的事件，形成完整的卷故事弧
2. 记录主要角色的状态变化
3. 未解决线索指本卷留下、后续需要处理的剧情线
4. 只输出 JSON，不要包含其他内容

卷标题：$volumeTitle

章节摘要列表：
$chapterSummariesJson
''';
}
