#!/bin/bash
# brand.sh — 品牌定制补丁
#
# 只动 diy.sh（用于本地 `./diy.sh` 调试与上游对齐）。
# CI 链路上的真实品牌值由 .github/workflows/QWRT.yml 直接静态指定，不靠 sed 注入，
# 这样上游同步时即使 QCA-6.12-VIKINGYFY.yml 被覆盖也不影响我们的构建产物。
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"

WRT_NAME='QWRT'
WRT_SSID='QWRT'
WRT_WORD='12345678'
WRT_THEME='argon'
WRT_IP='172.16.3.1'

echo "[brand] Applying brand customization to diy.sh..."
DIY_SH="$WORKSPACE/diy.sh"
if [ -f "$DIY_SH" ]; then
    sed -i "s/^export WRT_NAME=.*/export WRT_NAME='$WRT_NAME'/" "$DIY_SH"
    sed -i "s/^export WRT_SSID=.*/export WRT_SSID='$WRT_SSID'/" "$DIY_SH"
    sed -i "s/^export WRT_WORD=.*/export WRT_WORD='$WRT_WORD'/" "$DIY_SH"
    sed -i "s/^export WRT_THEME=.*/export WRT_THEME='$WRT_THEME'/" "$DIY_SH"
    sed -i "s/^export WRT_IP=.*/export WRT_IP='$WRT_IP'/" "$DIY_SH"
    # 用 | 作 sed 分隔符，避开引号嵌套——之前 "s/.../export WRT_CONFIG="X"/" 会被 shell 提前关闭
    sed -i 's|export WRT_CONFIG="IPQ60XX-NOWIFI"|export WRT_CONFIG="IPQ60XX-WIFI"|' "$DIY_SH"
    echo "[brand] diy.sh updated: NAME=$WRT_NAME IP=$WRT_IP CONFIG=IPQ60XX-WIFI"
fi

echo "[brand] Done"
