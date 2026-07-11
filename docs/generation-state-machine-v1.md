# AI 生成流程状态机 — 精准逻辑设计 v1

> 设计目标: 覆盖所有状态、所有边界情况、所有错误路径
> 使用方式: 你审阅确认后，我按此逻辑实现 Dart 代码，你再喂给你的 UI 工具

---

## 1. 状态图谱

```
                    ┌─────────┐
                    │  idle   │
                    └────┬────┘
                         │ 用户输入创意
                    ┌────▼────┐
                    │  ready  │ ← 可以修改输入
                    └────┬────┘
                         │ 点击"生成梗概"
              ┌──────────┼──────────┐
              │          │          │
         ┌────▼────┐    │    ┌─────▼─────┐
         │generating│    │    │  error    │ ← 网络/API/配额错误
         │ synopsis │    │    └─────┬─────┘
         └────┬────┘    │          │ 重试
              │ 完成     │     ┌────▼────┐
         ┌────▼────┐    │     │  ready  │
         │reviewing│    │     └─────────┘
         │ synopsis│────┘ 不满意→重来
         └────┬────┘
              │ 确认
         ┌────▼────┐
         │generating│
         │ outline │
         └────┬────┘
              │ 完成
         ┌────▼────┐
         │reviewing│←──────────┐
         │ outline │  不满意   │
         └────┬────┘  重来    │
              │ 确认           │
         ┌────▼───────┐       │
         │ generating │       │
         │  content   │       │
         └────┬───────┘       │
       ┌──────┼──┬─────┐      │
       │      │  │     │      │
   ┌───▼──┐ ┌─▼─┐ │ ┌──▼───┐ │
   │paused│ │err│ │ │completed│
   └───┬──┘ └───┘ │ └───────┘
       │ 恢复      │
       └───────────┘
```

## 2. 状态定义

```typescript
// === 所有可能的状态 ===
type GenerationState =
  | { type: 'idle' }
  | { type: 'ready'; input: GenerationInput }
  | { type: 'generating_synopsis'; input: GenerationInput; meta: GenerationMeta }
  | { type: 'reviewing_synopsis'; input: GenerationInput; result: SynopsisResult }
  | { type: 'generating_outline'; input: GenerationInput; synopsis: SynopsisResult; meta: GenerationMeta }
  | { type: 'reviewing_outline'; input: GenerationInput; result: OutlineResult }
  | { type: 'generating_content'; input: GenerationInput; plan: OutlineResult; currentChapter: number; meta: GenerationMeta }
  | { type: 'paused'; input: GenerationInput; snapshot: PausedSnapshot }
  | { type: 'completed'; input: GenerationInput; result: NovelResult }
  | { type: 'error'; input: GenerationInput; error: GenerationError; from: GenerationState['type'] }
  | { type: 'cancelled'; input: GenerationInput }
```

## 3. 数据结构

