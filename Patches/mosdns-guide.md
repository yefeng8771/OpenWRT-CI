# mosdns (yyysuo) 配置指南

> 适用项目：`yefeng8771/OpenWRT-CI` 中集成的 yyysuo/mosdns
> 文档日期：2026-04-25

---

## 一、项目概述

### 1.1 什么是 mosdns

mosdns 是一个**插件化的 DNS 转发器**，专为 OpenWrt 路由器设计。核心能力：
- 拦截 DNS 查询，按规则分流到不同上游 DNS
- 国内域名走国内 DNS，国外域名走代理 DNS（通过 SOCKS5 代理）
- 集成 nftables/ipset 实现 IP 分流
- 支持 eBPF DNS 加速和劫持

### 1.2 yyysuo/mosdns vs 原版 IrineSistiana/mosdns

| 特性 | 原版 (v5.3.4) | yyysuo fork |
|------|--------------|-------------|
| Web 管理界面 | 无 | 有（完整 Dashboard） |
| 运行时覆盖 | 无 | config_overrides.json + upstream_overrides.json |
| eBPF DNS 加速 | 无 | 有（cilium/ebpf，性能翻倍） |
| 阿里 DNS API | 无 | 有（aliapi 插件） |
| 自动更新 | 无 | 有（从 GitHub releases 拉取） |
| 开关插件 | 无 | switcher1~16（运行时切换规则） |
| Domain Mapper | 无 | 有（O(1) 多域名集匹配） |
| 版本格式 | v5.3.4 | v5-ph-srs-YYYYMMDD-sha |
| 更新频率 | 低 | 高（每 2-5 天自动发布） |

### 1.3 在 OpenWRT-CI 中的集成方式

通过 `Patches/inject-binaries.sh` 在 CI 构建时：
1. 从 `yyysuo/mosdns` releases 下载 `mosdns-linux-arm64.zip`
2. 注入到固件的 `/usr/bin/mosdns`
3. 从 `yyysuo/firetv` 下载配置包 `mosdns1225all.zip` 解压到 `/etc/mosdns/`
4. 从 `yyysuo/mosdns` 下载 init 脚本到 `/etc/init.d/mosdns`

---

## 二、固件中的文件布局

```
/usr/bin/mosdns                          # 二进制文件
/etc/init.d/mosdns                       # procd init 脚本 (START=99)
/etc/mosdns/                             # 工作目录
├── config.yaml 或 config_custom.yaml   # 主配置文件
├── config_overrides.json                # 运行时覆盖（SOCKS5/ECS）
├── upstream_overrides.json              # 上游 DNS 覆盖
├── gen/                                 # 生成文件
│   └── top_domains.txt                  # 热门域名列表
├── rule/                                # 域名规则文件
└── nft/                                 # nftables 配置
    ├── nft.conf                         # nft 规则
    ├── purenft.conf                     # 纯 nft 规则
    ├── nftadd.json                      # eBPF 配置
    └── fixip.txt                        # IP 修正
```

---

## 三、首次配置步骤

### 3.1 刷入固件后验证

```sh
ls -la /usr/bin/mosdns
ls -la /etc/mosdns/
ls -la /etc/init.d/mosdns
```

### 3.2 启用并启动服务

```sh
chmod +x /etc/init.d/mosdns
/etc/init.d/mosdns enable
/etc/init.d/mosdns start
```

### 3.3 访问 Web 管理界面

默认监听端口 **9099**：`http://<路由器IP>:9099/`

### 3.4 配置 SOCKS5 代理

**通过 Web UI：** System → SOCKS5 设置，填写 dae/sing-box 入站地址如 `127.0.0.1:7891`

**通过 config_overrides.json：**

```json
{
  "socks5": "127.0.0.1:7891",
  "ecs": "",
  "replacements": [
    {"original": "nft_false", "new": "nft_true", "comment": "启用 nftables"},
    {"original": "ebpf_nohijack", "new": "ebpf_hijack", "comment": "启用 eBPF DNS 劫持"}
  ]
}
```

### 3.5 配置上游 DNS

**通过 upstream_overrides.json：**

```json
{
  "forward_domestic": [
    {"tag": "ali_dns", "enabled": true, "protocol": "doh", "addr": "https://dns.alidns.com/dns-query", "socks5": ""}
  ],
  "forward_foreign": [
    {"tag": "google_dns", "enabled": true, "protocol": "doh", "addr": "https://dns.google/dns-query", "socks5": "127.0.0.1:7891"}
  ]
}
```

