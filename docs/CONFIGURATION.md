# QWRT 配置说明（精简版）

## 1. 当前推荐拓扑

当前固件推荐的使用方式非常简单：

- **代理核心：sing-box 裸核**
- **组网：EasyTier**
- **DNS：保持系统默认，按需再定制**

也就是说，先保证：

- 固件能正常启动
- 网络默认可用
- 你手动填好 sing-box 节点后再启用代理
- 你手动填好 EasyTier 参数后再启用组网

## 2. sing-box

### 2.1 文件位置

| 路径 | 说明 |
|---|---|
| `/usr/bin/sing-box` | CI 注入的 sing-box 二进制 |
| `/etc/init.d/sing-box` | procd 启动脚本 |
| `/etc/sing-box/config.json` | 默认配置模板 |
| `/etc/nftables.d/40-singbox-tproxy.nft` | TProxy 规则 |

### 2.2 首次使用

先编辑配置：

```sh
vi /etc/sing-box/config.json
```

把里面的占位节点换成你自己的真实节点，然后检查配置：

```sh
sing-box check -c /etc/sing-box/config.json
```

通过后再启用：

```sh
/etc/init.d/sing-box enable
/etc/init.d/sing-box start
```

### 2.3 常用排障

```sh
logread -e sing-box -l 200
service sing-box status
nft list table inet sing-box
```

如果启动后反复重启，通常是：

- 节点参数写错
- TLS / Reality 参数不匹配
- 出口测试失败导致 selector 全挂

## 3. EasyTier

### 3.1 当前策略

EasyTier 保持上游构建逻辑，不做二进制注入。
当前 fork 只做一件事：把 `version.mk` 更新到最新 prerelease。

### 3.2 启用方式

先在 LuCI 或配置文件里填好网络参数，再启用：

```sh
/etc/init.d/easytier enable
/etc/init.d/easytier start
```

### 3.3 排障

```sh
service easytier status
logread -e easytier -l 200
```

## 4. 默认行为

`99-qwrt-defaults` 当前只做最小动作：

- `sing-box` 默认禁用
- `easytier` 默认禁用
- 若历史遗留 `momo / mosdns / daed` 服务，统一禁用

它**不会**主动改你系统的 DNS、IPv6、peerdns 等默认行为。

## 5. 不再默认维护的能力

以下内容已不再作为当前主线能力维护：

- mosdns
- momo
- daed
- WiFi SSID 分频段自动改名

如果后面你又想加回来，建议单独做 feature flag，而不是重新塞回默认主线。
