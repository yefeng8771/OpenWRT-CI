# Package Inventory

## Purpose

这份文档记录三类信息：

- 上游默认的关键软件包
- fork 删除、恢复、新增的软件包
- 每个新增软件包的来源仓库与集成方式

这份表的目标不是覆盖最终固件的全部包，而是记录维护层真正关心的包。

---

## Upstream Default Key Packages

| Package | Upstream Default | Notes |
| --- | --- | --- |
| `luci-app-daed` | enabled | 上游默认开启 |
| `luci-app-dae` | enabled | 上游默认开启 |
| `luci-app-nikki` | enabled | 当前 fork 已关闭 |
| `luci-app-homeproxy` | disabled | 上游默认注释 |
| `luci-app-gecoosac` | enabled | 当前 fork 已关闭 |
| `luci-app-tailscale` | enabled | 当前 fork 已关闭 |
| `luci-app-ddns-go` | enabled | 当前 fork 已关闭 |
| `luci-app-lucky` | enabled | 当前 fork 已关闭 |
| `luci-theme-argon` | enabled | 上游默认开启 |
| `luci-app-zerotier` | enabled | 上游默认开启 |

---

## Current Fork Package Decisions

| Package | Action | Integration | Source Repo | Main Control Files | Notes |
| --- | --- | --- | --- | --- | --- |
| `luci-app-momo` | restore/enable | config + upstream repo injection | `https://github.com/nikkinikki-org/OpenWrt-momo` | `Config/GENERAL.txt`, `Scripts/Packages.sh` | 保留 `OpenWrt-momo`，但不再依赖编译版 `sing-box` |
| `luci-app-easytier` | add/enable | upstream repo injection | `https://github.com/EasyTier/luci-app-easytier` | `Config/GENERAL.txt`, `Scripts/Packages.sh` | LuCI 前端 |
| `easytier` | add/enable | prerelease binary package | `https://github.com/EasyTier/EasyTier` | `Config/GENERAL.txt`, `Scripts/Packages.sh`, `package/easytier/Makefile` | 安装 `easytier-core` 和 `easytier-cli` |
| `sing-box` | remove compiled package, keep runtime | prerelease binary to `/usr/bin` | `https://github.com/reF1nd/sing-box-releases` | `Config/GENERAL.txt`, `Scripts/Packages.sh`, `Scripts/Settings.sh` | 不再编译 `package/sing-box` |
| `nikki` | disable/remove | config + package removal | upstream default | `Config/GENERAL.txt`, `Scripts/Packages.sh` | 不保留 |
| `homeproxy` | remove | package removal | upstream/default feeds | `Scripts/Packages.sh` | 不保留 |
| `openclash` | remove | package removal | upstream/default feeds | `Scripts/Packages.sh` | 不保留 |
| `passwall` | remove | package removal | upstream/default feeds | `Scripts/Packages.sh` | 不保留 |
| `passwall2` | remove | package removal | upstream/default feeds | `Scripts/Packages.sh` | 不保留 |
| `tailscale` | disable/remove | config + package removal | upstream/default feeds | `Config/GENERAL.txt`, `Scripts/Packages.sh` | 不保留 |
| `vnt` | remove | package removal | upstream/default feeds | `Scripts/Packages.sh` | 不保留 |
| `ddns-go` | disable/remove | config + package removal | upstream/default feeds | `Config/GENERAL.txt`, `Scripts/Packages.sh` | 不保留 |
| `lucky` | disable/remove | config + package removal | upstream/default feeds | `Config/GENERAL.txt`, `Scripts/Packages.sh` | 不保留 |
| `gecoosac` | disable/remove | config + package removal | upstream/default feeds | `Config/GENERAL.txt`, `Scripts/Packages.sh` | 不保留 |

---

## Current Binary Integration Rules

### `sing-box`

- 来源：`reF1nd/sing-box-releases`
- 版本策略：最新 `prerelease`
- 集成方式：构建时下载 tar.gz，解压后放入 `/usr/bin/sing-box`
- 运行方式：由 `OpenWrt-momo` 调用
- 关键约束：不能再被 `package/sing-box` 编译链拉回去

### `easytier`

- 来源：`EasyTier/EasyTier`
- 版本策略：最新 `prerelease`
- 资产类型：`easytier-linux-aarch64-v*.zip`
- 安装内容：`easytier-core`、`easytier-cli`
- 当前集成方式：预编译二进制 package 安装到 `/usr/bin`

---

## Current Local Packages In Repo

当前仓库里存在的本地 package 目录：

- `package/dae`
- `package/easytier`
- `package/luci-app-dae`
- `package/sing-box`
- `package/v2ray-geodata`

其中需要特别注意：

- `package/sing-box` 仍然存在于仓库，用于过渡和兼容排查
- 但当前维护策略已经显式在构建时移除它，不让它进入最终编译链

---

## Update Checklist For Future Package Changes

下次改包时，更新这 5 列：

- `Package`
- `Action`
- `Integration`
- `Source Repo`
- `Main Control Files`

如果新增包，没有填仓库地址，这份清单就算没更新完整。
