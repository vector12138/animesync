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