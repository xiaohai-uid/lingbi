# 世界构建增强 — 需求规格

> ID: CAP-WORLDBUILD | 优先级: P1 | 依赖: CAP-WORLD

---

## 需求清单

### REQ-WB-01: 角色关系图谱 (已有代码)
- **优先级**: P1
- **描述**: 基于现有 `lib/services/character_graph_service.dart` 和 `lib/core/models/character_edge.dart`，完成 UI 集成
- **验收标准**:
  - CharacterGraphService CRUD 功能完整
  - 关系类型: 师徒 / 敌对 / 恋人 / 家族 / 主仆 / 盟友
  - 关系强度 1-10
  - 图谱可视化 UI (Codex 页面入口)
  - 关系图谱导出为图片

### REQ-WB-02: 势力管理 (已有代码)
- **优先级**: P1
- **描述**: 基于现有 `lib/services/faction_service.dart` 和 `lib/core/models/faction.dart`
- **验收标准**:
  - 势力类型: 宗门 / 国家 / 家族 / 组织
  - 成员管理 (角色 ↔ 势力)
  - 势力关系 (盟友 / 敌对 / 中立)
  - 势力视图 UI

### REQ-WB-03: 时间线和伏笔追踪 (已有代码)
- **优先级**: P1
- **描述**: 基于现有 `lib/services/timeline_service.dart`
- **验收标准**:
  - 时间线事件 CRUD
  - 分数索引排序
  - 故事内时间支持
  - 伏笔埋设 / 回收状态追踪
  - 时间线可视化 UI (故事画布集成)

### REQ-WB-04: 身份识别系统
- **优先级**: P1
- **描述**: 系统自动从行文识别角色身份
- **验收标准**:
  - 规则引擎: 称呼匹配 ("掌门"/"师妹"/"林长老") + 模式匹配
  - LLM 兜底: 规则匹配不到时调用 LLM 分析
  - 结果缓存: key=场景ID, ttl=编辑周期
  - 用户确认 UI: 通知气泡 + 确认/拒绝/修改
  - 渐进式学习: 用户确认的行为写入规则库

#### Scenario: 身份自动检测
- **Given**: 角色 "林月" 已有身份 "师妹"
- **When**: 用户写道 "林长老，此事万万不可"
- **Then**: 系统检测到 "林长老" 称呼 → 建议新增身份 "长老" → 用户确认后生效

### REQ-WB-05: 蝴蝶效应引擎
- **优先级**: P2
- **描述**: 分析关键事件对角色权重和剧情走向的影响
- **验收标准**:
  - ButterflyAnalyzer: 事件 → 受影响角色列表 + 权重变化
  - 费用预估: LLM 分析的费用提示
  - 用户确认弹窗: "分析将消耗约 X tokens，继续？"
  - 结果展示: 角色列表 + 权重变化 + 走向预测
  - 结果可手动编辑

### REQ-WB-06: 导入导出增强
- **优先级**: P2
- **描述**: 在现有 ExportService 基础上增强
- **验收标准**:
  - DOCX 原生导出 (Dart Open XML)
  - EPUB 原生导出 (Dart zip + XML)
  - Markdown/JSON 导入
  - Pandoc 可选: PDF/HTML 高级导出
  - 导出设置 UI (封面/作者/格式)