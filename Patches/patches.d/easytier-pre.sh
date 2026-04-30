#!/bin/bash
# easytier-pre.sh — 把 luci-app-easytier 的 version.mk 锁到最新 prerelease
#
# easytier 保持上游构建逻辑，本脚本只负责更新版本号，
# 不改 Makefile 的下载/打包流程。

set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[easytier-pre] Updating easytier to latest prerelease..."

VERSION_FILE="$WORKSPACE/$WRT_DIR/package/luci-app-easytier/version.mk"
if [ ! -f "$VERSION_FILE" ]; then
    VERSION_FILE=$(find "$WORKSPACE/$WRT_DIR/package/" -maxdepth 3 -name "version.mk" -path "*easytier*" 2>/dev/null | head -n 1)
fi

if [ -z "$VERSION_FILE" ] || [ ! -f "$VERSION_FILE" ]; then
    echo "[easytier-pre] WARNING: version.mk not found, skipping"
    exit 0
fi

GH_HEADERS=(-H 'Accept: application/vnd.github+json')
if [ -n "${GITHUB_TOKEN:-}" ]; then
    GH_HEADERS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

ET_VER=$(curl -fsSL "${GH_HEADERS[@]}" \
    "https://api.github.com/repos/EasyTier/EasyTier/releases" \
    | jq -r '[ .[] | select(.draft == false and .prerelease == true) | .tag_name ][0]')

if [ -z "$ET_VER" ] || [ "$ET_VER" = "null" ]; then
    echo "[easytier-pre] WARNING: Could not fetch prerelease tag (rate limited?), keeping current version"
    exit 0
fi

sed -i "s/^EASYTIER_VERSION=.*/EASYTIER_VERSION=$ET_VER/" "$VERSION_FILE"
echo "[easytier-pre] Updated to $ET_VER"

echo "[easytier-pre] Done"
