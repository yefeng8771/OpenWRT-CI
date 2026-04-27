#!/bin/bash
# packages.sh — 软件包增删补丁
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
PKG_DIR="${WORKSPACE}/${WRT_DIR:-wrt}/package"
echo "[packages] Applying package overrides..."
if [ ! -d "$PKG_DIR" ]; then
    echo "[packages] Package directory not found: $PKG_DIR, skipping"
    exit 0
fi
cd "$PKG_DIR"

# 删除不需要的插件
#   homeproxy/nikki/openclash/passwall*：替代品 daed
#   gecoosac/vnt：不需要
#   tailscale/zerotier：组网走 easytier
#   vlmcsd/ddns-go：不需要
REMOVE_PACKAGES=(
    "homeproxy" "nikki" "openclash" "passwall" "passwall2"
    "gecoosac" "vnt"
    "tailscale" "zerotier"
    "vlmcsd" "ddns-go"
)
for pkg in "${REMOVE_PACKAGES[@]}"; do
    FOUND=$(find ./ -maxdepth 2 -type d -iname "*$pkg*" 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        echo "$FOUND" | while read -r dir; do rm -rf "$dir"; echo "[packages] Removed: $dir"; done
    fi
done

# 删除 mosdns 源码包（改用 yyysuo 预编译二进制注入）
MOSDNS_DIRS=$(find ./ -maxdepth 2 -type d -iname "*mosdns*" 2>/dev/null || true)
if [ -n "$MOSDNS_DIRS" ]; then
    echo "$MOSDNS_DIRS" | while read -r dir; do rm -rf "$dir"; echo "[packages] Removed mosdns: $dir"; done
fi

# 新增插件
if [ ! -d "natmapt" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/openwrt-natmapt.git" natmapt-tmp
    mv -f natmapt-tmp natmapt; echo "[packages] Added: natmapt"
fi
if [ ! -d "luci-app-natmapt" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/luci-app-natmapt.git" luci-app-natmapt
    echo "[packages] Added: luci-app-natmapt"
fi
if [ ! -d "luci-app-tinyfilemanager" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/luci-app-tinyfilemanager.git" luci-app-tinyfilemanager
    echo "[packages] Added: luci-app-tinyfilemanager"
fi

echo "[packages] Done"
