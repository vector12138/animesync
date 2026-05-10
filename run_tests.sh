#!/bin/bash

set -e

echo "=== AnimeSync 项目完整测试 ==="
echo ""

cd /home/void/prj/animesync

# 创建虚拟环境
echo "[1/3] 创建虚拟环境..."
python3 -m venv .venv
source .venv/bin/activate
pip install -q pytest pytest-asyncio 2>/dev/null || true
echo "✓ 环境就绪"
echo ""

# 启动后端服务 (后台)
echo "[2/3] 启动后端服务..."
cd server
pkill -f "python app/main.py" 2>/dev/null || true
sleep 1
python app/main.py > /tmp/animesync_server.log 2>&1 &
SERVER_PID=$!
sleep 3

# 等待服务就绪
echo "  等待服务就绪..."
for i in {1..10}; do
  if curl -s http://localhost:8000/api/health | grep -q 'running'; then
    echo "✓ 服务已启动 (PID: $SERVER_PID)"
    break
  fi
  sleep 1
done

echo ""
echo "[3/3] 运行 Pytest..."
cd .. && PYTHONPATH=server pytest tests/ -v --tb=short 2>&1 || true

echo ""
echo "=== 测试完成 ==="
echo ""
echo "手动测试:"
echo "  服务器已运行: http://localhost:8000"
echo "  前端:          http://localhost:8000/index.html"
