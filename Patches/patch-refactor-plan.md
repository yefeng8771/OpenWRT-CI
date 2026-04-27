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
├── inject-binaries.sh      # 二进制注入（sing-box + mosdns + easytier）
├── patches.d/
│   ├── fantastic-feed.sh   # fantastic-packages feed
│   ├── momo-fix.sh         # momo 移除 sing-box 依赖
│   └── wifi-band-ssid.sh   # WiFi 按频段区分 SSID
├── fork-changes-analysis.md
├── patch-refactor-plan.md
└── mosdns-guide.md

Config/
└── CUSTOM.txt              # 自定义配置覆盖
```

## 三、二进制注入说明

以下组件不从源码编译，而是在 CI 构建时下载 prerelease/latest 预编译二进制注入：

| 组件 | 来源 | 版本策略 |
|------|------|----------|
| sing-box | reF1nd/sing-box-releases | prerelease |
| mosdns | yyysuo/mosdns | latest release |
| easytier-core/cli/web | EasyTier/EasyTier | prerelease |

上游 Packages.sh 会 clone easytier 源码包，packages.sh 会将其删除，改由 inject-binaries.sh 注入 prerelease 二进制。

上游 Packages.sh 也会 clone mosdns 源码包，packages.sh 同样删除，改由 inject-binaries.sh 注入 yyysuo 预编译。

## 四、CI 工作流

WRT-CORE.yml 中新增两个 step：

1. **Apply Custom Patches** — 调用 brand.sh → device-config.sh → packages.sh → patches.d/*.sh → 追加 CUSTOM.txt → make defconfig/clean
2. **Inject Prebuilt Binaries** — 调用 inject-binaries.sh 下载并注入二进制

## 五、自动同步

Auto-Sync-Upstream.yml：Git Data API 强制重置 main → 上游 HEAD，再恢复自定义文件和 WRT-CORE.yml 修改，触发编译。
