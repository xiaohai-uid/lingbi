# ADR-002: 唯一真源 (Single Source of Truth)

## 状态

已接受 (2026-07-24)

## 背景

灵笔当前数据存储分散：
- 正文：.md 文件（磁盘）
- 元数据：ZVec（Windows 降级为 JSON）
- 正典：ZVec/JSON
- 设置：JSON + 环境变量

问题：没有明确的"哪个是权威来源"。如果 ZVec 和 .md 文件冲突，以谁为准？

OpenWrite 的解决方案：`src/` 是唯一真源，`data/` 是运行态缓存。

## 决策

**Markdown 文件是正文和正典的唯一真源。**

分层规则：
| 层 | 格式 | 角色 | 可否作为事实来源 |
|----|------|------|----------------|
| Markdown | .md + YAML frontmatter | 正文 + 正典真源 | ✓ 唯一真源 |
| JSON | .json | 运行态（角色状态、承诺等） | ✓ 运行态真源 |
| SQLite | .db | 索引和检索 | ✗ 可重建 |
| 向量库 | ZVec/JSON | 相似度搜索辅助 | ✗ 非事实来源 |

冲突规则：
- Markdown 与 JSON 冲突 → Markdown 为准
- 向量索引与 Markdown 冲突 → Markdown 为准
- 用户手工编辑 .md → 触发 sync 更新派生数据

## 理由

1. Markdown 人可读可编辑，不依赖任何工具
2. 符合用户约束"正式小说资料不能依赖某个 SaaS 才能读取"
3. OpenWrite 验证了 src/ (Markdown) vs data/ (运行态) 分离的有效性
4. 向量库是概率性的，不能作为确定性事实来源
5. SQLite 索引可以从 Markdown 重建，不是真源

## 后果

- 正面：数据永远可读（纯文本编辑器即可）
- 正面：冲突解决规则明确
- 正面：索引损坏可重建
- 负面：需要 sync 机制保持派生数据一致
- 负面：Markdown 查询性能不如数据库（通过 SQLite 索引缓解）

## 来源

- OpenWrite：src/ vs data/ 分离
- 用户约束："正式小说资料不能依赖某个 SaaS 才能读取"
- 圆桌会议投票：13/13 赞成