```typescript
// === 输入 ===
interface GenerationInput {
  idea: string;           // 用户创意，非空校验：trim后长度≥10
  genre: string;          // 类型，必选：玄幻/仙侠/都市/科幻/悬疑/言情/轻小说
  style: string;          // 风格，必选：起点爆款/番茄爽文/传统文学/轻小说
  targetWords?: number;   // 目标字数，可选，默认 3000
}

// === 生成元数据 ===
interface GenerationMeta {
  startedAt: number;          // 开始时间戳
  phaseStartedAt: number;     // 当前阶段开始时间
  tokensUsed: number;         // 已使用 token 数
  streamedContent: string;    // 流式内容缓冲区
}

// === 各阶段结果 ===
interface SynopsisResult {
  synopsis: string;           // 故事梗概（≥500字）
  characters: Character[];    // 核心角色列表
  worldSettings: string;      // 世界观设定
  coreTheme: string;          // 核心主题
}

interface Character {
  name: string;               // 非空
  role: 'protagonist' | 'supporter' | 'antagonist' | 'side';
  personality: string;        // 性格描述
  arc: string;                // 成长弧光
}

interface OutlineResult {
  volumes: VolumeOutline[];   // 至少 1 卷
}

interface VolumeOutline {
  number: number;             // 卷号
  title: string;              // 卷名
  chapters: ChapterOutline[]; // 至少 3 章
}

interface ChapterOutline {
  number: number;             // 章号
  title: string;              // 章名
  summary: string;            // 本章概要（≥50字）
  scenes: SceneOutline[];     // 至少 1 个场景
}

interface SceneOutline {
  number: number;
  title: string;
  summary: string;
  characters: string[];       // 出场角色名
  location: string;
}

interface NovelResult {
  synopsis: SynopsisResult;
  outline: OutlineResult;
  chapters: ChapterContent[];   // 已生成的章节内容
}

interface ChapterContent {
  number: number;
  title: string;
  content: string;            // 正文（≥2000字）
  wordCount: number;
  generatedAt: number;
}

// === 暂停快照 ===
interface PausedSnapshot {
  state: GenerationState['type'];   // 暂停前的状态
  partialContent: string;           // 已生成的部分
  currentChapter?: number;
}

// === 错误 ===
interface GenerationError {
  code: 'NETWORK' | 'API_KEY_INVALID' | 'QUOTA_EXCEEDED' | 'TIMEOUT' | 'INVALID_OUTPUT' | 'UNKNOWN';
  message: string;
  retryable: boolean;         // 是否可以重试
  retryAfter?: number;        // 建议等待秒数
}
```

## 4. 状态转换矩阵

| 当前状态 | 事件 | 下一状态 | 前置条件 |
|----------|------|----------|----------|
| `idle` | `SET_INPUT` | `ready` | input.idea.trim().length >= 10 |
| `idle` | `SET_INPUT` | `idle` | ❌ 输入不足10字，不转换 |
| `ready` | `SET_INPUT` | `ready` | 更新 input |
| `ready` | `START_GENERATION` | `generating_synopsis` | 配额检查通过 |
| `ready` | `START_GENERATION` | `error` | 配额不足 |
| `generating_synopsis` | `STREAM_CHUNK` | `generating_synopsis` | 追加到 streamedContent |
| `generating_synopsis` | `PHASE_COMPLETE` | `reviewing_synopsis` | 输出解析成功（含 characters） |
| `generating_synopsis` | `PHASE_COMPLETE` | `generating_synopsis` | ❌ 输出不完整，要求重新生成 |
| `generating_synopsis` | `CANCEL` | `cancelled` | |
| `generating_synopsis` | `ERROR` | `error` | |
| `reviewing_synopsis` | `CONFIRM` | `generating_outline` | |
| `reviewing_synopsis` | `REJECT` | `ready` | 保留原始 input |
| `reviewing_synopsis` | `EDIT_INPUT` | `ready` | 修改 input 后重新开始 |
| `generating_outline` | `STREAM_CHUNK` | `generating_outline` | |
| `generating_outline` | `PHASE_COMPLETE` | `reviewing_outline` | |
| `generating_outline` | `CANCEL` | `cancelled` | |
| `generating_outline` | `ERROR` | `error` | |
| `reviewing_outline` | `CONFIRM` | `generating_content` | |
| `reviewing_outline` | `REJECT` | `ready` | |
| `generating_content` | `STREAM_CHUNK` | `generating_content` | |
| `generating_content` | `CHAPTER_COMPLETE` | `generating_content` | currentChapter++ |
| `generating_content` | `ALL_COMPLETE` | `completed` | |
| `generating_content` | `PAUSE` | `paused` | |
| `generating_content` | `CANCEL` | `cancelled` | |
| `generating_content` | `ERROR` | `error` | |
| `paused` | `RESUME` | `generating_content` | |
| `paused` | `CANCEL` | `cancelled` | |
| `error` | `RETRY` | 恢复 `from` 状态 | |
| `error` | `CANCEL` | `cancelled` | |
| `cancelled` | `RESET` | `ready` | 保留 input |
| `completed` | `RESET` | `idle` | |
| `completed` | `CONTINUE_EDITING` | `idle` | 进入编辑器 |
| ANY | `RESET_ALL` | `idle` | 强制重置 |

