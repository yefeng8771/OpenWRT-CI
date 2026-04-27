# QWRT 完整配置教程

> 适用：jdcloud_re-cs-02（京东云亚瑟）+ ImmortalWrt 24.10 / VIKINGYFY main + IPv4+IPv6 双栈

## 0. 快速概览

```
LAN: 172.16.3.0/24 (IPv4) + 公网 PD/64 (IPv6)
    │
    ▼
dnsmasq:53 (DHCP only, noresolv)
    │ 全部转发
    ▼
mosdns:5335 (yyysuo 魔改版，Web UI)
    │ 国内 → 阿里 DoT
    │ 国外 → udp://127.0.0.1:7800 (sing-box DNS in)
    │            └─→ fake IP (198.18.x.x / fc00::/18)
    ▼
客户端拿 fakeip 发起 TCP/UDP
    │
    ▼ nftables fwmark + ip rule
sing-box tproxy:7896 (sniff 还原域名)
    │ DIRECT / PROXY / AUTO / REJECT / CN / Final
    ▼
真实节点（VLESS / Trojan / Hysteria2 ...）

横向：EasyTier mesh 10.10.1.0/24，子网代理本地 LAN 172.16.3.0/24
```

## 1. OpenWrt IPv4 + IPv6 基础

### 1.1 LAN

`网络 → 接口 → LAN`：
- IPv4 地址：`172.16.3.1`
- IPv4 掩码：`255.255.255.0`
- IPv6 后缀：`eui64`（确保前缀变化时 LAN IP 不变）
- DHCP → 通用：忽略接口 ❌
- DHCP → IPv6：
  - 路由通告 (RA-Service)：**服务器模式**
  - DHCPv6 服务：**禁用**
  - NDP 代理：**禁用**
  - **取消勾选「Local IPv6 DNS server」** ← 关键，迫使客户端用 IPv4 网关查 DNS
  - 始终通告默认路由：✅

> 这些已由 `files/etc/uci-defaults/99-qwrt-defaults` 在首启动时自动设置，不必手动改。

### 1.2 WAN / WAN6

`网络 → 接口 → WAN`：
- 协议：PPPoE（按运营商）
- 高级 → ❌ 使用对方分配的 DNS
- ✅ 启用 IPv6 协商
- ✅ 委托 IPv6 前缀
- IPv6 分配长度：留空
- DHCP → IPv6：全部 disabled

如运营商不下发 PD，按 `https://blog.cycx.top:91/2026/01/28/openwrt-ipv6-设置方案/` 的 B 方案新建 WAN6 接口。

### 1.3 防火墙

保留 fw4 默认；本固件已携带 `/etc/nftables.d/40-singbox-tproxy.nft`，启用 sing-box 时 `fw4 reload` 自动加载。

## 2. mosdns（yyysuo + firetv 配置包）

固件已注入：
- `/usr/bin/mosdns` ← yyysuo 二进制
- `/etc/mosdns/` ← firetv `mosdns20251225allup.zip` 内容
- `/etc/init.d/mosdns` ← 修改了 `CONF=./config_custom.yaml`

### 2.1 首次进入 LuCI

`服务 → MosDNS`：

| 选项 | 值 |
|---|---|
| 启用 | ✅ |
| 监听端口 | `5335` |
| eBPF 53 端口重定向 | ✅ |
| 启用 LuCI Web UI | ✅ |

### 2.2 进入 mosdns 自带 Web UI

浏览器访问 `http://172.16.3.1:9099/`（端口看 `config_custom.yaml` 里 `api: addr: ":9099"`，按你实际值）。

#### 上游 DNS 设置（`upstream_overrides.json`）

| 组 | 配置 |
|---|---|
| `domestic` | 阿里 DoT `tls://223.5.5.5`、腾讯 `https://doh.pub/dns-query`、运营商 DNS（看 `https://ipw.cn/`）|
| `cnfake` | 同 domestic（一条即可）|
| `nocnfake` | **`udp://127.0.0.1:7800`** ← sing-box DNS in，fakeip 链路核心 |
| `foreign` | 任意 3 条 DoH/DoT，**SOCKS5 字段**留空（裸核 sing-box 默认无 mixed inbound；如需可在 sing-box 加 `mixed:7890`）|
| `mihomo` | 留空（不用）|
| `sing-box` | `udp://127.0.0.1:7800` |

#### 系统 → 高级 → SOCKS5/ECS IP

- ECS IP：填 `https://ipw.cn/` 看到的本机公网 IPv6 地址（启用 v6 后会有）

### 2.3 验证

```bash
nslookup baidu.com  127.0.0.1 -port=5335    # 国内 IP，毫秒级
nslookup youtube.com 127.0.0.1 -port=5335   # 198.18.x.x（fakeip）
```

## 3. sing-box（裸核 TProxy）

