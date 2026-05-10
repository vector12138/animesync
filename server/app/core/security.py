"""JWT + 密码哈希工具"""

from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import HTTPException, status

from app.config import get_jwt_config


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


def create_access_token(user_id: int) -> str:
    cfg = get_jwt_config()
    expire = datetime.now(timezone.utc) + timedelta(minutes=cfg["access_token_expire_minutes"])
    payload = {"sub": str(user_id), "exp": expire, "type": "access"}
    token = jwt.encode(payload, cfg["secret_key"], algorithm=cfg["algorithm"])
    # PyJWT 2.x returns str, older versions return bytes. Normalize.
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token


def create_refresh_token(user_id: int) -> str:
    cfg = get_jwt_config()
    expire = datetime.now(timezone.utc) + timedelta(days=cfg["refresh_token_expire_days"])
    payload = {"sub": str(user_id), "exp": expire, "type": "refresh"}
    token = jwt.encode(payload, cfg["secret_key"], algorithm=cfg["algorithm"])
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token


def decode_access_token(token: str) -> int:
    """解析 token 返回 user_id；失败抛 401"""
    cfg = get_jwt_config()
    try:
        payload = jwt.decode(token, cfg["secret_key"], algorithms=[cfg["algorithm"]])
        if payload.get("type") != "access":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        return int(payload["sub"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired")
    except (jwt.InvalidTokenError, KeyError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")


def verify_refresh_token(token: str) -> int:
    """验证 refresh token，返回 user_id；失败抛 401"""
    cfg = get_jwt_config()
    try:
        payload = jwt.decode(token, cfg["secret_key"], algorithms=[cfg["algorithm"]])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        return int(payload["sub"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired")
    except (jwt.InvalidTokenError, KeyError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")