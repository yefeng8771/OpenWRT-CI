#!/bin/bash
# packages.sh — 软件包增删补丁
# 在上游 Packages.sh 执行后追加/删除自定义包
# 原则：不修改上游的 Packages.sh，而是通过此脚本追加操作

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
PKG_DIR="${WRT_DIR:-wrt}/package"

echo "[packages] Applying package overrides..."

cd "$WORKSPACE/$PKG_DIR" 2>/dev/null || exit 0

# ============ 删除不需要的包 ============
# 上游可能安装了这些包，我们需要移除
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
    FOUND=$(find ./ -maxdepth 2 -type d -iname "*$pkg*" 2>/dev/null)
    if [ -n "$FOUND" ]; then
        echo "$FOUND" | while read -r dir; do
            rm -rf "$dir"
            echo "[packages] Removed: $dir"
        done
    fi
done

# ============ 新增包 ============
# 这些是上游没有的包

# natmapt
if [ ! -d "natmapt" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/openwrt-natmapt.git" natmapt-tmp
    mv -f natmapt-tmp natmapt
    echo "[packages] Added: natmapt"
fi

# luci-app-natmapt
if [ ! -d "luci-app-natmapt" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/luci-app-natmapt.git" luci-app-natmapt
    echo "[packages] Added: luci-app-natmapt"
fi

# luci-app-lucky
if [ ! -d "luci-app-lucky" ]; then
    git clone --depth=1 --single-branch --branch main "https://github.com/sirpdboy/luci-app-lucky.git" luci-app-lucky
    echo "[packages] Added: luci-app-lucky"
fi

# luci-app-tinyfilemanager
if [ ! -d "luci-app-tinyfilemanager" ]; then
    git clone --depth=1 --single-branch --branch master "https://github.com/muink/luci-app-tinyfilemanager.git" luci-app-tinyfilemanager
    echo "[packages] Added: luci-app-tinyfilemanager"
fi

# ============ mosdns: 移除源码编译版，使用 workflow 注入的预编译版 ============
# 上游 Packages.sh 中 sbwml/luci-app-mosdns 需要被注释或移除
# 这里删除其安装目录（如果存在）
MOSDNS_DIRS=$(find ./ -maxdepth 2 -type d -iname "*mosdns*" 2>/dev/null)
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
