# 灵笔第二次圆桌会议：技术实现对照与执行方案

> **勘误 (2026-07-24)**：
> - 用户提供的第三个 URL `http://111.170.163.42:4650/` 实际对应 **OpenWrite App v1.2.6**，而非 DreamEngine。
> - “DreamEngine/幻海Opus”身份判断**废弃**。
> - 后续对照对象修正为：**灵笔、OpenWrite App (v1.2.6)、OpenWrite CLI (v5.8.0)**。

> 会议时间：2026-07-24（第二次）
> 触发：用户要求深入研究 http://111.170.163.42:4650/ (OpenWrite) 的技术细节
> 新增证据：OpenWrite Python CLI v5.8.0 源码（novel_service.py, context_package.py, project_lock.py）
> 新增证据：OpenWrite Flutter App v1.2.6 产品页面

---

## 关键新发现

### OpenWrite 是双产品线

| 产品 | 版本 | 技术栈 | 定位 |
|------|------|--------|------|
| OpenWrite App | v1.2.6 | Flutter (Windows + Android) | 面向作者的 GUI 写作工具 |
| OpenWrite CLI | v5.8.0 | Python 3.10+ | 长篇写作引擎（Agent 编排） |

**灵笔与 OpenWrite App 同为 Flutter 桌面端产品，直接竞争。**

### OpenWrite App (v1.2.6) 已实现的功能

| 功能 | 灵笔状态 | 差距 |
|------|---------|------|
| 三栏可调整布局 | ✓ 已有 | 持平 |
| 多模型支持 (10+) | ✓ 已有 (5+自定义) | 持平 |
| 项目管理 | ✓ 已有 | 持平 |
| 人物库 | ✓ 已有 (Canon) | 持平 |
| 世界观构建 | ✓ 已有 (Canon) | 持平 |
| 对话式 AI 创作 | ✓ 已有 | 持平 |
| AI 直接读写项目文件 | ✗ 缺失 | **落后** |
| AI 网页搜索 | ✗ 缺失 | 落后 |
| Skill 广场 | ✓ 已有 | 持平 |
| WebDAV 云同步 | ✗ 缺失 | 落后 |
| Word (.docx) 导出 | ✗ 缺失 (只有 MD/TXT/PDF) | 落后 |
| 风格蒸馏 | ✓ 已有 (analyzeStyle) | 持平 |
| 解压即用 | ✗ 缺失 (需要 Flutter 环境) | 落后 |
| Android 移动端 | ✗ 缺失 | 落后（非优先） |
| Anthropic 兼容 | ✓ 已有 (Claude Provider) | 持平 |
| 思考模型切换 | ✗ 缺失 | 落后 |

### OpenWrite CLI (v5.8.0) 核心技术实现

#### 1. NovelApplicationService（统一 Action Surface，769行）

```python
class NovelApplicationService:
    - 线程锁 (threading.Lock) 防并发
    - write_chapter(): 组装上下文 → 获取锁 → 执行写作 → 释放锁 → 记录工作流
    - review_chapter(): 获取锁 → 执行审稿 → 存储结果 → 记录工作流
    - multi_write(): 多 Agent 编排 (director/writer/reviewer)
    - assemble_packet(): 调用 ChapterAssemblerV2 组装 canonical packet
    - continuity(): 伏笔 DAG + truth files + 工作流状态
    - import_book() / export_book(): 旧稿导入/整书导出
    - extract_source() / promote_source() / synthesize_style(): 风格管线
    - update_focus() / clear_focus(): 创作罗盘管理
    - create_document(): 人物/世界文档创建
```

#### 2. GenerationContext（上下文包，231行 Pydantic 模型）

```python
class GenerationContext(BaseModel):
    # 基础
    novel_id, chapter_id
    author_intent: str          # 作者意图（永不截断）
    creative_focus: str         # 创作罗盘（永不截断）
    chapter_goals: List[str]    # 本章目标
    target_words: int = 6000    # 目标字数
    emotion_arc: str            # 章内情绪变化
    
    # 戏剧位置（核心创新）
    dramatic_context: Dict      # 篇弧线结构/情感走向/节张力/本章位置
    
    # 大纲
    outline_window: List        # 大纲窗口
    current_chapter: Any        # 当前章节节点
    
    # 角色
    active_characters: List     # 出场角色
    
    # 伏笔
    foreshadowing: ForeshadowingState  # pending/planted/resolved
    
    # 风格
    style_profile: Any          # 风格档案
    
    # 世界观
    world_rules: WorldRules     # 约束/实体/关系
    
    # 真相文件
    recent_text: str            # 最近章节文本
    current_state: str          # 世界当前状态
    ledger: str                 # 资源账本
    relationships: str          # 角色关系
    chapter_summaries: str      # 章节摘要
    
    # 方法
    estimate_tokens()           # 估算 token (中文 1.5 字/token)
    to_prompt_sections()        # 转为有序 prompt 段落
    to_prompt_context()         # 生成完整 prompt 文本
```

#### 3. ProjectWriteLock（跨进程锁，117行）

```python
class ProjectWriteLock:
    - 使用 os.O_CREAT | os.O_EXCL 原子创建锁文件
    - 锁文件: data/novels/{id}/data/workflows/project.lock
    - 内容: {token, pid, operation, created_at}
    - 过期检测: 6小时 或 进程不存在
    - 上下文管理器: with ProjectWriteLock(...):
    - 失败: raise ProjectBusyError
```