### 3.6 将路由器 DNS 指向 mosdns

```sh
uci set dhcp.@dnsmasq[0].noresolv='1'
uci set dhcp.@dnsmasq[0].server='127.0.0.1#5335'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

---

## 四、配置文件详解

### 4.1 config_custom.yaml 结构

```yaml
log:
  level: info
  file: ""

include:
  - "extra_config.yaml"

api:
  http: "0.0.0.0:9099"

plugins:
  - tag: forward_domestic
    type: forward
    args:
      upstreams:
        - addr: https://dns.alidns.com/dns-query

  - tag: forward_foreign
    type: forward
    args:
      upstreams:
        - addr: https://dns.google/dns-query
          socks5: "127.0.0.1:7891"

  - tag: udp_server
    type: udp_server
    args:
      listen: 127.0.0.1:53
      entry: main_sequence

  - tag: main_sequence
    type: sequence
    args:
      exec:
        - if: has_resp
          exec: [ttl 3600-86400]
          else: [forward_domestic]
```

### 4.2 config_overrides.json

| 字段 | 说明 |
|------|------|
| `socks5` | 全局 SOCKS5 代理地址 |
| `ecs` | EDNS Client Subnet IP |
| `replacements` | 通用字符串替换（功能开关） |

### 4.3 upstream_overrides.json

- `forward_domestic`：国内 DNS 上游组
- `forward_foreign`：国外 DNS 上游组

---

## 五、eBPF DNS 加速

### 5.1 功能说明

- DNS 劫持到 sing-box/mihomo tproxy 入站
- 过期缓存服务（QPS 翻倍）
- 配置优化 + 极限缓存提升约 60% QPS

### 5.2 启用条件

1. 内核支持 eBPF（已开启）
2. sing-box/mihomo 配置 tproxy 入站
3. config_overrides.json 启用 `ebpf_hijack`
4. nftables 规则正确

---

## 六、后期维护

### 6.1 更新 mosdns 二进制

**Web UI：** System → Update

**手动：**
```sh
curl -fL -o /tmp/mosdns.zip "https://github.com/yyysuo/mosdns/releases/latest/download/mosdns-linux-arm64.zip"
unzip -q /tmp/mosdns.zip -d /tmp/mosdns-update
install -m 0755 /tmp/mosdns-update/mosdns /usr/bin/mosdns
/etc/init.d/mosdns restart
```

### 6.2 更新 mosdns 配置

**Web UI：** System → Config Management → 输入 URL：
```
https://raw.githubusercontent.com/yyysuo/firetv/refs/heads/master/mosdnsconfigupdate/mosdns1225all.zip
```

### 6.3 CI 版本控制

`Patches/inject-binaries.sh` 使用 `releases/latest` 自动获取最新版。如需固定版本：
```bash
MOSDNS_API="https://api.github.com/repos/yyysuo/mosdns/releases/tags/v5-ph-srs-20260424-1af2981"
```

### 6.4 排查问题

```sh
/etc/init.d/mosdns status
logread -f | grep mosdns
nslookup google.com 127.0.0.1
nslookup baidu.com 127.0.0.1
netstat -tlnp | grep mosdns
```

### 6.5 与 dae 的协作关系

```
DNS 查询 → mosdns(53) → 规则匹配
  ├── 国内域名 → 国内 DNS (直连)
  └── 国外域名 → 国外 DNS (SOCKS5 代理) → dae/sing-box (7891)

DNS 响应 IP → mosdns 写入 nftables 集合 → dae 读取集合 → 流量路由
  ├── 国内 IP → 直连
  └── 国外 IP → 代理
```

---

## 七、配置参考

### 7.1 常用国内 DNS

| 提供商 | DoH 地址 |
|--------|---------|
| 阿里 DNS | `https://dns.alidns.com/dns-query` |
| 腾讯 DNS | `https://doh.pub/dns-query` |
| 114 DNS | `https://doh.114dns.com/dns-query` |

### 7.2 常用国外 DNS

| 提供商 | DoH 地址 |
|--------|---------|
| Google | `https://dns.google/dns-query` |
| Cloudflare | `https://cloudflare-dns.com/dns-query` |

### 7.3 相关仓库

| 仓库 | 用途 |
|------|------|
| `yyysuo/mosdns` | 二进制 + init 脚本 |
| `yyysuo/firetv` | 配置包（ZIP） |
| `IrineSistiana/mosdns` | 原版上游 |
| 原版 Wiki | https://irine-sistiana.gitbook.io/mosdns-wiki/ |
