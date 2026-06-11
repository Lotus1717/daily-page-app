# 拾页 · 上架 Checklist

> 基于 2026-06-09 项目状态评估

---

## ✅ 已具备的

| 项目 | 状态 | 备注 |
|------|------|------|
| App Icon | ✅ 已就绪 | 所有尺寸齐全，含 1024x1024 |
| Info.plist | ✅ 基本就绪 | ATS 默认策略，API 走 HTTPS（tanmystudio.site） |
| 底部导航 | ✅ 今日 / 在读 / 我 |
| 每日书摘 | ✅ 核心流程完整 |
| 感想记录 | ✅ 可写可存可删，支持按书归档 |
| 书架管理 | ✅ 手动添加 | 2026-06-09 已移除微信读书同步 |
| 在读书队列 | ✅ 最多 3 本，支持指定今日书目 |
| 阅读统计 | ✅ 累计天数、连续记录、按书记数 |
| 本地通知 | ✅ 每日提醒（当天已写则跳过） |
| 历史记录 | ✅ 全部 / 按书两种视图 |
| 分享功能 | ✅ 生成分享文本 |
| 测试覆盖 | ✅ 94 项测试通过 |
| 错误处理 | ✅ 网络错误、配额用尽等提示 |
| 首次启动引导 | ✅ 三页轮播 Onboarding | 可跳过，仅首次展示 |
| 关于区块 | ✅ 「我」页底部 | 版本号、反馈（mailto）、隐私政策（浏览器打开，失败则复制） |
| 应用内评分引导 | ✅ 第 7 条感想触发一次 | `in_app_review` |
| 隐私政策 | ✅ GitHub Pages | https://lotus1717.github.io/daily-page-app/privacy.html |
| API HTTPS | 🟡 已部署，国内不稳定 | https://tanmystudio.site（Nginx + SSL 正常；**未 ICP 备案**时 DNSPod 会拦截，见运维备忘） |
| 公众号入口 | ✅ 「我」页 | 关注二维码，远程 `community.json`（每日/周/月推送规划见 business-model-plan） |

---

## ❌ 上架前必须补的

### 🔴 高优先级（不补会被拒）

| 项目 | 说明 | 工时 | 状态 |
|------|------|------|------|
| **1. ~~隐私政策上线~~** | GitHub Pages 自动部署 `docs/privacy.html` | — | ✅ 2026-06-09 |
| **2. ~~砍掉微信读书同步~~** | Cookie 登录 + 第三方凭证无法过审 | — | ✅ 2026-06-09 已移除 |
| **3. 处理无网络状态** | app 依赖服务端获取每日书摘。无网络时需给出清晰的引导，而不是空白或报错 | 半天 | ⬜ 待做 |

### 🟡 中优先级（不补体验不完整）

| 项目 | 说明 | 工时 | 状态 |
|------|------|------|------|
| **4. 适配深色模式** | iOS 13+ 用户可能用深色模式，目前 Theme 只有 light 一套 | 半天 | ⬜ 待做 |
| **5. 加载和空状态** | 各页面空状态已有基础文案，可再统一打磨 | 半天 | 🟡 部分完成 |
| **6. 反馈渠道** | 「我」页 mailto 至 2731967717@qq.com | — | ✅ |
| **7. Bundle ID 和开发者账号** | 确认 bundle ID（当前为 `$(PRODUCT_BUNDLE_IDENTIFIER)`，需硬编码），准备 $99/年的开发者账号 | — | ⬜ 待做 |
| **8. ICP 备案** | `tanmystudio.site` 备案后国内 API 才稳定；可与上架并行推进 | 1～3 周 | ⬜ 待提交 |

### 🟢 低优先级（发了再说也不迟）

| 项目 | 说明 |
|------|------|
| **9. 多语言** | 目前只有中文，英文版可以后续再做 |
| **10. 搜索功能** | 搜索书架、历史感想 |
| **11. 数据导出** | 用户导出所有感想为纯文本 |
| **12. iCloud 同步** | 多设备同步感想记录 |
| **13. 小组件** | iOS Widget 每日一页 |

---

## 📋 上架流程步骤

按顺序推进：

