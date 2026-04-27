#!/bin/bash
set -euo pipefail
WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_DIR="${WRT_DIR:-wrt}"
echo "[daed-makefile] Applying daed Makefile patch..."
DAED_MAKEFILE="$WORKSPACE/$WRT_DIR/package/luci-app-daed/daed/Makefile"
PATCH_MAKEFILE="$WORKSPACE/patches/daed/Makefile"
if [ -f "$DAED_MAKEFILE" ] && [ -f "$PATCH_MAKEFILE" ]; then
    rm -rf "$DAED_MAKEFILE"
    cp -r "$PATCH_MAKEFILE" "$DAED_MAKEFILE"
    echo "[daed-makefile] Patched"
fi
echo "[daed-makefile] Done"
