# Open Design 修复清单

## 4 个阻塞问题（必须修）

### 1. 缺 2 个页面
需要补生成：
- `canon_page`（知识库）— 角色/地点/事件/关系管理
- `story_canvas_page`（故事画布）— 场景关系图

### 2. settings 缺 AI Provider / API Key 配置
当前 settings.html 只有主题/账户/订阅/关于，缺少：
- AI Provider 选择器（DeepSeek/OpenAI/Claude/SenseNova）
- API Key 输入框（每 Provider 一个）
- 模型选择
- 额度显示

### 3. dashboard.html 和 index.html 暗色模式颜色错误
当前暗色背景设为 `#fafafa`（近白色），应该改为 `#1A1612`（深棕）
- dashboard.html 第 704-720 行
- index.html 第 561-577 行

### 4. editor.html 和 workspace.html 完全缺少暗色模式
这两个核心页面需要添加完整的暗色模式实现（参考 settings.html 的 `[data-theme="dark"]` 方案）

## 2 个质量问题

### 5. 暗色模式实现方式不统一
- settings.html 用 CSS `[data-theme="dark"]` ✅
- dashboard.html/index.html 用 JS `root.style.setProperty()` ❌
- 统一用 CSS data-theme 方案

### 6. localStorage key 不统一
- settings 用 `localStorage('lingbi.theme')`
- 其他页面用 `localStorage('lingbi:theme')`
- 统一成一个 key

## 编码问题
workspace.html 被存成了 ISO-8859 编码，中文字符乱码。需要重新保存为 UTF-8。