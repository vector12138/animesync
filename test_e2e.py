"""端到端集成测试：注册 -> 登录 -> 受保护API调用"""
import asyncio
import httpx
import json
from datetime import datetime

BASE_URL = "http://127.0.0.1:8000"

# 测试数据
TEST_USERNAME = f"test_autogen_{int(datetime.now().timestamp())}"
TEST_PASSWORD = "TestPass123!"
TEST_EMAIL = f"test_{int(datetime.now().timestamp())}@example.com"


async def test_full_flow():
    async with httpx.AsyncClient(timeout=10.0) as client:
        print("🚀 开始端到端测试...\n")

        # 1. 健康检查
        print("1️⃣ 健康检查")
        resp = await client.get(f"{BASE_URL}/api/health")
        print(f"   GET /api/health -> {resp.status_code}")
        assert resp.status_code == 200
        print(f"   ✓ 服务运行中\n")

        # 2. 用户注册
        print("2️⃣ 用户注册")
        register_data = {
            "username": TEST_USERNAME,
            "email": TEST_EMAIL,
            "password": TEST_PASSWORD
        }
        resp = await client.post(f"{BASE_URL}/api/auth/register", json=register_data)
        print(f"   POST /api/auth/register -> {resp.status_code}")
        if resp.status_code != 200:
            print(f"   错误响应: {resp.text}")
        assert resp.status_code == 200, f"注册失败: {resp.text}"
        print(f"   ✓ 注册成功: {TEST_USERNAME}\n")

        # 3. 用户登录
        print("3️⃣ 用户登录")
        login_data = {"username": TEST_USERNAME, "password": TEST_PASSWORD}
        resp = await client.post(f"{BASE_URL}/api/auth/login", json=login_data)
        print(f"   POST /api/auth/login -> {resp.status_code}")
        assert resp.status_code == 200, f"登录失败: {resp.text}"
        token = resp.json()["data"]["access_token"]
        print(f"   ✓ 获取 token（长度 {len(token)} 字符）\n")

        # 设置 Authorization 头
        headers = {"Authorization": f"Bearer {token}"}

        # 4. 获取当前用户信息
        print("4️⃣ 获取当前用户信息")
        resp = await client.get(f"{BASE_URL}/api/auth/me", headers=headers)
        print(f"   GET /api/auth/me -> {resp.status_code}")
        if resp.status_code != 200:
            print(f"   错误响应: {resp.text}")
        assert resp.status_code == 200, f"获取用户信息失败: {resp.text}"
        user_info = resp.json()["data"]
        print(f"   ✓ 用户 ID: {user_info['id']}, 用户名: {user_info['username']}\n")

        # 5. 创建番剧进度
        print("5️⃣ 创建番剧进度")
        progress_data = {
            "title": "测试番剧",
            "status": "watching",
            "watched_episodes": 1,
            "notes": "集成测试创建"
        }
        resp = await client.post(f"{BASE_URL}/api/progress", json=progress_data, headers=headers)
        print(f"   POST /api/progress -> {resp.status_code}")
        if resp.status_code not in (200, 201):
            print(f"   错误响应: {resp.text}")
        assert resp.status_code in (200, 201), f"创建失败: {resp.text}"
        progress = resp.json()["data"]
        progress_id = progress["id"]
        print(f"   ✓ 创建进度 ID: {progress_id}\n")

        # 6. 获取所有进度
        print("6️⃣ 获取所有进度")
        resp = await client.get(f"{BASE_URL}/api/progress", headers=headers)
        print(f"   GET /api/progress -> {resp.status_code}")
        assert resp.status_code == 200
        progress_list = resp.json()["data"]
        print(f"   ✓ 共 {len(progress_list)} 条进度记录\n")

        # 7. 更新进度
        print("7️⃣ 更新进度")
        update_data = {"watched_episodes": 2, "status": "completed"}
        resp = await client.put(f"{BASE_URL}/api/progress/{progress_id}", json=update_data, headers=headers)
        print(f"   PUT /api/progress/{progress_id} -> {resp.status_code}")
        assert resp.status_code == 200
        updated = resp.json()["data"]
        print(f"   ✓ 更新后已看集数: {updated['watched_episodes']}, 状态: {updated['status']}\n")

        # 8. Bangumi 搜索
        print("8️⃣ Bangumi 搜索")
        resp = await client.get(f"{BASE_URL}/api/subjects", params={"q": "测试"}, headers=headers)
        print(f"   GET /api/subjects?q=测试 -> {resp.status_code}")
        assert resp.status_code == 200
        search_results = resp.json()["data"]
        print(f"   ✓ 搜索到 {len(search_results.get('items', []))} 个结果\n")

        # 9. 删除进度（清理）
        print("9️⃣ 删除进度测试数据")
        resp = await client.delete(f"{BASE_URL}/api/progress/{progress_id}", headers=headers)
        print(f"   DELETE /api/progress/{progress_id} -> {resp.status_code}")
        assert resp.status_code == 200
        print(f"   ✓ 测试数据已清理\n")

        print("🎉 所有端到端测试通过！")
        return True


if __name__ == "__main__":
    try:
        success = asyncio.run(test_full_flow())
        exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ 测试异常: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
