# ADR-002: World 作为核心实体

> 2026-07-06 | 状态: 已采纳

## 上下文

灵笔当前架构以 **Project（项目）** 为顶级实体，其模型设计于 P0 阶段，定位为"一本小说/作品的容器"：

```dart
class Project {
  String id;
  String name;
  String directoryPath;  // Documents/灵笔/{name}/
  DateTime createdAt;
  DateTime updatedAt;
}
```

经过 v3.1 完成和 grilling 会话确认，产品定位发生根本性转变：

> **灵笔不是「一本小说的编辑器」，而是一个「世界写作平台」**
> 
> 用户笔下从来不是一本小说，而是一个世界。
> 一个世界可以生长出多部作品（网文、剧本、游戏脚本）。

现有 Project 模型无法承载：
- 一个世界观产出多部叙事作品
- 角色权重按卷/事件动态调整
- 世界线分支（游戏编剧场景）
- 蝴蝶效应分析

## 决策

### 新顶级实体：World

```
World（世界）
├── 基础信息（名称、描述、类型分类）
├── Codex（世界观资产）
│   ├── Characters（角色）— 含全局权重
│   ├── Locations（地点）
│   ├── Lore（传说/设定）
│   └── WorldRules（世界观规则）
├── Timeline（世界线）
│   ├── Events（事件）— 含分支支持
│   └── ButterflyEffect（蝴蝶效应记录）
└── Works（叙事作品集）
    ├── Work A（如《青云传》网络小说）
    │   ├── Synopsis（总纲）
    │   ├── Volume 1（卷1）
    │   │   ├── WeightOverrides（卷级角色权重偏移）
    │   │   ├── Chapter 1…
    │   │   └── Chapter 2…
    │   ├── Volume 2…
    │   └── ...
    └── Work B（如同世界观游戏剧本）
        └── ...
```

### 关键设计原则

1. **World 拥有 Codex** — 角色/地点/规则属于世界，跨作品共享
2. **Works 引用 Codex** — 作品不拥有数据，只引用 + 叠加权重
3. **权重分层** — 全局权重 (World) → 卷偏移 (Volume) → 事件偏移 (Event)
4. **世界线可选** — 默认线性（网文模式），分支模式（游戏编剧模式）为开关选项
5. **向后兼容** — 现有 Project 数据通过迁移脚本转为 World + Work

## 后果

### 正面
- 承载多作品、世界线分支、蝴蝶效应等高级场景
- Codex 数据复用，避免多作品间重复输入
- 为游戏编剧场景打下基础（可导出到 Twine/Ren'Py 等引擎）

### 负面
- 需要数据迁移（现有 Project → World + Work）
- v3.2 只能实现核心骨架，全量特性需多版本迭代
- 复杂度增加，尤其是权重系统和蝴蝶效应引擎

### 迁移策略
- Phase 1: 新增 World 模型 + Work 模型，Project 保留兼容
- Phase 2: 自动迁移脚本：Project → World("默认世界") + Work("未命名作品")
- Phase 3: 废弃旧 Project 模型