# QWRT 架构说明

## 1. 当前目标

这个 fork 的目标很直接：

- **上游保持可同步**
- **代理栈只保留 sing-box 裸核**
- **EasyTier 继续走上游构建逻辑，只改到最新 prerelease**
- **不再维护 mosdns / momo / daed 这一层额外复杂度**

一句话：**尽量薄改上游，把 fork 差异压缩到必要的运行时和构建定制上。**

## 2. 目录职责

| 路径 | 作用 |
|---|---|
| `Config/CUSTOM.txt` | 自定义编译配置覆盖 |
| `Patches/brand.sh` | 品牌名、展示文案等轻量改动 |
| `Patches/device-config.sh` | 设备相关的额外处理 |
| `Patches/packages.sh` | 删减不需要的软件包、保留必要插件 |
| `Patches/patches.d/easytier-pre.sh` | 将 EasyTier 锁到最新 prerelease |
| `Patches/inject-binaries.sh` | 仅注入 sing-box 预编译二进制 |
| `files/etc/init.d/sing-box` | sing-box 裸核 procd 脚本 |
| `files/etc/sing-box/config.json` | sing-box 默认配置模板 |
| `files/etc/nftables.d/40-singbox-tproxy.nft` | sing-box TProxy 规则 |
| `files/etc/uci-defaults/99-qwrt-defaults` | 首次启动时的最小默认行为 |
| `.github/workflows/QWRT.yml` | 自定义构建入口 |
| `.github/workflows/Auto-Sync-Upstream.yml` | 与上游自动同步 |

## 3. 构建流程

```text
上游源码
  ↓
（可选）Pre-Feed Patch
  ↓
feeds update / install
  ↓
brand.sh / device-config.sh / packages.sh / patches.d/*.sh
  ↓
追加 Config/CUSTOM.txt 到 .config
  ↓
make defconfig
  ↓
inject-binaries.sh 注入 sing-box
  ↓
编译固件
```

## 4. 当前设计原则

### 4.1 sing-box 是唯一代理核心

当前 fork 只保留 sing-box 裸核：

- 不再依赖 momo
- 不再依赖 mosdns
- 不再依赖 daed
- 不主动接管默认 DNS

这样做的核心收益是：**运行链路更短，排障路径更清晰。**

### 4.2 EasyTier 保持上游构建

EasyTier 不走二进制注入，也不额外接管它的打包逻辑。
当前只做一件事：

- 通过 `Patches/patches.d/easytier-pre.sh` 更新 `version.mk`
- 让上游构建流程继续负责下载和打包 EasyTier

这能把 fork 对 EasyTier 的维护成本压到最低。

### 4.3 首启动默认最小化

`99-qwrt-defaults` 不再改 dnsmasq / IPv6 / peerdns 等系统级默认行为，
只统一处理服务状态：

- `sing-box` 默认禁用
- `easytier` 默认禁用
- 若历史上残留 `momo / mosdns / daed` 服务，也统一禁用

目的不是"功能最多"，而是**首次刷机最稳**。

## 5. 维护建议

后续如果继续收敛 fork，优先级建议如下：

1. 继续压缩自定义点，尽量避免同步后大量 restore
2. 让 `WRT-CORE.yml` 与上游差异保持在最小集合
3. 把运行时差异集中在 `files/` 与少量 patch 脚本里
4. 不要预置当前没有实际消费的 feed
5. 新增功能前先问一句：它是否真的值得增加维护成本
