#!/bin/bash
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"
echo "[momo-fix] Removing sing-box dependency from momo..."
MOMO_FILE=$(find "$WORKSPACE/$WRT_DIR/package/" -maxdepth 3 -type f -wholename "*/momo/Makefile" | head -n 1)
if [ -f "$MOMO_FILE" ]; then
    sed -i 's/ +sing-box//' "$MOMO_FILE"
    echo "[momo-fix] Done"
fi
