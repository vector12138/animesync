"""数据库连接 — 从 config 获取 database_url
CIFS 兼容: 禁用 WAL 避免锁问题
"""

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from app.config import get_database_url


_engine = None
_SessionLocal = None


def get_engine():
    global _engine
    if _engine is None:
        url = get_database_url()
        connect_args = {}
        if "sqlite" in url:
            connect_args["check_same_thread"] = False
        _engine = create_engine(
            url,
            connect_args=connect_args,
            echo=False,
        )
        # CIFS 兼容: 关闭 WAL，使用 DELETE 模式
        if "sqlite" in url:
            @event.listens_for(_engine, "connect")
            def _set_sqlite_pragma(dbapi_connection, connection_record):
                cursor = dbapi_connection.cursor()
                cursor.execute("PRAGMA journal_mode=DELETE")
                cursor.execute("PRAGMA busy_timeout=5000")
                cursor.close()
    return _engine


def get_session_local():
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=get_engine())
    return _SessionLocal


class Base(DeclarativeBase):
    pass


def get_db():
    """FastAPI 依赖注入，自动关闭 session"""
    db = get_session_local()()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """创建所有表（开发/测试用）"""
    Base.metadata.create_all(bind=get_engine())