"""番剧进度 API 路由"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.core.deps import get_current_user
from app.schemas.anime import AnimeCreate, AnimeUpdate, WatchUpdate, AnimeResponse
from app.services import progress_service as svc

router = APIRouter(prefix="/api/progress", tags=["progress"])


def _resp(data):
    return {"code": 200, "message": "ok", "data": data}


def _to_schema(item) -> dict:
    return AnimeResponse.model_validate(item).model_dump(mode="json")


@router.get("")
def list_progress(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    items = svc.list_progress(db, current_user.id)
    return _resp([_to_schema(i) for i in items])


@router.post("")
def create_progress(req: AnimeCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    item = svc.create_progress(db, current_user.id, req)
    return _resp(_to_schema(item))


@router.put("/{progress_id}")
def update_progress(progress_id: int, req: AnimeUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    item = svc.get_progress(db, current_user.id, progress_id)
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="番剧记录不存在")
    updated = svc.update_progress(db, item, req)
    return _resp(_to_schema(updated))


@router.patch("/{progress_id}/watch")
def watch_progress(progress_id: int, req: WatchUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    item = svc.get_progress(db, current_user.id, progress_id)
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="番剧记录不存在")
    updated = svc.update_watch(db, item, req)
    return _resp(_to_schema(updated))


@router.delete("/{progress_id}")
def delete_progress(progress_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    item = svc.get_progress(db, current_user.id, progress_id)
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="番剧记录不存在")
    svc.delete_progress(db, item)
    return _resp(None)