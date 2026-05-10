"""Bangumi 搜索与详情 API 测试"""

import pytest
import requests


def test_subjects_search_requires_auth(base_url):
    """未认证搜索被拒绝"""
    r = requests.get(f"{base_url}/api/subjects", params={"q": "test"})
    assert r.status_code == 401


def test_subjects_search_success(base_url, auth_headers):
    """认证用户可搜索"""
    r = requests.get(f"{base_url}/api/subjects", params={"q": "测试"}, headers=auth_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["code"] == 200
    assert "items" in body["data"]
    assert "total" in body["data"]
    # 搜索"测试"可能无结果，但结构正确
    assert isinstance(body["data"]["items"], list)
    assert isinstance(body["data"]["total"], int)


def test_subjects_search_limit(base_url, auth_headers):
    """limit 参数限制在 25 以内"""
    r = requests.get(f"{base_url}/api/subjects", params={"q": "a", "limit": 50}, headers=auth_headers)
    assert r.status_code == 200
    # 即使请求50，也应限制为25或更少
    items = r.json()["data"]["items"]
    assert len(items) <= 25


def test_get_subject_requires_auth(base_url):
    """未认证获取详情被拒绝"""
    r = requests.get(f"{base_url}/api/subjects/123")
    assert r.status_code == 401


def test_get_subject_not_found(base_url, auth_headers):
    """不存在的条目返回 404"""
    r = requests.get(f"{base_url}/api/subjects/9999999", headers=auth_headers)
    assert r.status_code == 404
    assert r.json()["detail"] == "条目不存在"