## 5. 边界情况清单

### 输入校验
- [ ] idea 为空字符串 → 不允许提交
- [ ] idea 只有空格 → trim 后拒绝
- [ ] idea 长度 < 10 字 → 提示"创意至少10个字"
- [ ] genre 不在预定义列表中 → 默认 fallback 到"玄幻"
- [ ] style 不在预定义列表中 → 默认 fallback 到"起点爆款"

### 生成过程
- [ ] 网络断开 → error.code = NETWORK，retryable = true
- [ ] API Key 无效 → error.code = API_KEY_INVALID，retryable = false
- [ ] 配额耗尽 → error.code = QUOTA_EXCEEDED，retryable = false
- [ ] 生成超时（>120秒）→ error.code = TIMEOUT，retryable = true
- [ ] AI 输出格式异常（无法解析）→ 自动重试 1 次，仍失败则报 INVALID_OUTPUT
- [ ] 用户在 streaming 过程中多次快速点击取消 → 保证只取消一次（幂等）
- [ ] 组件卸载时正在生成 → 自动 cancel（避免内存泄漏）
- [ ] 流式内容缓冲区超过 50KB → 截断，只保留尾部 50KB

### 状态机安全
- [ ] 非法转换（如从 idle 直接 CONFIRM）→ 静默忽略，不抛异常
- [ ] 重复事件（如两次 STREAM_CHUNK 中间没有状态变化）→ 幂等处理
- [ ] 并发事件（用户同时点取消和确认）→ 按时间戳先后顺序，后者覆盖前者

## 6. 事件定义

```typescript
type GenerationEvent =
  | { type: 'SET_INPUT'; input: GenerationInput }
  | { type: 'START_GENERATION' }
  | { type: 'STREAM_CHUNK'; chunk: string }
  | { type: 'PHASE_COMPLETE'; output: SynopsisResult | OutlineResult }
  | { type: 'CHAPTER_COMPLETE'; content: ChapterContent }
  | { type: 'ALL_COMPLETE'; result: NovelResult }
  | { type: 'CONFIRM'; feedback?: string }
  | { type: 'REJECT'; reason?: string }
  | { type: 'EDIT_INPUT'; input: GenerationInput }
  | { type: 'PAUSE' }
  | { type: 'RESUME' }
  | { type: 'CANCEL' }
  | { type: 'RETRY' }
  | { type: 'RESET' }
  | { type: 'RESET_ALL' }
  | { type: 'ERROR'; error: GenerationError }
```

## 7. Dart 实现要点

```dart
// 推荐实现方式: sealed class + 模式匹配
sealed class GenerationState {}

class IdleState extends GenerationState {}
class ReadyState extends GenerationState {
  final GenerationInput input;
  ReadyState(this.input);
}
class GeneratingSynopsisState extends GenerationState {
  final GenerationInput input;
  final GenerationMeta meta;
  GeneratingSynopsisState(this.input, this.meta);
}
// ... 其余状态类似

// 转换函数: pure function
GenerationState transition(GenerationState current, GenerationEvent event) {
  return switch ((current, event)) {
    (IdleState(), SetInputEvent(:final input)) when input.isValid => ReadyState(input),
    (IdleState(), _) => current, // 忽略非法转换
    (ReadyState(:final input), StartGenerationEvent()) => GeneratingSynopsisState(input, GenerationMeta.initial()),
    (GeneratingSynopsisState(:final input, :final meta), StreamChunkEvent(:final chunk)) =>
      GeneratingSynopsisState(input, meta.copyWith(streamedContent: meta.streamedContent + chunk)),
    // ... 其他转换
    _ => current, // 默认忽略非法转换
  };
}
```