```
Step 1: Apple Developer Program 注册（$99）
        → 已有则跳过

Step 2: 配置 App Store Connect
        → 填写 app 名称、副标题、描述、关键词
        → 上传隐私政策 URL（先完成 notes/privacy_policy.html 托管）
        → 设置定价（免费 / 付费 / 内购）

Step 3: 准备审核素材
        → 截图 6.5 寸 + 5.5 寸（每种语言各一套）
        → App 预览视频（可选但有帮助）
        → 审核备注（账号、测试说明）

Step 4: 清理代码
        → ✅ 已移除微信读书自动同步（2026-06-09）
        → 确认无私有 API 调用
        → 替换关于页占位邮箱/隐私政策 URL

Step 5: 构建上传
        → flutter build ios --release
        → Xcode → Archive → Upload to App Store Connect

Step 6: TestFlight 内测
        → 先发给几个朋友试用 2-3 天
        → 收集反馈修 bug

Step 7: 提交审核
        → 通常在 24-48 小时内出结果
```

---

## 💰 变现策略（可选，不紧急）

以当前功能量，上架后的变现方案：

| 方案 | 适合阶段 | 说明 |
|------|---------|------|
| 免费无广告 | 冷启动期 | 先积累用户，再考虑变现 |
| 免费 + 内购（深度反思） | 用户量稳定后 | 按之前讨论的 ¥18 买断 |
| 免费 + 打赏 | 始终可选 | 不影响用户体验 |

建议 **第一版上架完全免费**，等积累几百个用户后再加付费功能。审核也更容易过。

---

## 📅 运维备忘（上架后也要看）

### ICP 备案 · tanmystudio.site（国内访问稳定的前提）

| 项目 | 内容 |
|------|------|
| **现象** | `http://tanmystudio.site` 被 DNSPod 302 到 `webblock.html`；`https://` 时而通、时而不通 |
| **原因** | 域名托管在腾讯云大陆服务器，**未完成 ICP 备案**会被拦截 |
| **服务器本身** | ✅ 正常（`http://175.178.249.107/health` 或本机 `127.0.0.1:8000` 稳定） |
| **控制台** | [腾讯云备案](https://console.cloud.tencent.com/beian) |
| **审核周期** | 通常 1～3 周 |

**备案步骤：**

```
□ 1. 腾讯云备案控制台提交（域名 tanmystudio.site + 轻量服务器 175.178.249.107）
□ 2. 按指引完成实名 / 网站信息 / 管局审核
□ 3. 备案通过后验证：浏览器稳定打开 https://tanmystudio.site/health
□ 4. 确认 http://tanmystudio.site 不再跳转 webblock.html
```

**备案期间自用：** 可临时改 `server_config.dart` 为 `http://175.178.249.107` + Info.plist ATS 例外（仅内测，勿上架）。

**App Store 审核：** 审核服务器在海外，`https://tanmystudio.site` 一般可正常访问；国内用户需等备案完成。

---

### SSL 证书续签 · tanmystudio.site

| 项目 | 内容 |
|------|------|
| **到期日** | **2026-09-06**（建议 8 月底前处理） |
| **控制台** | [腾讯云 SSL 证书](https://console.cloud.tencent.com/ssl) |
| **服务器证书路径** | `/etc/nginx/ssl/tanmystudio.site_bundle.crt`、`tanmystudio.site.key` |
| **部署文档** | `nonsense_prophet_app/server/deploy/DEPLOY_HTTPS.md` |

**续签步骤：**

```
□ 1. 腾讯云申请/续签免费证书（域名 tanmystudio.site）
□ 2. 下载 Nginx 格式，临时放到 server/deploy/ssl/
□ 3. bash server/deploy/deploy_ssl.sh（或 scp 到服务器 /etc/nginx/ssl/）
□ 4. 服务器执行：sudo nginx -t && sudo systemctl reload nginx
□ 5. 验证：curl -s https://tanmystudio.site/health
□ 6. 删除本机证书副本（.crt / .key 不要留本地、不要进 Git）
```

到期未续签 → App 无法拉书摘，需优先处理。

---

## 📝 总结

**2026-06-09 进展：** HTTPS 已部署；书友会入口已接入；域名国内访问不稳定根因为 **未 ICP 备案**（已记入运维备忘）。

上架前红色优先级还剩 **2 项**：

1. ⬜ 无网络状态的友好提示
2. ⬜ ICP 备案（可与上架并行，国内用户依赖此项）

预计还需 **半天～1 天** 可进入 TestFlight（备案审核单独计算）。
