# AnimeSync — 番剧进度同步系统

## 项目结构
所有代码在 `/home/void/prj/animesync/` 下。

- `server/` — FastAPI 后端
- `client/` — Web 前端客户端
- `docker/` — Docker 部署文件

## 项目约束
1. **代码精简复用** — 统一响应格式 `{"code":200,"message":"ok","data":...}`
2. **配置统一** — 只有 `config_loader.py` 读 config.json
3. **日志统一** — 只在 main.py 初始化，模块用 `get_logger(__name__)`

## 开发命令
```bash
cd server
python app/main.py          # 启动服务
pytest tests/ -v            # 运行测试
```

## 约束
- RESTful API 风格，名词复数路径
- 所有番剧数据按 user_id 隔离
- JWT 认证，token 通过 Authorization: Bearer 头传递

## 项目经验

### FastAPI 路由注册顺序
API 路由必须在挂载 StaticFiles 之前注册，否则静态文件路由会遮蔽 API 路由。

### BASE_DIR 计算
从 app/ 出发通过 `parent.parent.parent` 定位到项目根目录。

## 前端技术栈
同时有 Web + 移动端时，统一使用 Flutter 在 client/ 目录开发。
## 安装步骤

### 后端

```bash
cd server
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp config.example.json config.json
# 编辑配置文件
uvicorn app.main:app --reload
```

### 前端 (Flutter)

```bash
cd client
flutter pub get
flutter run
```

### 测试

```bash
# 后端
pytest tests/ -v
python ../../test_e2e.py

# 前端
flutter test
```
