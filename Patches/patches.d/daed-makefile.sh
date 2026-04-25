#!/bin/bash
# daed-makefile.sh — 应用 daed Makefile 补丁
# 用自定义 Makefile 替换 daed 的 Makefile 以修复编译问题

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[daed-makefile] Applying daed Makefile patch..."

DAED_MAKEFILE="$WORKSPACE/$WRT_DIR/package/luci-app-daed/daed/Makefile"
PATCH_MAKEFILE="$WORKSPACE/patches/daed/Makefile"

if [ -f "$DAED_MAKEFILE" ] && [ -f "$PATCH_MAKEFILE" ]; then
    rm -rf "$DAED_MAKEFILE"
    cp -r "$PATCH_MAKEFILE" "$DAED_MAKEFILE"
    echo "[daed-makefile] Patched successfully"
else
    echo "[daed-makefile] Source or target not found, skipping"
    [ ! -f "$DAED_MAKEFILE" ] && echo "  Missing: $DAED_MAKEFILE"
    [ ! -f "$PATCH_MAKEFILE" ] && echo "  Missing: $PATCH_MAKEFILE"
fi

echo "[daed-makefile] Done"
