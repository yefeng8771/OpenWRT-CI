# OpenWRT-CI Fork 更改分析文档

> 对比上游：`davidtall/OpenWRT-CI` (main)
> Fork：`yefeng8771/OpenWRT-CI` (main)
> 更新日期：2026-04-27

---

## 一、总体概述

Fork 的核心目标：**与上游保持同步，仅编译京东云亚瑟 (jdcloud_re-cs-02) WiFi 固件，品牌 QWRT。**

所有自定义通过 `Patches/` 外置，对源项目侵入式修改最小化。

---

## 二、定制修改详表

### 2.1 品牌参数

| 参数 | 上游值 | QWRT 值 |
|------|--------|---------|
| WRT_NAME | DAE-WRT | **QWRT** |
| WRT_SSID | DAE-WRT | **QWRT**（按频段 QWRT4/5/6） |
| WRT_IP | 192.168.10.1 | **172.16.3.1** |

### 2.2 设备与编译矩阵

| 项目 | 上游 | QWRT |
|------|------|------|
| 编译矩阵 | `[IPQ60XX-NOWIFI, IPQ60XX-WIFI]` | **仅 `[IPQ60XX-WIFI]`** |
| 启用设备 | 全系列 8 台 | **仅 jdcloud_re-cs-02** |

### 2.3 插件变更对比

**删除的插件（上游有，QWRT 移除）：**

| 插件 | 说明 | 移除原因 |
|------|------|----------|
| homeproxy | 代理客户端 | 已有 daed |
| nikki | 代理客户端 | 已有 daed |
| openclash | Clash 客户端 | 已有 daed |
| passwall | 代理客户端 | 已有 daed |
| passwall2 | 代理客户端 | 已有 daed |
| gecoosac | 科学工具 | 不需要 |
| vnt | P2P VPN | 不需要 |
| tailscale | VPN | 不需要 |
| zerotier | VPN | 不需要 |
| vlmcsd | KMS 激活 | 不需要 |
| ddns-go | DDNS | 不需要 |

**修改行为的插件：**

| 插件 | 上游行为 | QWRT 行为 | 原因 |
|------|----------|-----------|------|
| mosdns | 源码编译 sbwml v5 | **删除源码，注入 yyysuo 预编译二进制** | Web UI / eBPF / 自动更新 |
| sing-box | 随包依赖编译 | **注入 reF1nd prerelease 二进制** | 最新版 |
| easytier | 源码包下载稳定版 | **删除源码包，注入 prerelease 二进制** | 最新功能 |
| momo | 直接安装 | 移除 **+sing-box 依赖** | sing-box 已外部注入 |

**新增的插件（上游没有）：**

| 插件 | 说明 |
|------|------|
| luci-app-tinyfilemanager | Web 文件管理器 |
| luci-app-natmapt + natmapt | NAT 端口映射 |

### 2.4 二进制注入

| 二进制 | 来源 | 目标路径 |
|--------|------|----------|
| sing-box | `reF1nd/sing-box-releases` prerelease | /usr/bin/sing-box |
| mosdns | `yyysuo/mosdns` latest | /usr/bin/mosdns |
| easytier-core | `EasyTier/EasyTier` prerelease | /usr/bin/easytier-core |
| easytier-cli | `EasyTier/EasyTier` prerelease | /usr/bin/easytier-cli |
| easytier-web | `EasyTier/EasyTier` prerelease | /usr/bin/easytier-web |
| mosdns 配置 | `yyysuo/firetv` | /etc/mosdns/ |
| mosdns init | `yyysuo/mosdns` scripts | /etc/init.d/mosdns |

### 2.5 其他设置修改

| 修改项 | 实现 |
|--------|------|
| 新增 fantastic-packages feed | `patches.d/fantastic-feed.sh` |
| WiFi SSID 按频段区分 | `patches.d/wifi-band-ssid.sh` |
| WRT_PACKAGE 输入验证 | 内联 WRT-CORE.yml |
| v2ray-geodata-updater 禁用 | CUSTOM.txt |
| mosdns init CONF 路径 → config_custom.yaml | inject-binaries.sh |

---

## 三、EasyTier + sing-box 共存注意事项

同一路由器运行 EasyTier 和 sing-box 时需注意：

1. **TUN 模式冲突**：两者都创建 TUN 接口，可能导致路由表混乱，控制面在线但数据面不通
2. **推荐方案**：EasyTier 关闭 TUN，开启 SOCKS5 代理；sing-box 将 EasyTier SOCKS5 作为上游代理
3. **分流规则**：将 EasyTier 网段 CIDR 流量指向 EasyTier 代理
4. **绕过规则**：确保 EasyTier 网段不在代理的绕过列表中
5. **UDP 限制**：EasyTier SOCKS5 不支持 UDP
6. **端口规划**：EasyTier 默认 11010，避免与 sing-box 冲突

---

## 四、Patches 目录结构

```
Patches/
├── brand.sh                # 品牌定制（名称、IP、WiFi）
├── device-config.sh        # 设备选择覆盖
├── packages.sh             # 包增删（删除代理/VPN/科学，删除 mosdns/easytier 源码，新增 natmapt/tinyfilemanager）
├── inject-binaries.sh      # 二进制注入（sing-box + mosdns + easytier prerelease）
├── patches.d/
│   ├── fantastic-feed.sh   # 添加 fantastic-packages feed
│   ├── momo-fix.sh         # momo 移除 sing-box 依赖
│   └── wifi-band-ssid.sh   # WiFi 按频段区分 SSID
├── fork-changes-analysis.md
├── patch-refactor-plan.md
└── mosdns-guide.md
```

## 五、与上游同步

使用 `Auto-Sync-Upstream.yml` 自动同步：Git Data API 强制重置 main 到上游 HEAD，再恢复自定义文件。
