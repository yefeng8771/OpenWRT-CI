# OpenWRT-CI Patch 重构方案

## 一、核心思路

将所有 fork 自定义改动外置为独立的 patch 脚本和配置文件，使得：

1. **主分支可以无损同步上游** — Patches/ 不在上游中，不会冲突
2. **自定义逻辑集中管理** — 所有品牌定制、功能增强都在 `Patches/` 目录下
3. **上游更新只需解决 patch 兼容性** — 不再逐文件手动解决冲突

## 二、目录结构

```
Patches/
├── brand.sh                # 品牌定制
├── device-config.sh        # 设备选择覆盖
├── packages.sh             # 包增删
├── inject-binaries.sh      # 二进制注入（sing-box + mosdns）
├── patches.d/
│   ├── fantastic-feed.sh   # fantastic-packages feed
│   ├── momo-fix.sh         # momo 移除 sing-box 依赖
│   ├── easytier-pre.sh     # 更新 easytier version.mk 到 prerelease
│   └── wifi-band-ssid.sh   # WiFi 按频段区分 SSID
├── fork-changes-analysis.md
├── patch-refactor-plan.md
└── mosdns-guide.md

Config/
└── CUSTOM.txt              # 自定义配置覆盖
```

## 三、二进制注入说明

**注入方式**（编译时下载，直接放入 files/）：

| 组件 | 来源 | 版本策略 |
|------|------|----------|
| sing-box | reF1nd/sing-box-releases | prerelease |
| mosdns | yyysuo/mosdns | latest release |

**版本覆盖方式**（保留上游 Makefile，仅改版本号）：

| 组件 | 上游行为 | QWRT 行为 |
|------|----------|-----------|
| easytier | Makefile 下载稳定版二进制 | `easytier-pre.sh` 更新 version.mk 到 prerelease，Makefile 自动下载 prerelease 二进制 |

## 四、CI 工作流

WRT-CORE.yml 中新增两个 step：

1. **Apply Custom Patches** — 调用 brand.sh → device-config.sh → packages.sh → patches.d/*.sh → 追加 CUSTOM.txt → make defconfig/clean
2. **Inject Prebuilt Binaries** — 调用 inject-binaries.sh 下载并注入 sing-box + mosdns 二进制

## 五、自动同步

Auto-Sync-Upstream.yml：Git Data API 强制重置 main → 上游 HEAD，再恢复自定义文件和 WRT-CORE.yml 修改，触发编译。
