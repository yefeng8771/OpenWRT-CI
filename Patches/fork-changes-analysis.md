# OpenWRT-CI Fork 更改分析文档

> 对比上游：`davidtall/OpenWRT-CI` (main)
> Fork：`yefeng8771/OpenWRT-CI` (main)
> 分析日期：2026-04-25
> 状态：ahead 12 commits / behind 2 commits / diverged

---

## 一、总体概述

Fork 的核心目标是：**将上游的 DAE-WRT 品牌定制为 QWRT 品牌固件，聚焦京东云亚瑟设备，替换 mosdns/sing-box 为预编译二进制注入方案，并精简不需要的代理插件。**

---

## 二、逐文件差异分析

### 2.1 `diy.sh` — 本地构建入口

| 改动项 | 上游值 | Fork 值 | 类型 |
|--------|--------|---------|------|
| 默认配置 | `IPQ60XX-NOWIFI` | `IPQ60XX-WIFI` | 品牌定制 |
| 品牌名 WRT_NAME | `OWRT` | `QWRT` | 品牌定制 |
| WiFi名 WRT_SSID | `OWRT` | `QWRT` | 品牌定制 |
| 默认IP WRT_IP | `192.168.10.1` | `172.16.3.1` | 品牌定制 |
| fantastic-packages feed | 无 | 新增 `src-git --root=feeds fantastic_packages` | 功能增强 |
| feeds 清理方式 | 注释掉的 `rm -rf feeds` | `rm -rf feeds/*` | 构建修复 |

### 2.2 `.github/workflows/QCA-6.12-VIKINGYFY.yml` — CI 触发配置

| 改动项 | 上游值 | Fork 值 | 类型 |
|--------|--------|---------|------|
| 编译矩阵 CONFIG | `[IPQ60XX-NOWIFI, IPQ60XX-WIFI]` | `[IPQ60XX-WIFI]` | 设备精简 |
| WRT_THEME | `aurora` | `argon` | 品牌定制 |
| WRT_NAME | `DAE-WRT` | `QWRT` | 品牌定制 |
| WRT_SSID | `DAE-WRT` | `QWRT` | 品牌定制 |
| WRT_IP | `192.168.10.1` | `172.16.3.1` | 品牌定制 |

### 2.3 `.github/workflows/WRT-CORE.yml` — CI 核心流程

**新增 step（关键改动）：** `Inject reF1nd sing-box prerelease and yyysuo mosdns runtime`

此 step 完成以下操作：
1. 从 `$GITHUB_WORKSPACE/files/` 复制自定义文件到构建目录
2. 检测目标架构（aarch64/x86_64）
3. 从 `reF1nd/sing-box-releases` 下载 sing-box prerelease musl 二进制 → `/usr/bin/sing-box`
4. 从 `yyysuo/mosdns` 下载最新 mosdns 二进制 → `/usr/bin/mosdns`
5. 从 `yyysuo/firetv` 下载 mosdns 配置包 → `/etc/mosdns/`
6. 从 `yyysuo/mosdns` 下载 OpenWrt init 脚本，修改 CONF 路径为 `config_custom.yaml` → `/etc/init.d/mosdns`

### 2.4 `Scripts/Packages.sh` — 软件包管理

#### 删除的包（上游有，Fork 没有）

| 包名 | 说明 |
|------|------|
| `homeproxy` | ImmortalWrt 官方代理客户端 |
| `nikki` | 代理客户端 |
| `openclash` | Clash 图形客户端 |
| `passwall` | 代理客户端 |
| `passwall2` | 代理客户端 |
| `gecoosac` | 科学工具 |
| `vnt` | P2P VPN |

#### 新增的包（Fork 有，上游没有）

| 包名 | 说明 |
|------|------|
| `luci-app-lucky` | 多功能工具 |
| `luci-app-tinyfilemanager` | 文件管理器 |
| `natmapt` | NAT 端口映射 |
| `luci-app-natmapt` | NAT 端口映射 LuCI |

#### 修改的包逻辑

| 包名 | 上游 | Fork | 说明 |
|------|------|------|------|
| `momo` | 直接安装 | 安装后移除 sing-box 依赖 | momo 不需要内置 sing-box，用外部注入的 |
| `mosdns` | `UPDATE_PACKAGE "sbwml/luci-app-mosdns" "v5"` | 注释掉，改由 workflow 下载 yyysuo 预编译 | 核心改动：从源码编译改为二进制注入 |
| `easytier` | 直接安装 | 安装后更新到 prerelease 版本 | 使用最新测试版 |

### 2.5 `Scripts/Settings.sh` — 构建设置

