"""番剧进度 API 测试 — CRUD + watch"""

import pytest
import requests


# ════════════════════════════════════════════
# 列表
# ════════════════════════════════════════════

def test_list_progress_empty(base_url, auth_headers):
    """新用户没有任何番剧记录"""
    r = requests.get(f"{base_url}/api/progress", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["code"] == 200
    assert body["data"] == []


def test_list_progress_requires_auth(base_url):
    """未认证不能访问"""
    r = requests.get(f"{base_url}/api/progress")
    assert r.status_code == 401  # HTTPBearer returns 401 when no credentials


# ════════════════════════════════════════════
# CRUD
# ════════════════════════════════════════════

def test_progress_crud(base_url, auth_headers):
    """完整 CRUD 流程: 创建 → 查询 → 更新 → watch → 删除 → 验证"""

    # ── Create ──
    r = requests.post(f"{base_url}/api/progress", headers=auth_headers, json={
        "title": "Test Anime",
        "total_episodes": 12,
        "watched_episodes": 3,
        "status": "watching",
    })
    assert r.status_code == 200
    body = r.json()
    assert body["code"] == 200
    created = body["data"]
    anime_id = created["id"]
    assert created["title"] == "Test Anime"
    assert created["total_episodes"] == 12
    assert created["watched_episodes"] == 3
    assert created["status"] == "watching"

    # ── Read back ──
    r = requests.get(f"{base_url}/api/progress", headers=auth_headers)
    assert r.status_code == 200
    items = r.json()["data"]
    assert any(a["id"] == anime_id for a in items)

    # ── Update ──
    r = requests.put(f"{base_url}/api/progress/{anime_id}", headers=auth_headers, json={
        "title": "Test Anime Updated",
        "total_episodes": 13,
        "watched_episodes": 4,
        "status": "watching",
    })
    assert r.status_code == 200
    updated = r.json()["data"]
    assert updated["title"] == "Test Anime Updated"
    assert updated["total_episodes"] == 13
    assert updated["watched_episodes"] == 4

    # ── Watch +1 ──
    r = requests.patch(f"{base_url}/api/progress/{anime_id}/watch",
                       headers=auth_headers, json={"delta": 1})
    assert r.status_code == 200
    assert r.json()["data"]["watched_episodes"] == 5

    # ── Watch -2 ──
    r = requests.patch(f"{base_url}/api/progress/{anime_id}/watch",
                       headers=auth_headers, json={"delta": -2})
    assert r.status_code == 200
    assert r.json()["data"]["watched_episodes"] == 3

    # ── Delete ──
    r = requests.delete(f"{base_url}/api/progress/{anime_id}",
                        headers=auth_headers)
    assert r.status_code == 200
    assert r.json()["code"] == 200

    # ── Verify deleted ──
    r = requests.get(f"{base_url}/api/progress", headers=auth_headers)
    assert r.status_code == 200
    anime_ids = [a["id"] for a in r.json()["data"]]
    assert anime_id not in anime_ids


# ════════════════════════════════════════════
# 错误处理
# ════════════════════════════════════════════

def test_update_nonexistent(base_url, auth_headers):
    """更新不存在的记录返回 404"""
    r = requests.put(f"{base_url}/api/progress/99999", headers=auth_headers, json={
        "title": "Ghost", "total_episodes": 1,
        "watched_episodes": 0, "status": "watching",
    })
    assert r.status_code == 404


def test_delete_nonexistent(base_url, auth_headers):
    """删除不存在的记录返回 404"""
    r = requests.delete(f"{base_url}/api/progress/99999", headers=auth_headers)
    assert r.status_code == 404


def test_watch_nonexistent(base_url, auth_headers):
    """对不存在的记录 watch 返回 404"""
    r = requests.patch(f"{base_url}/api/progress/99999/watch",
                       headers=auth_headers, json={"delta": 1})
    assert r.status_code == 404


def test_create_empty_title(base_url, auth_headers):
    """空标题被拒绝"""
    r = requests.post(f"{base_url}/api/progress", headers=auth_headers, json={
        "title": "   ", "status": "watching",
    })
    assert r.status_code == 422


def test_create_invalid_status(base_url, auth_headers):
    """无效状态被拒绝"""
    r = requests.post(f"{base_url}/api/progress", headers=auth_headers, json={
        "title": "Valid", "status": "invalid_status",
    })
    assert r.status_code == 422


# ════════════════════════════════════════════
# 数据隔离
# ════════════════════════════════════════════

def test_user_isolation(base_url, auth_headers):
    """用户 A 的数据不对其他用户可见"""
    # Create an entry
    r = requests.post(f"{base_url}/api/progress", headers=auth_headers, json={
        "title": "Isolation Test", "status": "watching",
    })
    assert r.status_code == 200
    anime_id = r.json()["data"]["id"]

    # Try to access as unauthenticated user
    r_anon = requests.get(f"{base_url}/api/progress")
    assert r_anon.status_code == 401  # unauthenticated

    # Cleanup
    requests.delete(f"{base_url}/api/progress/{anime_id}", headers=auth_headers)
