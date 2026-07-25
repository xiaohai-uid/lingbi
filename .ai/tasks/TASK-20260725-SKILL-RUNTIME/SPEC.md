# TASK-20260725-SKILL-RUNTIME

## 标题

Skill Runtime MVP + Store 联动 + 蒸馏（批次2+3）

## 来源

- ADR-0002: Skill 生态架构 — 分层运行时 + 声明式权限
- `docs/decisions/skill-ecosystem-execution-plan.md` 批次 2 + 批次 3

## 前置条件

- 批次1（基础体验修复）已验证通过（`reports/batch1-verify/verification-report.md`，PASS）
- `SkillActionService` 已有 3 个内置技能 + `registerSkill`/`unregisterSkill` 接口
- `SkillMarketplace` 已有安装/卸载逻辑 + 事件流

## 范围

### 批次 2：Skill Runtime MVP

| 子任务 | 交付物 | 验收标准 |
|--------|--------|---------|
| 2.1 Skill 包格式标准 | `lib/services/skill/skill_manifest.dart` | 解析 Anthropic frontmatter + 纯 Markdown 两种 SKILL.md 格式 |
| 2.2 声明式权限系统 | `lib/services/skill/skill_permission.dart` | 6 种权限枚举 + PermissionSet + 轻量默认只读 |
| 2.3 动态 Skill 加载器 | `lib/services/skill/skill_loader.dart` | 扫描安装目录 → 解析 → 注册；监听 Marketplace 事件实时刷新 |
| 2.4 Skill 执行沙箱 | `lib/services/skill/skill_executor.dart` | SandboxedSkillApi 权限守卫 + 轻量/重量双路径执行 |
| 2.5 DynamicPromptSkill 桥接 | `lib/services/skill/dynamic_prompt_skill.dart` | SKILL.md → SkillAction 适配 + 模板占位符替换 |
| 2.6 ServiceLocator 接线 | `lib/core/di/service_locator.dart` 修改 | 启动时 loadAll + listenToMarketplace；失败不阻断主流程 |
| 2.7 端到端测试 | `test/skill_*_test.dart`（6 个文件） | manifest 解析、权限校验、加载器、执行器、E2E 全通过 |

### 批次 3：Store 联动 + 蒸馏

| 子任务 | 交付物 | 验收标准 |
|--------|--------|---------|
| 3.1 Marketplace 事件通知 | `lib/services/skill_marketplace.dart` 修改 | install/uninstall 发出 SkillMarketEvent |
| 3.2 SkillActionService 动态注册 | `lib/services/skill_action_service.dart` 修改 | registerSkill/unregisterSkill 公开接口 |
| 3.3 蒸馏即创作 | `lib/services/skill/distillation_service.dart` | Canon + 文档样本 → AI 分析 → 生成 SKILL.md → 保存并注册 |
| 3.4 蒸馏测试 | `test/skill_store_distillation_test.dart` | 蒸馏流程端到端通过 |

## 不在范围

- Skill Store UI 改动（`skill_market_page.dart` 的 UI 变更属于批次3 UI 层，另行处理）
- 重量 Skill 的真实 API 代理实现（当前为接口 + 沙箱骨架，生产代理需 CanonService/DocumentService 适配）
- 市场情报、云同步、收费系统（批次4/5）

## 验收门禁

1. `flutter analyze lib/` — 0 error
2. `flutter test` — 全部通过（含新增 Skill 测试）
3. 以下场景端到端可运行（测试覆盖）：
   - 轻量 Skill：安装 → 斜杠触发 → 权限校验 → prompt 构建 → 输出
   - 重量 Skill：声明 canon.write → 执行写入 → 成功
   - 重量 Skill：未声明 canon.write → 执行被拒绝（PermissionViolation）
   - 蒸馏：收集素材 → AI 生成 SKILL.md → 保存 → 自动注册

## 约束

- 轻量 Skill 使用 Anthropic 标准 SKILL.md 格式，不扩展 frontmatter
- 重量 Skill 声明式 API，不执行任意代码
- Skill 生态加载失败不阻断应用主流程（降级为无 Skill 模式）
- 分发复用 GitHub 基础设施，不自建服务端
