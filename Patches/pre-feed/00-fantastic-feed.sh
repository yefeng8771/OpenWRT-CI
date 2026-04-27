#!/bin/bash
# 00-fantastic-feed.sh — 添加 fantastic-packages feed
#
# **必须在 ./scripts/feeds update -a 之前执行**，否则新 feed 不会被索引。
# 因此本脚本放在 Patches/pre-feed/，由 WRT-CORE.yml 在 "Update Feeds" 步骤之前调用，
# 而非和其他细粒度补丁一起放在 patches.d/（那个目录在 feeds 之后才执行）。
#
# 仓库 fantastic-packages/packages 的官方 README 推荐写法：
#   src-git --root=feeds fantastic_packages https://github.com/fantastic-packages/packages.git;master
# 其中 --root=feeds 指明 feed 内容在仓库的 feeds/ 子目录，是 OpenWrt scripts/feeds 的扩展。
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[fantastic-feed] Adding fantastic-packages feed..."
FEEDS_CONF="$WORKSPACE/$WRT_DIR/feeds.conf.default"

if [ ! -f "$FEEDS_CONF" ]; then
    echo "[fantastic-feed] WARNING: $FEEDS_CONF not found, source not yet cloned?"
    exit 0
fi

if grep -q "fantastic_packages" "$FEEDS_CONF"; then
    echo "[fantastic-feed] Already present, nothing to do"
else
    echo "src-git --root=feeds fantastic_packages https://github.com/fantastic-packages/packages.git;master" >> "$FEEDS_CONF"
    echo "[fantastic-feed] Added to feeds.conf.default"
fi

echo "[fantastic-feed] Done"
