# 三层生成管线 — Spec

## 目标

从 AI_NovelGenerator 的 `expand_idea_service.py` (44KB) 移植三层小说生成架构到灵笔，作为独立微服务 `novel-engine` 运行在 `:8092`。

## 三层架构

```
Layer 1: 梗概·人设
  ├─ 用户输入创意（100-500 字）
  ├─ AI 生成完整故事梗概
  ├─ AI 生成核心人设（主角/配角/反派）
  └─ 输出: SynopsisAndCharacters

Layer 2: 卷·章细纲
  ├─ 基于 Layer 1 输出
  ├─ 生成分卷结构
  ├─ 每卷生成章节细纲
  ├─ 每章包含 3-5 个场景
  └─ 输出: LayeredNovelStructure (VolumeOutline[])

Layer 3: 逐场景正文生成
  ├─ 基于 Layer 2 输出
  ├─ 逐场景生成正文（可并行）
  ├─ 每场景 500-2000 字
  └─ 输出: 完整章节正文
```

## 流式支持

- Layer 1-2: 非流式（结构化输出，需完整 Schema 验证）
- Layer 3: 流式生成（SSE），逐场景逐个 chunk 推送到 Flutter 客户端

## 降级策略

```
三层生成 → 降级为 expand_idea_v2（单层生成） → 降级为直接 LLM 调用
```

## 结构化输出

使用 Function Calling / 结构化生成确保输出符合 Schema：

```dart
class SynopsisAndCharacters {
  String synopsis;        // 500-1000 字完整故事梗概
  List<CharacterProfile> characters;  // 3-8 个人物
  String setting;         // 时代/世界设定
  List<String> themes;    // 核心主题
}

class VolumeOutline {
  String title;
  String summary;
  List<ChapterOutline> chapters;
}

class ChapterOutline {
  String title;
  String summary;
  List<SceneOutline> scenes;
}
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `lingbi_server/microservices/novel-engine/main.dart` | 微服务入口 |
| `lingbi_server/microservices/novel-engine/lib/layer1_generator.dart` | Layer 1 生成器 |
| `lingbi_server/microservices/novel-engine/lib/layer2_generator.dart` | Layer 2 生成器 |
| `lingbi_server/microservices/novel-engine/lib/layer3_generator.dart` | Layer 3 生成器 |
| `lingbi_server/microservices/novel-engine/lib/structure_models.dart` | 数据模型 |
| `lingbi_server/microservices/novel-engine/lib/retry_handler.dart` | 重试逻辑 |
| `lingbi_server/microservices/novel-engine/routes/` | API 路由 |
| Docker 更新 | docker-compose.yml 添加 novel-engine 服务 |

## API 设计

```
POST /novel/generate-layer1
  Request:  { userIdea: string, genre: string, style: string }
  Response: { synopsis, characters, setting, themes }

POST /novel/generate-layer2
  Request:  { layer1: SynopsisAndCharacters, numVolumes: int }
  Response: { volumes: VolumeOutline[] }

POST /novel/generate-layer3 (SSE)
  Request:  { volumeIndex: int, chapterIndex: int, sceneIndex: int }
  Response: Stream<{ chunk: string, sceneComplete: bool }>
```