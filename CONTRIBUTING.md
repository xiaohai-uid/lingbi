# 参与贡献

感谢你帮助改进灵笔。Bug 修复、文档、小白体验、模型兼容和写作工作流改进都很欢迎。

## 开始之前

- Bug 和功能建议先搜索现有 Issues。
- 大型功能先开 Issue 说明用户场景、边界和验收方式。
- 安全漏洞不要公开提交，请按 [SECURITY.md](SECURITY.md) 报告。
- 不要提交 API Key、真实用户作品、模型响应日志或其他敏感数据。

## 本地环境

- Windows 10/11 x64
- Git
- Visual Studio 2022，安装 Desktop development with C++
- Flutter 3.44.6

```powershell
git clone https://github.com/xiaohai-uid/lingbi.git
cd lingbi
flutter pub get --enforce-lockfile
flutter doctor -v
```

## 开发流程

1. 从最新 `main` 创建分支。
2. 先为行为变化补充失败测试，再实现最小修复。
3. 保持本地优先、候选确认和项目目录沙箱边界。
4. 不把外部服务可用性写成确定能力。
5. 只提交与本次变更相关的文件。

提交前运行：

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib/
flutter test --exclude-tags network
```

涉及 Windows 发布时再运行：

```powershell
flutter build windows --release
tool/windows/build_release_assets.ps1 -SkipBuild -SkipInstaller
```

## Pull Request

PR 请说明改动服务的用户问题、行为与兼容性影响、实际运行过的测试、未验证的外部条件，以及 UI 变化的截图或录屏。

维护者会优先检查数据安全、候选写入边界、迁移兼容、模型错误处理和测试证据。
