# 贡献指南

感谢你考虑为灵笔做出贡献！

## 开发流程

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feat/your-feature`
3. 提交更改：`git commit -m "feat: add your feature"`
4. 推送分支：`git push origin feat/your-feature`
5. 提交 Pull Request

## 开发规范

### 代码风格

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 指南
- 使用 `dart format` 格式化代码
- 所有文件必须通过 `flutter analyze` (0 error 0 warning)

### 提交信息格式

使用 Conventional Commits：

```
<type>: <description>

feat:    新功能
fix:     Bug 修复
docs:    文档变更
refactor:代码重构
test:    测试相关
chore:   构建/工具
```

### 测试

- 所有代码必须有对应测试
- 客户端: 运行 `flutter test` 确保所有测试通过
- 微服务: 每个微服务至少 10 个测试，运行 `dart test` 确保通过
- 新增功能需添加测试覆盖

### 微服务开发

微服务位于 `lingbi_server/microservices/` 下，每个微服务是一个独立的 Dart/Node.js 项目。

```
lingbi_server/microservices/
├── ai/           # AI Provider (Dart, :8081)
├── project/      # 项目管理 (Dart, :8082)
├── document/     # 文档管理 (Dart, :8083)
├── canon/        # 正典条目 (Dart, :8084)
├── export/       # 导出服务 (Dart, :8085)
├── version/      # 版本历史 (Dart, :8086)
├── settings/     # 用户设置 (Node.js, :8087)
├── quota/        # AI 配额 (Dart, :8088)
├── storage/      # 向量存储 (Dart, :8089)
├── sync/         # 文件同步 (Dart, :8090)
└── canvas/       # 故事画布 (Node.js, :8091)
```

开发流程：

```bash
# 进入微服务目录
cd lingbi_server/microservices/<service_name>

# 安装依赖
dart pub get   # 或 npm install (Node.js 服务)

# 启动服务
dart run bin/server.dart --port <PORT>

# 运行测试
dart test
```

所有微服务必须实现 `GET /health` 端点，返回 `{"status":"ok","service":"<name>"}`.

### 启动器 (Launcher) 开发

启动器是独立的 Flutter Desktop 项目，位于 `launcher/` 目录：

```bash
cd launcher
flutter pub get
flutter run -d windows
flutter test
```

### Pull Request 检查清单

- [ ] `flutter analyze` 通过 (0 error)
- [ ] `flutter test` 全部通过
- [ ] 微服务测试全部通过 (如涉及)
- [ ] 代码符合 Effective Dart 规范
- [ ] 添加了必要的测试
- [ ] 更新了相关文档
- [ ] Docker 构建正常 (如涉及 docker-compose 变更)
- [ ] 无 Codex 残留引用 (应使用 Canon)

## 问题反馈

如有问题或建议，请提交 [Issue](https://github.com/YOUR_USERNAME/lingbi/issues)。