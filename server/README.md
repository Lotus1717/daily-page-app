# 拾页 · 后端说明

拾页的后端**不在此目录维护**，与「废话预言家」共用同一份服务端代码：

```
../nonsense_prophet_app/server/
```

线上地址：`http://175.178.249.107`（同一 Docker 容器，80 端口）

## 拾页相关 API

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/v1/daily-page` | 生成每日书摘 |
| `POST` | `/v1/reflection-prompt` | AI 引导提问 |

源码位置：`nonsense_prophet_app/server/app/services/daily_page_service.py` 等。

## 部署 / 更新

在 `nonsense_prophet_app` 目录执行：

```bash
bash server/deploy/deploy_update.sh
bash server/deploy/smoke_test.sh
```

详见 [`nonsense_prophet_app/server/deploy/DEPLOY_IP.md`](../../nonsense_prophet_app/server/deploy/DEPLOY_IP.md)。
