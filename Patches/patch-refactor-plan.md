# Patch 重构计划（当前版）

## 1. 目标

把 fork 差异收敛成最少的几个稳定入口：

- `Config/CUSTOM.txt`
- `Patches/packages.sh`
- `Patches/patches.d/easytier-pre.sh`
- `Patches/inject-binaries.sh`
- `files/`
- 可选的 pre-feed patch（仅在确实需要新增 feed 时再引入）

## 2. 当前建议结构

```text
Patches/
├── brand.sh
├── device-config.sh
├── packages.sh
├── inject-binaries.sh          # 只注入 sing-box
└── patches.d/
    └── easytier-pre.sh         # 只负责 EasyTier prerelease

Config/
└── CUSTOM.txt

files/
└── etc/
    ├── init.d/sing-box
    ├── nftables.d/40-singbox-tproxy.nft
    ├── sing-box/config.json
    └── uci-defaults/99-qwrt-defaults
```

## 3. 重构原则

### 原则一：二进制注入只留 sing-box

不要再把 mosdns 之类额外组件塞回 `inject-binaries.sh`。

### 原则二：EasyTier 不接管构建链

只改版本，不改它的主构建逻辑。

### 原则三：默认行为最小化

不要在 `uci-defaults` 里做太多网络栈接管动作。

### 原则四：失败不阻塞主线

像 WiFi SSID 分频段这种"锦上添花"能力，如果不稳定，就不应该继续占主线复杂度预算。

### 原则五：不要预置无实际消费的 feed

只有当当前仓库真的要编译某个 feed 里的包时，才引入对应 pre-feed patch。
如果仓库本身没有消费 `fantastic-packages` 的包，就不要把它写进主线。
