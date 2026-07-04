# Task 2: Settings Service 完善 (Node.js)

## 位置
`lingbi_server/microservices/settings/`

## 当前状态
基本骨架：service.js, storage.js, crypto.js, settings.json, package.json
缺少完整 REST API、AES-256 加密、配置验证、导入导出。

## 目标
完善设置管理 API，支持 AES-256 加密存储、配置验证、导入导出。

## 需要实现

### 1. service.js — 完整 Express 路由

| 端点 | 方法 | 说明 |
|------|------|------|
| `/settings` | GET | 获取所有设置 |
| `/settings/:key` | GET | 获取单个设置 |
| `/settings/:key` | PUT | 更新单个设置 |
| `/settings/encrypt` | POST | 加密存储敏感数据 |
| `/settings/decrypt` | POST | 解密读取敏感数据 |
| `/settings/export` | GET | 导出所有设置为JSON |
| `/settings/import` | POST | 从JSON导入设置 |
| `/settings/reset` | POST | 重置为默认设置 |
| `/settings/validate` | POST | 验证设置值 |
| `/settings/health` | GET | 健康检查 |

### 2. crypto.js — AES-256 加密/解密
- 使用 Node.js 内置 `crypto` 模块 (不要额外依赖)
- AES-256-GCM 加密模式
- `encrypt(text)` → 返回 hex 编码的加密字符串
- `decrypt(encryptedHex)` → 返回原文
- 密钥从环境变量 `SETTINGS_SECRET` 读取，默认使用设备指纹

### 3. storage.js — 加密 JSON 存储
- 读写 `settings.json` 文件
- 敏感字段（apiKey, secret, token）自动加密存储
- 读取时自动解密
- 支持设置验证规则

### 4. 默认设置
```json
{
  "theme": "system",
  "language": "zh-CN",
  "autoSave": true,
  "autoSaveInterval": 30,
  "fontSize": 16,
  "editorMode": "wysiwyg"
}
```

### 5. 单元测试 (≥10 个)
- 使用 Jest + Supertest
- 覆盖: 获取/更新设置、加密/解密、导入/导出、重置、验证、健康检查

## 端口
8087

## 质量要求
- `npm test` 全部通过
- 健康检查端点可用
- 敏感字段自动加密