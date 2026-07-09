# 灵笔 Launcher README

## 一键启动所有微服务

双击运行 `lingbi_launcher.exe`，自动启动：
- API Gateway (:8080)
- AI Provider (:8081)
- Project (:8082)
- Document (:8083)
- Codex (:8084)
- Export (:8085)
- Version (:8086)
- Settings (:8087)
- Quota (:8088)
- Storage (:8089)
- Sync (:8090)
- Canvas (:8091)
- Flutter 客户端

## 启动模式

- **本地模式**: 直接启动 dart_frog/Node.js 子进程
- **Docker 模式**: 使用 docker-compose 启动容器
- **混合模式**: 本地启动 Flutter 客户端，远程连接 Docker 后端

## 系统托盘

- 左键点击: 显示/隐藏窗口
- 右键菜单: 启动/停止/退出

## 环境要求

- Dart SDK 3.6+ 或 Flutter 3.38+
- Node.js 20+
- Docker (Docker 模式需要)