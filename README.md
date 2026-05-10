# AnimeSync

番剧进度同步系统。支持多端同步进度、标记状态、评分评分、备注等功能。

## 快速开始

### 1. 克隆仓库

```bash
git clone <repo-url>
cd animesync
```

### 2. 复制环境变量

```bash
cp server/.env.example server/.env
```

### 3. 启动 (Docker Compose)

```bash
docker compose up --build -d
```

访问 http://localhost:8000

## 手动运行

### 后端

```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
PYTHONPATH=. python app/main.py
```

### 前端 (Flutter)

需要 Flutter SDK >= 3.2。

```bash
cd client
flutter pub get
flutter run          # 连接设备后运行
# 或
flutter run -d web   # 浏览器运行
flutter build apk    # 构建 Android APK
flutter build ios    # 构建 iOS (需 macOS)
```

## 项目结构

```
animesync/
├── server/          # FastAPI 后端
│   ├── app/
│   │   ├── api/     # 路由 (auth, progress, subjects)
│   ├── app/models.py
│   ├── app/database.py
│   ├── Dockerfile
│   └── requirements.txt
├── client/          # Flutter 客户端 (跨平台: Android/iOS/Web)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/      # 数据模型
│   │   ├── services/    # API & 存储 (http, shared_preferences)
│   │   ├── providers/   # 状态管理 (Provider)
│   │   ├── screens/     # 页面 (Setup, Auth, Home)
│   │   └── widgets/     # 组件 (AnimeCard)
│   └── pubspec.yaml
└── docker-compose.yml
```

## API 文档

启动后访问 http://localhost:8000/docs


## 生产环境部署

1. 生成强密钥：`openssl rand -hex 32`
2. 创建 `config.production.json`（参考 `config.example.json`），替换 `jwt.secret_key`，数据库切换到 PostgreSQL（推荐）
3. 设置环境变量：`export ANIMESYNC_CONFIG=/path/to/config.production.json`
4. 启动：`uvicorn app.main:app --host 0.0.0.0 --port 8000`（生产建议使用 `gunicorn -k uvicorn.workers.UvicornWorker`）

详见 `CLAUDE.md` 中的部署约束。
