# AnimeSync — 番剧进度同步系统 实现计划

> **项目名:** animesync
> **路径:** `/home/void/prj/animesync`

## 一、需求综述

番剧进度同步软件，支持多账号隔离，用户可以指定服务器地址。

**核心流程：**
1. 用户启动客户端 → 输入服务器地址
2. 注册/登录账号
3. 添加正在看的番剧 → 记录看到第几集 → 数据同步到服务器
4. 换设备登录同一账号 → 进度自动恢复

## 二、数据模型

```
用户 (User)
  ├── id (PK)
  ├── username (唯一)
  ├── password_hash
  └── created_at

番剧进度 (AnimeProgress)
  ├── id (PK)
  ├── user_id (FK → User)
  ├── title (番剧名称)
  ├── cover_url (封面URL, 可选)
  ├── total_episodes (总集数, 可选)
  ├── watched_episodes (已看集数, 默认0)
  ├── status (watching/completed/on_hold/dropped/plan_to_watch)
  ├── rating (评分 0-10, 可选)
  ├── notes (备注, 可选)
  ├── created_at
  └── updated_at
```

## 三、架构设计

```
┌───────────────────┐     HTTP/JSON     ┌──────────────────────┐
│   Flutter 客户端   │ ◄──────────────► │   FastAPI 服务端      │
│                   │     JWT Auth       │                      │
│  - 指定服务器地址   │                   │  - 用户认证 (JWT)    │
│  - 账号登录        │                   │  - 番剧CRUD          │
│  - 浏览/管理进度   │                   │  - 账号数据隔离      │
│  - Dart + Flutter │                   │  - config.json 配置  │
└───────────────────┘                   └──────────┬───────────┘
                                                   │ SQLAlchemy
                                                   ▼
                                            ┌──────────────┐
                                            │   SQLite/DB   │
                                            └──────────────┘
```

### 为什么选择 Flutter？
- 一套代码多端运行（Web、移动端），未来可扩展。
- 开发体验优秀，热重载提升效率。
- 原生支持指定服务器地址（配置界面）。
- 性能优于纯 Web 方案，离线体验更佳。

## 四、API 设计

### 用户认证
- `POST /api/auth/register` — 注册
- `POST /api/auth/login` — 登录，返回 JWT token
- `GET /api/auth/me` — 获取当前用户信息
- `POST /api/auth/refresh` — 刷新 access token（需提供有效的 refresh token）

### 番剧进度 (需认证)
- `GET /api/progress` — 获取用户的所有番剧进度
- `POST /api/progress` — 添加番剧进度
- `PUT /api/progress/{id}` — 更新番剧进度（集数、状态等）
- `DELETE /api/progress/{id}` — 删除番剧进度
- `PATCH /api/progress/{id}/watch` — 增加/减少观看集数

## 五、目录结构

```
/home/void/prj/animesync/
├── server/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py              # FastAPI 入口
│   │   ├── config.json          # 统一配置文件
│   │   ├── config_loader.py     # 配置加载器 (单例)
│   │   ├── logging_config.py    # 日志配置器 (单例)
│   │   ├── database.py          # 数据库连接
│   │   ├── models/
│   │   │   ├── __init__.py
│   │   │   ├── user.py          # User 模型
│   │   │   └── anime.py         # AnimeProgress 模型
│   │   ├── schemas/
│   │   │   ├── __init__.py
│   │   │   ├── user.py          # Pydantic 请求/响应模型
│   │   │   └── anime.py
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py          # 认证路由
│   │   │   └── progress.py      # 番剧进度路由
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── security.py      # JWT + 密码哈希工具
│   │   │   └── deps.py          # 依赖注入 (get_current_user等)
│   │   └── services/
│   │       ├── __init__.py
│   │       └── progress_service.py  # 业务逻辑
│   ├── requirements.txt
│   └── alembic/                 # (暂不用，SQLite直接sync)
├── client/                      # Flutter 客户端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── providers/
│   │   ├── services/
│   │   ├── screens/
│   │   ├── constants/
│   │   └── utils/
│   ├── pubspec.yaml
│   └── ...
├── docker/
│   ├── docker-compose.yml
│   └── Dockerfile
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   └── test_progress.py
├── CLAUDE.md
├── Makefile
└── README.md
```

## 六、配置架构（硬性约束）

### config.json（统一配置）

