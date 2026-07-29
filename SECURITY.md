# 安全政策

## 支持范围

安全修复优先覆盖最新正式版本和 `main`。旧版本用户应先升级到最新 Release。

## 私密报告漏洞

请通过 GitHub 的 [Private vulnerability reporting](https://github.com/xiaohai-uid/lingbi/security/advisories/new) 提交报告。不要在公开 Issue、Discussion 或截图中披露未修复漏洞、API Key、访问令牌或私人作品。

报告请包含受影响版本、复现步骤、影响范围和可行的缓解方式。请使用最小化、脱敏的测试数据。

## 项目安全边界

- 项目与作品默认保存在用户本地目录。
- API Key 优先存入操作系统安全存储。
- AI 请求会发送到用户明确选择的第三方提供商。
- Agent 文件工具必须受项目目录沙箱限制。
- 发布包在获得可信证书前属于未签名产物，可能触发 SmartScreen。

第三方模型、搜索服务、WebDAV 服务和自定义端点不由本项目运营；使用者应独立评估其隐私政策和数据处理规则。
