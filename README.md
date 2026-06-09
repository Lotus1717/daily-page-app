# 拾页

不用读完一本书，每天一页就好。读完了，写一句话。

## 产品形态

| Tab | 功能 |
|-----|------|
| **今日** | 每日书摘 + AI 引导提问 + 写感想 |
| **在读** | 管理在读书（最多 3 本），手动添加藏书 |
| **我** | 阅读统计、感想记录、每日提醒 |

### 选书

- **默认**：自动选最久未读的在读书
- **换一本**：「今日」页点多本在读书时可用；探索模式随机换书
- **换一页**：书摘卡片章节行右侧，同一本书换一段摘录

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
| `POST /v1/reflection-prompt` | AI 引导提问 |

### 部署 / 更新

```bash
cd ../nonsense_prophet_app
bash server/deploy/deploy_update.sh   # 上传 + 远程 sudo docker compose rebuild
bash server/deploy/smoke_test.sh      # 验证接口（含 daily-page）
```

未加入在读书时，App 进入**探索模式**：服务端 DeepSeek 随机荐书，首页可点「换一本」。

## 添加藏书

1. 打开「在读」Tab
2. 点右下角「添加」，输入书名和作者
3. 新书会自动加入在读书队列（未满 3 本时）
