"""番剧条目 API — 集成 Bangumi 搜索与详情"""

from fastapi import APIRouter, HTTPException
from fastapi import Depends

from app.services.bangumi import get_bangumi_client
from app.core.deps import get_current_user
from app.models.user import User

router = APIRouter(prefix="/api/subjects", tags=["subjects"])


@router.get("")
async def list_subjects(q: str, limit: int = 10, current_user: User = Depends(get_current_user)):
    """搜索 Bangumi 番剧条目

    Args:
        q: 搜索关键词
        limit: 返回数量 (最大 25)
    """
    client = get_bangumi_client()
    try:
        results = await client.search(q, limit=min(limit, 25))
        return {
            "code": 200,
            "message": "ok",
            "data": {
                "items": results,
                "total": len(results),
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Bangumi API 错误: {str(e)}")
    finally:
        await client.close()


@router.get("/{subject_id}")
async def get_subject(subject_id: int, current_user: User = Depends(get_current_user)):
    """获取 Bangumi 番剧条目详情

    Args:
        subject_id: Bangumi subject ID
    """
    client = get_bangumi_client()
    try:
        result = await client.get_subject(subject_id)
        if not result:
            raise HTTPException(status_code=404, detail="条目不存在")
        return {"code": 200, "message": "ok", "data": result}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Bangumi API 错误: {str(e)}")
    finally:
        await client.close()
