"""AnimeProgress 模型"""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base

import enum


class AnimeStatus(str, enum.Enum):
    watching = "watching"
    completed = "completed"
    on_hold = "on_hold"
    dropped = "dropped"
    plan_to_watch = "plan_to_watch"


class AnimeProgress(Base):
    __tablename__ = "anime_progress"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    cover_url = Column(String(500), nullable=True)
    total_episodes = Column(Integer, nullable=True)
    watched_episodes = Column(Integer, default=0, nullable=False)
    status = Column(SAEnum(AnimeStatus), default=AnimeStatus.watching, nullable=False)
    rating = Column(Integer, nullable=True)
    notes = Column(String(1000), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    owner = relationship("User", backref="anime_progress")