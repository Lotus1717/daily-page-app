# 拾页

不用读完一本书，每天一页就好。读完了，写一句话。

## 产品形态

| Tab | 功能 |
|-----|------|
| **今日** | 每日书摘 + AI 引导提问 + 写感想 |
| **在读** | 管理在读书（最多 3 本）+ 同步微信读书 |
| **我** | 选书策略、阅读统计、Cookie 配置 |

### 选书策略（可在「我」中切换）

- **轮询** — 按顺序每天换一本在读书
- **最久未读** — 优先读最久没碰的那本
- **随机** — 在 3 本在读书中随机
- **手动指定** — 自己选今天读哪本

### AI 辅助

读完后 AI 提一个**开放问题**引导写感想，不代写、不生成书摘。

## iOS 安装（优先平台）

```bash
cd daily_page_app
flutter pub get

# 真机调试（需连接 iPhone）
flutter run -d 00008150-001605D61A47401C   # 或 flutter devices 查看 ID

# 构建 IPA（需 Apple 开发者签名）
flutter build ios --release
# 然后在 Xcode 打开 ios/Runner.xcworkspace 签名并安装
```

## 服务端

后端与「废话预言家」**共用一份代码**，位于：

```
nonsense_prophet_app/server/    ← 唯一源码，改 API 在这里
```

线上地址 **`http://175.178.249.107`**（同一 Docker 容器，80 端口）。

| API | 用途 |
|-----|------|
| `POST /v1/daily-page` | 每日书摘 |
| `POST /v1/weread/sync` | 微信读书同步 |
| `POST /v1/reflection-prompt` | AI 引导提问 |

### 部署 / 更新

```bash
cd ../nonsense_prophet_app
bash server/deploy/deploy_update.sh   # 上传 + 远程 sudo docker compose rebuild
bash server/deploy/smoke_test.sh      # 验证接口（含 daily-page）
```

未配置微信读书时，App 进入**探索模式**：服务端 DeepSeek 随机荐书，首页可点「换一本」。

## 微信读书 Cookie

1. 浏览器打开 weread.qq.com 并登录
2. F12 → Cookies → 复制 `wr_vid`、`wr_skey`
3. App「我」→ 粘贴保存
4. 「在读」→ 同步微信读书 → 加入在读书
