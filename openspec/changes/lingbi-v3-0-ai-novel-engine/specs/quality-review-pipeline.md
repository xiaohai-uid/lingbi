# 质量审查管线 — Spec

## 目标

从 AI_NovelGenerator 移植质量审查系统，在生成过程中自动检查内容质量。

## 审查模块

### 1. 角色一致性检测 (character_consistency.py)

```dart
class CharacterConsistencyResult {
  bool isConsistent;
  int deviationScore;     // 0-100, 0=完全一致
  String reason;
  List<String> specificIssues;
}
```

检查维度：
- 性格一致性（角色行为是否符合人设）
- 动机一致性（角色选择是否符合动机）
- 对话风格一致性
- 情绪转换合理性

### 2. 爽点密度分析 (hook_density.py)

```dart
class HookDensityResult {
  List<HookEvent> hookEvents;
  double density;         // 爽点数量 / 1000 字
  int wordCount;
  bool meetsRequirement;  // 番茄模式: ≥2.0/1000字
}
```

爽点类型：打脸、反转、升级、获得、装逼、复仇、保护、揭秘

### 3. 格式审查 (format_review_service.py)

- 段落长度检查
- 对话/叙述比例
- 章节结构完整性
- 禁止内容检查（标题/JSON/说明语）

### 4. 综合审查报告

```dart
class ReviewReport {
  double overallScore;   // 0-10
  EditorFeedback? editorFeedback;
  double? qualityScore;
  List<String> consistencyIssues;
  bool needsRewrite;
  String rewriteReason;
}
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `lib/services/quality/review_pipeline.dart` | 审查管线编排 |
| `lib/services/quality/character_consistency.dart` | 角色一致性检测 |
| `lib/services/quality/hook_density.dart` | 爽点密度分析 |
| `lib/services/quality/format_review.dart` | 格式审查 |
| `lib/services/quality/review_models.dart` | 数据模型 |