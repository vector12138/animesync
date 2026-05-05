"""AnimeSync 服务端入口"""

from app.config_loader import get_app_config
from app.logging_config import setup_logging, get_logger


def create_app():
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware

    cfg = get_app_config()

    app = FastAPI(title=cfg.get("name", "AnimeSync"), debug=cfg.get("debug", False))

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/api/health")
    def health():
        return {"code": 200, "message": "ok", "data": {"status": "running"}}

    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn

    setup_logging()
    cfg = get_app_config()
    logger = get_logger(__name__)
    logger.info("Starting %s...", cfg.get("name"))
    uvicorn.run("app.main:app", host=cfg["host"], port=cfg["port"], reload=cfg.get("debug", True))