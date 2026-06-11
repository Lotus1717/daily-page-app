# 备案期间 IP 直连修复

## 现象

App 已配置 `http://175.178.249.107`，但仍无法拉取书摘。

## 原因（已实测）

| 请求 | 结果 |
|------|------|
| `http://175.178.249.107/health` | **301** → 跳转到 `https://175.178.249.107/health` |
| `https://175.178.249.107/health` | **502 Bad Gateway** |
| `http://175.178.249.107:8000` | 外网不可达（端口未开放） |

Dart `http` 客户端会**自动跟随 301**，最终落到坏的 HTTPS，所以改 App 里的 baseUrl 不够，**必须在服务器改 Nginx**。

## 修复步骤（SSH 登录 175.178.249.107）

### 1. 确认后端在跑

```bash
curl -s http://127.0.0.1:8000/health
```

应返回 JSON（如 `{"status":"ok"}`）。若失败，先重启 Docker：

```bash
cd /path/to/nonsense_prophet_app/server
sudo docker compose up -d
```

### 2. 添加 IP 专用 Nginx 配置

将本目录 `nginx-ip-http.conf` 复制到服务器：

```bash
sudo cp nginx-ip-http.conf /etc/nginx/sites-available/ip-http.conf
sudo ln -sf /etc/nginx/sites-available/ip-http.conf /etc/nginx/sites-enabled/ip-http.conf
sudo nginx -t && sudo systemctl reload nginx
```

### 3. 验证（在你本机 Mac 执行）

```bash
curl -s http://175.178.249.107/health
```

应**直接**返回 JSON，而不是 301 或 HTML。

```bash
curl -s -X POST http://175.178.249.107/v1/daily-page \
  -H "Content-Type: application/json" \
  -d '{"device_id":"smoke-test"}'
```

应返回书摘 JSON。

### 4. 重装 / 重启 App

```bash
flutter install -d <你的设备ID>
```

## 备案通过后

1. App `server_config.dart` 改回 `https://tanmystudio.site`
2. 删除 `Info.plist` 里 `175.178.249.107` 的 ATS 例外
3. 可移除服务器上的 `ip-http.conf`（恢复纯 HTTPS）
