#!/bin/bash
# easytier-pre.sh — 更新 easytier 到最新 prerelease 版本

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[easytier-pre] Updating easytier to prerelease..."

VERSION_FILE="$WORKSPACE/$WRT_DIR/package/luci-app-easytier/version.mk"
if [ -f "$VERSION_FILE" ]; then
    ET_TAG=$(curl -sL "https://api.github.com/repos/EasyTier/EasyTier/releases" | jq -r 'map(select(.prerelease == true)) | first | .tag_name')
    if [ -n "$ET_TAG" ]; then
        ET_VER=$(echo "$ET_TAG" | sed 's/^v//')
        sed -i "s/EASYTIER_VERSION=.*/EASYTIER_VERSION=$ET_VER/g" "$VERSION_FILE"
        echo "[easytier-pre] Updated to $ET_VER"
    else
        echo "[easytier-pre] No prerelease found"
    fi
else
    echo "[easytier-pre] version.mk not found, skipping"
fi

echo "[easytier-pre] Done"
