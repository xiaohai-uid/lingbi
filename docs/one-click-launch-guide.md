只需在命令行运行一次以下两个命令，以后就可以双击桌面图标启动了：

### 第一步：构建启动器 + 主程序

```bash
cd C:\Users\Administrator\Desktop\reasonix\lingbi

# 1. 构建启动器
C:\Users\Administrator\Desktop\reasonix\flutter\flutter\bin\flutter.bat build windows --release -t launcher\lib\main.dart

# 2. 构建主程序
C:\Users\Administrator\Desktop\reasonix\flutter\flutter\bin\flutter.bat build windows --release

# 3. 复制到桌面（可选）
copy build\windows\x64\runner\Release\lingbi_launcher.exe %USERPROFILE%\Desktop\灵笔.exe
```

### 第二步：双击启动

构建完成后，双击桌面 `灵笔.exe`，启动器会：

1️⃣ 显示所有 15 个服务的状态面板（12 个旧服务 + 2 个 v3.0 新服务 + 灵笔主程序）  
2️⃣ 点击 **"启动全部"** → 自动启动所有微服务 + 打开灵笔主界面  
3️⃣ 系统托盘驻留 → 右键可停止/重启单个服务  
4️⃣ 内置日志查看器 → 每个服务的实时日志

### 启动模式

启动器支持 3 种模式（右上角设置菜单切换）：

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| **本地** | 直接启动 Dart/Node.js 子进程 | 日常开发 |
| **Docker** | 通过 docker-compose 启动容器 | 生产/测试 |
| **混合** | 本地 Flutter 客户端 + Docker 后端 | 灵活部署 |

### 灵笔 v3.0 更新内容（launcher 已适配）

- ✅ 新增 `Novel Engine :8092` — 三层生成管线
- ✅ 新增 `Quality Review :8093` — 质量审查服务
- ✅ 新增 `Lingbi Client` — 自动启动主程序
- ✅ 系统托盘 + 日志查看器
- ✅ 自动健康检查 + 状态指示