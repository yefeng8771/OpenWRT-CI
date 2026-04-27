#!/bin/bash
# momo-fix.sh — 移除 momo Makefile 对 sing-box 包的依赖
#
# sing-box 二进制由 inject-binaries.sh 注入到 /usr/bin/sing-box，
# 不走 opkg。momo 的 DEPENDS 里保留 +sing-box 会让 opkg 要求装上游 feed 里的
# sing-box 包（CUSTOM.txt 已设为 =n），导致 momo 自身也装不上。
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"

echo "[momo-fix] Removing sing-box dependency from momo Makefile..."
MOMO_FILE=$(find "$WORKSPACE/$WRT_DIR/package/" -maxdepth 4 -type f -wholename "*/momo/Makefile" 2>/dev/null | head -n 1)

if [ -f "$MOMO_FILE" ]; then
    # 用 ERE + g 全局替换，[[:space:]]* 兼容前导空格/Tab/紧贴 := 的情况。
    # 之前 's/ +sing-box//' 只匹配第一处且强制要有前导单空格。
    sed -i -E 's/[[:space:]]*\+sing-box//g' "$MOMO_FILE"
    echo "[momo-fix] Patched: $MOMO_FILE"
else
    echo "[momo-fix] WARNING: momo Makefile not found, skipping"
fi

echo "[momo-fix] Done"
