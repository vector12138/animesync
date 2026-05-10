"""番剧进度业务逻辑"""

from sqlalchemy.orm import Session

from app.models.anime import AnimeProgress, AnimeStatus
from app.schemas.anime import AnimeCreate, AnimeUpdate, WatchUpdate


def list_progress(db: Session, user_id: int) -> list[AnimeProgress]:
    return db.query(AnimeProgress).filter(AnimeProgress.user_id == user_id).order_by(AnimeProgress.updated_at.desc()).all()


def get_progress(db: Session, user_id: int, progress_id: int) -> AnimeProgress | None:
    return db.query(AnimeProgress).filter(AnimeProgress.id == progress_id, AnimeProgress.user_id == user_id).first()


def create_progress(db: Session, user_id: int, data: AnimeCreate) -> AnimeProgress:
    item = AnimeProgress(user_id=user_id, **data.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_progress(db: Session, item: AnimeProgress, data: AnimeUpdate) -> AnimeProgress:
    for key, val in data.model_dump(exclude_unset=True).items():
        setattr(item, key, val)
    db.commit()
    db.refresh(item)
    return item


def update_watch(db: Session, item: AnimeProgress, data: WatchUpdate) -> AnimeProgress:
    new_val = item.watched_episodes + data.delta
    if new_val < 0:
        new_val = 0
    item.watched_episodes = new_val

    # 如果看完，自动标记为 completed
    if item.total_episodes and item.watched_episodes >= item.total_episodes and item.status == AnimeStatus.watching:
        item.status = AnimeStatus.completed

    db.commit()
    db.refresh(item)
    return item


def delete_progress(db: Session, item: AnimeProgress) -> None:
    db.delete(item)
    db.commit()