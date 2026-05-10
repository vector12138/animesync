"""pytest shared fixtures for AnimeSync API tests.

Assumes the server is running at localhost:8000 before tests execute.
"""

import pytest
import requests
import uuid


BASE_URL = "http://localhost:8000"


@pytest.fixture(scope="session")
def base_url():
    """Base URL of the running AnimeSync server."""
    return BASE_URL


@pytest.fixture(scope="session")
def test_user(base_url):
    """Create a unique test user, return credentials dict.

    Session-scoped: registers once, reuses across all test modules.
    """
    username = f"test_{uuid.uuid4().hex[:8]}"
    password = "Test1234"

    # Register (409 if already exists from previous interrupted run is fine)
    r = requests.post(f"{base_url}/api/auth/register", json={
        "username": username,
        "password": password,
    })
    if r.status_code == 409:
        # Already exists — log in instead
        r = requests.post(f"{base_url}/api/auth/login", json={
            "username": username,
            "password": password,
        })
        assert r.status_code == 200, f"Login failed after 409: {r.text}"
        token = r.json()["data"]["access_token"]
    elif r.status_code == 200:
        token = r.json()["data"]["access_token"]
    else:
        r.raise_for_status()

    return {"username": username, "password": password, "token": token}


@pytest.fixture(scope="session")
def auth_headers(test_user):
    """Authorization headers with Bearer token for the test user."""
    return {"Authorization": f"Bearer {test_user['token']}"}
