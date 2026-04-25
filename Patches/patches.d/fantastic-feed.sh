#!/bin/bash
# fantastic-feed.sh — 添加 fantastic-packages feed
# 在 diy.sh 的 feeds.conf.default 中追加第三方 feed

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[fantastic-feed] Adding fantastic-packages feed..."

FEEDS_CONF="$WORKSPACE/$WRT_DIR/feeds.conf.default"
if [ -f "$FEEDS_CONF" ]; then
    if ! grep -q "fantastic_packages" "$FEEDS_CONF"; then
        echo "src-git --root=feeds fantastic_packages https://github.com/fantastic-packages/packages.git;master" >> "$FEEDS_CONF"
        echo "[fantastic-feed] Added to feeds.conf.default"
    else
        echo "[fantastic-feed] Already present in feeds.conf.default"
    fi
fi

# 同时修改 diy.sh，确保本地构建也包含此 feed
DIY_SH="$WORKSPACE/diy.sh"
if [ -f "$DIY_SH" ]; then
    if ! grep -q "fantastic_packages" "$DIY_SH"; then
        # 在 feeds update 之前插入 feed 添加行
        sed -i '/\.\/scripts\/feeds update/a #添加 fantastic-packages feed\necho "src-git --root=feeds fantastic_packages https://github.com/fantastic-packages/packages.git;master" >> feeds.conf.default\n' "$DIY_SH"
        echo "[fantastic-feed] Added to diy.sh"
    fi
fi

echo "[fantastic-feed] Done"
