# 商业化 — 需求规格

> ID: CAP-COMMERCE | 优先级: P2 | 依赖: CAP-MS (Quota :8088)

---

## 需求清单

### REQ-COMMERCE-01: 配额系统
- **优先级**: P1
- **描述**: AI API 调用配额管理（已有 `lib/services/quota_service.dart`）
- **验收标准**:
  - 免费用户: 100 次/天
  - 会员用户: 无限制
  - 配额计数持久化 (Drift)
  - 配额耗尽时提示 + 引导升级
  - 管理员可重置配额

### REQ-COMMERCE-02: 会员系统
- **优先级**: P2
- **描述**: 会员身份验证和权益管理
- **验收标准**:
  - 会员状态检查 (本地令牌)
  - 会员权益: 无限 API + 优先更新 + 高级导出
  - 会员到期处理
  - 爱发电集成: 捐赠确认 → 会员激活

### REQ-COMMERCE-03: GitHub 开源发布
- **优先级**: P1
- **描述**: 准备 GitHub 开源发布
- **验收标准**:
  - MIT License
  - README.md: 项目介绍 + 截图 + 安装说明
  - CONTRIBUTING.md: 贡献指南
  - SECURITY.md: 安全策略
  - .github/ISSUE_TEMPLATE/
  - GitHub Actions: CI (flutter analyze + test)
  - Docker Hub: 镜像自动构建

### REQ-COMMERCE-04: 代码安全扫描
- **优先级**: P1
- **描述**: 开源前安全扫描
- **验收标准**:
  - git secrets 扫描 (API Keys / tokens / passwords)
  - .env.example 清理 (敏感信息移入 .env)
  - flutter analyze 0 error
  - 依赖审计 (已知漏洞检查)
  - 代码风格检查 (dart format)

### REQ-COMMERCE-05: Windows 打包
- **优先级**: P2
- **描述**: MSIX 安装包 + 自动更新
- **验收标准**:
  - MSIX 配置 (msix_config)
  - 应用图标 + 名称配置
  - 安装包签名
  - 自动更新检查 (GitHub Releases)