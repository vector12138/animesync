"""番剧进度 Pydantic schemas"""

from datetime import datetime
from pydantic import BaseModel, field_validator


class AnimeCreate(BaseModel):
    title: str
    cover_url: str | None = None
    total_episodes: int | None = None
    watched_episodes: int = 0
    status: str = "watching"
    rating: int | None = None
    notes: str | None = None

    @field_validator("title")
    @classmethod
    def title_not_empty(cls, v: str) -> str:
        v = v.strip()
        if not v or len(v) > 200:
            raise ValueError("番剧名称不能为空且不超过200字")
        return v

    @field_validator("status")
    @classmethod
    def status_valid(cls, v: str) -> str:
        valid = {"watching", "completed", "on_hold", "dropped", "plan_to_watch"}
        if v not in valid:
            raise ValueError(f"状态必须是: {', '.join(sorted(valid))}")
        return v

    @field_validator("watched_episodes")
    @classmethod
    def watched_non_negative(cls, v: int) -> int:
        if v < 0:
            raise ValueError("已看集数不能为负")
        return v


class AnimeUpdate(BaseModel):
    title: str | None = None
    cover_url: str | None = None
    total_episodes: int | None = None
    watched_episodes: int | None = None
    status: str | None = None
    rating: int | None = None
    notes: str | None = None

    @field_validator("watched_episodes")
    @classmethod
    def watched_non_negative(cls, v: int | None) -> int | None:
        if v is not None and v < 0:
            raise ValueError("已看集数不能为负")
        return v

    @field_validator("status")
    @classmethod
    def status_valid(cls, v: str | None) -> str | None:
        if v is not None:
            valid = {"watching", "completed", "on_hold", "dropped", "plan_to_watch"}
            if v not in valid:
                raise ValueError(f"状态必须是: {', '.join(sorted(valid))}")
        return v


class WatchUpdate(BaseModel):
    delta: int

    @field_validator("delta")
    @classmethod
    def delta_not_zero(cls, v: int) -> int:
        if v == 0:
            raise ValueError("delta 不能为0")
        return v


class AnimeResponse(BaseModel):
    id: int
    title: str
    cover_url: str | None = None
    total_episodes: int | None = None
    watched_episodes: int
    status: str
    rating: int | None = None
    notes: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}