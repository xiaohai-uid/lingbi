# 灵笔 LingBi

面向中文长篇小说作者的本地优先 AI 写作桌面应用。灵笔把项目、章节、人物、世界观、AI 辅助、审稿和导出放在同一个 Windows 工作台里；AI 生成内容先成为候选稿，确认后才会写入正文。

[![CI](https://github.com/xiaohai-uid/lingbi/actions/workflows/ci.yml/badge.svg)](https://github.com/xiaohai-uid/lingbi/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/xiaohai-uid/lingbi)](https://github.com/xiaohai-uid/lingbi/releases/latest)
[![License](https://img.shields.io/github/license/xiaohai-uid/lingbi)](LICENSE)

## 直接下载

当前版本：**v1.1.0**，支持 Windows 10/11 x64。

- [下载安装版 `Lingbi-Setup-1.1.0.exe`](https://github.com/xiaohai-uid/lingbi/releases/latest/download/Lingbi-Setup-1.1.0.exe)（推荐）
- [下载免安装版 `Lingbi-Windows-Portable-1.1.0.zip`](https://github.com/xiaohai-uid/lingbi/releases/latest/download/Lingbi-Windows-Portable-1.1.0.zip)
- [查看全部版本与校验文件](https://github.com/xiaohai-uid/lingbi/releases)

安装版目前没有商业代码签名证书。Windows SmartScreen 可能显示“Windows 已保护你的电脑”，请确认下载地址属于 `xiaohai-uid/lingbi`，核对 Release 中的 SHA-256 后，再选择“更多信息 → 仍要运行”。

## 三分钟开始写作

1. 安装并启动灵笔，按首次配置向导选择 AI 提供商。
2. 填入自己的 API Key，选择模型并执行连接测试。
3. 创建项目，填写题材和创作目标，然后新建第一章。

没有 API Key 时仍可使用本地项目、编辑、资料管理和导出；AI 生成、联网检索等功能需要对应服务可用。API Key 保存在 Windows 安全存储中，不会写入项目文件。

第一次使用遇到问题，请从[零基础使用指南](docs/GETTING_STARTED.md)开始；常见报错见[常见问题](docs/FAQ.md)。

## 核心能力

| 创作环节 | 灵笔提供的能力 |
| --- | --- |
| 项目与正文 | 本地项目、章节树、富文本编辑、自动保存、版本历史 |
| 世界构建 | 人物、地点、时间线、设定资料与正史上下文 |
| AI 写作 | 多提供商与自定义端点、模型切换、多模型路由、长会话压缩 |
| 安全落稿 | 候选稿预览、差异检查、人工采用、原子写入与恢复 |
| 资料研究 | Web 搜索、来源浏览、资料引用和上下文插入 |
| 质量审阅 | 六维章节审稿、历史报告、确认式章节结算 |
| 交付 | Markdown、TXT、DOCX、PDF 导出与便携项目包 |
| 扩展 | 本地 Skill 发现、Agent 项目工具和项目目录沙箱 |

## 数据与隐私

- 默认项目目录：`%USERPROFILE%\Documents\灵笔`
- 卸载应用不会主动删除项目和用户数据。
- AI 请求会把当前任务所需内容发送给你选择的第三方模型提供商。
- 请定期备份项目目录；升级或迁移前尤其如此。
- 源代码采用 MIT 许可证，第三方 AI 服务可能按各自规则收费。

## 从源码运行

需要 Windows 10/11、Git、Visual Studio 2022 Desktop development with C++ 和 Flutter 3.44.6。

```powershell
git clone https://github.com/xiaohai-uid/lingbi.git
cd lingbi
flutter pub get --enforce-lockfile
flutter run -d windows
```

验证与构建：

```powershell
flutter analyze lib/
flutter test --exclude-tags network
flutter build windows --release
tool/windows/build_release_assets.ps1 -SkipBuild -SkipInstaller
```

项目结构、提交规范和测试要求见[贡献指南](CONTRIBUTING.md)。安全问题请阅读[安全政策](SECURITY.md)，不要在公开 Issue 中披露凭据或未修复漏洞。

## 发布透明度

仓库 CI 会分析、测试并构建 Windows 产物；版本标签会生成安装器、便携 ZIP、`SHA256SUMS.txt` 和 `PROVENANCE.json`。后者记录版本、源码提交和构建平台。

代码签名、授权市场数据、支付、法律审批和专业作者试点属于外部商业门槛，不会被描述为已经完成。详细证据见[发布报告](docs/qa/commercial-release-report.md)和[Windows 发布检查表](docs/qa/p0-windows-release-checklist.md)。

## 参与项目

欢迎提交 Bug、文档改进、模型兼容修复和写作工作流建议。开始开发前请先阅读[贡献指南](CONTRIBUTING.md)。

## 许可证

[MIT License](LICENSE)
