"""统一配置加载器 — 唯一读取 config.json 的地方"""

import json
import os
from functools import lru_cache
from typing import Any

_CONFIG_PATH_ENV = "ANIMESYNC_CONFIG"


def _get_config_path() -> str:
    """获取配置文件路径，优先环境变量，默认同目录下的 config.json"""
    return os.environ.get(_CONFIG_PATH_ENV) or os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "config.json"
    )


@lru_cache(maxsize=1)
def get_config() -> dict[str, Any]:
    """读取并缓存完整配置"""
    path = _get_config_path()
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_database_config() -> dict[str, Any]:
    return get_config()["database"]


def get_jwt_config() -> dict[str, Any]:
    return get_config()["jwt"]


def get_logging_config() -> dict[str, Any]:
    return get_config()["logging"]


def get_app_config() -> dict[str, Any]:
    return get_config()["app"]


def get_database_url() -> str:
    return get_database_config()["url"]


def reload_config():
    """手动刷新配置（清除缓存）"""
    get_config.cache_clear()