# TASK-20260725-MARKET-SYNC-BILLING

## 标题

市场情报 + 云同步 + 收费系统（批次4+5）

## 来源

- `docs/decisions/skill-ecosystem-execution-plan.md` 批次 4 + 批次 5
- 产品愿景审计会议决策（Q8/Q9）

## 前置条件

- 批次2+3（Skill Runtime）已验证通过
- `ContextAssembler` 已有 marketContext 注入点
- `SettingsService` 已有配置持久化能力

## 范围

### 批次 4：市场情报 + 云同步

| 子任务 | 交付物 | 验收标准 |
|--------|--------|---------|
| 4.1 用户输入字段 | `lib/core/models/project.dart` 修改 | Project 含 targetPlatform/genre/audience，可序列化 |
| 4.2 平台数据服务 | `lib/services/market_intel_service.dart` | API 拉取 + 本地缓存 + 离线回退 + 上下文摘要生成 |
| 4.3 匿名数据聚合 | `lib/services/sync/sync_manager.dart`（AnalyticsConsent/Payload） | 默认开启、仅匿名统计、可关闭 |
| 4.4 WebDAV 云同步 | `lib/services/sync/webdav_service.dart` + `sync_manager.dart` | PROPFIND/GET/PUT/DELETE/MKCOL + 冲突检测 + 状态机 |
| 4.5 AI 上下文注入 | `lib/modules/pipeline/context_assembler.dart` 修改 | marketContext 参数注入生成上下文 |
| 4.6 测试 | `test/market_sync_test.dart` | Project 字段、MarketIntel、WebDAV、SyncManager 全覆盖 |

### 批次 5：收费系统

| 子任务 | 交付物 | 验收标准 |
|--------|--------|---------|
| 5.1 Pro 订阅层 | `lib/services/subscription_service.dart` | Free/Pro 分层 + ProFeature 枚举门禁 + 过期回退 |
| 5.2 许可证验证 | `lib/services/license_service.dart` | 格式验证 + 机器绑定 + 离线激活 + 过期检测 |
| 5.3 测试 | `test/subscription_billing_test.dart` | 分层、门禁、许可证全路径覆盖 |

## 不在范围

- 模型套餐代理服务端（`lingbi_server/microservices/billing/`）— 需服务端部署
- 爬虫微服务实现（`lingbi_server/microservices/market-intel/`）— 当前客户端仅消费 API
- 设置页 WebDAV 配置 UI — 属于 UI 层另行处理
- 隐私政策文档

## 验收门禁

1. `flutter analyze lib/` — 0 error
2. `flutter test` — 全部通过（含 market_sync_test + subscription_billing_test）
3. 场景覆盖：
   - Project 模型：targetPlatform/genre/audience 可读写、可序列化
   - MarketIntelService：API 拉取 → 缓存 → 离线回退 → 上下文摘要
   - WebDAV：配置验证 → 连接测试 → 上传/下载 → 冲突检测
   - Subscription：Free 门禁 → Pro 解锁 → 过期回退 Free
   - License：格式验证 → 机器绑定 → 离线激活 → 过期失效

## 约束

- 离线优先：许可证验证不依赖网络
- 优雅降级：Pro 过期后回退 Free，不阻断基础功能
- 匿名统计默认开启，仅传不可逆聚合数据，提供关闭选项
- WebDAV 密码不明文写入 settings.json（由安全存储管理）
- 市场数据 API 超时 10s，失败回退本地缓存
