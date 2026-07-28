# 灵笔 (Lingbi)

灵笔是面向中文长篇小说作者与小型工作室的 Windows 桌面写作工具。项目坚持 local-first：项目、文档、资产和导出不因授权状态而失去本地访问能力；AI 写入遵循候选稿、差异检查、人工批准和可恢复写入流程。

## 当前发布状态

仓库版本为 **1.0.1**。当前代码可以从受 Git 跟踪的源码和 `pubspec.lock` 复现依赖、测试、Windows release build 与便携包；GitHub PR CI 会上传包含相对路径 SHA-256 和源码 provenance 的未签名便携包。

这不是“商业就绪”声明。Inno Setup 元数据已统一到 `Lingbi-Setup-1.0.1.exe`，但 Task 1 CI 产物是未签名便携包，尚未证明安装、升级、卸载保留数据和回滚矩阵。Windows 代码签名、商户支付、法律文本审批、授权市场数据、真实提供商验收及专业作者试用均为 `BLOCKED_EXTERNAL`。

详细能力证据和限制见 [商业发布报告](docs/qa/commercial-release-report.md) 与 [P0 Windows 发布门禁](docs/qa/p0-windows-release-checklist.md)。

## 已验证与受限范围

| 范围 | 状态 | 说明 |
|------|------|------|
| 本地项目/文档访问与编辑 | REAL | Windows 本地文件和项目数据不依赖订阅权限 |
| 候选稿、人工采用与原子文件写入 | REAL | 自动化测试覆盖候选稿不直接覆盖正文及可恢复写入 |
| Windows 快捷键、命令面板和基础响应式布局 | REAL | 有针对性 Flutter 测试 |
| 题材建项、三问引导、首章恢复链路 | PARTIAL | 组件存在，端到端 golden path 尚未闭合 |
| 运行时模型切换、许可证、隐私诊断 | PARTIAL | 生产信任根和真实连接验证尚未完成；购买入口保持禁用 |
| 恢复中心、便携项目导入、迁移回滚 | PARTIAL | 服务骨架/单测存在，干净目录重启事务尚未闭合 |
| 上下文编译、Skill 执行、WebDAV、市场情报 | PARTIAL | 不能把单元级实现当作完整生产链路或外部兼容证据 |
| DOCX、系统拖放、稳定章节选择 | NOT_IMPLEMENTED | 不宣称 Word 导出或完整拖放体验 |
| 终端/通用 system command 工具 | DISABLED | 在单独审查的沙箱存在前不会启用 |

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
tool/windows/                Windows release 包装脚本
installer/                   Inno Setup 元数据（未进入 Task 1 CI 产物）
docs/qa/                     发布证据、限制与人工门禁
.github/workflows/ci.yml     PR/push 分析、测试、release build/package
```

## 许可证

[MIT](LICENSE)
