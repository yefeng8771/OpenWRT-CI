#!/bin/bash
set -euo pipefail
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
#   代理栈只保留裸核 sing-box + easytier，移除额外包装层和重复方案
#   gecoosac/vnt：不需要
#   tailscale/zerotier：组网走 easytier
#   vlmcsd/ddns-go：不需要
REMOVE_PACKAGES=(
    "homeproxy" "nikki" "openclash" "passwall" "passwall2"
    "momo" "mosdns" "daed"
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

# 修复上游 samba4-libs 漏声明 ICU 运行库依赖：
# 当前 QWRT feeds 的 samba4 4.22.7 会安装链接 libicui18n/libicuuc 的 .so，
# 但 Makefile 没有把 icu 写入 DEPENDS，导致 APK 打包时报
# "Package samba4-libs is missing dependencies"。
SAMBA4_MAKEFILE="${WORKSPACE}/${WRT_DIR:-wrt}/feeds/packages/net/samba4/Makefile"
if [ -f "$SAMBA4_MAKEFILE" ]; then
    if ! grep -q '+icu' "$SAMBA4_MAKEFILE"; then
        python3 - "$SAMBA4_MAKEFILE" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
if any('+icu' in line for line in lines):
    raise SystemExit(0)
for idx, line in enumerate(lines):
    if '+libuuid' in line:
        newline = '\n' if line.endswith('\n') else ''
        lines.insert(idx + 1, '\t+icu \\' + newline)
        path.write_text(''.join(lines))
        break
else:
    raise SystemExit(f"libuuid dependency marker not found in {path}")
PY
        echo "[packages] Patched samba4-libs dependency: +icu"
    else
        echo "[packages] samba4-libs already depends on icu"
    fi
else
    echo "[packages] WARNING: samba4 Makefile not found: $SAMBA4_MAKEFILE"
fi

# Install the in-repository StunDeck package template after the upstream source is cloned.
STUNDECK_TEMPLATE="${WORKSPACE}/package/stundeck"
if [ ! -f "${STUNDECK_TEMPLATE}/Makefile" ]; then
    echo "[packages] StunDeck template missing: ${STUNDECK_TEMPLATE}" >&2
    exit 1
fi
rm -rf "${PKG_DIR}/stundeck"
cp -a "${STUNDECK_TEMPLATE}" "${PKG_DIR}/stundeck"
echo "[packages] Added: stundeck"

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
