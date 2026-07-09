# 任务清单

> 灵笔 v3.2 "世界写作平台"核心重构 | 预估工期: 4 周

---

## Phase 0: 快速修复（半天）

- [ ] 0.1 修复 `claude_provider.jpg` → `claude_provider.dart`
- [ ] 0.2 更新 `pubspec.yaml` 版本号 → `0.5.0-dev`
- [ ] 0.3 创建 `assets/prompts/` 目录

**产出:** `flutter analyze` 0 error, 版本号正确

---

## Phase 1: 存储层迁移 — Drift + 文件混合（9天）

### Phase 1a: 核心存储（5天）

- [ ] 1.1 Drift 集成 + build.yaml + 依赖管理
- [ ] 1.2 表结构定义（15 张表）
- [ ] 1.3 数据迁移脚本（Project→World + Work）
- [ ] 1.4 Repository 层（Character/Scene/Timeline）

### Phase 1b: Service 适配（4天）

- [ ] 1.5 现有 17 个 Service 改从 Drift 读数据
- [ ] 1.6 ZVec 与 Drift 共存方案 + 索引迁移
- [ ] 1.7 现有测试适配新数据层

---

## Phase 2: 身份识别系统（4天）

### Phase 2a: 规则引擎 + 基础匹配（2天）

- [ ] 2.1 称呼规则库（"掌门"/"师妹"/"林长老" 等模式匹配）
- [ ] 2.2 基础 IdentityDetector（纯规则，不上 LLM）
- [ ] 2.3 结果缓存（同一场景不重复分析）

### Phase 2b: LLM 兜底 + UI（2天）

- [ ] 2.4 LLM 辅助分析（规则匹配不到时调用）
- [ ] 2.5 身份管理 UI（角色面板 + 通知气泡 + 确认/拒绝/修改）
- [ ] 2.6 渐进式学习（用户确认的行为写入规则库）

---

## Phase 3: 上下文注入引擎（3天）

- [ ] 3.1 ContextResolver（按权重排序 + 活跃身份 + 地点/规则/时间线）
- [ ] 3.2 LRU 缓存（key=章节ID, 失效=用户编辑）
- [ ] 3.3 ContextInjector（分层 Prompt + 1500 tokens 预算）
- [ ] 3.4 Token 计数器（注入前/蝴蝶效应前费用预估）

---

## Phase 4: 蝴蝶效应引擎（2天）

- [ ] 4.1 ButterflyAnalyzer
- [ ] 4.2 费用提示 UI + 用户确认弹窗
- [ ] 4.3 结果展示（角色列表 + 权重变化 + 走向预测）

---

## Phase 5: 导入/导出（3天）

- [ ] 5.1 Markdown/JSON/TXT 原生导出
- [ ] 5.2 DOCX/EPUB 原生导出（Dart 生成 Open XML + ZIP）
- [ ] 5.3 Markdown/JSON 导入 + 导出 UI

---

## Phase 6: 测试覆盖（2天，贯穿全流程）

- [ ] 6.1 Drift 数据库测试
- [ ] 6.2 IdentityDetector 测试
- [ ] 6.3 ContextResolver 测试
- [ ] 6.4 ButterflyAnalyzer 测试
- [ ] 6.5 补充 Layer2/Layer3 测试

---

## 依赖关系

```
Phase 0 ──→ Phase 1a ──→ Phase 1b ──→ Phase 2a ──→ Phase 2b ──→ Phase 3
                                                                       │
                                            Phase 4 ◄─────────────────┘
                                            Phase 5
                                            Phase 6 (贯穿全流程)
```