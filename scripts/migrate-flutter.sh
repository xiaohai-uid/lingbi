#!/bin/bash
# 灵笔 v4.0 Flutter 前端重构脚本
# 运行方式: 从项目根目录执行 bash scripts/migrate-flutter.sh
# 作用: 删除旧业务逻辑文件，替换为 gRPC 客户端

set -e

echo "=== 灵笔 v4.0 Flutter 重构脚本 ==="
echo ""

# 1. 删除旧业务逻辑
echo "[1/4] 删除旧业务逻辑层..."
rm -rf lib/services/
rm -rf lib/core/database/
rm -rf lib/core/di/
rm -rf lib/core/file_system/
rm -rf lib/data/
echo "  ✅ 已删除: services/ core/database/ core/di/ core/file_system/ data/"

# 2. 添加 gRPC 客户端
echo "[2/4] 添加 gRPC 客户端层..."
mkdir -p lib/grpc/generated
echo "  ✅ 已创建: lib/grpc/ 目录"

# 3. 更新 pubspec.yaml
echo "[3/4] 更新依赖..."
# 注意: 手动更新 pubspec.yaml:
# 删除: drift, sqlite3_flutter_libs, path_provider, file_picker
# 添加: grpc, protobuf, fixnum

# 4. 更新 main.dart
echo "[4/4] 更新 main.dart 入口..."
# 添加 gRPC 初始化:
# void main() async {
#   WidgetsFlutterBinding.ensureInitialized();
#   await GrpcClientFactory.instance.init(host: 'localhost', port: 50051);
#   runApp(LingbiApp());
# }

echo ""
echo "=== 重构完成 ==="
echo "下一步: 手动更新 pubspec.yaml 依赖"
echo "然后运行: flutter pub get && flutter analyze"