| 改动项 | 上游 | Fork | 类型 |
|--------|------|------|------|
| 镜像源替换 | `sed -i 's/mirrors.vsean.net/mirror.nju.edu.cn/g'` | 删除此行 | 清理 |
| WiFi SSID 设置 | 统一 `ssid='$WRT_SSID'` | 按频段区分：2g=QWRT4, 5g=QWRT5, 6g=QWRT6 | 品牌定制 |
| WRT_PACKAGE 过滤 | 直接 `echo -e "$WRT_PACKAGE" >> .config` | 增加 `sed`/`grep` 过滤无效行 | 构建修复 |

### 2.6 `Config/GENERAL.txt` — 通用配置

#### 代理插件变更

| 包名 | 上游 | Fork | 说明 |
|------|------|------|------|
| `luci-app-homeproxy` | 无（未列出） | `=n` | 显式禁用 |
| `luci-app-nikki` | `=y` | `=n` | 禁用 |
| `luci-app-momo` | 注释 | `=y` | 启用 |
| `luci-app-openclash` | 无 | `=n` | 显式禁用 |
| `luci-app-passwall` | 无 | `=n` | 显式禁用 |
| `luci-app-passwall2` | 无 | `=n` | 显式禁用 |
| `luci-app-sing-box` | 无 | `=n` | 显式禁用 |

#### 功能插件变更

| 包名 | 上游 | Fork | 说明 |
|------|------|------|------|
| `luci-app-gecoosac` | `=y` | `=n` | 禁用 |
| `luci-app-tailscale` | `=y` | `=n` | 禁用 |
| `luci-app-zerotier` | `=y` | `=n` | 禁用 |
| `luci-app-vlmcsd` | `=y` | `=n` | 禁用 |
| `luci-app-ddns-go` | `=y` | `=n` | 禁用 |
| `luci-app-lucky` | 无 | `=y` | 新增 |
| `luci-app-tinyfilemanager` | 无 | `=y` | 新增 |
| `luci-app-natmapt` | 无 | `=y` | 新增 |
| `v2ray-geodata-updater` | `=y` | 注释掉 | geodata 由 daed 自带 |

### 2.7 `Config/IPQ60XX-WIFI.txt` — 设备选择

| 设备 | 上游 | Fork |
|------|------|------|
| cmiot_ax18 | `=y` | `=n` |
| jdcloud_re-ss-01 | `=y` | `=n` |
| jdcloud_re-cs-02 | `=y` | `=y` (唯一启用) |
| qihoo_360v6 | `=y` | `=n` |
| redmi_ax5-jdcloud | `=y` | `=n` |
| redmi_ax5 | `=y` | `=n` |
| xiaomi_ax1800 | `=y` | `=n` |
| zn_m2 | `=y` | `=n` |

### 2.8 新增文件（Fork 独有）

| 文件 | 说明 |
|------|------|
| `files/etc/init.d/mosdns` | mosdns OpenWrt init 脚本（START=99，CONF=./config.yaml） |
| `files/etc/mosdns/config.yaml` | 最简 mosdns 配置（仅转发 Google DNS，占位用，实际被 workflow 覆盖） |

### 2.9 未修改的文件

| 文件 | 说明 |
|------|------|
| `Scripts/Handles.sh` | 与上游完全一致 |
| `Scripts/function.sh` | 与上游完全一致 |
| `Scripts/init_build_environment.sh` | 与上游完全一致 |

---

## 三、改动分类汇总

### A. 品牌定制（参数替换类）

- WRT_NAME: DAE-WRT → QWRT
- WRT_SSID: DAE-WRT → QWRT
- WRT_IP: 192.168.10.1 → 172.16.3.1
- WRT_THEME: aurora → argon
- WiFi SSID 按频段区分

### B. 设备/插件选择（配置选择类）

- 编译矩阵只保留 IPQ60XX-WIFI
- 设备只保留 jdcloud_re-cs-02
- 代理插件开关
- 新增插件

### C. 功能增强（逻辑变更类）

1. 二进制注入机制（sing-box + mosdns）
2. fantastic-packages feed
3. momo 依赖修改
4. easytier 版本更新
5. daed Makefile 补丁
6. WRT_PACKAGE 输入验证

### D. 构建修复

- feeds 清理方式
- WRT_PACKAGE 过滤

### E. 清理

- 移除镜像源替换

---

## 四、与上游同步的冲突风险评估

| 文件 | 冲突风险 | 原因 |
|------|----------|------|
| `QCA-6.12-VIKINGYFY.yml` | 中 | 品牌参数散布在 workflow 中 |
| `WRT-CORE.yml` | 高 | 新增了大段二进制注入 step |
| `Config/GENERAL.txt` | 高 | 双方都在调整插件列表 |
| `Config/IPQ60XX-WIFI.txt` | 中 | 设备选择差异 |
| `Scripts/Packages.sh` | 高 | 包列表大幅不同，新增逻辑 |
| `Scripts/Settings.sh` | 中 | WiFi 逻辑变更、过滤逻辑 |
| `diy.sh` | 中 | 品牌参数、feed 新增 |