固件已携带：
- `/usr/bin/sing-box` ← reF1nd prerelease 1.14.x
- `/etc/sing-box/config.json` ← 占位节点的默认模板
- `/etc/init.d/sing-box`
- `/etc/nftables.d/40-singbox-tproxy.nft`

默认 `disable`，需先填节点再启用。

### 3.1 编辑配置文件

SSH 登录路由器：

```bash
vi /etc/sing-box/config.json
```

把 `outbounds` 段里两个占位 VLESS 节点改成你的真实订阅。最简单：从机场拿 sing-box 订阅 → 替换 `outbounds` 与 `route.rule_set`。

### 3.2 验证配置语法

```bash
sing-box check -c /etc/sing-box/config.json && echo OK
```

### 3.3 启用并启动

```bash
/etc/init.d/sing-box enable
/etc/init.d/sing-box start
fw4 reload                # 加载 nftables.d/40-singbox-tproxy.nft
ip rule show              # 应有 "100: from all fwmark 0x1 lookup 100"
ip route show table 100   # 应有 "local default dev lo"
```

### 3.4 一键自检

```bash
# 路由器自身可以走代理
curl -m 5 https://www.youtube.com -I

# 看 zashboard
# 浏览器：http://172.16.3.1:9090/ui
```

### 3.5 模式对比 / 选型

| 维度 | TProxy（本固件采用）| TUN | Redirect |
|---|---|---|---|
| 协议 | TCP+UDP+v6 完整 | TCP+UDP+v6 完整 | **TCP only**，UDP 死 |
| 性能 | 最高，可走 NSS Flow Offload | 中（用户态转发）| 低（NAT 表压力）|
| 源 IP/端口保留 | ✅ | ✅ | 改写 |
| 嗅探 + fakeip | 完美 | 完美 | 残废 |
| 推荐度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ |

## 4. EasyTier（10.10.1.0/24 + 子网代理 172.16.3.0/24）

`服务 → EasyTier`：

| 选项 | 值 |
|---|---|
| 启用 | ✅ |
| 网络名 | 自定义如 `qwrt-mesh` |
| 网络密钥 | 强密码 |
| 本机 IPv4 | `10.10.1.1/24` |
| 监听 | `tcp://0.0.0.0:11010`、`udp://0.0.0.0:11010`、`wg://0.0.0.0:11011` |
| 对端 (`peer`) | `tcp://公网节点:11010` |
| 子网代理 | `172.16.3.0/24` ← 把本路由器 LAN 暴露给 mesh |
| 自动配置接口 | ✅ |
| 自动配置防火墙 | ✅ |

mesh 段 `10.10.1.0/24` 已被 sing-box 配置和 nftables 规则双重直连白名单，不会被代理吃掉。

## 5. momo（备用，默认禁用）

固件保留 `luci-app-momo`（已修过 `+sing-box` 依赖）但默认禁用。
要切换回 momo 模式：

```bash
/etc/init.d/sing-box stop && /etc/init.d/sing-box disable
fw4 reload          # 清除裸核 nft 规则
/etc/init.d/momo enable && /etc/init.d/momo start
```

momo 会自己写 nftables 规则、调用同一个 `/usr/bin/sing-box` 二进制。

## 6. 常见问题

| 症状 | 原因 | 修法 |
|---|---|---|
| LAN 解析全废 | sing-box 启动后但配置错误，dns hijack 没工作 | 先 `nslookup baidu.com 172.16.3.1`，看看返回什么；不通查 mosdns 日志 `logread -e mosdns` |
| YouTube 能开但搜索框白屏 | sing-box 内部又开了 fakeip，与 mosdns 冲突 | 我们默认配置 `dns.servers` 已包含 fakeip server，但只在 query_type=A/AAAA 路由进 fakeip；如果还冲突，把 `query_type` 那条规则删掉 |
| EasyTier 对端不通 | mesh 段被 sing-box 吃了 | 检查 nft：`nft list table inet sing-box`，应该有 `ip daddr 10.10.1.0/24 return` |
| 启动后 sing-box 一直重启 | 节点错误，TLS 失败导致 urltest 全挂 | `logread -e sing-box -l 50`，把出错节点删掉，或把 PROXY selector 默认改回 DIRECT |
| 重启后 sing-box 没起 | uci-defaults 把它 disable 了，没手动 enable | `/etc/init.d/sing-box enable && start` |

## 7. 调试命令速查

```bash
# 状态
service sing-box status
service mosdns status
service easytier status

# 日志
logread -e sing-box -l 200
logread -e mosdns   -l 200
logread -e easytier -l 200

# nftables
nft list table inet sing-box

# 路由
ip rule show
ip route show table 100
ip -6 rule show
ip -6 route show table 100

# DNS 链路
nslookup baidu.com   172.16.3.1
nslookup youtube.com 172.16.3.1
nslookup baidu.com   127.0.0.1 -port=5335

# Clash API
curl http://127.0.0.1:9090/version
curl http://127.0.0.1:9090/proxies | jq .
```
