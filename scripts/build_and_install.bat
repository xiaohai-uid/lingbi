@echo off
chcp 65001 >nul
title 灵笔 — 构建启动器
echo ============================================
echo   灵笔 v3.0 — 构建启动器
echo ============================================
echo.
echo 本工具只需运行一次，之后双击 lingbi_launcher.exe 即可启动。
echo.

:: 1. 构建启动器
echo [1/3] 构建灵笔启动器...
cd /d "C:\Users\Administrator\Desktop\reasonix\lingbi"
call C:\Users\Administrator\Desktop\reasonix\flutter\flutter\bin\flutter.bat build windows --release -t launcher\lib\main.dart
if %ERRORLEVEL% neq 0 (
    echo [失败] 启动器构建失败
    pause
    exit /b 1
)
echo [完成] 启动器构建成功

:: 2. 构建灵笔主程序
echo [2/3] 构建灵笔主程序...
call C:\Users\Administrator\Desktop\reasonix\flutter\flutter\bin\flutter.bat build windows --release
if %ERRORLEVEL% neq 0 (
    echo [失败] 主程序构建失败
    pause
    exit /b 1
)
echo [完成] 主程序构建成功

:: 3. 复制启动器到桌面
echo [3/3] 创建桌面快捷方式...
copy "build\windows\x64\runner\Release\lingbi_launcher.exe" "%USERPROFILE%\Desktop\灵笔.exe" >nul
echo [完成] 桌面快捷方式已创建

echo.
echo ============================================
echo   ✅ 全部完成！
echo.
echo   以后只需双击桌面「灵笔」图标即可启动。
echo ============================================
pause