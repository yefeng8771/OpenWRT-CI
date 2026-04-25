#!/bin/bash
# packages.sh — 软件包增删补丁
# 在上游 Packages.sh 执行后追加/删除自定义包
# 原则：不修改上游的 Packages.sh，而是通过此脚本追加操作

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
PKG_DIR="${WORKSPACE}/${WRT_DIR:-wrt}/package"

echo "[packages] Applying package overrides..."

if [ ! -d "$PKG_DIR" ]; then
    echo "[packages] Package directory not found: $PKG_DIR, skipping"
    exit 0
fi

cd "$PKG_DIR"

# ============ 删除不需要的包 ============
REMOVE_PACKAGES=(
    "homeproxy"
    "nikki"
    "openclash"
    "passwall"
    "passwall2"
    "gecoosac"
    "vnt"
)

for pkg in "${REMOVE_PACKAGES[@]}"; do
    FOUND=$(find ./ -maxdepth 2 -type d -iname "*$pkg*" 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        echo "$FOUND" | while read -r dir; do
            rm -rf "$dir"
            echo "[packages] Removed: $dir"
        done
    fi
done

# ============ 新增包 ============
if [ ! -d "natmapt" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/openwrt-natmapt.git" natmapt-tmp
    mv -f natmapt-tmp natmapt
    echo "[packages] Added: natmapt"
fi

if [ ! -d "luci-app-natmapt" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/luci-app-natmapt.git" luci-app-natmapt
    echo "[packages] Added: luci-app-natmapt"
fi

if [ ! -d "luci-app-lucky" ]; then
    git clone --depth=1 --single-branch --branch main "https://github.com/sirpdboy/luci-app-lucky.git" luci-app-lucky
    echo "[packages] Added: luci-app-lucky"
fi

if [ ! -d "luci-app-tinyfilemanager" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/luci-app-tinyfilemanager.git" luci-app-tinyfilemanager
    echo "[packages] Added: luci-app-tinyfilemanager"
fi

# ============ mosdns: 移除源码编译版 ============
MOSDNS_DIRS=$(find ./ -maxdepth 2 -type d -iname "*mosdns*" 2>/dev/null || true)
if [ -n "$MOSDNS_DIRS" ]; then
    echo "$MOSDNS_DIRS" | while read -r dir; do
        rm -rf "$dir"
        echo "[packages] Removed mosdns package (will be injected as binary): $dir"
    done
fi

# ============ daed Makefile 补丁 ============
if [ -d "luci-app-daed/daed" ] && [ -f "$WORKSPACE/patches/daed/Makefile" ]; then
    rm -rf luci-app-daed/daed/Makefile
    cp -r "$WORKSPACE/patches/daed/Makefile" luci-app-daed/daed/
    echo "[packages] Applied daed Makefile patch"
fi

echo "[packages] Done"
