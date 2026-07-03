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
- 运行 `flutter test` 确保所有测试通过
- 新增功能需添加测试覆盖

### Pull Request 检查清单

- [ ] `flutter analyze` 通过
- [ ] `flutter test` 全部通过
- [ ] 代码符合 Effective Dart 规范
- [ ] 添加了必要的测试
- [ ] 更新了相关文档

## 问题反馈

如有问题或建议，请提交 [Issue](https://github.com/YOUR_USERNAME/lingbi/issues)。