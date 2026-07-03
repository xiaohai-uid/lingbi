# 0001 — Flutter 技术栈选择

## 状态
✅ 已接受 (P0)

## 背景
灵笔需要从零复刻 OpenWrite 核心功能，以桌面应用形式运行。

## 决策
使用 Flutter (Dart) 最新版跨平台框架。

## 理由
- 跨平台：一套代码覆盖 Windows/macOS/Linux
- 原版 OpenWrite 同技术栈
- Dart 语言的类型安全适合桌面应用开发
- Flutter 生态成熟，桌面支持已稳定

## 替代方案
| 方案 | 优点 | 缺点 |
|---|---|---|
| Electron (JS) | 生态大 | 内存占用高，启动慢 |
| Tauri (Rust) | 编译体积小 | 技术栈割裂，配置复杂 |
| .NET MAUI | .NET 生态 | 仅 Windows 体验好 |

## 影响
- 使用 Flutter Desktop 渲染三栏布局
- 使用 flutter_quill 作为 WYSIWYG 编辑器
- 桌面窗口管理通过 window_manager 包
- 后续可扩展至 macOS/Linux 而无需重写