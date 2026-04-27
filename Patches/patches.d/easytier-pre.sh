#!/bin/bash
# easytier-pre.sh — 更新 easytier 版本号为 prerelease
# easytier/Makefile 的 Build/Prepare 会自动从 GitHub releases 下载对应版本二进制
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"
echo "[easytier-pre] Updating easytier to prerelease..."
VERSION_FILE="$WORKSPACE/$WRT_DIR/package/luci-app-easytier/version.mk"
if [ ! -f "$VERSION_FILE" ]; then
    # Try alternate path (cloned directory name may differ)
    VERSION_FILE=$(find "$WORKSPACE/$WRT_DIR/package/" -maxdepth 3 -name "version.mk" -path "*/easytier/*" 2>/dev/null | head -n 1)
fi
if [ -f "$VERSION_FILE" ]; then
    ET_TAG=$(curl -sL "https://api.github.com/repos/EasyTier/EasyTier/releases" | jq -r 'map(select(.prerelease == true)) | first | .tag_name')
    if [ -n "$ET_TAG" ] && [ "$ET_TAG" != "null" ]; then
        ET_VER=$(echo "$ET_TAG" | sed 's/^v//')
        sed -i "s/EASYTIER_VERSION=.*/EASYTIER_VERSION=$ET_VER/g" "$VERSION_FILE"
        echo "[easytier-pre] Updated to $ET_VER"
    else
        echo "[easytier-pre] WARNING: Could not fetch prerelease tag"
    fi
else
    echo "[easytier-pre] WARNING: version.mk not found, skipping"
fi
echo "[easytier-pre] Done"
