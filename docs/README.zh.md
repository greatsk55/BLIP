# BLIP

**说完，消失。**

🌐 [한국어](README.ko.md) | [English](../README.md) | [日本語](README.ja.md) | [中文](#) | [Español](README.es.md) | [Français](README.fr.md)

---

BLIP是一个不留痕迹的临时聊天服务。
没有账号，没有记录，没有个人资料。一个链接即可开始，结束后一切消失。

> "这段对话不需要保留" — 为这样的时刻而生。

---

## 为什么选择 BLIP？

现有的即时通讯工具保留了太多东西。账号、好友列表、聊天记录、通知...
但生活中大多数对话，其实只是**说几句就可以消失的**。

| 传统即时通讯 | BLIP |
|---|---|
| 需要创建账号 | 无需账号 |
| 聊天记录永久保存 | 零记录 — 不可恢复 |
| 需要添加好友 | 一个链接即可加入 |
| 数据存储在服务器 | 无服务器存储，端到端加密 |

## 核心理念

- **零准备成本** — 一个链接即刻开始
- **零持久性** — 结束后不可恢复
- **零身份** — 无账号、好友、个人资料
- **100%共识驱动** — 仅在所有参与者同意时存在
- **自动粉碎** — 仅最新消息留在屏幕上，旧消息实时销毁
- **截图防护** — 检测截屏和录屏尝试，立即模糊处理消息

## 使用方式

```
1. 创建房间  →  一键创建
2. 分享链接  →  发送给对方
3. 聊天      →  端到端加密实时通讯
4. 结束      →  所有数据立即销毁
```

## 预测游戏 ✨ NEW

预测现实世界的结果，赚取 **BP（BLIP 积分）**— 完全匿名。

- 🔮 **为预测投票** — 比特币会突破10万美元吗？GTA 6会在2026年发售吗？
- 🏆 **赢取奖励** — 正确投票根据人气加权分配获得积分
- 📊 **6级排名系统** — Static → Receiver → Signal → Decoder → Control → Oracle
- ✏️ **自己创建** — 任何人都可以创建预测问题（150 BP，等级折扣）
- 🕵️ **完全匿名** — 仅使用设备指纹，无需账号
- 🌍 **支持8种语言** — EN, KO, JA, ZH, ZH-TW, ES, FR, DE

## 使用场景

- "聊几句，然后炸掉房间"
- "开完战略会议，消除所有痕迹"
- "一个链接，立刻集合"
- 游戏组队协调、活动现场沟通、一次性敏感对话

## 设计哲学

BLIP不是即时通讯工具。
它是一个**用完即弃的通信工具**。

它的存在不是为了让人停留更久。
它的存在是为了消除麻烦，说完话，然后消失。

### 我们不做的事

本服务有意**不提供**以下功能：

- ~~添加好友~~
- ~~聊天记录~~
- ~~用户资料~~
- ~~对话存档~~
- ~~社交功能~~

> 我们绝不为了便利而放弃理念。

## 技术栈

- 基于WebSocket的实时通信
- 端到端加密（E2E — Curve25519 ECDH + XSalsa20-Poly1305）
- 服务器仅充当中继角色
- 房间关闭时：服务器和客户端均不可恢复
- 自动粉碎：超出显示范围的消息随blob URL释放立即删除
- 截图防护：标签切换、快捷键、右键菜单检测后模糊处理消息

## BLIP me — 一次性联系链接

在个人资料上分享一个链接。有人点击后，即刻开始1:1加密聊天 — 无需账号，无需添加好友。

- **专属链接** — 创建唯一URL（例如 `blip.me/yourname`）
- **实时提醒** — 访客连接时立即收到通知
- **链接管理** — 随时更改或删除URL
- **无需账号** — 基于设备的令牌证明所有权
- 网页访问 `/blipme`，移动端选择 **BLIP me** 标签

## 我的聊天室

最近创建或加入的聊天室会自动保存到本地 — 无服务器存储。

- **自动保存**: 创建/加入房间时保存到 localStorage（网页）或 SecureStorage（移动端）
- **一键重新加入**: 已保存的密码让你无需重新输入即可进入
- **管理员权限持久化**: 群聊管理员令牌被保存，跨会话保持权限
- **统一列表**: 1:1 和群聊集中管理
- 网页端访问 `/my-rooms`，移动端点击**聊天**标签

> 密码和管理员令牌永远不会离开你的设备。清除浏览器数据会将其永久删除。

## 嵌入

一个iframe即可将BLIP聊天添加到任何网站：

```html
<iframe
  src="https://blip-blip.vercel.app/embed"
  width="400"
  height="600"
  style="border: none;"
  allow="clipboard-write"
></iframe>
```

监听嵌入事件：

```js
window.addEventListener('message', (e) => {
  if (e.origin !== 'https://blip-blip.vercel.app') return;

  switch (e.data.type) {
    case 'blip:ready':         // 小组件加载完成
    case 'blip:room-created':  // 房间创建（roomId, shareUrl）
    case 'blip:room-joined':   // 进入聊天
    case 'blip:room-destroyed': // 房间销毁
  }
});
```

- 轻量布局 — 无广告、无导航
- 保持完整的端到端加密
- 分享链接保持在嵌入上下文中
- 完整示例：[embed-example.html](../web/public/embed-example.html)

## 下载

<a href="https://play.google.com/store/apps/details?id=com.bakkum.blip" target="_blank"><img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="在 Google Play 上获取" width="200"></a>
<a href="https://apps.apple.com/us/app/blip-ephemeral-chat/id6759429660" target="_blank"><img src="https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg" alt="在 App Store 上下载" width="170"></a>

## 支持

如果您喜欢这个项目，请我喝杯咖啡吧！

<a href="https://buymeacoffee.com/ryokai" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>

## 许可证

MIT
