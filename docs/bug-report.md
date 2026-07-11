# Bug 诊断报告 — 章节内容显示为空

> 诊断日期: 2026-07-10
> 方法: 代码路径追踪 + 数据流分析
> 状态: 根因已定位，修复方案已明确

---

## 问题描述

用户反馈：
1. 在 DashBoard 中看到"项目1"，点击进入工作区
2. 侧边栏显示了章节列表（有标题、卷结构）
3. 但点击具体章节后，编辑器显示**空白内容**
4. 感觉章节"存在但打开后没有内容"

---

## 数据流追踪

### 正常应有的数据流

```
Chapter ←→ Scene (documentId) ←→ Document (filePath) ←→ .md 文件
```

- `Chapter` 表: id, volumeId, chapterNumber, title, synopsis
- `Scene` 表: id, chapterId, sceneNumber, documentId ← **关键链接**
- `Document` 表: id, worldId, workId, filePath, currentSceneId

创建章节时 (`WorldService.createChapterWithDocument`, 第100-163行):
1. 创建 Chapter 记录
2. 创建 Document 记录（含 filePath 指向 `.md` 文件）
3. 创建 Scene 记录（含 documentId 指向 Document）
4. 写入 `# 标题\n\n` 到 `.md` 文件 ✅

### 实际出问题的代码路径

**`wg_editor_page.dart` → `_loadDocument()` (第124-140行):**

```dart
Future<void> _loadDocument() async {
  try {
    final db = await ServiceLocator.instance.databaseManager
        .getDatabase(widget.world.id);
    final docs = await db.select(db.documents).get();  // ❌ 取 ALL 文档
    if (docs.isNotEmpty) {
      final doc = docs.first;  // ❌ 硬取第一个文档
      final content = await _documentService.readContent(doc.filePath);
      if (mounted) {
        setState(() {
          _currentDocument = doc;          // ← 永远指向第一个文档
          _editorContent = content;        // ← 永远显示第一个文档内容
        });
      }
    }
  } catch (_) {}
}
```

**用户点击章节时的反应 (`_buildToc`, 第275行):**

```dart
onTap: () => setState(() => _currentChapter = i),
// ❌ 只更新了索引，没有重新加载文档
```

---

## 根因分析

### 🐛 Bug 1: 章节切换不加载对应文档（P0）

| 项目 | 内容 |
|------|------|
| **位置** | `wg_editor_page.dart:124-140` (`_loadDocument`) + `:275` (onTap) |
| **原因** | `_loadDocument()` 无条件加载所有文档并取第一个，而非根据当前章节加载 |
| **结果** | 无论点哪个章节，编辑器始终显示**同一个**文档内容 |

### 🐛 Bug 2: 章节→文档映射未使用（P0）

| 项目 | 内容 |
|------|------|
| **位置** | `wg_editor_page.dart:96-140` |
| **原因** | 数据库设计有 `Scene.documentId → Document` 的映射链路，但 UI 层完全没使用 |
| **结果** | 即使文档存在，也无法将章节和其正文文件关联 |

### 🐛 Bug 3: 第一个文档不存在时空内容（P0）

| 项目 | 内容 |
|------|------|
| **位置** | `wg_editor_page.dart:128-132` |
| **原因** | `if (docs.isNotEmpty)` 为空时不执行任何操作，`_editorContent` 保持空字符串 |
| **结果** | 当世界刚创建且尚无文档时，编辑器一片空白 |

---

## 修复方案

### Fix 1: 章节选中时加载对应文档

```dart
// 在 _buildToc 的 onTap 中（第275行附近）
onTap: () {
  setState(() => _currentChapter = i);
  _loadDocumentForChapter(_chapters[i]);  // ← 新增：加载对应章节的文档
},
```

### Fix 2: 新增按章节加载文档的方法

```dart
Future<void> _loadDocumentForChapter(db_model.Chapter chapter) async {
  try {
    final db = await ServiceLocator.instance.databaseManager
        .getDatabase(widget.world.id);
    // 1. 找到该章节下的所有场景
    final scenes = await (db.select(db.scenes)
          ..where((t) => t.chapterId.equals(chapter.id)))
        .get();
    if (scenes.isEmpty) return;

    // 2. 取第一个场景的 documentId
    final scene = scenes.first;
    
    // 3. 找到对应的 Document 记录
    final doc = await (db.select(db.documents)
          ..where((t) => t.id.equals(scene.documentId)))
        .getSingleOrNull();
    if (doc == null) return;

    // 4. 读取文件内容
    final content = await _documentService.readContent(doc.filePath);
    if (mounted) {
      setState(() {
        _currentDocument = db_model.Document(
          id: doc.id,
          projectId: '',  // 兼容旧接口
          title: chapter.title,
          filePath: doc.filePath,
        );
        _editorContent = content;
      });
    }
  } catch (_) {}
}
```

> 注：由于 `drift` 生成的 `Document` 类型与 `core/models/document.dart` 的 `Document` 类型不同（命名冲突），需要处理类型对齐。

### Fix 3: `initState` 时加载第一个章节

```dart
@override
void initState() {
  super.initState();
  _isDark = _settings.themeMode == ThemeMode.dark;
  _loadChapters();
  _loadCharacters();
  // 不在这里调 _loadDocument()，改在 _loadChapters 完成后触发
}

Future<void> _loadChapters() async {
  // ... 现有加载逻辑 ...
  if (mounted) {
    setState(() {
      _chapters = allChapters;
      _loadingChapters = false;
    });
    // 自动加载第一个章节的文档
    if (allChapters.isNotEmpty) {
      _loadDocumentForChapter(allChapters.first);
    }
  }
  // ...
}
```

---

## 影响范围

| 影响 | 说明 |
|------|------|
| **所有已创建的世界** | 只要有多章节，切换章节时都显示错误内容 |
| **新创建的世界** | 章节存在但编辑器可能显示空白 |
| **导出功能** | 不直接影响（导出用的是 DocumentService，走 ZVec） |
| **AI 生成** | 不影响 |

---

## 测试建议

1. 创建新世界 → 进入编辑器 → 应看到"第一章"的默认内容
2. 创建第二个章节 → 在 TOC 中点第二个章节 → 编辑器应切换显示
3. 在各章节间来回切换 → 每次切换编辑器内容应更新