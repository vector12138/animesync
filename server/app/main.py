"""AnimeSync 服务端入口"""

from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import get_app_config
from app.logging_config import setup_logging, get_logger
from app.database import init_db


def create_app():
    cfg = get_app_config()

    app = FastAPI(title=cfg.get("name", "AnimeSync"), debug=cfg.get("debug", False))

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 初始化数据库
    init_db()

    # ── API 路由（必须在静态文件之前注册，确保优先匹配）──
    from app.api.auth import router as auth_router
    from app.api.progress import router as progress_router
    from app.api.subjects import router as subjects_router

    app.include_router(auth_router)
    app.include_router(progress_router)
    app.include_router(subjects_router)

    # 健康检查
    @app.get("/api/health")
    def health():
        return {"code": 200, "message": "ok", "data": {"status": "running"}}

    # ── 静态文件（最后挂载，避免覆盖 API 路由）──
    client_dir = Path(__file__).resolve().parent.parent.parent / "client"
    if client_dir.exists():
        app.mount("/", StaticFiles(directory=str(client_dir), html=True), name="client")

    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn

    setup_logging()
    cfg = get_app_config()
    logger = get_logger(__name__)
    logger.info("Starting %s...", cfg.get("name"))
    uvicorn.run("app.main:app", host=cfg["host"], port=cfg["port"], reload=cfg.get("debug", True))