#### 4. 工作流生命周期

```python
# BookStage 枚举
CHAPTER_PREFLIGHT → WRITING → REVIEW_AND_REVISE → ...

# 写章后自动:
_record_write_lifecycle():
  1. 标记 context_assembly = completed
  2. 标记 writing = completed
  3. 更新 BookState (stage, current_chapter, last_agent_action)

# 审稿后自动:
_record_review_lifecycle():
  1. 提取 critical/warning issues
  2. 标记 review = completed
  3. 更新 BookState (passed → CHAPTER_PREFLIGHT, failed → REVIEW_AND_REVISE)
```

---

## 第二次圆桌决议：执行方案

### 参与者共识

基于 OpenWrite 源码级证据，与会者达成以下共识：

1. **灵笔与 OpenWrite App 在 GUI 层面差距不大**（三栏、多模型、Skill、正典）
2. **核心差距在"引擎层"**：灵笔没有 canonical packet、写作锁、工作流、状态结算
3. **OpenWrite 的 GenerationContext 模型可以直接借鉴设计**（不复制代码）
4. **ProjectWriteLock 的 O_EXCL 方案在 Windows 上需要适配**（Windows 不支持 O_EXCL）
5. **BookState 状态机是灵笔最急需的**：让 AI 知道"现在该做什么"

### 执行优先级重排

基于"用户预算有限 + 频繁使用便宜模型 + 强模型只做高价值决策"的约束：

| 优先级 | 任务 | 理由 | 工期 |
|--------|------|------|------|
| P0 | 修复 Novel Engine 递归 bug | 阻塞性 bug | 10分钟 |
| P1 | 实现 GenerationContext 模型 | 上下文治理基础 | 2天 |
| P2 | 实现 ContextAssembler | 组装上下文包 | 3天 |
| P3 | 实现 WritingPipeline 状态机 | 写作闭环 | 3天 |
| P4 | 实现 WriteLock (Windows 适配) | 可靠性 | 1天 |
| P5 | 实现候选区 + 采纳机制 | 作者控制权 | 2天 |
| P6 | 实现 Settlement (状态结算) | 长篇连续性 | 3天 |
| P7 | 实现创作罗盘 (intent + focus) | 方向控制 | 1天 |
| P8 | 实现模型路由 (按任务分配) | 成本控制 | 2天 |

### 立即执行清单（Phase 0 + Phase 1 启动）

```
1. 修复 services/novel-engine/main.dart 递归 bug
2. 创建 lib/modules/pipeline/ 目录结构
3. 实现 GenerationContext 数据模型 (Dart 版)
4. 实现 ContextAssembler 骨架
5. 实现 WritingPipelineState 状态机
6. 实现 WriteLockService (Windows 文件锁)
7. 实现 CandidateService (候选区管理)
8. 编写单元测试
```

---

## 技术对照：灵笔 vs OpenWrite 实现映射

| OpenWrite 文件 | 灵笔对应 | 实现方式 |
|---------------|---------|---------|
| novel_service.py | lib/modules/pipeline/novel_action_surface.dart | 新建 |
| context_package.py (GenerationContext) | lib/modules/pipeline/generation_context.dart | 新建 |
| chapter_assembler.py | lib/modules/pipeline/context_assembler.dart | 新建 |
| project_lock.py | lib/modules/pipeline/write_lock_service.dart | 新建（Windows 适配） |
| workflow_scheduler.py | lib/modules/pipeline/writing_pipeline_state.dart | 新建 |
| truth_manager.py | lib/modules/pipeline/truth_service.dart | 新建 |
| chapter_memory.py | lib/modules/pipeline/chapter_memory_service.dart | 新建 |
| foreshadowing_manager.py | lib/modules/narrative/foreshadowing_service.dart | Phase 5 |
| style_synthesizer.py | lib/services/ai_service.dart (analyzeStyle) | 已有，需升级 |
| source_pack.py | lib/modules/skill/source_pack_service.dart | Phase 8 |
| goethe.py | lib/modules/pipeline/planner_agent.dart | Phase 3 |
| chapter_pipeline.py | lib/modules/pipeline/writing_pipeline.dart | Phase 3 |
| review_store.py | lib/modules/pipeline/review_store.dart | Phase 4 |
| agent/book_state.py | lib/modules/pipeline/book_state.dart | 新建 |

---

## Windows 文件锁适配方案

OpenWrite 使用 `os.O_CREAT | os.O_EXCL`（POSIX 原子创建），Windows 上 Dart 的等价实现：

```dart
// Dart Windows 适配方案
class WriteLockService {
  Future<bool> acquire(String projectDir, String operation) async {
    final lockFile = File('$projectDir/.lingbi/project.lock');
    try {
      // Windows: 使用 FileMode.writeOnlyAppend + exclusive create
      final raf = await lockFile.open(mode: FileMode.writeOnly);
      // 写入锁信息
      await raf.writeString(jsonEncode({
        'pid': pid,
        'operation': operation,
        'created_at': DateTime.now().toIso8601String(),
      }));
      await raf.close();
      return true;
    } catch (e) {
      // 检查是否过期（6小时）
      if (await _isStale(lockFile)) {
        await lockFile.delete();
        return acquire(projectDir, operation); // 重试一次
      }
      return false;
    }
  }
}
```
