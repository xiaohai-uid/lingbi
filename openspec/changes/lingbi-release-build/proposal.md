# 灵笔 Windows 桌面发布包 — OpenSpec 提案

## 概述

将灵笔从开发阶段的 Debug 模式构建为 **Release 桌面应用**，像 Clash Plus 那样：
- 双击 `lingbi.exe` 直接运行
- 不依赖 Flutter SDK / 命令行
- 包含所有运行时 DLL
- 带桌面快捷方式

## 参考项目

`D:\Program Files\Clash Plus\` — Flutter Release 构建结构：
```
Clash Plus/
├── MyClash.exe              ← 主程序
├── flutter_windows.dll      ← 引擎
├── *_plugin.dll             ← 插件 (12个)
├── data/
│   ├── flutter_assets/      ← 资源文件
│   └── icudtl.dat           ← 国际化
└── unins000.exe             ← 卸载程序
```

## 实施步骤

### 1. Release 构建
```bash
cd C:\Users\Administrator\Desktop\reasonix\lingbi
flutter build windows --release
```

### 2. 部署目录
将 `build\windows\x64\runner\Release\` 整个目录复制到 `D:\Program Files\灵笔\`

### 3. 创建桌面快捷方式
`lingbi.exe → 右键 → 发送到桌面快捷方式`

### 4. 命名
重命名 `lingbi.exe` → `灵笔.exe`

## 验证标准
- [ ] 双击 `灵笔.exe` 直接打开应用
- [ ] 编辑器可正常输入
- [ ] 项目创建/保存正常
- [ ] 不需要命令行