# Fork 差异分析（精简版）

## 1. 当前 fork 与上游的核心差异

相比上游 `davidtall/OpenWRT-CI`，当前 fork 主要保留这几类差异：

| 类别 | 当前策略 |
|---|---|
| 自动同步 | 保留 `Auto-Sync-Upstream.yml`，用真正 merge 的方式跟上游同步 |
| 构建入口 | 保留 `QWRT.yml` 作为自定义编译入口 |
| 配置覆盖 | 通过 `Config/CUSTOM.txt` 控制插件启停与内核模块 |
| 代理核心 | 只保留 sing-box 裸核 |
| 组网 | 保留 EasyTier，上游构建，只升 prerelease |
| 默认行为 | 首启只处理服务状态，不接管系统 DNS |

## 2. 当前保留的功能取舍

### 保留

- sing-box 裸核运行
- EasyTier 最新 prerelease
- 自动同步上游
- 少量品牌/设备级 patch

### 移除 / 不再维护

- mosdns
- momo
- daed
- WiFi SSID 分频段改名

## 3. 当前设计判断

这版 fork 的方向是：

**把复杂网络全家桶收缩成 sing-box + EasyTier 两层结构。**

收益很明确：

- 更容易同步上游
- 更容易定位构建问题
- 更容易定位运行时问题
- 文档也更容易维护

## 4. 维护建议

后续继续演进时，尽量遵守两条：

1. 能不接管上游的功能，就别接管
2. 能放在 `files/` 的运行时差异，就不要写成复杂 patch 链
