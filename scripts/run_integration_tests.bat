@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo   灵笔 v2.0 集成测试启动器
echo ============================================
echo.

set "LINGBI_DIR=C:\Users\Administrator\Desktop\reasonix\lingbi"
set "COMPOSE_FILE=%LINGBI_DIR%\docker-compose.yml"

:: Step 1: 启动 Docker 容器
echo [1/4] 启动 Docker 微服务容器...
cd /d "%LINGBI_DIR%"
docker compose -f "%COMPOSE_FILE%" up -d
if %ERRORLEVEL% neq 0 (
    echo [错误] Docker Compose 启动失败
    echo 请确认 Docker Desktop 正在运行
    pause
    exit /b 1
)
echo [完成] 容器已启动，正在等待就绪...
echo.

:: Step 2: 等待微服务就绪
echo [2/4] 等待微服务就绪...
set "READY_COUNT=0"
set "TOTAL_SERVICES=12"

:WAIT_LOOP
set "READY_NOW=0"
for %%p in (8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090 8091) do (
    curl -s http://localhost:%%p/health >nul 2>&1
    if !ERRORLEVEL! equ 0 set /a "READY_NOW+=1"
)
set /a "READY_COUNT+=1"
echo   [尝试 !READY_COUNT!/15] !READY_NOW!/%TOTAL_SERVICES% 服务已就绪
if !READY_NOW! lss %TOTAL_SERVICES% (
    if !READY_COUNT! lss 15 (
        timeout /t 2 /nobreak >nul
        goto WAIT_LOOP
    ) else (
        echo [警告] 部分服务未就绪，继续执行测试...
    )
) else (
    echo [完成] 所有微服务已就绪！
)
echo.

:: Step 3: 运行集成测试
echo [3/4] 运行 Flutter 集成测试...
cd /d "%LINGBI_DIR%"
flutter test integration_test/ --reporter expanded
set "TEST_EXIT=%ERRORLEVEL%"

if %TEST_EXIT% equ 0 (
    echo [完成] 所有集成测试通过！
) else (
    echo [失败] 部分测试未通过 (exit code: %TEST_EXIT%)
)
echo.

:: Step 4: 清理 Docker 容器
echo [4/4] 清理 Docker 容器...
docker compose -f "%COMPOSE_FILE%" down
echo [完成] 容器已停止

echo.
echo ============================================
if %TEST_EXIT% equ 0 (
    echo 结果: 全部通过 ✅
) else (
    echo 结果: 部分失败 ❌ (exit code: %TEST_EXIT%)
)
echo ============================================

exit /b %TEST_EXIT%