```json
{
  "app": {
    "name": "AnimeSync",
    "host": "0.0.0.0",
    "port": 8000,
    "debug": true
  },
  "database": {
    "url": "sqlite:///./animesync.db"
  },
  "jwt": {
    "secret_key": "change-this-in-production",
    "algorithm": "HS256",
    "access_token_expire_minutes": 1440
  },
  "logging": {
    "level": "INFO",
    "file": "logs/animesync.log",
    "max_bytes": 10485760,
    "backup_count": 3,
    "format": "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s"
  }
}
```

### 谁读 config.json
- **只有** `config_loader.py` 读文件
- `config_loader.py` 用 `@lru_cache` 缓存，不重复读盘
- 其他模块通过 `get_config()` / `get_database_config()` 等函数获取

### 日志初始化
- 只在一个地方初始化: `app/main.py` 启动时调用 `setup_logging()`
- 所有模块用 `logger = get_logger(__name__)` 获取

## 七、实现步骤

---

### Step 1: 创建项目骨架

**文件操作：**
- 创建目录结构
- 写入 `server/app/config.json`
- 写入 `server/app/config_loader.py`
- 写入 `server/app/logging_config.py`
- 写入 `server/app/__init__.py`
- 写入 `server/app/main.py`（空架子）
- 写入 `server/requirements.txt`
- 写入 `.gitignore`
- 写入 `CLAUDE.md`
- 写入 `Makefile`
- `git init + 初次提交`

**验证：** `python -c "from app.config_loader import get_config; print(get_config())"` 打印配置

---

### Step 2: 实现数据库层 + User 模型

**文件操作：**
- 写入 `server/app/database.py`
- 写入 `server/app/models/__init__.py`
- 写入 `server/app/models/user.py`
- 写入 `server/app/models/anime.py`

**验证：** pytest 测试建表成功

---

### Step 3: 实现认证系统

**文件操作：**
- 写入 `server/app/core/security.py` — JWT + bcrypt
- 写入 `server/app/core/deps.py` — `get_current_user` 依赖
- 写入 `server/app/schemas/user.py` — 请求/响应模型
- 写入 `server/app/api/auth.py` — 注册/登录路由
- 更新 `server/app/main.py` — 挂载路由

**验证：** curl 注册 → 登录 → 获取 token → token 访问受保护接口

---

### Step 4: 实现番剧进度 API

**文件操作：**
- 写入 `server/app/schemas/anime.py`
- 写入 `server/app/services/progress_service.py`
- 写入 `server/app/api/progress.py`
- 更新 `server/app/main.py` — 挂载路由

**验证：** curl 带 token 做 CRUD 操作

---

### Step 5: 实现 Web 前端客户端

**文件操作：**
- 写入 `client/index.html`
- 写入 `client/css/style.css`
- 写入 `client/js/app.js`
- 配置 FastAPI 静态文件服务

**功能：**
- 服务器地址设置页面
- 登录/注册页面
- 番剧列表页面（看过的、在看的、想看的分组）
- 添加/编辑番剧弹窗
- 集数快速增减按钮

**验证：** 在浏览器中完整走一遍流程

---

### Step 6: Docker 部署

**文件操作：**
- 写入 `docker/Dockerfile`
- 写入 `docker/docker-compose.yml`
- 写入 `docker/nginx.conf`
- 写入 `docker/config.production.json`

**验证：** `docker compose up -d` → 访问 http://localhost → 完整走通

---

### Step 7: 测试

**文件操作：**
- 写入 `tests/conftest.py`
- 写入 `tests/test_auth.py`
- 写入 `tests/test_progress.py`

**验证：** `pytest tests/ -v` 全部通过

### Step 8: 质量与体验提升 (已完成)

**主要改进：**
- ✅ Refresh Token 轮转，提升安全性
- ✅ 前端错误统一提示与空状态优化
- ✅ 操作即时反馈（成功/失败提示）
- ✅ 自动刷新队列（避免并发请求重复刷新）
- ✅ 常量统一管理（API 路径与 Header）
- ✅ 更新 README 与运行指南
- ✅ 扩展集成测试（覆盖 refresh 流程）

---

## 八、约束速查

| 约束 | 规则 |
|------|------|
| 代码复用 | 统一响应格式 `{"code":200,"message":"ok","data":...}`，统一异常处理，依赖注入 |
| 配置管理 | 只有 `config_loader.py` 读 config.json，其他模块通过函数获取 |
| 日志 | 只在 `main.py` 初始化，模块用 `get_logger(__name__)` 获取 |
| API风格 | RESTful，名词复数路径 |
| 数据隔离 | 所有番剧数据关联 user_id，API 自动从 JWT 获取当前用户 |

---

## 九、开始开发

准备就绪后，按 Step 1 → Step 7 顺序执行。每个 Step 完成后提交代码。