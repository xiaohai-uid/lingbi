# 灵笔 (Lingbi) — Open Design UI 重构输入文档

## 项目信息
- 项目路径: D:/lingbi-repair
- 技术栈: Flutter (Dart) Desktop + Go/Rust 微服务
- 当前主题: Warm Glass（暖白+琥珀金+玻璃拟态）
- 构建命令: flutter build windows --release → lingbi.exe
- 测试: 334 单元测试全绿

## 当前 UI 文件结构

### 页面 (lib/ui/pages/)
| 文件 | 功能 | 状态 |
|------|------|------|
| wg_dashboard_page.dart | 首页仪表盘：侧边栏+顶栏+统计卡片+项目列表+活动流+写作目标 | 功能完整 |
| wg_workspace_page.dart | 三栏写作工作区：章节目录+标签页(大纲/角色/章节/时间线/AI生成)+上下文面板 | 导航已接通 |
| wg_editor_page.dart | 全屏编辑器：TOC面板+格式工具栏+写作区+质量面板+AI操作+快捷键 | 原型壳子 |
| canon_page.dart | 知识库：角色/地点/事件/关系管理 | 功能完整 |
| story_canvas_page.dart | 故事画布：场景关系图 | 新建 |
| settings_page.dart | 设置：主题/AI Provider/API Key管理 | 功能完整 |

### 组件 (lib/ui/components/) — 16 个
butterfly_analysis_dialog, character_graph_view, export_dialog, faction_view,
identity_dialog, identity_notification, import_dialog, memory_panel,
name_generator_dialog, search_dialog, selection_edit_popup, style_panel,
timeline_view, version_history_dialog, writing_calendar_view, writing_goal_card

### 主题 (lib/ui/theme/)
| 文件 | 内容 |
|------|------|
| app_theme.dart | ThemeData + 配色（暖白#FAF8F5/深棕#1A1612/琥珀金#E8A838） |
| wg_components.dart | Warm Glass 组件库：WgGlassPanel, WgCard, WgButton 等 |

## 核心配色
- 暖白底色: #FAF8F5（亮色）/ 深棕 #1A1612（暗色）
- 琥珀金强调: #E8A838
- 暖棕文字: #3D3529
- 玻璃拟态: backdrop-filter blur + 半透明表面

## 需要 Open Design 重新设计的页面 (优先级高→低)
1. wg_dashboard_page — 仪表盘: 侧边栏导航+统计卡片+项目列表
2. wg_editor_page — 全屏编辑器: 写作区+工具栏+质量面板+AI智能助手
3. wg_workspace_page — 三栏工作区: 章节目录+标签页+上下文面板
4. canon_page — 知识库: 角色/地点/事件管理
5. story_canvas_page — 故事画布: 场景关系图

## 设计方向
- 风格: 对标 Effie 极简 + 纯纯写作流畅
- 目标用户: 网文作者
- 差异化: 长篇稳定性（500万字） + AI 辅助创作
- 需保持: 暗色模式切换、专注模式（隐藏侧边栏）