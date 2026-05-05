"""统一日志配置 — 所有模块通过 get_logger(__name__) 获取 logger"""

import logging
import logging.handlers
import os
import sys

from app.config_loader import get_logging_config

_initialized = False


def setup_logging():
    """应用启动时调用一次，配置根 logger"""
    global _initialized
    if _initialized:
        return

    cfg = get_logging_config()
    level = getattr(logging, cfg.get("level", "INFO").upper(), logging.INFO)
    fmt = cfg.get("format", "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s")
    log_file = cfg.get("file")
    max_bytes = cfg.get("max_bytes", 10 * 1024 * 1024)
    backup_count = cfg.get("backup_count", 3)

    formatter = logging.Formatter(fmt)

    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    root_logger.handlers.clear()

    # 控制台输出
    console = logging.StreamHandler(sys.stdout)
    console.setFormatter(formatter)
    console.setLevel(level)
    root_logger.addHandler(console)

    # 文件输出（带旋转）
    if log_file:
        os.makedirs(os.path.dirname(log_file) or ".", exist_ok=True)
        file_handler = logging.handlers.RotatingFileHandler(
            log_file, maxBytes=max_bytes, backupCount=backup_count, encoding="utf-8"
        )
        file_handler.setFormatter(formatter)
        file_handler.setLevel(level)
        root_logger.addHandler(file_handler)

    _initialized = True


def get_logger(name: str) -> logging.Logger:
    """获取带模块名的 logger，在 setup_logging() 之后使用"""
    return logging.getLogger(name)