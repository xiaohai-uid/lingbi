#!/bin/bash
# 灵笔 v4.0 全栈集成测试套件
# 运行: bash scripts/run-integration-tests.sh
# 前提: docker compose up -d 已运行
# 退出码: 0 = 全部通过, 1 = 有失败

set -e
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

check() {
    local name="$1"
    local cmd="$2"
    echo -n "  🔍 $name ... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        FAIL=$((FAIL + 1))
    fi
}

echo "=========================================="
echo " 灵笔 v4.0 全栈集成测试"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

# ===== Phase 1: 健康检查 =====
echo "--- Phase 1: 健康检查 ---"

check "API Gateway" "curl -sf http://localhost:8080/health"
check "AI Provider" "curl -sf http://localhost:8081/health"
check "Project Service" "curl -sf http://localhost:8082/health"
check "Document Service" "curl -sf http://localhost:8083/health"
check "Canon Service" "curl -sf http://localhost:8084/health"
check "Export Service" "curl -sf http://localhost:8085/health"
check "Version History" "curl -sf http://localhost:8086/health"
check "Settings Service" "curl -sf http://localhost:8087/health"
check "Quota Service" "curl -sf http://localhost:8088/health"
check "Storage Service" "curl -sf http://localhost:8089/health"
check "Sync Service" "curl -sf http://localhost:8090/health"
check "Canvas Service" "curl -sf http://localhost:8091/health"
check "Novel Engine" "curl -sf http://localhost:8092/health"
check "Quality Review" "curl -sf http://localhost:8093/health"
check "Timeline Service" "curl -sf http://localhost:8094/health"
check "Faction Service" "curl -sf http://localhost:8095/health"
check "Butterfly Analyzer" "curl -sf http://localhost:8096/health"

# ===== Phase 2: 核心 API =====
echo ""
echo "--- Phase 2: 核心 API ---"

# 2.1 Project Service
check "Create World" 'curl -sf -X POST http://localhost:8082/api/v1/worlds \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"测试世界\",\"description\":\"测试用\",\"genres\":[\"玄幻\"]}" | grep -q "id"'

WORLD_ID=$(curl -sf -X POST http://localhost:8082/api/v1/worlds \
  -H "Content-Type: application/json" \
  -d '{"name":"测试世界","description":"测试用","genres":["玄幻"]}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

check "List Worlds" "curl -sf http://localhost:8082/api/v1/worlds | grep -q '测试世界'"

# 2.2 Settings Service
check "Set Setting" 'curl -sf -X PUT http://localhost:8087/api/v1/settings/theme \
  -H "Content-Type: application/json" \
  -d "{\"value\":\"dark\"}" | grep -q "dark"'

check "Get Setting" "curl -sf http://localhost:8087/api/v1/settings/theme | grep -q 'dark'"

# 2.3 Quota Service
check "Quota Check" 'curl -sf -X POST http://localhost:8088/api/v1/quota/check \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"test\",\"model\":\"gpt-4o\"}" | grep -q "remaining"'

# 2.4 Novel Engine (requires AI Provider)
check "Novel Layer1" 'curl -sf -X POST http://localhost:8092/api/v1/novel/generate-layer1 \
  -H "Content-Type: application/json" \
  -d "{\"user_idea\":\"一个少年修仙的故事\",\"genre\":\"玄幻\",\"style\":\"qidian\"}" | grep -q "synopsis"'

# 2.5 Quality Review
check "Quality Hooks" 'curl -sf -X POST http://localhost:8093/api/v1/review/hooks \
  -H "Content-Type: application/json" \
  -d "{\"content\":\"他突然发现了一个惊天秘密，整个宗门都震怒了。\",\"genre\":\"玄幻\"}" | grep -q "density"'

# 2.6 Canon Service
check "Canon Create Character" 'curl -sf -X POST http://localhost:8084/api/v1/canon/characters \
  -H "Content-Type: application/json" \
  -d "{\"world_id\":\"test\",\"name\":\"张三\",\"description\":\"主角\",\"arc\":\"成长\",\"weight\":10}" | grep -q "张三"'

# 2.7 Sync Service
check "Sync Status" "curl -sf http://localhost:8090/api/v1/sync/status | grep -q 'status'"

# 2.8 Canvas Service
check "Canvas Nodes" "curl -sf http://localhost:8091/api/v1/canvas/nodes | grep -q '\\['"

# ===== Phase 3: 微服务间交互 =====
echo ""
echo "--- Phase 3: 服务间交互 ---"

# 3.1 Project → Document: Create scene → Save document
SCENE_ID=$(curl -sf -X POST http://localhost:8082/api/v1/scenes \
  -H "Content-Type: application/json" \
  -d '{"chapter_id":"test","title":"第一场","summary":"开场","sort_order":1}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

# 3.2 Version History: Snapshot → History → Diff
check "Version Snapshot" 'curl -sf -X POST "http://localhost:8086/api/v1/versions/test/snapshot" \
  -H "Content-Type: application/json" \
  -d "{\"content\":\"第一版正文\"}" | grep -q "version"'

check "Version History" "curl -sf 'http://localhost:8086/api/v1/versions/test/history' | grep -q 'version'"

# 3.3 Author → API Gateway (JWT auth)
check "Auth Login" 'curl -sf -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"test\",\"password\":\"test\"}" | grep -q "token"'

# ===== 汇总 =====
echo ""
echo "=========================================="
echo -e " 结果: ${GREEN}${PASS} 通过${NC}, ${RED}${FAIL} 失败${NC}"
echo "=========================================="

if [ $FAIL -gt 0 ]; then
    echo "❌ 部分测试未通过，请检查服务日志"
    exit 1
else
    echo "✅ 全部测试通过！"
    exit 0
fi