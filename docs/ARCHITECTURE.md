# 架构总览

本仓库采用 **fork + patch** 模型：尽量不动上游 `davidtall/OpenWRT-CI`，所有定制隔离在
`Patches/`、`Config/CUSTOM.txt`、`files/` 与一份独立的 `QWRT.yml` 工作流里。

## 1. 三层架构

```
┌────────────────────────────────────────────────────────────────────┐
│  L1 同步层  (.github/workflows/Auto-Sync-Upstream.yml)              │
│  每天 03:00 上海时间                                                 │
│   ├ 比较 ahead/behind                                                │
│   ├ POST /repos/.../merges  base=main  head=upstream-sync-temp       │
│   ├ 冲突 → 开 issue → 人工解决                                       │
│   └ 成功 → disable QCA-* yml + 触发 QWRT.yml                          │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│  L2 构建层  (.github/workflows/QWRT.yml + WRT-CORE.yml)              │
│  matrix=[IPQ60XX-WIFI]  品牌静态 QWRT/172.16.3.1                     │
│   1. Pre-Feed Patches  → Patches/pre-feed/*.sh （加 fantastic feed）│
│   2. Update Feeds      → ./scripts/feeds update -a                   │
│   3. Custom Packages   → Scripts/Packages.sh + Handles.sh            │
│   4. Custom Settings   → generate_config; Settings.sh; WRT_PACKAGE  │
│   5. Apply Custom Patches:                                           │
│        Patches/brand.sh        修 diy.sh                             │
│        Patches/device-config.sh 收敛到 jdcloud_re-cs-02              │
│        Patches/packages.sh      增删上游 package/                    │
│        Patches/patches.d/*.sh   细粒度补丁                           │
│        cat Config/CUSTOM.txt >> .config                              │
│        make defconfig + clean                                        │
│   6. Inject Prebuilt Binaries                                        │
│        Patches/inject-binaries.sh                                    │
│           复制 files/* → wrt/files/                                  │
│           下载 sing-box / mosdns / firetv-config / mosdns-init        │
│   7. Compile + Release                                                │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│  L3 运行时   (路由器固件内)                                           │
│   /usr/bin/sing-box  /usr/bin/mosdns  /usr/bin/easytier-core         │
│   /etc/sing-box/config.json   /etc/mosdns/config_custom.yaml         │
│   /etc/init.d/{sing-box,mosdns,easytier,momo}                        │
│   /etc/nftables.d/40-singbox-tproxy.nft                              │
│   /etc/uci-defaults/99-qwrt-defaults  (首启动一次性)                  │
└────────────────────────────────────────────────────────────────────┘
```

## 2. 文件分类

| 类型 | 路径 | 上游存在？ | 同步影响 |
|---|---|---|---|
| 工作流 - 自定义 | `.github/workflows/QWRT.yml` | ❌ | 不冲突 |
| 工作流 - 自定义 | `.github/workflows/Auto-Sync-Upstream.yml` | ❌ | 不冲突 |
| 工作流 - 修改 | `.github/workflows/WRT-CORE.yml` | ✅ | 上游改了会冲突，需手动 merge |
| 工作流 - 上游 | `.github/workflows/QCA-6.12-VIKINGYFY.yml` | ✅ | 同步后由 Auto-Sync 步骤 disable |
| 补丁脚本 | `Patches/**` | ❌ | 不冲突 |
| 配置覆盖 | `Config/CUSTOM.txt` | ❌ | 不冲突 |
| 配置 - 修改 | `Config/IPQ60XX-WIFI.txt` | ✅ | **device-config.sh 在运行时改，at-rest 不改**，不冲突 |
| 注入文件 | `files/**` | ✅（上游有空 `files/` 目录） | 一般不冲突 |
| 文档 | `docs/**` | ❌ | 不冲突 |
| 上游核心 | `Scripts/`, `package/`, `patches/` | ✅ | 完全跟随上游，不动 |

**结论**：除 `WRT-CORE.yml` 外，所有定制都是「上游不存在的新文件」，不会和上游产生冲突。  
唯一可能冲突的是 `WRT-CORE.yml`，因为我们插了 `Pre-Feed Patches`、`Apply Custom Patches`、`Inject Prebuilt Binaries` 三步。

## 3. 同步策略

### 3.1 当前（修复后）：真合并

```
Auto-Sync-Upstream.yml:
  1. compare upstream:main ↔ origin:main
  2. behind == 0 → 退出
  3. behind > 0:
       a. git refs POST upstream-sync-temp → upstream HEAD
       b. POST /merges base=main head=upstream-sync-temp
       c. 成功 → 合并提交进 main，触发 QWRT.yml
       d. 冲突 → 开 issue（标签 auto-sync-conflict），不动 main
       e. cleanup temp ref
```

### 3.2 之前（已修复）的问题

老的 `Auto-Sync-Upstream.yml` 用 `gh api refs/heads/main -X PATCH ... force:true`，相当于 `git push --force` 把 main 重置到上游 SHA。

副作用：
- `Patches/`（11 个文件）从 main 上消失
- `Config/CUSTOM.txt` 消失
- `Auto-Sync-Upstream.yml` 自己消失（自杀）
- `files/`、`docs/` 消失
- "Restore Custom Files" 步骤只检查不恢复，仅 `WRT-CORE.yml` 通过 Contents API PUT 复活

第一次上游推新提交 = 整个 fork 报废。新 PR 改用合并 API 杜绝此问题。

## 4. 冲突处理

如果 Auto-Sync 检测到合并冲突会开 issue（标签 `auto-sync-conflict`）。本地解决步骤：

```bash
git remote add upstream https://github.com/davidtall/OpenWRT-CI.git
git fetch upstream main
git checkout main
git merge upstream/main
# 解决冲突，多半在 .github/workflows/WRT-CORE.yml
git commit
git push origin main
```

若上游对 `WRT-CORE.yml` 做了大改，可以参考 `docs/CHANGES.md` 第 2 节的「修改」清单，把我们插入的三个步骤（Pre-Feed Patches / Apply Custom Patches / Inject Prebuilt Binaries）重新拼回去。

## 5. 关键设计决策

### 5.1 为什么不用 git rebase
rebase 会重写我们的提交，让 GitHub Compare 永远显示 "ahead 35"，每次同步都得重新 force push。merge 提交虽然有"merge bubble"，但 ahead/behind 计数稳定、可审计。

### 5.2 为什么 QWRT.yml 静态写品牌而不是 brand.sh sed
两个原因：
- 上游 yml 一改我们就冲突，runtime sed 多一份脆弱依赖
- `workflow_call` 入参在 yml 顶部用 `with:` 块声明，和 sed 改硬编码字符串相比，可读性高得多

### 5.3 为什么把 fantastic-feed 拆到 pre-feed/ 而不是和其它 patches 共处
`patches.d/` 在 `Apply Custom Patches` 阶段执行（feeds update 之后），而 `feeds.conf.default` 必须在 feeds update 之前修改才有效。强行用文件名前缀 `00-` 也无法让 it run earlier in the same step。所以另起一个目录最干净。

### 5.4 为什么默认禁用 sing-box
sing-box 占位配置里的节点是 `x.x.x.x`，启动会立刻失败重启。默认 `disable` 让用户先填节点再 `enable`，避免 100M log spam。
