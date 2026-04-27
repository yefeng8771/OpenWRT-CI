#!/bin/bash
# easytier-pre.sh — 把 luci-app-easytier 的 version.mk 锁到最新 prerelease
#
# easytier/Makefile 的 Build/Prepare 会按 EASYTIER_VERSION 从 GitHub Releases
# 拉取对应架构的 easytier-core 二进制，本脚本只改版本号，不动其它逻辑。
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[easytier-pre] Updating easytier to latest prerelease..."

VERSION_FILE="$WORKSPACE/$WRT_DIR/package/luci-app-easytier/version.mk"
if [ ! -f "$VERSION_FILE" ]; then
    VERSION_FILE=$(find "$WORKSPACE/$WRT_DIR/package/" -maxdepth 3 -name "version.mk" -path "*easytier*" 2>/dev/null | head -n 1)
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "[easytier-pre] WARNING: version.mk not found, skipping"
    exit 0
fi

# 用 GITHUB_TOKEN 鉴权（CI 环境下默认有），匿名请求每小时 60 次会被限速
AUTH_HEADER=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

ET_TAG=$(curl -fsSL \
    "${AUTH_HEADER[@]}" \
    -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/EasyTier/EasyTier/releases" \
    | jq -r 'map(select(.prerelease == true)) | first | .tag_name')

if [ -z "$ET_TAG" ] || [ "$ET_TAG" = "null" ]; then
    echo "[easytier-pre] WARNING: Could not fetch prerelease tag (rate limited?), keeping current version"
    exit 0
fi

ET_VER="${ET_TAG#v}"
sed -i "s/^EASYTIER_VERSION=.*/EASYTIER_VERSION=$ET_VER/" "$VERSION_FILE"
echo "[easytier-pre] Updated to $ET_VER"

echo "[easytier-pre] Done"
