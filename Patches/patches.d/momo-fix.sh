#!/bin/bash
# momo-fix.sh — 移除 momo 对 sing-box 的编译依赖
# momo 不需要内置 sing-box，使用外部注入的预编译版本

set -euo pipefail

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[momo-fix] Removing sing-box dependency from momo..."

MOMO_FILE=$(find "$WORKSPACE/$WRT_DIR/package/" -maxdepth 3 -type f -wholename "*/momo/Makefile" | head -n 1)
if [ -f "$MOMO_FILE" ]; then
    sed -i 's/ +sing-box//' "$MOMO_FILE"
    echo "[momo-fix] sing-box dependency removed from: $MOMO_FILE"
else
    echo "[momo-fix] momo Makefile not found, skipping"
fi

echo "[momo-fix] Done"
