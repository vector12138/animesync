"""认证路由: 注册 / 登录 / 获取当前用户 / 刷新token"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserRegister, UserLogin, RefreshRequest
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    verify_refresh_token,
)
from app.core.deps import get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])


def _wrap(data):
    return {"code": 200, "message": "ok", "data": data}


def _to_user_dict(u: User) -> dict:
    return {
        "id": u.id,
        "username": u.username,
        "created_at": str(u.created_at) if u.created_at else None,
    }


@router.post("/register")
def register(req: UserRegister, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == req.username).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="用户名已存在"
        )
    user = User(username=req.username, password_hash=hash_password(req.password))
    db.add(user)
    db.commit()
    db.refresh(user)

    # 生成 refresh token
    refresh_token = create_refresh_token(user.id)
    user.refresh_token = refresh_token
    db.commit()

    access_token = create_access_token(user.id)
    return _wrap(
        {
            "access_token": access_token,
            "token_type": "bearer",
            "refresh_token": refresh_token,
            "user": _to_user_dict(user),
        }
    )


@router.post("/login")
def login(req: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == req.username).first()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="用户名或密码错误"
        )

    # 生成新的 refresh token (轮转)
    refresh_token = create_refresh_token(user.id)
    user.refresh_token = refresh_token
    db.commit()

    access_token = create_access_token(user.id)
    return _wrap(
        {
            "access_token": access_token,
            "token_type": "bearer",
            "refresh_token": refresh_token,
            "user": _to_user_dict(user),
        }
    )


@router.post("/refresh")
def refresh(req: RefreshRequest, db: Session = Depends(get_db)):
    user_id = verify_refresh_token(req.refresh_token)

    user = db.query(User).filter(User.id == user_id).first()
    if not user or user.refresh_token != req.refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token 不匹配或已失效",
        )

    # 轮转 refresh token: 生成新的并替换旧的
    new_refresh_token = create_refresh_token(user.id)
    user.refresh_token = new_refresh_token
    db.commit()

    new_access_token = create_access_token(user.id)
    return _wrap(
        {
            "access_token": new_access_token,
            "token_type": "bearer",
            "refresh_token": new_refresh_token,
            "user": _to_user_dict(user),
        }
    )


@router.get("/me")
def me(current_user: User = Depends(get_current_user)):
    return _wrap(_to_user_dict(current_user))
