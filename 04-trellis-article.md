---
title: Trellis 逛逛GitHub 风格文章（扩充版）
date: 2026-07-09
tags:
  - guanggua-github-style
  - article
  - trellis
status: draft
type: article
source: 微信文章 + GitHub README
---

# 这个 GitHub 上 1.2 万人点赞的 AI 编程框架，让团队规范再也不会失忆了。

Original 逛逛逛逛

逛逛GitHub

最近逛 GitHub Trending，看到一个挂着 Mindfold AI logo 的项目。

叫 Trellis。

乍一看，这又是一个 AI 编程框架。但仔细扫了一遍 README 和文档，发现它解决的东西跟其他框架不太一样——不是"怎么让 AI 写代码更快"，而是"怎么让 AI 记住你的规矩、守你的规矩"。

说实话，用过 AI 编程的人基本都遇到过这几种情况：

跟 Claude Code 聊了一下午，上下文一压缩，之前反复叮嘱的目录结构、命名规范，它转头就忘了。

CLAUDE.md 里写得清清楚楚"不要碰 tests 目录"，AI 大部分时候听话，但偶尔就是要给你搞个"惊喜"。

团队里三个人用三种 AI 编程工具（有人 Claude Code、有人 Cursor、有人 Codex），每个人喂给 AI 的规范都不一样，代码风格越写越野。

这三个问题的根源是同一件事：**AI 编程工具普遍缺一个团队级的记忆和管理层**。单靠一份 CLAUDE.md 或几个 Skill，解决的是"这一次对话"的问题，解决不了"这个项目、这个团队"的问题。

Trellis 就是冲这个来的。

---

01
**Trellis 是什么**

一句话定位：**团队级的 Agent Harness 框架，内置 LLM Wiki**。

GitHub 上目前 12k Star。

说白了，Trellis 把三样东西叠在一起：

- **Agent Harness（执行骨架）**：管 workflow 状态、hook、skill、子代理怎么调度
- **内置 LLM Wiki（知识库）**：Spec（团队规范）、Task（任务知识）、Journal（会话记忆）全部以文件形式存进仓库
- **团队层（协作层）**：这些文件全部 git 版本化，团队共享，同时适配 17 个不同的 AI 编程平台

这套架构解决了什么问题？往下看。

**核心抽象：Spec / Task / Journal**

Trellis 把 AI 编程中的"记忆"拆成了三份：

- **Spec（规范）**：放在 `.trellis/spec/` 下，每个文件覆盖一个主题——`error-handling.md`、`database.md`、`testing.md`。文件本身就小，不占上下文。执行任务时 AI 只把当前任务相关的 spec 写进 manifest，按需注入。
- **Task（任务）**：放在 `.trellis/tasks/<日期-名称>/` 下，每个任务有独立的 PRD、research 文件夹、implement.jsonl、check.jsonl。子代理只读当前 active task 的 jsonl，跨任务隔离。
- **Journal（会话记忆）**：放在 `.trellis/workspace/<你的名字>/` 下，每次任务完成自动追加。下次打开会话，AI 知道你上次做了什么、做到哪了。

**四阶段工作流**

Trellis 不是"你问 AI 答"的聊天模式，它走一条固定流程：

**① Plan（规划）**：`trellis-brainstorm` 子代理登场，一个一个问题问清楚需求，写下 PRD。如果涉及研究性内容，`trellis-research` 子代理单独去查。最终输出：一份清晰的 prd.md + 清单文件 implement.jsonl（点名 implement 阶段要读哪些 spec 文件）。

**② Implement（实现）**：`trellis-implement` 子代理上场，严格按照 PRD 写代码。注入的上下文完全由 implement.jsonl 控制——"只读这个任务需要的 4 个 spec"，50 万行的大仓库对 AI 来说跟一个 4 文件的项目差不多。写完后不自动 commit。

