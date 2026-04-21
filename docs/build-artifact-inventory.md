# Build Artifact Inventory

## Purpose

这份文档记录最终固件产物和验证方式。

重点不是记录“理论上应该有什么”，而是记录“编译后实际包含了什么”。

后续每次重要改动后，都应该根据最新构建产物刷新这份文档。

---

## Current Build Target

- Workflow：`QCA-6.12-VIKINGYFY`
- Config：`IPQ60XX-WIFI`
- Device：`jdcloud_re-cs-02`
- Firmware line：`12M only`

---

## Artifact Source Of Truth

编译产物核对时，以下内容优先级最高：

1. Release 里的 `*.manifest`
2. Release 里的 `Config-*.txt`
3. 最终 rootfs 中的实际文件
4. GitHub Actions 日志中的 package list

不要只根据 `Config/GENERAL.txt` 推测最终固件内容。

---

## Current Artifact Naming Rule

产物由 `WRT-CORE.yml` 打包并重命名。

主要规则：

- 配置文件会进入 `upload/`
- 固件会带上平台、分支、日期信息
- 最终由 GitHub Release 上传

后续如果命名规则变了，要先更新这份文档。

---

## Key Runtime Components To Verify

每次构建后，优先确认这些关键组件是否真的进入固件：

| Component | Expected Result | Verification Source | Notes |
| --- | --- | --- | --- |
| `luci-app-momo` | present | `*.manifest` / LuCI | 运行时前端应存在 |
| `luci-app-easytier` | present | `*.manifest` / LuCI | LuCI 前端应存在 |
| `easytier` | present | `*.manifest` | 当前 manifest 已确认存在 |
| `easytier-core` | present in `/usr/bin` | rootfs / package install result | 需通过 rootfs 或设备内实测确认 |
| `easytier-cli` | present in `/usr/bin` | rootfs / package install result | 需通过 rootfs 或设备内实测确认 |
| `sing-box` | present in `/usr/bin/sing-box` | rootfs | 由 `Settings.sh` 注入，不会体现在 manifest 包列表里 |
| `nikki` | absent | `*.manifest` | 不应再出现 |
| `passwall` | absent | `*.manifest` | 不应再出现 |
| `passwall2` | absent | `*.manifest` | 不应再出现 |
| `homeproxy` | absent | `*.manifest` | 不应再出现 |
| `tailscale` | absent | `*.manifest` | 不应再出现 |
| `lucky` | absent | `*.manifest` | 不应再出现 |
| `ddns-go` | absent | `*.manifest` | 不应再出现 |
| `gecoosac` | absent | `*.manifest` | 不应再出现 |
| `openclash` | absent | `*.manifest` | 不应再出现 |
| `vnt` | absent | `*.manifest` | 不应再出现 |

---

## Latest Verified Release

## Release Record

- Release tag: `QCA-6.12-VIKINGYFY-IPQ60XX-WIFI_26.04.21-02.10.23`
- Release URL: `https://github.com/yefeng8771/OpenWRT-CI/releases/tag/QCA-6.12-VIKINGYFY-IPQ60XX-WIFI_26.04.21-02.10.23`
- Source repo: `https://github.com/VIKINGYFY/immortalwrt.git`
- Source branch: `main`
- Source commit: `30e074d`
- Config: `IPQ60XX-WIFI`
- Device: `jdcloud_re-cs-02`
- Login IP: `172.16.3.1`
- Kernel: `6.12.80`
- Manifest file: `-main-qualcommax-ipq60xx-26.04.21-02.10.23.manifest`
- Config file: `Config-IPQ60XX-WIFI--main-26.04.21-02.10.23.txt`
- Factory firmware: `-main-qualcommax-ipq60xx-jdcloud_re-cs-02-squashfs-factory-26.04.21-02.10.23.bin`
- Sysupgrade firmware: `-main-qualcommax-ipq60xx-jdcloud_re-cs-02-squashfs-sysupgrade-26.04.21-02.10.23.bin`
- Result: `release uploaded successfully`
- Notes: `当前 release 描述中的插件列表已包含 luci-app-momo 和 luci-app-easytier`

---

## Latest Manifest Review

- Confirmed present in manifest:
  - `easytier`
  - `luci-app-easytier`
  - `luci-app-momo`

- Confirmed absent in manifest:
  - `nikki`
  - `passwall`
  - `passwall2`
  - `homeproxy`
  - `tailscale`
  - `lucky`
  - `ddns-go`
  - `gecoosac`
  - `openclash`
  - `vnt`

- Not manifest-verifiable, requires rootfs or runtime verification:
  - `/usr/bin/sing-box`
  - `/usr/bin/easytier-core`
  - `/usr/bin/easytier-cli`

- Practical conclusion:
  - 包层已经确认 `momo + easytier` 在固件中
  - 裁剪目标包已经确认未进入 manifest
  - `sing-box` 属于运行时注入路径，需要在 rootfs 或设备内进一步确认

---

## Release Recording Template

每次发布后，复制下面这个模板补一条记录：

```md
## Release Record

- Release tag:
- Workflow run:
- Source repo:
- Source branch:
- Source commit:
- Config:
- Device:
- Manifest file:
- Firmware file:
- Result:
- Notes:
```

---

## Manifest Review Template

每次检查 manifest 时，优先补这一段：

```md
## Manifest Review

- Confirmed present:
  - luci-app-momo
  - luci-app-easytier
  - easytier

- Confirmed runtime files:
  - /usr/bin/sing-box
  - /usr/bin/easytier-core
  - /usr/bin/easytier-cli

- Confirmed absent:
  - nikki
  - passwall
  - passwall2
  - homeproxy
  - tailscale
  - lucky
  - ddns-go
  - gecoosac
  - openclash
  - vnt
```

---

## Refresh Rule

满足以下任一条件时，应该刷新这份文档：

- 改了 `Config/GENERAL.txt`
- 改了 `Scripts/Packages.sh`
- 改了 `Scripts/Settings.sh`
- 改了任何本地 package 定义
- 换了上游源码分支
- 构建成功并产生了新的 Release

---

## Practical Rule

如果下次只想快速判断“这次改动会不会影响最终固件”，优先看：

1. `docs/package-inventory.md`
2. 最新 Release 的 `*.manifest`
3. 这份文档里的 `Key Runtime Components To Verify`

这样就不用重新从头分析整仓库。
