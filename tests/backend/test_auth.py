"""认证模块测试 — register / login / me"""

import uuid
import pytest
import requests


# ════════════════════════════════════════════
# 注册
# ════════════════════════════════════════════

def test_register_success(base_url):
    """正常注册返回 token 和用户信息"""
    username = f"reg_{uuid.uuid4().hex[:8]}"
    r = requests.post(f"{base_url}/api/auth/register", json={
        "username": username,
        "password": "Test1234",
    })
    assert r.status_code == 200
    body = r.json()
    assert body["code"] == 200
    assert "access_token" in body["data"]
    assert body["data"]["token_type"] == "bearer"
    assert body["data"]["user"]["username"] == username


def test_register_duplicate_username(base_url, test_user):
    """重复用户名返回 409"""
    r = requests.post(f"{base_url}/api/auth/register", json={
        "username": test_user["username"],
        "password": "Another1",
    })
    assert r.status_code == 409


@pytest.mark.parametrize("password,expected_status", [
    ("short", 422),            # < 8 chars
    ("nouppercase1", 422),     # no uppercase
    ("NOLOWERCASE1", 422),     # no lowercase
    ("NoDigitsAbc", 422),      # no digit
])
def test_register_weak_password(base_url, password, expected_status):
    """弱密码被拒绝 422"""
    r = requests.post(f"{base_url}/api/auth/register", json={
        "username": f"pw_{uuid.uuid4().hex[:6]}",
        "password": password,
    })
    assert r.status_code == expected_status


def test_register_short_username(base_url):
    """用户名太短被拒绝"""
    r = requests.post(f"{base_url}/api/auth/register", json={
        "username": "ab",
        "password": "Test1234",
    })
    assert r.status_code == 422


# ════════════════════════════════════════════
# 登录
# ════════════════════════════════════════════

def test_login_success(base_url, test_user):
    """正确凭据登录成功"""
    r = requests.post(f"{base_url}/api/auth/login", json={
        "username": test_user["username"],
        "password": test_user["password"],
    })
    assert r.status_code == 200
    body = r.json()
    assert body["code"] == 200
    assert body["data"]["token_type"] == "bearer"
    assert len(body["data"]["access_token"]) > 20
    assert body["data"]["user"]["username"] == test_user["username"]


def test_login_wrong_password(base_url, test_user):
    """错误密码返回 401"""
    r = requests.post(f"{base_url}/api/auth/login", json={
        "username": test_user["username"],
        "password": "WrongPass1",
    })
    assert r.status_code == 401


def test_login_nonexistent_user(base_url):
    """不存在的用户返回 401"""
    r = requests.post(f"{base_url}/api/auth/login", json={
        "username": f"noexist_{uuid.uuid4().hex[:8]}",
        "password": "Test1234",
    })
    assert r.status_code == 401


# ════════════════════════════════════════════
# 获取当前用户
# ════════════════════════════════════════════

def test_me_authenticated(base_url, auth_headers, test_user):
    """已认证用户获取个人信息"""
    r = requests.get(f"{base_url}/api/auth/me", headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["code"] == 200
    assert body["data"]["username"] == test_user["username"]
    assert "id" in body["data"]


def test_me_no_token(base_url):
    """无 token 被拒绝"""
    r = requests.get(f"{base_url}/api/auth/me")
    assert r.status_code == 401  # HTTPBearer returns 401 when no credentials


def test_me_bad_token(base_url):
    """无效 token 被拒绝"""
    r = requests.get(f"{base_url}/api/auth/me", headers={
        "Authorization": "Bearer not.a.real.token",
    })
    assert r.status_code == 401
