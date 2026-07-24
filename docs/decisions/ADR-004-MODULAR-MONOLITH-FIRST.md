# ADR-004: 模块化单体优先 (Modular Monolith First)

## 状态

已接受 (2026-07-24)

## 背景

灵笔当前存在两套并行架构：
1. **桌面端**（`lib/`）：Flutter 模块化单体，ServiceLocator 注入，本地运行
2. **微服务**（`docker-compose.yml`）：15 个 Docker 服务（api-gateway, ai-provider, project, document, canon, export, version, settings, quota, storage, sync, canvas, novel-engine, quality-review, litellm）

问题：
- 桌面端完全不使用微服务（`lib/` 中无 HTTP 调用到 localhost:8080-8093）
- 15 个微服务对个人开发者维护成本过高
- Novel Engine 有递归 bug 从未成功启动
- 微服务之间没有实际数据流验证
- 用户以 Windows 桌面端为主要环境，不需要 Docker

## 决策

**采用模块化单体架构，暂停微服务作为运行依赖。**

具体：
1. 桌面端继续使用模块化单体（ServiceLocator + 模块接口）
2. 现有微服务代码保留为参考实现，不删除
3. docker-compose.yml 保留但不作为运行前提
4. LiteLLM 保留为可选的 Docker 部署（高级用户）
5. 新功能全部在 `lib/` 内以模块形式实现
6. 模块之间通过接口通信，未来如需拆分可拆

**模块划分：**
```
lib/
├── modules/
│   ├── project/        # 项目管理
│   ├── canon/          # 正典管理
│   ├── outline/        # 大纲管理
│   ├── pipeline/       # 写作流水线
│   ├── review/         # 审稿
│   ├── adoption/       # 采纳
│   ├── settlement/     # 结算
│   ├── narrative/      # 叙事追踪（承诺/剧情线/伏笔）
│   ├── worldline/      # 世界线 [Phase 6]
│   ├── memory/         # 记忆/RAG
│   ├── skill/          # 技能系统
│   └── model_router/   # 模型路由
```

## 理由

1. 个人开发者无法维护 15 个微服务的部署、监控和调试
2. 桌面端是单用户单进程，微服务的网络开销无意义
3. 模块化单体保留了未来拆分的可能性（接口隔离）
4. 用户约束"本地模式必须始终可用"与微服务依赖矛盾
5. 反方审查员指出"不为了微服务而增加微服务"
6. OpenWrite 也是单体架构（Python 包 + 本地 Studio）

## 后果

- 正面：部署简单（一个 exe 即可）
- 正面：调试简单（单进程，断点即可）
- 正面：无网络延迟（模块间直接调用）
- 正面：本地模式始终可用
- 负面：未来如需多人协作需要重新考虑
- 缓解：模块接口清晰，未来可拆分为服务
- 负面：现有微服务代码成为"死代码"
- 缓解：保留为参考，不删除，标记为 experimental

## 保留的微服务

| 服务 | 处置 | 理由 |
|------|------|------|
| LiteLLM | 保留为可选 Docker | 高级用户可能需要统一模型网关 |
| novel-engine | 保留代码，修复 bug | 3 层生成模型设计有参考价值 |
| quality-review | 保留代码 | 审查维度设计有参考价值 |
| 其余 12 个 | 保留 docker-compose，不维护 | 未来云端部署参考 |

## 来源

- 反方审查员："15 微服务是过度设计"
- 用户约束："本地模式必须始终可用"
- OpenWrite：单体 Python 包验证了长篇写作不需要微服务
- 圆桌会议投票：11/13 赞成，1 反对（成本工程师认为应保留 LiteLLM），1 弃权
