# 灵笔 (LingBi)

灵笔是面向中文长篇小说作者与小型工作室的 Windows 桌面写作工具。项目坚持 local-first：项目、文档、资产和导出不因授权状态而失去本地访问能力；AI 写入遵循候选稿、差异检查、人工批准和可恢复写入流程。

## 正式发布状态

仓库版本为 **1.2.0**，当前 GitHub `main` 已进入正式可用状态。Windows 黄金路径、首章生成与采纳、恢复中心、便携项目、导入导出、模型配置、技能市场与实验标签均已通过本机 Release 构建和 Windows integration test 验证。

- 安装版：`Lingbi-Setup-1.2.0.exe`
- 便携版：`Lingbi-Windows-Portable-1.2.0.zip`
- 系统要求：Windows 10/11 x64
- 下载入口：[GitHub Releases](https://github.com/xiaohai-uid/lingbi/releases/latest)

## 已验证范围

| 范围 | 状态 | 说明 |
|------|------|------|
| 本地项目/文档访问与编辑 | REAL | Windows 本地文件和项目数据不依赖订阅权限 |
| 候选稿、人工采用与原子文件写入 | REAL | 候选稿不直接覆盖正文，写入支持版本锁、快照和可恢复提交 |
| Windows 快捷键、命令面板和响应式布局 | REAL | 覆盖键盘导航、命令面板和 1024/1280/1440 布局 |
| 题材建项、三问引导、首章恢复链路 | REAL | Windows integration test 已验证完整首章旅程 |
| 模型配置、免费模型与运行时模型选择 | REAL | 免费模型端点和模型配置已在本机运行验证 |
| 恢复中心、便携项目导入、迁移回滚 | REAL | 软删除、恢复、便携包校验和项目身份迁移已闭合 |
| 技能市场、Skill 执行与路由 | REAL | 技能安装、Level 3 资源加载、路由和 Token 账本已接通 |
| 导入导出 Markdown/TXT/DOCX 与便携包 | REAL | Windows integration test 已验证导出和便携包回读 |
| WebDAV 项目同步 | PARTIAL | 本地代码与测试存在，真实第三方服务器验收仍待外部环境 |
| 授权市场情报 | BLOCKED_EXTERNAL | 需要授权数据源、协议和正式凭证 |
| 付费、许可证与商业法律材料 | BLOCKED_EXTERNAL | 购买入口保持禁用，支付/退款/税务/法律文本未接入 |
| Windows 代码签名 | BLOCKED_EXTERNAL | 未配置真实 EV/OV 证书，SmartScreen 会提示风险 |
| 终端/通用 system command 工具 | DISABLED | 在单独审查的沙箱存在前不会启用 |

详细证据见 [Path 2 Windows Smoke](docs/qa/path2-windows-smoke-2026-08-05.md)、[MutationProtocol P0 报告](docs/qa/mutation-protocol-p0-report.md) 和 [商业发布报告](docs/qa/commercial-release-report.md)。

## 发布说明

本版本定位为“正式可用版本”，不代表商业就绪认证。未签名安装包会在 Windows SmartScreen 中显示提示；完成代码签名、支付、法律文本、授权数据源和专业试点后，才能作为面向公开市场的商业发行版本发布。

## 开发与验证

前置要求：Flutter 3.44.6、Windows 10/11 x64。

```powershell
git clone https://github.com/xiaohai-uid/lingbi.git
cd lingbi
flutter pub get --enforce-lockfile
flutter analyze lib/
flutter test
flutter build windows --release
tool/windows/package_release.ps1 -SkipBuild
```

便携包输出到传入的 `-OutputDir`（未传入时为系统临时目录下的 `lingbi-release-package`）；CI 使用 runner 临时目录，其中：

- `SHA256SUMS.txt` 使用包内相对路径，避免机器相关绝对路径；
- `PROVENANCE.json` 记录应用版本、Git commit/ref、dirty 状态、构建配置和平台；
- `source_dirty: true` 的本地产物只能用于诊断，不能作为正式发布证据。

运行应用：

```powershell
flutter run -d windows
```

AI 提供商配置位于应用设置页。不要把 API Key 写入仓库、日志、诊断事件或 provenance。

## 项目结构

```text
lib/                         Flutter 应用与服务
test/                        自动化测试与发布契约
integration_test/            Windows 实机验收测试
tool/windows/                Windows release 包装脚本
installer/                   Inno Setup 安装脚本
docs/qa/                     发布证据、限制与人工门禁
.github/workflows/ci.yml     PR/push 分析、测试、release build/package
```

## 许可证

[MIT](LICENSE)
