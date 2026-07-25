# ADR-0002: AI 供应商统一化 + 双协议

## 状态

已接受 (2026-07-25)

## 背景

灵笔当前有 5 个硬编码内置供应商（Free/SenseNova/DeepSeek/OpenAI/Claude），自定义供应商藏在设置页深处。大量用户使用中转站（自定义 API 端点），当前设计将他们拒之门外。

两种方案：
- **方案 A（统一化）**：取消"内置 vs 自定义"区分，所有供应商都是 `EndpointConfig`，官方预置只是默认配置
- **方案 B（双轨制）**：保留内置特殊逻辑，自定义走独立通道

## 决策

采用方案 A（统一化），对齐 OpenWrite 做法：

1. **所有供应商 = `EndpointConfig`**：`{ id, name, baseUrl, apiKey, protocol, modelId }`
2. **双协议支持**：OpenAI 兼容格式（`/v1/chat/completions`）+ Anthropic 格式（`/v1/messages`）
3. **模型自动发现**：从 `/v1/models` 拉取可用模型列表，用户无需手动输入 modelId
4. **官方预置 = 默认配置**：5 家内置供应商降级为"预置 EndpointConfig"，与用户添加的自定义端点走完全相同的代码路径
5. **Onboarding 一等公民**：创建项目/首次启动时，"添加供应商"入口与选择预置供应商平级展示

关键约束：
- `AIProviderFactory` 不再 `switch(name)`，统一用 `baseUrl + protocol` 创建 Provider
- "Free" 模式作为一条特殊预置配置（baseUrl 指向灵笔免费代理），配额逻辑挂在配置上
- 环境变量 API Key 优先级仍高于 UI 配置（保持现有行为）

## 后果

- 正面：中转站用户零门槛接入；新增供应商无需改代码；UI 路径统一
- 负面：需要重构 `AIProviderFactory`、`OnboardingWizard`、`SettingsPage` 的供应商相关逻辑
- 风险：部分供应商有非标准鉴权（如 SenseNova 的 token 刷新），需在 EndpointConfig 上扩展 auth 策略