**③ Verify（审查）**：`trellis-check` 子代理审查刚才的代码改了什么、是否符合 spec、lint 和测试能不能过。发现问题直接自己改、重跑验证，不用你盯着。

**④ Finish（归档）**：确认没问题后，`trellis-update-spec` 把这次学到的经验写回 `.trellis/spec/`，然后归档任务、更新 journal。下次新会话，AI 自动读到这些沉淀。

```
开源地址：https://github.com/mindfold-ai/Trellis
```

**用个场景感受一下**

你维护一个老项目写了大半年。今天新来了个队友，他第一次打开项目、启动 AI 编程工具。

— 没有 Trellis：他要先翻半天文档，然后写一轮 prompt 告诉 AI 项目的代码风格、数据库约定、错误处理方式。AI 听不听看运气，过两天他又忘了再写一遍。

— 有 Trellis：`git pull` → `trellis init -u 他的名字` → 打开 AI 会话。Spec 自动注入该项目的所有规范，Journal 告诉他"上次改了支付模块，review 了一轮，还有一个边缘 case 没处理"。队友不用问任何人，直接开干。

Trellis 的核心思路就是"文件即记忆"——不靠模型记住，靠仓库里的文件重新加载。

---

02
**说实话的短板**

当然，也不是没有门槛。

首先得装 Node.js 18+ 和 Python 3.9+，然后在项目根目录跑初始化。首次配置大约 10-15 分钟。所以如果你只是偶尔写一次脚本、一个简单的 CLAUDE.md 就能搞定，那轻量方案更省事。

其次，Trellis 的工作流是设计给长期维护项目的。如果是做一周搞定的原型或者一次性脚本，这套框架反而显得重了——装依赖、跑初始化、建 task，走了三步活都干完了。

最后，Trellis 官方明确不建议和其他工作流框架混用。比如和 Superpowers、OpenSpec 这类框架同时跑，两者都想控制"当前该干什么"，谁来决定？两套阶段提示同时注入，AI 输出不可预期。出了问题你也不知道是哪个框架引起的。所以选一个就用到底，别混着来。

是不错，但如果是单人开发、项目不大、一口吐沫一个钉，那现有方案可能更省事。Trellis 更适合多人团队、长期项目、混合工具栈的场景。

---

03
**怎么上手**

第一步，装 Trellis CLI：

```bash
代码解读
复制代码
npm install -g @mindfoldhq/trellis@latest
```

第二步，在项目根目录初始化：

```bash
代码解读
复制代码
trellis init -u your-name
```

或者指定你实际在用的平台（省得生成多余文件）：

```bash
代码解读
复制代码
trellis init --cursor --opencode --codex -u your-name
```

第三步，打开配置好的 AI 会话，Trellis 会自动注入工作流。

首次配置约 10-15 分钟。之后每个新任务的流程是：用自然语言描述需求 → AI 走 brainstorm 帮你把需求理清 → implement 子代理写代码 → check 子代理自审 → 没问题敲 `/trellis:finish-work` 归档。

> 试试这样开始你的第一个任务：
> "分析一下当前项目的目录结构和代码风格，帮我写一份适合这个项目的 spec 规范文件，覆盖命名约定、错误处理和数据库操作三个主题。"

---

04
**作者背景**

Trellis 由 Mindfold AI 团队开发。这是一个专注于 AI 编程基础设施的团队，核心理念是"AI 写代码很快，但记不住项目规矩"——这个痛点驱动了整个项目的诞生。

项目从 2026 年 1 月开源，不到半年在 GitHub 上积累了 12k Star，npm 下载量持续上升。文档站 trytrellis.app 提供了中英文双语文档，涵盖快速开始、平台适配、真实场景案例和 FAQ。

---

05
**点击下方卡片，关注逛逛GitHub**

这个公众号历史发布过很多有趣的开源项目，如果你懒得翻文章一个个找，你直接关注微信公众号：逛逛 GitHub ，后台对话聊天就行了：

[二维码图片]