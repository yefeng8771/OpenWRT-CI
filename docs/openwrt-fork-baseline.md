# OpenWrt Fork Baseline

## Purpose

这份文档记录当前 fork 的维护基线。

目标是让后续修改不需要重新从头分析仓库，而是直接基于这份基线做增量调整。

---

## Repositories

- 上游仓库：`https://github.com/davidtall/OpenWRT-CI`
- 个人 fork：`https://github.com/yefeng8771/OpenWRT-CI`
- 当前 fork 基线提交：`c1be6a2`
- 当前上游参考提交：`2d80a39`

---

## Repository Workflow Map

- Compile entry：`.github/workflows/QCA-6.12-VIKINGYFY.yml`
- Compile core：`.github/workflows/WRT-CORE.yml`
- Sync workflow：`.github/workflows/sync-upstream.yml`
- Target selection：`QCA-6.12-VIKINGYFY.yml` 的 `CONFIG: [IPQ60XX-WIFI]`
- Profile selection：`Config/IPQ60XX-WIFI.txt`
- Package config source：`Config/GENERAL.txt`
- Package injection path：`Scripts/Packages.sh`
- System settings path：`Scripts/Settings.sh`
- Rootfs overlay path：`files/`
- Local package path：`package/`
- Artifact output path：`wrt/upload/`，由 `WRT-CORE.yml` 发布到 GitHub Release

---

## Upstream Default Workflow

上游 `davidtall/OpenWRT-CI` 的默认特点：

- 触发方式：`workflow_run + workflow_dispatch`
- 编译范围：`IPQ60XX-NOWIFI` 和 `IPQ60XX-WIFI`
- 默认 LAN IP：`192.168.10.1`
- 默认主题：`aurora`
- 默认主机名：`DAE-WRT`
- 默认 Wi-Fi 名称：`DAE-WRT`
- 默认 Wi-Fi 密码：`12345678`

---

## Current Fork Workflow

当前 fork 的维护策略：

- 触发方式：`push + workflow_dispatch`
- 新增了独立的上游同步 workflow
- 增加了 workflow 并发控制，避免同一分支重复编译
- 只编译单目标：`IPQ60XX-WIFI`
- 只保留单设备：`jdcloud_re-cs-02`

---

## Current Target Policy

- 目标平台：`qualcommax/ipq60xx`
- 目标配置：`IPQ60XX-WIFI`
- 设备 profile：`jdcloud_re-cs-02`
- 固件线定位：`12M only`
- Multi-profile：关闭
- Per-device rootfs：关闭

---

## Current System Defaults

- 默认 LAN IP：`172.16.3.1`
- 默认主题：`aurora`
- 默认主机名：`DAE-WRT`
- 默认 Wi-Fi 名称：`DAE-WRT`
- 默认 Wi-Fi 密码：`12345678`
- 默认登录密码提示：`无`

---

## Current Maintenance Rules

- 尽量保持 fork 与上游同步
- 优先通过配置和脚本做最小修改
- 删除软件包优先走“禁用/注释”，不是深度改包
- 对有现成 release 二进制的软件包，优先直接集成
- 只为 `jdcloud_re-cs-02` 维护固件

---

## Files To Check First

后续任何修改，先检查这些文件：

- `.github/workflows/QCA-6.12-VIKINGYFY.yml`
- `.github/workflows/WRT-CORE.yml`
- `.github/workflows/sync-upstream.yml`
- `Config/GENERAL.txt`
- `Config/IPQ60XX-WIFI.txt`
- `Scripts/Packages.sh`
- `Scripts/Settings.sh`
- `package/easytier/Makefile`
- `files/`

---

## How To Use This Document Next Time

下次改需求时，按这个顺序：

1. 先确认上游基线是否有变化
2. 再确认当前 fork 的 workflow 是否有变化
3. 查 `package-inventory.md`，决定删减或新增哪些包
4. 查 `build-artifact-inventory.md`，确认最终固件里实际包含了什么
5. 只改最小正确层，不要重新大范围翻仓库
