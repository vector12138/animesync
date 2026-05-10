"""User 模型"""

from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    password_hash = Column(String(128), nullable=False)
    refresh_token = Column(String(128), nullable=True)  # 用于 token 轮转
    created_at = Column(DateTime, server_default=func.now())