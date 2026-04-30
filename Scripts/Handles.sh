#!/bin/bash
set -euo pipefail

PKG_PATH="${GITHUB_WORKSPACE}/${WRT_DIR}/package/"
cd "$PKG_PATH"

# 当前仅保留仍可能影响 QWRT 主线稳定性的修正：
#   1. NSS 相关 init 启动顺序
#   2. Rust 构建开关

NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then
	sed -i 's/START=.*/START=85/g' "$NSS_DRV"
	echo "[handles] qca-nss-drv start order fixed"
fi

NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then
	sed -i 's/START=.*/START=86/g' "$NSS_PBUF"
	echo "[handles] qca-nss-pbuf start order fixed"
fi

RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile" | head -n 1)
if [ -n "$RUST_FILE" ] && [ -f "$RUST_FILE" ]; then
	sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"
	echo "[handles] rust build flags fixed"
fi

echo "[handles] Minimal package fixes done"