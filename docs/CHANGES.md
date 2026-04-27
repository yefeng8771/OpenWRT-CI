# 变更记录 — `fix/audit-and-bare-singbox`

本 PR 是对前期 fork 改动的一次审计 + 修复 + 框架补全。

## 1. Bug 修复（P1–P8）

| ID | 文件 | 问题 | 修复 |
|----|------|------|------|
| P1 | `Patches/brand.sh` | 第 18 行 sed 引号嵌套错误，`WRT_CONFIG` 永远不会改写 | 改用 `\|` 作分隔符；同时移除对 `QCA-6.12-VIKINGYFY.yml` 的运行时 sed（改由 `QWRT.yml` 静态指定） |
| P2 | `Patches/patches.d/fantastic-feed.sh` + `WRT-CORE.yml` | 脚本在 `Apply Custom Patches` 阶段跑（feeds update 之后），永远不会真正生效；硬编码已经在 yml 第 161 行 | 拆出 `Patches/pre-feed/00-fantastic-feed.sh`，新增 `Pre-Feed Patches` 步骤位于 `Update Feeds` 之前 |
| P3 | `files/etc/...`（缺失） | 裸核 sing-box 缺少 init/config/nft/uci-defaults，刷机后跑不起来 | 新增 4 个文件（见下） |
| P4 | `Patches/packages.sh` | `REMOVE_PACKAGES` 漏 `tailscale/zerotier/vlmcsd/ddns-go` | 补全 |
| P5 | `Config/CUSTOM.txt` | 没禁源码 mosdns，opkg 安装阶段会覆盖 yyysuo 注入版 | 加 `CONFIG_PACKAGE_mosdns=n` `sing-box=n` `kmod-nft-tproxy=y` 等 |
| P6 | `Patches/patches.d/momo-fix.sh` | sed 不鲁棒，只匹配 ` +sing-box`（强制单空格） | 改 ERE+g：`s/[[:space:]]*\+sing-box//g` |
| P7 | `Patches/patches.d/wifi-band-ssid.sh` | 二阶 sed 链式，依赖第一条成功才能触发第二条 | 单条 sed 直接替换为三元 ucode 表达式 |
| P8 | `Patches/patches.d/easytier-pre.sh` | `curl api.github.com` 匿名访问，CI 限速 60 次/h | 加 `Authorization: Bearer ${GITHUB_TOKEN}` header |

## 2. 新增文件

### 裸核 sing-box 运行框架
- `files/etc/init.d/sing-box` — procd init 脚本（启动时自动配 `ip rule fwmark 1 → table 100`）
- `files/etc/sing-box/config.json` — 默认配置（TProxy 7896 + DNS 7800 + fakeip + 占位节点）
- `files/etc/nftables.d/40-singbox-tproxy.nft` — fw4 自动加载的 TProxy 转发规则（含 fakeip 段、EasyTier 段直连）
- `files/etc/uci-defaults/99-qwrt-defaults` — 首启动一次性配置：dnsmasq → mosdns 转发，LAN IPv6 不下发 DNS，服务默认状态

### 工作流
- `.github/workflows/QWRT.yml` — 专用编译工作流，矩阵静态为 `[IPQ60XX-WIFI]`，品牌静态为 QWRT/172.16.3.1
- 重写 `.github/workflows/Auto-Sync-Upstream.yml` — 真合并（POST /merges）替代原 force-reset

### 文档
- `docs/CHANGES.md`（本文件）
- `docs/CONFIGURATION.md` — mosdns/sing-box/easytier 全栈配置教程
- `docs/ARCHITECTURE.md` — 同步、构建、运行时三层架构说明

### 补丁
- `Patches/pre-feed/00-fantastic-feed.sh`（从 `patches.d/` 移过来并扩展）

## 3. 行为变更

### 3.1 Auto-Sync-Upstream 改为真合并
**之前**：`gh api ... -X PATCH ... force:true` 把 main 强制重置到上游 SHA → 我们的 `Patches/`、`CUSTOM.txt`、`Auto-Sync-Upstream.yml` 自身都会被擦除（"Restore Custom Files" 步骤只检查不恢复）。

**之后**：`POST /repos/X/Y/merges` 创建合并提交。冲突时开 issue 通知人工处理，绝不丢工作。

### 3.2 编译矩阵收敛到 IPQ60XX-WIFI
- `QCA-6.12-VIKINGYFY.yml` 不再用于 CI（被 Auto-Sync 同步成功后 `gh workflow disable` 关闭）
- 所有编译走 `QWRT.yml`，矩阵 `[IPQ60XX-WIFI]`，设备由 `device-config.sh` 收敛到 `jdcloud_re-cs-02`

### 3.3 momo 默认禁用，sing-box 裸核运行
- `CUSTOM.txt` 仍然把 `luci-app-momo=y` 编进固件（保留备用）
- `uci-defaults/99-qwrt-defaults` 让 momo 默认 `disable`，sing-box 默认 `disable`，mosdns 默认 `enable`
- 用户在 LuCI 里编辑 sing-box 配置加节点后再手动启用

## 4. 文件清单

```
新增：
  .github/workflows/QWRT.yml
  docs/ARCHITECTURE.md
  docs/CHANGES.md
  docs/CONFIGURATION.md
  files/etc/init.d/sing-box
  files/etc/nftables.d/40-singbox-tproxy.nft
  files/etc/sing-box/config.json
  files/etc/uci-defaults/99-qwrt-defaults
  Patches/pre-feed/00-fantastic-feed.sh

修改：
  .github/workflows/Auto-Sync-Upstream.yml
  .github/workflows/WRT-CORE.yml
  Config/CUSTOM.txt
  Patches/brand.sh
  Patches/device-config.sh
  Patches/inject-binaries.sh
  Patches/packages.sh
  Patches/patches.d/easytier-pre.sh
  Patches/patches.d/momo-fix.sh
  Patches/patches.d/wifi-band-ssid.sh

删除（移动到新位置）：
  Patches/patches.d/fantastic-feed.sh  →  Patches/pre-feed/00-fantastic-feed.sh
```
