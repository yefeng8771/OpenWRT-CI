# 本轮精简变更记录

## 目标

这轮调整的目标不是继续堆功能，而是**主动降复杂度**：

- EasyTier 继续跟上游构建，只切到最新 prerelease
- 移除 mosdns / momo / daed 相关链路
- 只保留 sing-box 裸核运行
- WiFi SSID 分频段脚本不再作为必须能力维护
- fantastic-packages feed 不再预置到主线构建

## 主要改动

| 模块 | 调整 | 结果 |
|---|---|---|
| `Config/CUSTOM.txt` | 禁用 `luci-app-momo` `luci-app-mosdns` `luci-app-daed` | 代理栈回到 sing-box only |
| `Patches/inject-binaries.sh` | 去掉 mosdns 二进制、配置包、init 注入 | 注入逻辑只剩 sing-box |
| `Patches/packages.sh` | 清理 `momo` `mosdns` `daed` 相关包目录 | 构建链更干净 |
| `files/etc/uci-defaults/99-qwrt-defaults` | 不再接管 DNS / IPv6 等系统默认项 | 首次启动更稳、更接近原生 OpenWrt |
| `Patches/patches.d/easytier-pre.sh` | 保留 | EasyTier 继续走上游构建，只升 prerelease |
| `Patches/pre-feed/00-fantastic-feed.sh` | 删除 | 不再为未实际使用的 feed 增加复杂度 |
| `Patches/patches.d/wifi-band-ssid.sh` | 不再作为当前维护重点 | SSID 定制失败时不阻塞主线 |

## 当前状态

当前 fork 的主线可以概括成：

- **构建层**：尽量贴上游
- **代理层**：只保留 sing-box 裸核
- **组网层**：保留 EasyTier，但不接管其构建链
- **默认行为**：从"全家桶预配置"退回"最小可用"

## 这么做的收益

1. 构建失败点更少
2. 首次开机更不容易翻车
3. 排障路径明显缩短
4. 上游同步冲突面收窄
5. 避免因为无用 feed 增加 feeds update / install 的不确定性

## 代价

1. 不再提供 mosdns 的现成 DNS 分流体验
2. 不再保留 momo 的 LuCI 包装层
3. 需要用户自己填写 sing-box 节点和按需启用服务

但从长期维护看，这个 trade-off 是划算的。
