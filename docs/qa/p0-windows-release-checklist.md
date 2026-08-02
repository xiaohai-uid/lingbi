# P0 Windows 发布门禁

日期：2026-07-28

分支：`agent/lingbi-openwrite-commercial-delta`

## 自动化硬门禁

- [x] `Ctrl+N` 返回题材模板入口，不以空白对话框代替创建流程。
- [x] `Ctrl+O` 打开本地便携项目目录。
- [x] `Ctrl+K` 打开可搜索且自动聚焦的命令面板。
- [x] `Ctrl+Shift+A` 显示/隐藏 AI 助手。
- [x] `Ctrl+,` 打开真实设置页。
- [x] `Ctrl+S` 向当前编辑器发送原子保存命令。
- [x] Escape 只在存在设置/技能市场等临时层时由根工作区处理；编辑器无临时层时保留 Escape。
- [x] 1440px：章节栏 + 最少 600px 编辑区 + AI 固定栏。
- [x] 1280px：AI 可折叠，编辑区保持至少 600px。
- [x] 1024px：AI 作为覆盖层，编辑区保持至少 600px。
- [x] 章节导航、新建文档、项目内容区和 AI 面板具有语义标签/工具提示。
- [x] Windows 默认窗口为 1440×900，中文产品标题。

覆盖测试：`test/windows_keyboard_navigation_test.dart`

## P0 数据安全门禁

- [x] 项目题材选择写入 `ProjectBrief`，不会在下一步重复选择。
- [x] 引导答案、跳过状态和下一步可恢复。
- [x] AI 生成先成为候选稿，确认前不覆盖原文。
- [x] 确认采用经过版本锁和快照。
- [x] 文稿、版本和导出采用临时文件 + flush + 原子替换 + `.bak` 回退。
- [x] 回收站为软删除，恢复中心统一列出候选稿、版本、快照和回收站。
- [x] 项目包包含 schema、文件分类、大小和 SHA-256；损坏、路径穿越和非空目标目录均拒绝导入。
- [x] 未实现标准 DOCX 时不再宣称支持 Word。

## Task 1 源码与发布证据门禁

- [x] 导入的生产源码、`pubspec.lock` 和本清单均由 Git 跟踪；`test/release_metadata_contract_test.dart` 覆盖。
- [ ] `dart format --output=none --set-exit-if-changed lib test tool`：基线仍有 173 个历史文件未格式化；Task 1 未做全库机械改写。
- [x] `flutter analyze lib/`：`No issues found`。
- [x] `flutter test`：1002 tests，零失败。
- [x] `flutter build windows --release`：成功生成 `lingbi.exe`。
- [x] `tool/windows/package_release.ps1 -SkipBuild`：成功生成便携包。
- [x] `SHA256SUMS.txt` 使用包内相对路径，`PROVENANCE.json` 记录版本和源码 commit/ref/dirty 状态。
- [ ] 干净安装、升级、保留数据卸载和回滚矩阵通过。
- [ ] 代码签名：`BLOCKED_EXTERNAL`，直到提供真实 Windows 证书。

任何未勾选项都禁止把构建标记为“商业就绪”。
