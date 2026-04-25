# OpenWRT-CI Patch 重构方案

## 一、核心思路

将所有 fork 自定义改动外置为独立的 patch 脚本和配置文件，使得：

1. **主分支可以无损同步上游** — merge 上游时被修改的文件恢复为上游版本，然后重新运行 patch
2. **自定义逻辑集中管理** — 所有品牌定制、功能增强都在 `Patches/` 目录下
3. **上游更新只需解决 patch 兼容性** — 不再逐文件手动解决冲突

## 二、目录结构设计

```
OpenWRT-CI/
├── Patches/                    # 所有自定义改动集中于此
│   ├── brand.sh                # 品牌定制（名称、IP、主题、WiFi）
│   ├── packages.sh             # 包列表差异（增删改）
│   ├── inject-binaries.sh      # 二进制注入逻辑（从 WRT-CORE.yml 抽取）
│   ├── device-config.sh        # 设备选择覆盖
│   ├── patches.d/              # 细粒度补丁
│   │   ├── fantastic-feed.sh   # 添加 fantastic-packages feed
│   │   ├── momo-fix.sh         # momo 移除 sing-box 依赖
│   │   ├── easytier-pre.sh     # easytier prerelease 更新
│   │   ├── daed-makefile.sh    # daed Makefile 替换
│   │   └── wifi-band-ssid.sh   # WiFi 按频段区分 SSID
│   ├── fork-changes-analysis.md  # Fork 差异分析文档
│   ├── patch-refactor-plan.md    # 本方案文档
│   └── mosdns-guide.md           # mosdns 配置指南
├── Config/
│   ├── ...（上游原样）
│   └── CUSTOM.txt              # 覆盖 GENERAL.txt 的自定义部分
├── files/                      # mosdns init 和配置
├── Scripts/                    # 尽量恢复为上游原样
├── .github/workflows/
│   ├── WRT-CORE.yml            # 恢复为上游原样 + 调用 patch 脚本
│   └── QCA-6.12-VIKINGYFY.yml  # 恢复为上游原样，参数由 patch 覆盖
└── diy.sh                      # 恢复为上游原样 + 调用 patch
```

## 三、改动分类与重构策略

### 3.1 可以完全外置的改动

| 改动 | 当前位置 | 重构为 | 理由 |
|------|----------|--------|------|
| 品牌参数 | diy.sh, QCA workflow | `Patches/brand.sh` | 纯参数替换 |
| WiFi 按频段 SSID | Settings.sh | `Patches/patches.d/wifi-band-ssid.sh` | 覆盖上游逻辑 |
| 包列表增删 | Packages.sh | `Patches/packages.sh` | 追加/删除 |
| 设备选择 | IPQ60XX-WIFI.txt | `Patches/device-config.sh` | 覆盖设备开关 |
| 代理插件禁用 | GENERAL.txt | `Config/CUSTOM.txt` | 追加覆盖 |
| fantastic-packages feed | diy.sh | `Patches/patches.d/fantastic-feed.sh` | 追加 feed |
| momo 移除 sing-box | Packages.sh | `Patches/patches.d/momo-fix.sh` | 独立补丁 |
| easytier prerelease | Packages.sh | `Patches/patches.d/easytier-pre.sh` | 独立补丁 |
| daed Makefile | Packages.sh | `Patches/patches.d/daed-makefile.sh` | 已有补丁文件 |
| WRT_PACKAGE 验证 | Settings.sh | `Patches/patches.d/package-filter.sh` | 增强逻辑 |
| 二进制注入 | WRT-CORE.yml | `Patches/inject-binaries.sh` | 从 workflow 抽取 |

## 四、重构后的工作流

```
同步上游 → 运行 patch 脚本 → 编译
```

### 4.1 同步上游

```bash
git remote add upstream https://github.com/davidtall/OpenWRT-CI.git
git fetch upstream
git merge upstream/main
# Patches/ 不在上游中，不会冲突
```

### 4.2 应用 patch

```bash
bash Patches/brand.sh
bash Patches/packages.sh
bash Patches/inject-binaries.sh
bash Patches/device-config.sh
for f in Patches/patches.d/*.sh; do bash "$f"; done
```

### 4.3 CI 中自动应用

WRT-CORE.yml 中 "Apply Custom Patches" step 调用所有 patch 脚本。

## 五、关键重构：二进制注入从 Workflow 抽取为脚本

当前 ~80 行注入逻辑嵌在 WRT-CORE.yml 中，重构后 `Patches/inject-binaries.sh` 包含所有逻辑，WRT-CORE.yml 只需一行调用。

## 六、预期收益

| 维度 | 当前 | 重构后 |
|------|------|--------|
| 同步上游冲突文件数 | 7 | 0（Patches/ 不存在于上游） |
| 品牌定制修改 | 散布在 4+ 个文件 | 集中在 brand.sh |
| 包列表维护 | 直接改 Packages.sh | 追加到 packages.sh |
| 二进制注入维护 | 改 WRT-CORE.yml | 改 inject-binaries.sh |
